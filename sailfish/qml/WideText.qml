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
    property string displayBody: ""
    property ListItem listItem
    property var inlineMedia: []

    signal clicked

    height: childrenRect.height
    Column {
        spacing: Theme.paddingSmall
        id: commentCol
        Loader {
            id: commentLoader
            sourceComponent: normalCommentComponent
        }
        Repeater {
            model: inlineMedia
            delegate: Loader {
                width: commentCol.width
                property var media: modelData
                sourceComponent: media.type === "gif" ? gifDelegate : imgDelegate
                onLoaded: {
                    item.media = media;
                    console.log("Loaded "+media.type+" "+media.source+" width:"+media.widthHint);
                }
            }
        }
    }

    function updateImages() {
        var newInlineMedia = []
        var updatedBody = body || ""
        // Look for gifs
        var regex = /<[a-z\s]*="(https?:\/\/[^\.]+\.redd\.it\/([^\.]*\.gif)[^"]*)"[^>]*[^>]*>/gi
        var match;
        while ((match = regex.exec(updatedBody)) !== null) {
            console.log("Found gif: "+match[2]);
            newInlineMedia.push({
                type: "gif",
                source: match[1].replace(/&amp;/g, "&")
            })
        }
        updatedBody = updatedBody.replace(regex, "");
        // Look for linked images
        regex = /href="(https?:\/\/preview\.redd\.it\/([^\.]*\.[a-z]{3,4})[^"]*width=([0-9]+)[^"]*)"/gi
        while ((match = regex.exec(updatedBody)) !== null) {
            console.log("Found preview image: "+match[2]);
            var re = new RegExp(">https:\/\/preview.redd.it\/" + match[2] + "[^<]*<", "i");
            updatedBody = updatedBody.replace(re, ">https://preview.redd.it/"+match[2]+"<");
            newInlineMedia.push({
                type: "image",
                source: match[1].replace(/&amp;/g, "&"),
                widthHint: parseInt(match[3], 10)
            })
        }
        
        inlineMedia = newInlineMedia
        if (displayBody !== updatedBody)
            displayBody = updatedBody
    }

    Component.onCompleted: {
        updateImages()
    }

    onBodyChanged: updateImages()

    Component {
        id: gifDelegate
        AnimatedImage {
            id: gifItem
            property var media
            width: commentCol.width
            height: implicitWidth > 0 ? Math.round(width * implicitHeight / implicitWidth) : 0
            source: media ? media.source : ""
            asynchronous: true
            cache: true
            fillMode: Image.PreserveAspectFit

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (!media)
                        return;
                    globalUtils.openImageViewPage(media.source);
                }
            }
        }
    }

    Component {
        id: imgDelegate
        Image {
            property var media
            width: media && media.widthHint ? Math.min(commentCol.width, media.widthHint) : commentCol.width
            source: media ? media.source : ""
            asynchronous: true
            cache: true
            fillMode: Image.PreserveAspectFit

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (!media)
                        return;
                    globalUtils.openImageViewPage(media.source);
                }
            }
        }
    }

    Component {
        id: normalCommentComponent
        Text {
            id: commentBodyTextInner

            // viewhack to render richtext wide again after orientation goes horizontal (?)
            property bool oriChanged: false
            onWidthChanged: {
                if (oriChanged) {
                    text = text + " ";
                    updateImages();
                }
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
            text: constant.contentStyle(listItem.enabled) + displayBody
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
                    if (oriChanged) {
                        text = text + " ";
                        updateImages();
                    }
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
                text: constant.contentStyle(listItem.enabled) + displayBody
                onLinkActivated: globalUtils.openLink(link);
            }
        }
    }

}

