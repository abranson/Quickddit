/*
    Quickddit - Reddit client for mobile phones
    Copyright (C) 2015  Sander van Grieken

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
import harbour.quickddit.Core 1.0

ListItem {
    id: linkDelegate

    property bool showSubreddit: true

    readonly property bool cardLayout: settings.postLayout === Settings.CardLayout
    // inset of the card background from the list item edges
    readonly property int cardInset: constant.paddingSmall

    contentHeight: layoutLoader.height + 2 * (cardLayout ? cardInset + constant.paddingMedium : constant.paddingMedium)

    Rectangle {
        visible: cardLayout
        anchors { fill: parent; margins: cardInset }
        radius: constant.paddingSmall
        color: Theme.rgba(constant.colorMid, 0.1)
    }

    Loader {
        id: layoutLoader
        anchors {
            left: parent.left; right: parent.right
            leftMargin: cardLayout ? cardInset + constant.paddingMedium : constant.paddingMedium
            rightMargin: cardLayout ? cardInset + constant.paddingMedium : constant.paddingMedium
            verticalCenter: parent.verticalCenter
        }
        sourceComponent: cardLayout ? cardComponent : compactComponent
    }

    Component {
        id: compactComponent

        Item {
            height: Math.max(thumbnail.height, postInfoText.height)

            PostInfoText {
                id: postInfoText

                link: model
                compact: true
                highlighted: linkDelegate.highlighted
                showSubreddit: linkDelegate.showSubreddit

                anchors {
                    left: parent.left; right: thumbnail.left; rightMargin: constant.paddingMedium
                    verticalCenter: parent.verticalCenter
                }

                height: childrenRect.height
                spacing: constant.paddingSmall
            }

            PostThumbnail {
                id: thumbnail

                link: model
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                onLongPressed: linkDelegate.pressAndHold(null)
            }
        }
    }

    Component {
        id: cardComponent

        LinkCard {
            link: model
            highlighted: linkDelegate.highlighted
            showSubreddit: linkDelegate.showSubreddit
            bleed: constant.paddingMedium
            onLongPressed: linkDelegate.pressAndHold(null)
        }
    }

    Rectangle {
        id: savedRect
        anchors.fill: parent
        visible: model.saved
        color: Theme.highlightColor
        opacity: 0.1
    }

    Image {
        visible: model.saved
        anchors {
            right: parent.right
            top: parent.top
            topMargin: 5
            rightMargin: 5
        }

        source: "image://theme/icon-s-favorite?" + Theme.highlightColor
    }
}
