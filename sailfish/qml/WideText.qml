/*
    Quickddit - Reddit client for mobile phones
    Copyright (C) 2016  Sander van Grieken

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

import QtQuick 2.6
import Sailfish.Silica 1.0

Item {
    id: rootItem

    property string body
    property ListItem listItem

    signal clicked

    height: childrenRect.height
    Column {
        spacing: 2
        id: imageCol
        Loader {
            id: commentLoader
            sourceComponent: normalCommentComponent
        }
    }

    function updateImages() {
        var regex = /<[a-z\s]*="(https?:\/\/[^\.]+\.redd\.it\/([^\.]*\.gif)[^"]*)"[^>]*[^>]*>/gi
        var match;
        while ((match = regex.exec(body)) !== null) {
            console.log("Found gif: "+match[2]);
            var newImage = Qt.createQmlObject('import QtQuick 2.6; AnimatedImage { source: "'
                 + match[1].replace(/&amp;/g, "&") + '"; fillMode: Image.PreserveAspectFit; }', imageCol)
        }
        regex = /href="(https?:\/\/preview\.redd\.it\/([^\.]*\.[a-z]{3,4})[^"]*width=([0-9]+)[^"]*)"/gi
        while ((match = regex.exec(body)) !== null) {
            console.log("Found preview image: "+match[2]);
            var re = new RegExp(">https:\/\/preview.redd.it\/" + match[2] + "[^<]*<", "i");
            body = body.replace(re, ">https://preview.redd.it/"+match[2]+"<");
            var newImage = Qt.createQmlObject('import QtQuick 2.6; Image { source: "'
                 + match[1].replace(/&amp;/g, "&") + '"; width: Math.min('+imageCol.width+', ' + match[3] + '); fillMode: Image.PreserveAspectFit; }', imageCol)
            //console.log("Width: "+imageCol.width+", "+match[3]);
        }
        
    }

    Component.onCompleted: {
        updateImages()
    }

    Component {
        id: normalCommentComponent
        Text {
            id: commentBodyTextInner

            // viewhack to render richtext wide again after orientation goes horizontal (?)
            property bool oriChanged: false
            onWidthChanged: {
                if (oriChanged) text = text + " ";
            }
            Connections {
                target: appWindow
                onOrientationChanged: oriChanged = true
            }

            width: rootItem.width
            font.pixelSize: constant.fontSizeDefault
            color: listItem.enabled ? (listItem.highlighted ? Theme.highlightColor : constant.colorLight)
                                    : constant.colorDisabled
            wrapMode: Text.Wrap
            textFormat: Text.RichText
            text: constant.contentStyle(listItem.enabled) + body
            onLinkActivated: globalUtils.openLink(link);

            Component.onCompleted: {
                if (commentBodyTextInner.paintedWidth > listItem.width && commentLoader.sourceComponent != wideCommentComponent) {
                    commentLoader.sourceComponent = wideCommentComponent
                }
            }
        }
    }

    Component {
        id: wideCommentComponent
        Flickable {
            width: rootItem.width
            height: childrenRect.height
            contentWidth: commentBodyTextInner.paintedWidth
            contentHeight: commentBodyTextInner.height
            flickableDirection: Flickable.HorizontalFlick
            clip: true

            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: false
                onClicked: rootItem.clicked()
                onPressed: listItem.onPressed(mouse)
                onReleased: listItem.onReleased(mouse)
            }

            Text {
                id: commentBodyTextInner

                // viewhack to render richtext wide again after orientation goes horizontal (?)
                property bool oriChanged: false
                onWidthChanged: {
                    if (oriChanged) text = text + " ";
                }
                Connections {
                    target: appWindow
                    onOrientationChanged: oriChanged = true
                }

                width: rootItem.width
                font.pixelSize: constant.fontSizeDefault
                color: listItem.enabled ? (listItem.highlighted ? Theme.highlightColor : constant.colorLight)
                                        : constant.colorDisabled
                wrapMode: Text.Wrap
                textFormat: Text.RichText
                text: constant.contentStyle(listItem.enabled) + body
                onLinkActivated: globalUtils.openLink(link);
            }
        }
    }

}

