import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import types
import unittest
from unittest.mock import patch


WRAPPER = Path(__file__).resolve().parents[1] / 'sailfish/qml/ytdl_wrapper.py'


class DownloaderTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.bundled = Path(self.temp.name) / 'bundled'
        self.installed = Path(self.temp.name) / 'installed'
        self.bundled.mkdir()
        self.installed.mkdir()
        self.events = []
        bridge = types.ModuleType('pyotherside')
        bridge.send = lambda *args: self.events.append(args)
        self.modules = patch.dict(sys.modules, {'pyotherside': bridge})
        self.modules.start()
        self.addCleanup(self.modules.stop)
        spec = importlib.util.spec_from_file_location('quickddit_test_wrapper', WRAPPER)
        self.wrapper = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.wrapper)
        self.wrapper._bundled_path = str(self.bundled)
        # Deliberately put the bundled directory first, as older QML code did.
        self.paths = patch.object(sys, 'path', [str(self.bundled), str(self.installed)])
        self.paths.start()
        self.addCleanup(self.paths.stop)

    def package(self, root, name, marker, sanitize=False):
        package = root / name
        package.mkdir()
        (package / 'extractor.py').write_text('MARKER = {!r}\n'.format(marker))
        (package / '__init__.py').write_text('''
from {name} import extractor
class utils:
    class DownloadError(Exception):
        pass
class YoutubeDL:
    def __init__(self, options):
        self.options = options
    def __enter__(self):
        return self
    def __exit__(self, *args):
        pass
    def extract_info(self, url, download):
        assert download is False
        if url == 'error':
            raise utils.DownloadError('extraction failed')
        return {{'source': extractor.MARKER, 'url': url}}
'''.format(name=name))
        if sanitize:
            with (package / '__init__.py').open('a') as output:
                output.write('''
    def sanitize_info(self, info):
        return dict(info, sanitized=True)
''')

    def test_default_is_bundled_even_when_installed(self):
        self.package(self.bundled, 'youtube_dl', 'bundled')
        self.package(self.installed, 'youtube_dl', 'installed')
        result = self.wrapper.retrieveVideoInfo('https://example.org/video')
        self.assertEqual(result['source'], 'bundled')

    def test_switching_youtube_dl_replaces_cached_extractors(self):
        self.package(self.bundled, 'youtube_dl', 'bundled')
        self.package(self.installed, 'youtube_dl', 'installed')
        for backend, expected in [(0, 'bundled'), (1, 'installed'), (0, 'bundled')]:
            result = self.wrapper.retrieveVideoInfo('https://example.org/video', backend)
            self.assertEqual(result['source'], expected)

    def test_missing_installed_package_does_not_use_cached_bundle(self):
        self.package(self.bundled, 'youtube_dl', 'bundled')
        self.wrapper.retrieveVideoInfo('https://example.org/video')
        self.assertIsNone(self.wrapper.retrieveVideoInfo('https://example.org/video', 1))
        self.assertEqual(self.events[-1][0], 'fail')
        self.assertIn('Installed youtube-dl is unavailable', self.events[-1][1])

    def test_missing_bundle_does_not_use_installed_package(self):
        self.package(self.installed, 'youtube_dl', 'installed')
        self.assertIsNone(self.wrapper.retrieveVideoInfo('https://example.org/video'))
        self.assertIn('Bundled youtube-dl is unavailable', self.events[-1][1])

    def test_yt_dlp_is_sanitized(self):
        self.package(self.installed, 'yt_dlp', 'yt-dlp', sanitize=True)
        result = self.wrapper.retrieveVideoInfo('https://example.org/video', 2)
        self.assertEqual(result['source'], 'yt-dlp')
        self.assertTrue(result['sanitized'])

    def test_broken_installed_package_preserves_working_bundle(self):
        self.package(self.bundled, 'youtube_dl', 'bundled')
        self.package(self.installed, 'youtube_dl', 'installed')
        (self.installed / 'youtube_dl/__init__.py').write_text('raise ImportError("dependency missing")')
        self.wrapper.retrieveVideoInfo('https://example.org/video')
        self.assertIsNone(self.wrapper.retrieveVideoInfo('https://example.org/video', 1))
        self.assertIn('could not be loaded: dependency missing', self.events[-1][1])
        result = self.wrapper.retrieveVideoInfo('https://example.org/video')
        self.assertEqual(result['source'], 'bundled')

    def test_extraction_failure_is_reported(self):
        self.package(self.installed, 'yt_dlp', 'yt-dlp')
        self.assertIsNone(self.wrapper.retrieveVideoInfo('error', 2))
        self.assertEqual(self.events[-1], ('fail', 'extraction failed'))

    def executable(self, body):
        path = Path(self.temp.name) / 'downloader with spaces'
        path.write_text('#!' + sys.executable + '\n' + body)
        path.chmod(0o700)
        return str(path)

    def test_executable_receives_url_without_shell_expansion(self):
        executable = self.executable('import json, sys\n'
                                     'print(json.dumps({"url": sys.argv[-1], "args": sys.argv[1:]}))\n')
        url = 'https://example.org/?x=1&y=$(touch should-not-exist);%20'
        info = self.wrapper.retrieveVideoInfo(url, 3, executable)
        self.assertEqual(info['url'], url)
        self.assertEqual(info['args'], ['--ignore-config', '--dump-single-json',
                                       '--skip-download', '--no-playlist', '--', url])

    def test_executable_nonzero_exit_reports_stderr(self):
        executable = self.executable('import sys\n'
                                     'sys.stderr.write("extractor failed")\n'
                                     'sys.exit(2)\n')
        self.assertIsNone(self.wrapper.retrieveVideoInfo('https://example.org/', 3, executable))
        self.assertEqual(self.events[-1], ('fail', 'extractor failed'))

    def test_executable_missing_or_not_executable_reports_access_error(self):
        for path in [str(Path(self.temp.name) / 'missing'), self.executable('pass\n')]:
            if Path(path).exists():
                Path(path).chmod(0o600)
            self.assertIsNone(self.wrapper.retrieveVideoInfo('https://example.org/', 3, path))
            self.assertIn('Could not run video downloader', self.events[-1][1])
            self.assertIn('sandbox', self.events[-1][1])

    def test_executable_empty_path_is_rejected(self):
        self.assertIsNone(self.wrapper.retrieveVideoInfo('https://example.org/', 3, '  '))
        self.assertIn('Select a video downloader executable', self.events[-1][1])

    def test_executable_bad_json_is_rejected(self):
        executable = self.executable('print("not JSON")\n')
        self.assertIsNone(self.wrapper.retrieveVideoInfo('https://example.org/', 3, executable))
        self.assertEqual(self.events[-1], ('fail', 'Video downloader returned invalid JSON.'))

    def test_executable_wrong_json_shape_is_rejected(self):
        for value in [None, [], {}, {'title': 'No video'}, {'_type': 'playlist', 'entries': []}]:
            with self.subTest(value=value):
                executable = self.executable('print({!r})\n'.format(json.dumps(value)))
                self.assertIsNone(self.wrapper.retrieveVideoInfo('https://example.org/', 3, executable))
                self.assertEqual(self.events[-1], ('fail', 'Video downloader returned no video information.'))

    def test_executable_playlist_metadata_is_accepted(self):
        info = {'_type': 'playlist', 'entries': [{'formats': [{'url': 'https://example.org/video'}]}]}
        executable = self.executable('print({!r})\n'.format(json.dumps(info)))
        self.assertEqual(self.wrapper.retrieveVideoInfo('https://example.org/', 3, executable), info)

    def test_executable_timeout_is_reported(self):
        executable = self.executable('import time\ntime.sleep(5)\n')
        with patch.object(self.wrapper, 'EXECUTABLE_TIMEOUT', 0.05):
            self.assertIsNone(self.wrapper.retrieveVideoInfo('https://example.org/', 3, executable))
        self.assertEqual(self.events[-1], ('fail', 'Video downloader timed out.'))


if __name__ == '__main__':
    unittest.main()
