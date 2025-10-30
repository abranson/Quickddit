/*
    Quickddit - Reddit client for mobile phones
    Copyright (C) 2016-2020  Sander van Grieken

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

ListItem {
    id: subredditDelegate
    contentHeight: visible ? mainColumn.height + constant.paddingSmall : 0
    opacity: visible ? 1 : 0

    Column {
        id: mainColumn
        anchors {
            left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
            margins: constant.paddingLarge
        }
        spacing: constant.paddingSmall

        Row {
            spacing: constant.paddingMedium

            Image {
                id: subredditIcon
                height: Theme.itemSizeSmall
                width: height
                anchors.verticalCenter: parent.verticalCenter
                source: model.iconUrl
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: subredditIcon.width
                        height: subredditIcon.height
                        radius: subredditIcon.width/4
                    }
                }
            }

            Row {
                id: textRow
                spacing: 0
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    id: titleText
                    font.pixelSize: constant.fontSizeSmall
                    color: subredditDelegate.highlighted ? Theme.highlightColor : constant.colorMid
                    text: "/r/"
                }
                Text {
                    anchors.baseline: titleText.baseline
                    font.pixelSize: constant.fontSizeMedium
                    color: subredditDelegate.highlighted ? Theme.highlightColor : constant.colorLight
                    text: model.displayName
                }
            }

            Row {
                spacing: constant.paddingMedium
                anchors.verticalCenter: parent.verticalCenter

                Bubble {
                    font.pixelSize: constant.fontSizeSmall
                    visible: model.isNSFW
                    text: qsTr("NSFW")
                    color: "red"
                }
                Bubble {
                    font.pixelSize: constant.fontSizeSmall
                    visible: model.isContributor
                    text: qsTr("Contributor")
                }
                Bubble {
                    font.pixelSize: constant.fontSizeSmall
                    visible: model.isBanned
                    text: qsTr("Banned")
                    color: "red"
                }
                Bubble {
                    font.pixelSize: constant.fontSizeSmall
                    visible: model.isModerator
                    text: qsTr("Mod")
                    color: "blue"
                }
                Bubble {
                    font.pixelSize: constant.fontSizeSmall
                    visible: model.isMuted
                    text: qsTr("Muted")
                    color: "grey"
                }
            }
        }

    }
}
