/*
    Quickddit - Reddit client for mobile phones
    Copyright (C) 2015-2018  Sander van Grieken

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
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0
import harbour.quickddit.Core 1.0

Item {
    id: thumbnail

    property variant link
    property bool enabled: true
    property bool showLinkTypeIndicator: true

    property alias source: image.source
    property alias sourceSize: image.sourceSize
    property alias status: image.status

    // the MouseArea below takes the press, so forward long presses to the list item
    signal longPressed()

    // blurred until the user taps once to reveal it
    property bool revealed: false
    readonly property bool blurred: !revealed && image.status === Image.Ready
                                    && ((settings.blurNSFW && !!link.isNSFW) || (settings.blurSpoilers && !!link.isSpoiler))

    implicitWidth: image.implicitWidth
    implicitHeight: image.implicitHeight

    Image {
        id: image
        anchors.fill: parent
        source: link.thumbnailUrl
        asynchronous: true
        visible: !thumbnail.blurred
    }

    FastBlur {
        anchors.fill: image
        source: image
        radius: 64
        visible: thumbnail.blurred
    }

    Label {
        anchors.centerIn: parent
        width: parent.width - 2 * constant.paddingSmall
        visible: thumbnail.blurred
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fontSizeExtraSmall
        font.bold: true
        color: "white"
        style: Text.Outline
        styleColor: "black"
        text: (settings.blurNSFW && !!link.isNSFW) ? qsTr("NSFW") : qsTr("Spoiler")
    }

    MouseArea {
        anchors.fill: parent
        enabled: (!link.isSelfPost || thumbnail.blurred) && thumbnail.enabled
        onClicked: {
            if (thumbnail.blurred)
                thumbnail.revealed = true;
            else
                globalUtils.openLink(link.url);
        }
        onPressAndHold: thumbnail.longPressed()
    }

    onStatusChanged: {
        if (thumbnail.status === Image.Ready)
            applyScale();
    }

    Connections {
        target: settings
        onThumbnailScaleChanged: applyScale()
    }

    function applyScale() {
        var scale = QMLUtils.pScale // ScaleAuto
        switch (settings.thumbnailScale) {
        case Settings.Scale100: scale = 1; break;
        case Settings.Scale125: scale = 1.25; break;
        case Settings.Scale150: scale = 1.5; break;
        case Settings.Scale175: scale = 1.75; break;
        case Settings.Scale200: scale = 2; break;
        case Settings.Scale250: scale = 2.5; break;
        }

        width = sourceSize.width * scale
        height = sourceSize.height * scale
    }

    Rectangle {
        color: Theme.colorScheme ? "white" : "black"
        opacity: 0.5
        visible: linkTypeIndicator.visible
        width: linkTypeIndicator.width/2
        height: linkTypeIndicator.height/2
        anchors {
            bottom: thumbnail.bottom
            left: thumbnail.left
        }
    }

    Image {
        id: linkTypeIndicator
        opacity: 0.8
        visible: settings.showLinkType && showLinkTypeIndicator && thumbnail.status === Image.Ready && !thumbnail.blurred
        width: 24 * QMLUtils.pScale
        height: 24 * QMLUtils.pScale
        source: globalUtils.previewableImage(link.url) ? "image://theme/icon-m-image?" + Theme.primaryColor
                : globalUtils.previewableVideo(link.url) ? "image://theme/icon-m-video?" + Theme.primaryColor
                : globalUtils.redditLink(link.url) ? "image://theme/icon-m-forward?" + Theme.primaryColor
                : "image://theme/icon-m-link?" + Theme.primaryColor
        anchors {
            bottom: thumbnail.bottom
            left: thumbnail.left
            bottomMargin: -12 * QMLUtils.pScale
            leftMargin: -12 * QMLUtils.pScale
        }
    }
}
