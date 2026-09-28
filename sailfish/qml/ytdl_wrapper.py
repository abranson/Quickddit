#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import unicode_literals
import importlib.machinery
import importlib.util
import json
import os
import subprocess
import sys
import pyotherside

# Keep these values in sync with Settings::VideoDownloader.
BUNDLED_YOUTUBE_DL = 0
INSTALLED_YOUTUBE_DL = 1
INSTALLED_YT_DLP = 2
DOWNLOADER_EXECUTABLE = 3
EXECUTABLE_TIMEOUT = 120

_bundled_path = os.path.realpath(os.path.join(os.path.dirname(__file__), '..'))
_backend = None
_backend_module = None

downloaddir = '/tmp'

class MyLogger(object):
    def debug(self, msg):
        pyotherside.send('log', 'debug: ' + msg)

    def warning(self, msg):
        pyotherside.send('log', 'warn: ' + msg)

    def error(self, msg):
        pyotherside.send('log', 'err: ' + msg)

logger = MyLogger()

ytdl_info_opts = {
    'dump_single_json': 'true',
    'simulate': 'true',
    'noplaylist': 'true',
    'logger': logger
}

def loadBackend(backend):
    global _backend, _backend_module

    if backend == _backend:
        return _backend_module

    if backend == BUNDLED_YOUTUBE_DL:
        name = 'youtube_dl'
        paths = [_bundled_path]
        label = 'Bundled youtube-dl'
    elif backend in (INSTALLED_YOUTUBE_DL, INSTALLED_YT_DLP):
        name = 'yt_dlp' if backend == INSTALLED_YT_DLP else 'youtube_dl'
        # The bundled package must never satisfy an installed-backend request.
        paths = [path for path in sys.path if os.path.realpath(path) != _bundled_path]
        label = 'Installed ' + name.replace('_', '-')
    else:
        raise RuntimeError('Unknown video downloader')

    spec = importlib.machinery.PathFinder.find_spec(name, paths)
    if spec is None:
        raise RuntimeError(label + ' is unavailable. Install its system Python package '
                           'or select another video downloader in Settings.')

    # Both copies of youtube-dl use absolute imports under the same package name.
    # Switch the entire package, including cached extractor modules, together.
    previous = {key: value for key, value in sys.modules.copy().items()
                if key == name or key.startswith(name + '.')}
    for key in previous:
        del sys.modules[key]
    try:
        module = importlib.util.module_from_spec(spec)
        sys.modules[name] = module
        spec.loader.exec_module(module)
    except Exception as error:
        for key in list(sys.modules):
            if key == name or key.startswith(name + '.'):
                del sys.modules[key]
        sys.modules.update(previous)
        raise RuntimeError(label + ' could not be loaded: ' + str(error))

    _backend = backend
    _backend_module = module
    return module

def setDownloadDir(dir):
    downloaddir = dir

def retrieveExecutableVideoInfo(url, executable):
    executable = os.path.expanduser(executable.strip())
    if not executable:
        pyotherside.send('fail', 'Select a video downloader executable in Settings.')
        return None

    try:
        # Pass the URL as one argument, never through a shell. Ignore downloader
        # configuration so this metadata request cannot trigger configured downloads.
        result = subprocess.run(
            [executable, '--ignore-config', '--dump-single-json', '--skip-download',
             '--no-playlist', '--', url],
            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            timeout=EXECUTABLE_TIMEOUT)
    except OSError as error:
        pyotherside.send('fail', 'Could not run video downloader: ' + str(error)
                         + '. Check that it and its dependencies are accessible '
                         'inside Quickddit\'s sandbox.')
        return None
    except subprocess.TimeoutExpired:
        pyotherside.send('fail', 'Video downloader timed out.')
        return None

    diagnostic = result.stderr.decode('utf-8', errors='replace').strip()
    if result.returncode:
        pyotherside.send('fail', diagnostic[-2000:] or
                         'Video downloader exited with code ' + str(result.returncode))
        return None

    try:
        info = json.loads(result.stdout.decode('utf-8'))
    except (ValueError, UnicodeError):
        pyotherside.send('fail', 'Video downloader returned invalid JSON.')
        return None

    video = info
    if isinstance(info, dict) and info.get('_type') == 'playlist':
        entries = info.get('entries')
        video = entries[0] if isinstance(entries, list) and entries else None
    if not isinstance(video, dict) or not (
            isinstance(video.get('formats'), list) and video['formats']
            and all(isinstance(item, dict) for item in video['formats'])
            or video.get('formats') is None and isinstance(video.get('url'), str)):
        pyotherside.send('fail', 'Video downloader returned no video information.')
        return None
    return info

def retrieveVideoInfo(url, backend=BUNDLED_YOUTUBE_DL, executable=''):
    if backend == DOWNLOADER_EXECUTABLE:
        return retrieveExecutableVideoInfo(url, executable)

    try:
        module = loadBackend(backend)
    except RuntimeError as error:
        pyotherside.send('fail', str(error))
        return None

    try:
        logger.debug('retrieveVideoUrl ' + str(url))
        with module.YoutubeDL(ytdl_info_opts) as downloader:
            info = downloader.extract_info(url, download=False)
            # yt-dlp may return lazy objects that PyOtherSide cannot convert.
            if hasattr(downloader, 'sanitize_info'):
                info = downloader.sanitize_info(info)
            return info
    except module.utils.DownloadError as e:
        pyotherside.send('fail', ','.join(e.args))

def downloadVideo(url):
    logger.debug('downloadVideo ' + str(url))
    # not implemented yet
