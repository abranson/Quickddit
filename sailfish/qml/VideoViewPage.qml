/*
    Quickddit - Reddit client for mobile phones
    Copyright (C) 2017  Sander van Grieken

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see [http://www.gnu.org/licenses/].
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0
import harbour.quickddit.Core 1.0

AbstractPage {
    id: videoViewPage
    title: qsTr("Video")

    property string videoUrl
    property string origUrl

    property bool error: false

    SilicaFlickable {
        id: videoFlickable
        anchors { top: parent.top; left: parent.left; right: parent.right; bottom: parent.bottom }

        PullDownMenu {
            MenuItem {
                text: qsTr("URL")
                onClicked: globalUtils.createOpenLinkDialog(origUrl || videoUrl);
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                playPauseButton.opacity = 1
                if (mediaPlayer.playbackState == MediaPlayer.PlayingState)
                    hideTimer.restart()
            }
        }

        VideoOutput {
            anchors.fill: parent

            source: MediaPlayer {
                id: mediaPlayer
                autoPlay: false
                onDurationChanged: {
                    // clamp number of loops so we loop for 1 minute max (holy holy battery)
                    if (duration < 0)
                        return
                    if (!settings.loopVideos)
                        return
                    if (duration == 0)
                        loops = 1
                    else
                        loops = Math.max(1, Math.round(60000/duration))
                }
                onStopped: playPauseButton.opacity = 1
                onError: {
                    infoBanner.warning(errorString);
                    console.log(errorString);
                }

                onBufferProgressChanged: {
                    if (bufferProgress > 0.95)
                        play();
                    else if (bufferProgress < 0.05)
                        pause();
                }

                onSourceChanged: console.log("media player source url: " + source)
                onStatusChanged: {
                    if (status === MediaPlayer.Loaded)
                        play()
                }
            }

            Item {
                id: spinner
                anchors.centerIn: parent

                width: busyIndicator.width
                height: busyIndicator.height
                visible: mediaPlayer.bufferProgress < 1 && mediaPlayer.status !== MediaPlayer.Loaded && mediaPlayer.error === MediaPlayer.NoError && !error

                BusyIndicator {
                    id: busyIndicator
                    size: BusyIndicatorSize.Large
                    running: true
                }

                Label {
                    anchors.centerIn: parent
                    font.pixelSize: constant.fontSizeSmall
                    text: Math.round(mediaPlayer.bufferProgress * 100) + "%"
                }
            }

            Label {
                id: errorText
                anchors.centerIn: parent
                visible: mediaPlayer.error !== MediaPlayer.NoError || error
                text: qsTr("Error loading video")
            }
        }

        Text {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                leftMargin: constant.paddingLarge
                rightMargin: constant.paddingLarge
                topMargin: constant.paddingLarge
            }
            text: ( mediaPlayer.metaData.videoCodec !== undefined ? mediaPlayer.metaData.videoCodec + " | " : "" ) +
                ( mediaPlayer.metaData.audioCodec !== undefined ? mediaPlayer.metaData.audioCodec + " | " : "" ) +
                ( mediaPlayer.metaData.resolution !== undefined ? mediaPlayer.metaData.resolution.width + " x " + mediaPlayer.metaData.resolution.height : "")
            visible: mediaPlayer.metaData !== undefined
            font.pixelSize: constant.fontSizeSmall
            color: constant.colorHi
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            opacity: playPauseButton.opacity
        }

        Slider {
            id: progressBar
            enabled: mediaPlayer.seekable && opacity > 0
            opacity: playPauseButton.opacity
            anchors {
                left: parent.left
                bottom: parent.bottom
                right: parent.right
            }
            maximumValue: mediaPlayer.duration > 0 ? mediaPlayer.duration : 1
            value: mediaPlayer.position
            onReleased: {
                mediaPlayer.seek(value)
                value = Qt.binding(function() { return mediaPlayer.position; })
                playPauseButton.opacity = 1
                hideTimer.restart()
            }
        }

        Text {
            anchors {
                left: progressBar.left
                bottom: progressBar.top
                leftMargin: progressBar.leftMargin
                bottomMargin: -progressBar._extraPadding
            }
            text: globalUtils.formatDuration(Math.floor(mediaPlayer.position/1000))
            font.pixelSize: constant.fontSizeLarge
            color: constant.colorLight
            opacity: playPauseButton.opacity
        }

        Text {
            anchors {
                right: progressBar.right
                bottom: progressBar.top
                rightMargin: progressBar.rightMargin
                bottomMargin: -progressBar._extraPadding
            }
            text: globalUtils.formatDuration(Math.floor(mediaPlayer.duration/1000))
            font.pixelSize: constant.fontSizeLarge
            color: constant.colorLight
            opacity: playPauseButton.opacity
        }

        Image {
            id: playPauseButton
            source: "image://theme/icon-l-" + (mediaPlayer.playbackState === MediaPlayer.PlayingState ? "pause" : "play")

            anchors {
                bottom: progressBar.top
                horizontalCenter: parent.horizontalCenter
            }

            MouseArea {
                anchors.fill: parent
                enabled: playPauseButton.opacity > 0
                onClicked: {
                    if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                        mediaPlayer.pause()
                        hideTimer.stop()
                        playPauseButton.opacity = 1
                    } else if (mediaPlayer.playbackState === MediaPlayer.PausedState || mediaPlayer.playbackState === MediaPlayer.StoppedState) {
                        mediaPlayer.play()
                        hideTimer.start()
                    }
                }
            }
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }

    Component.onCompleted: {
        if (videoUrl === "") {
            // resolve with youtube-dl
            console.log("only origUrl set, resolving with youtube-dl...")
            python.requestVideoUrlFor(origUrl)
        } else {
            mediaPlayer.source = videoUrl
        }
    }

    Timer {
        id: hideTimer
        running: true
        interval: 1500
        onTriggered: {
            playPauseButton.opacity = 0
        }
    }

    Connections {
        target: python
        onVideoInfo: {
            var i
            var preferLoDef = settings.preferredVideoSize === Settings.VS360
            var currUrl
            var currHeight = 0
            var adaptiveUrl
            var adaptiveCurrHeight = 0
            var formats = python.info["_type"] === "playlist" ? python.info["entries"][0]["formats"] : python.info["formats"]

            function checkUrl(url, height, adaptive, msg) {
                if (height === undefined) return
                var desiredHeight = preferLoDef?360:720
                if (Math.abs(desiredHeight - height) >= 
                        Math.abs(desiredHeight - (adaptive ? adaptiveCurrHeight : currHeight))) return;
                // better match
                if (adaptive) {
                    adaptiveCurrHeight = height
                    adaptiveUrl = url;
                } else {
                    currHeight = height
                    currUrl = url;
                }
                console.log(msg);
            }

            function isHlsManifest(f) {
                var manifest = f["manifest_url"] || ""
                var url = f["url"] || ""
                var protocol = f["protocol"] || ""
                var isDash = manifest.indexOf(".mpd") > -1 || url.indexOf(".mpd") > -1 || protocol.indexOf("dash") > -1
                var isHls = manifest.indexOf(".m3u8") > -1 || url.indexOf(".m3u8") > -1 || protocol.indexOf("m3u8") === 0 || protocol.indexOf("hls") === 0
                return isHls && !isDash
            }

            if (formats === undefined)
                formats = [ python.info ]

            for (i = 0; i < formats.length; i++) {
                var format = formats[i]

                if (isHlsManifest(format)) {
                    var manifestUrl = format["manifest_url"] || format["url"]
                    var height = format["height"]
                    checkUrl(manifestUrl, height, true, "Adaptive stream selected: " + format["format_id"] + ". Height:"+height)
                }

                // selection by format_id for youtube, vimeo, streamable
                // mp4-mobile: 360p (streamable.com)
                // 18: 360p,mp4,acodec mp4a.40.2,vcodec avc1.42001E (youtube)
                // 22: 720p,mp4,acodec mp4a.40.2,vcodec avc1.64001F (youtube)
                // http-360p: 360p (vimeo)
                // http-720p, 720p (vimeo)
                if (~["mp4-mobile","18","http-360p","22","http-720p"].indexOf(format["format_id"])) {
                    if (format["format_id"] !== undefined && format["format_id"].indexOf("av01") > -1) continue; // poorly supported
                    var idHeight = ~["22","http-720p"].indexOf(format["format_id"]) ? 720 : 360
                    checkUrl(format["url"], idHeight, false, "format selected by id " + format["format_id"])
                } else if (~["mp4","webm"].indexOf(format["ext"]) && ~[360,480,720].indexOf(format["height"])) {
                    if (format["format_id"] !== undefined && format["format_id"].indexOf("av01") > -1) continue; // poorly supported
                    checkUrl(format["url"], format["height"], false, "format selected by ext " + format["ext"] + " and height " + format["height"])
                }
            }

            // Special Reddit video hack
            if (python.info["extractor"].indexOf("Reddit") === 0) {
                for (i = 0; i < formats.length; i++) {
                    var format = formats[i]
                    // selection by height if format_id is like hls-*, for v.redd.it (with 'deref' HLS stream by string replace, so only works for v.redd.it)
                    if (format["format_id"].indexOf("hls-") !== 0)
                        continue
                    if (format["height"] === undefined) // audio
                        continue
                    // acodec none,vcodec one of avc1.4d001f,avc1.4d001e,avc1.42001e
                    if (format["height"] <= 480) {
                        checkUrl(format["url"].replace("_v4.m3u8",".ts"), format["height"], 
                            false, "Reddit video format selected by id " + format["format_id"] + " and height <= 480")  // 'deref' by string replace
                    } else {
                        console.log()
                        checkUrl(format["url"].replace("_v4.m3u8",".ts"), format["height"], 
                            false, "Reddit video format selected by id " + format["format_id"] + " and height > 480")  // 'deref' by string replace
                    }
                }
            }

            // Return most preferred URL
            if (settings.preferAdaptive && adaptiveUrl !== undefined) {
                mediaPlayer.source = adaptiveUrl
                return
            }
            if (currUrl !== undefined) {
                mediaPlayer.source = currUrl
                return
            }

            // Else find any mp4 or webm URL and try that
            for (i = 0; i < formats.length; i++) {
                var format = formats[i]
                if (~["mp4","webm"].indexOf(format["ext"])) {
                    console.log("Fallback format selected: " + format["format_id"])
                    mediaPlayer.source = format["url"]
                    return;
                }
            }
            // Run out of options. Fail.
            fail(qsTr("Problem finding stream URL"))
        }

        onError: {
            error = true
            infoBanner.warning(qsTr("youtube-dl error: %1").arg(traceback));
        }

        onFail: {
            error = true
            infoBanner.warning(reason);
        }

    }

    DisplayBlanking {
        preventBlanking: (mediaPlayer.playbackState !== MediaPlayer.StoppedState && mediaPlayer.playbackState !== MediaPlayer.PausedState)
    }
}
