import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0

AbstractPage {
    id: videoViewPage
    title: "Video"

    property alias videoUrl: mediaPlayer.source
    property string origUrl

    SilicaFlickable {
        id: videoFlickable
        anchors { top: parent.top; left: parent.left; right: parent.right; bottom: parent.bottom }

        PullDownMenu {
            MenuItem {
                text: "URL"
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
                autoPlay: true
                onStopped: playPauseButton.opacity = 1
                onError: console.log(errorString)
            }

            Item {
                id: spinner
                anchors.centerIn: parent

                width: busyIndicator.width
                height: busyIndicator.height
                visible: mediaPlayer.bufferProgress < 1 && mediaPlayer.error === MediaPlayer.NoError

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
                visible: mediaPlayer.error !== MediaPlayer.NoError
                text: qsTr("Error loading video")
            }
        }

        Slider {
            id: progressBar
            enabled: mediaPlayer.seekable
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

    Timer {
        id: hideTimer
        running: true
        interval: 1500
        onTriggered: {
            playPauseButton.opacity = 0
        }
    }
}
