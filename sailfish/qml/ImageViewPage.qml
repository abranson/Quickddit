/*
    Quickddit - Reddit client for mobile phones
    Copyright (C) 2014  Dickson Leong
    Copyright (C) 2015-2020  Sander van Grieken

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
import Sailfish.Share 1.0

AbstractPage {
    id: imageViewPage
    title: qsTr("Image")

    property url imageUrl
    property alias imgurUrl: imgurManager.imgurUrl
    property alias galleryUrl: galleryManager.galleryUrl
    property QtObject activeManager: imgurManager.imgurUrl ? imgurManager : galleryManager

    property int imageCount: activeManager.imageUrls.length > 0
                             ? activeManager.imageUrls.length
                             : imageUrl.toString() !== "" ? 1 : 0
    property Item currentSwipeItem: imageSwipeView.currentItem
    property Item currentViewer: currentSwipeItem ? currentSwipeItem.viewer : null
    property bool currentImageZoomed: currentViewer && currentViewer.image
                                      && currentViewer.image.scale > (currentViewer.fitScale * 1.01)
    property url currentImageUrl: currentSwipeItem ? currentSwipeItem.sourceUrl : imageUrl

    function jumpToImage(index) {
        if (index < 0 || index >= imageSwipeView.count)
            return

        imageSwipeView.cancelFlick()
        imageSwipeView.positionViewAtIndex(index, ListView.Beginning)
        if (imageSwipeView.currentIndex !== index)
            imageSwipeView.currentIndex = index
    }

    // to make the image outside of the page not visible during page transitions
    clip: true

    SilicaFlickable {
        id: pageFlickable
        anchors {
            top: parent.top
            left: parent.left
            right: isPortrait ? parent.right : thumbnailListView.left
            bottom: isPortrait ? thumbnailListView.top : parent.bottom
        }
        contentWidth: width
        contentHeight: height

        ShareAction {
            id: sharer
            mimeType: "text/x-url"
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Save Image")
                enabled: currentImageUrl.toString() !== ""
                onClicked: QMLUtils.saveImage(currentImageUrl.toString())
            }
            MenuItem {
                text: qsTr("Share Image")
                enabled: currentViewer && currentViewer.status === Image.Ready
                onClicked: {
                    var url;
                    if (imgurUrl.toString() !== "") { url = imgurUrl.toString(); console.log("Imgur " + url); }
                    else if (galleryUrl.toString() !== "") { url = galleryUrl.toString(); console.log("Gallery " + url); }
                    else if (currentImageUrl.toString() !== "") { url = currentImageUrl.toString(); console.log("Image " + url); }
                    sharer.resources = [{ "type": "text/x-url", "linkTitle": "Image from Reddit", "status": url.toString() }]
                    sharer.trigger()
                }
            }
            MenuItem {
                text: qsTr("URL")
                onClicked: globalUtils.createOpenLinkDialog(imgurUrl || galleryUrl || currentImageUrl.toString())
            }
        }

        ListView {
            id: imageSwipeView
            anchors.fill: parent
            clip: true
            orientation: ListView.Horizontal
            snapMode: ListView.SnapOneItem
            boundsBehavior: Flickable.StopAtBounds
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: 0
            preferredHighlightEnd: width
            model: imageCount
            interactive: count > 1 && !currentImageZoomed

            delegate: Item {
                id: imagePageDelegate

                width: imageSwipeView.width
                height: imageSwipeView.height
                property bool isCurrentImage: imageSwipeView.currentIndex === index

                property alias viewer: viewer
                property url sourceUrl: activeManager.imageUrls.length > 0
                                        ? activeManager.imageUrls[index]
                                        : imageViewPage.imageUrl

                SilicaFlickable {
                    id: imageFlickable
                    anchors.fill: parent
                    contentWidth: viewer.width
                    contentHeight: viewer.height

                    // Width and height updates can arrive in random order during orientation changes.
                    onHeightChanged: resizeTimer.start()
                    onWidthChanged: resizeTimer.start()

                    ImageViewer {
                        id: viewer
                        flickable: imageFlickable
                        source: imagePageDelegate.sourceUrl
                        paused: imageViewPage.status !== PageStatus.Active
                                || !Qt.application.active
                                || !imagePageDelegate.isCurrentImage
                        onSourceChanged: console.log("source changed: " + source)
                    }

                    ScrollDecorator {}
                }

                Timer {
                    id: resizeTimer
                    interval: 1
                    repeat: false
                    onTriggered: viewer._fitToScreen()
                }
            }

            onCurrentIndexChanged: {
                if (activeManager.imageUrls.length > 0 && activeManager.selectedIndex !== currentIndex)
                    activeManager.selectedIndex = currentIndex
                if (thumbnailListView.count > 0)
                    thumbnailListView.positionViewAtIndex(currentIndex, ListView.Center)
            }
        }
    }

    Loader {
        id: busyIndicatorLoader
        anchors.centerIn: parent
        sourceComponent: {
            if (activeManager.busy)
                return busyIndicatorComponent

            if (!currentViewer)
                return undefined

            switch (currentViewer.status) {
            case Image.Loading: return busyIndicatorComponent
            case Image.Error: return failedLoading
            default: return undefined
            }
        }

        Component {
            id: busyIndicatorComponent

            Item {
                width: busyIndicator.width
                height: busyIndicator.height

                anchors.centerIn: parent

                BusyIndicator {
                    id: busyIndicator
                    size: BusyIndicatorSize.Large
                    running: true
                }

                Label {
                    anchors.centerIn: parent
                    visible: !activeManager.busy
                    font.pixelSize: constant.fontSizeSmall
                    text: Math.round((currentViewer ? currentViewer.progress : 0) * 100) + "%"
                }
            }
        }

        Component { id: failedLoading; Label { text: qsTr("Error loading image") } }
    }

    ListView {
        id: thumbnailListView
        property int _itemSize: 150

        anchors {
            left: isPortrait ? parent.left : undefined
            right: parent.right
            top: isPortrait ? undefined : parent.top
            bottom: parent.bottom
        }
        height: isPortrait
                ? visible ? _itemSize : 0
                : undefined
        width: isPortrait
               ? undefined
               : visible ? _itemSize : 0
        visible: count > 0
        model: activeManager.thumbnailUrls
        orientation: isPortrait ? Qt.Horizontal : Qt.Vertical
        delegate: Item {
            id: thumbnailDelegate
            height: thumbnailListView._itemSize
            width: thumbnailListView._itemSize

            Image {
                id: thumbnailImage
                anchors.fill: parent
                asynchronous: true
                cache: true
                smooth: !thumbnailDelegate.ListView.view.moving
                fillMode: Image.PreserveAspectCrop
                source: modelData
            }

            Loader {
                anchors.centerIn: parent
                sourceComponent: thumbnailImage.status == Image.Loading ? thumbnailBusy : undefined

                Component { id: thumbnailBusy; BusyIndicator { running: true } }
            }

            Rectangle {
                id: selectedIndicator
                anchors.fill: parent
                color: "transparent"
                border.color: index === imageSwipeView.currentIndex ? "steelblue" : "black"
                border.width: 4
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    imageViewPage.jumpToImage(index)
                    if (activeManager.selectedIndex !== index)
                        activeManager.selectedIndex = index
                }
            }
        }

        onModelChanged: if (count > 0) positionViewAtIndex(imageSwipeView.currentIndex, ListView.Center)
        onOrientationChanged: latePositioning.start()

        Timer {
            id: latePositioning
            interval: 0
            repeat: false
            onTriggered: if (thumbnailListView.count > 0) thumbnailListView.positionViewAtIndex(imageSwipeView.currentIndex, ListView.Center)
        }
    }

    ImgurManager {
        id: imgurManager
        manager: quickdditManager
        onError: {
            infoBanner.warning(errorString)
            console.log(errorString)
        }
    }

    GalleryManager {
        id: galleryManager
        manager: quickdditManager
        onError: {
            infoBanner.warning(errorString)
            console.log(errorString)
        }
    }

    Connections {
        target: activeManager
        onSelectedIndexChanged: {
            if (activeManager.selectedIndex >= 0
                    && activeManager.selectedIndex < imageSwipeView.count
                    && imageSwipeView.currentIndex !== activeManager.selectedIndex) {
                imageViewPage.jumpToImage(activeManager.selectedIndex)
            }
        }
    }

    Connections {
        target: QMLUtils
        onSaveImageSucceeded: infoBanner.alert(qsTr("Image saved to gallery"))
        onSaveImageFailed: infoBanner.warning(qsTr("Image save failed!"))
    }
}
