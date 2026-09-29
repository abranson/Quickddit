/*
    Quickddit - Reddit client for mobile phones
    Copyright (C) 2026  Joshua Jun

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

// Card layout for a post: header, title, large preview image and a score/comments footer.
// Posts without a preview image fall back to a small thumbnail next to the title.
Column {
    id: card

    property variant link
    property bool highlighted: false
    property bool showSubreddit: true

    // horizontal space around the column that the preview image bleeds into
    property int bleed: 0

    readonly property bool hasPreview: String(link.previewUrl) !== "" && link.previewWidth > 0 && link.previewHeight > 0
    // set when the preview fails to load, so the card collapses to the thumbnail layout
    property bool previewFailed: false
    readonly property bool showPreview: hasPreview && !previewFailed

    // long press on the preview or thumbnail, which would otherwise not reach the list item
    signal longPressed()

    // blurred until the user taps once to reveal it
    property bool revealed: false
    readonly property bool blurred: !revealed && previewImage.status === Image.Ready
                                    && ((settings.blurNSFW && !!link.isNSFW) || (settings.blurSpoilers && !!link.isSpoiler))

    spacing: constant.paddingMedium

    Text {
        width: parent.width
        font.pixelSize: constant.fontSizeSmaller
        color: highlighted ? Theme.secondaryHighlightColor : constant.colorMid
        elide: Text.ElideRight
        text: (showSubreddit ? "r/" + link.subreddit + " · " : "") + "u/" + link.author + " · " + link.created
    }

    PostBubbles {
        width: parent.width
        visible: !empty
        link: card.link
    }

    Item {
        width: parent.width
        height: Math.max(titleText.height, thumbnailLoader.height)

        Text {
            id: titleText
            anchors {
                left: parent.left
                right: thumbnailLoader.active ? thumbnailLoader.left : parent.right
                rightMargin: thumbnailLoader.active ? constant.paddingMedium : 0
            }
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            maximumLineCount: 4
            font.pixelSize: constant.fontSizeDefault
            font.bold: true
            color: highlighted ? Theme.highlightColor : constant.colorLight
            text: link.title
        }

        Loader {
            id: thumbnailLoader
            anchors.right: parent.right
            active: !showPreview && String(link.thumbnailUrl) !== ""
            sourceComponent: PostThumbnail {
                link: card.link
                onLongPressed: card.longPressed()
            }
        }
    }

    Text {
        width: parent.width
        visible: !showPreview && !!link.isSelfPost && link.text !== ""
        textFormat: Text.StyledText
        wrapMode: Text.Wrap
        elide: Text.ElideRight
        maximumLineCount: 3
        font.pixelSize: constant.fontSizeSmaller
        color: highlighted ? Theme.secondaryHighlightColor : constant.colorMid
        linkColor: color
        text: visible ? globalUtils.formatForStyledText(link.text) : ""
    }

    Item {
        id: preview
        visible: showPreview
        x: -bleed
        width: parent.width + 2 * bleed
        // keep tall images from taking over the whole screen
        height: visible ? Math.min(width * link.previewHeight / link.previewWidth, Screen.width * 1.25) : 0
        clip: true

        Rectangle {
            anchors.fill: parent
            color: Theme.rgba(constant.colorMid, 0.1)
            visible: previewImage.status !== Image.Ready
        }

        Image {
            id: previewImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: width
            asynchronous: true
            source: hasPreview ? link.previewUrl : ""
            visible: !blurred
            onStatusChanged: {
                if (status === Image.Error)
                    card.previewFailed = true;
            }
        }

        // blurring the full-size image leaves shapes recognisable, so blur a tiny
        // downscaled copy instead; only colours survive
        Image {
            id: blurSource
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 16
            smooth: true
            asynchronous: true
            source: blurred ? link.previewUrl : ""
            visible: false
        }

        FastBlur {
            anchors.fill: blurSource
            source: blurSource
            radius: 64
            cached: true
            visible: blurred
        }

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.25
            visible: blurred
        }

        Label {
            anchors.centerIn: parent
            visible: blurred
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeSmall
            font.bold: true
            color: "white"
            style: Text.Outline
            styleColor: "black"
            text: ((settings.blurNSFW && !!link.isNSFW) ? qsTr("NSFW") : qsTr("Spoiler")) + "\n" + qsTr("Tap to reveal")
        }

        Image {
            anchors.centerIn: parent
            visible: !blurred && previewImage.status === Image.Ready && !link.isSelfPost
                     && globalUtils.previewableVideo(link.url)
            source: "image://theme/icon-l-play"
        }

        MouseArea {
            anchors.fill: parent
            enabled: blurred || !link.isSelfPost
            onClicked: {
                if (blurred)
                    card.revealed = true;
                else
                    globalUtils.openLink(link.url);
            }
            onPressAndHold: card.longPressed()
        }
    }

    Row {
        width: parent.width
        spacing: constant.paddingMedium

        Text {
            font.pixelSize: constant.fontSizeSmaller
            color: {
                if (link.likes > 0)
                    return constant.colorLikes;
                else if (link.likes < 0)
                    return constant.colorDislikes;
                else
                    return highlighted ? Theme.highlightColor : constant.colorLight;
            }
            text: (link.score < 0 ? "-" : "") + qsTr("%n points", "", Math.abs(link.score))
        }

        Text {
            font.pixelSize: constant.fontSizeSmaller
            color: highlighted ? Theme.highlightColor : constant.colorLight
            text: "·  " + qsTr("%n comments", "", link.commentsCount)
        }

        Text {
            visible: !link.isSelfPost
            width: Math.max(0, parent.width - x)
            font.pixelSize: constant.fontSizeSmaller
            color: highlighted ? Theme.secondaryHighlightColor : constant.colorMid
            elide: Text.ElideRight
            text: "·  " + link.domain
        }
    }
}
