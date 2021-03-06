/*
    Quickddit - Reddit client for mobile phones
    Copyright (C) 2014  Dickson Leong
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

AbstractPage {
    id: commentPage
    title: "Comments"
    busy: (commentModel.busy && commentListView.count > 0) || commentVoteManager.busy || commentManager.busy || linkVoteManager.busy

    property alias link: commentModel.link
    property alias linkPermalink: commentModel.permalink
    property VoteManager linkVoteManager
    property bool morechildren_animation
    property bool widePage: commentPage.width > 700

    function refresh(refreshOlder) {
        morechildren_animation = false
        commentModel.refresh(refreshOlder);
    }

    readonly property variant commentSortModel: ["Best", "Top", "New", "Hot", "Controversial", "Old"]

    function __createCommentDialog(title, fullname, originalText, isEdit) {
        var dialog = pageStack.push(Qt.resolvedUrl("TextAreaDialog.qml"), {title: title, text: originalText || ""});
        dialog.accepted.connect(function() {
            if (isEdit) // edit
                commentManager.editComment(fullname, dialog.text);
            else // add
                commentManager.addComment(fullname, dialog.text);
        })
    }

    function __createLinkTextDialog(title, fullname, originalText) {
        var dialog = pageStack.push(Qt.resolvedUrl("TextAreaDialog.qml"), {linkManager: linkManager, title: title, text: originalText || ""});
        dialog.accepted.connect(function() {
            linkManager.editLinkText(fullname, dialog.text);
        })
    }

    function loadMoreChildren(index, children) {
        morechildren_animation = true
        commentModel.moreComments(index, children);
    }

    SilicaListView {
        id: commentListView
        anchors.fill: parent
        model: commentModel

        PullDownMenu {
            MenuItem {
                visible: link.author === appSettings.redditUsername && link.isSelfPost
                text: "Edit Post"
                onClicked: {
                    __createLinkTextDialog("Edit Post", link.fullname, link.rawText);
                }
            }

            MenuItem {
                text: "Sort"
                onClicked: globalUtils.createSelectionDialog("Sort", commentSortModel, commentModel.sort,
                function (selectedIndex) {
                    commentModel.sort = selectedIndex;
                    refresh(false);
                });
            }

            MenuItem {
                enabled: quickdditManager.isSignedIn && !commentManager.busy && !!link
                text: "Add comment"
                onClicked: __createCommentDialog("Add Comment", link.fullname);
            }

            MenuItem {
                enabled: !commentModel.busy
                text: "Refresh"
                onClicked: refresh(false);
            }
        }

        header: link ? headerComponent : null

        Component {
            id: headerComponent

            Column {
                width: parent.width
                height: childrenRect.height

                PageHeader { title: commentPage.title }

                Item {
                    anchors { left: parent.left; right: parent.right }
                    height: Math.max(postInfoText.height + postButtonRow.height, thumbnail.height) + constant.paddingMedium

                    PostInfoText {
                        id: postInfoText
                        link: commentModel.link

                        anchors {
                            left: parent.left
                            right: thumbnail.left
                            margins: constant.paddingMedium
                        }
                    }

                    PostThumbnail {
                        id: thumbnail
                        link: commentModel.link

                        function scaleToText() {
                            var scale = (postInfoText.height + postButtonRow.height) / thumbnail.sourceSize.height;
                            return Math.max(Math.min(scale, 2.0), 1.0);
                        }

                        width: widePage ? sourceSize.width * scaleToText() : sourceSize.width
                        height: widePage ? sourceSize.height * scaleToText() : sourceSize.height

                        anchors {
                            right: parent.right
                            top: parent.top
                            margins: constant.paddingMedium
                        }
                    }

                    Item {
                        anchors.top: postInfoText.bottom
                        anchors.left: parent.left
                        anchors.right: thumbnail.height > postInfoText.height ? thumbnail.left : parent.right

                        PostButtonRow {
                            id: postButtonRow

                            anchors.horizontalCenter: parent.horizontalCenter

                            link: commentModel.link
                            linkVoteManager: commentPage.linkVoteManager
                        }
                    }
                }

                Column {
                    id: bodyWrapper
                    anchors { left: parent.left; right: parent.right }
                    height: childrenRect.height
                    spacing: constant.paddingMedium
                    visible: link.text.length > 0

                    Separator {
                        anchors { left: parent.left; right: parent.right }
                        color: constant.colorMid
                    }

                    Flickable {
                        id: bodyText
                        anchors { left: parent.left; right: parent.right; margins: constant.paddingMedium }
                        height: bodyTextInner.height
                        contentWidth: bodyTextInner.paintedWidth
                        contentHeight: bodyTextInner.height
                        flickableDirection: Flickable.HorizontalFlick
                        interactive: bodyTextInner.paintedWidth > parent.width
                        clip: true

                        Text {
                            id: bodyTextInner
                            width: bodyWrapper.width - (constant.paddingMedium * 2)
                            wrapMode: Text.Wrap
                            textFormat: Text.RichText
                            font.pixelSize: constant.fontSizeDefault
                            color: constant.colorLight
                            text: "<style>a { color: " + Theme.highlightColor + "; }</style>" + link.text
                            onLinkActivated: globalUtils.openLink(link);
                        }
                    }

                    // For spacing after text
                    Item { anchors { left: parent.left; right: parent.right } height: 1 }
                }

                Separator {
                    anchors { left: parent.left; right: parent.right }
                    color: constant.colorMid
                }

                Item {
                    anchors { left: parent.left; right: parent.right }
                    height: visible ? viewAllCommentColumn.height + 2 * constant.paddingMedium : 0
                    visible: commentModel.commentPermalink

                    Column {
                        id: viewAllCommentColumn
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                        height: childrenRect.height
                        spacing: constant.paddingMedium

                        Label {
                            anchors { left: parent.left; right: parent.right; margins: constant.paddingMedium }
                            wrapMode: Text.Wrap
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            text: "Viewing a single comment's thread"
                        }

                        Button {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "View All Comments"
                            onClicked: {
                                commentModel.commentPermalink = false;
                                refresh(false);
                            }
                        }
                    }
                }
            }
        }

        delegate: CommentDelegate {
            id: commentDelegate
            menu: Component { CommentMenu {} }
            onClicked: {
                var p = {comment: model, linkPermalink: link.permalink, commentVoteManager: commentVoteManager};
                var dialog = showMenu(p);
                dialog.showParent.connect(function() {
                    var parentIndex = commentModel.getParentIndex(index);
                    commentDelegate.ListView.view.positionViewAtIndex(parentIndex, ListView.Contain);
                    commentDelegate.ListView.view.currentIndex = parentIndex;
                    commentDelegate.ListView.view.currentItem.highlight();
                })
                dialog.replyClicked.connect(function() { __createCommentDialog("Reply Comment", model.fullname); });
                dialog.editClicked.connect(function() {
                    __createCommentDialog("Edit Comment", model.fullname, model.rawBody, true);
                });
                dialog.deleteClicked.connect(function() {
                    commentDelegate.remorseAction("Deleting comment", function() {
                        commentManager.deleteComment(model.fullname);
                    })
                });
            }
        }

        footer: LoadingFooter { visible: commentModel.busy && commentListView.count == 0; listViewItem: commentListView }

        VerticalScrollDecorator {}
    }

    CommentModel {
        id: commentModel
        manager: quickdditManager
        permalink: link.permalink
        onError: infoBanner.alert(errorString)
        onCommentLoaded: {
            var path = permalink.split("?")[0].split("/");
            var post = path[path.length-1];
            var postIndex = commentModel.getCommentIndex("t1_" + post);
            if (postIndex !== -1) {
                commentListView.positionViewAtIndex(postIndex, ListView.Contain);
                commentListView.currentIndex = postIndex;
                commentListView.currentItem.highlight();
            }
        }
    }

    VoteManager {
        id: commentVoteManager
        manager: quickdditManager
        onVoteSuccess: {
            if (fullname.indexOf("t1") === 0) // comment
                commentModel.changeLikes(fullname, likes);
            else if (fullname.indexOf("t3") === 0) // link
                commentModel.changeLinkLikes(fullname, likes);
        }
        onError: infoBanner.alert(errorString);
    }

    CommentManager {
        id: commentManager
        manager: quickdditManager
        model: commentModel
        linkAuthor: link ? link.author : ""
        onSuccess: infoBanner.alert(message);
        onError: infoBanner.alert(errorString);
    }

    LinkManager {
        id: linkManager
        manager: quickdditManager
        commentModel: commentModel
        onSuccess: infoBanner.alert(message);
        onError: infoBanner.alert(errorString);
    }

    Connections {
        target: linkVoteManager
        onVoteSuccess: if (linkVoteManager != commentVoteManager) { commentModel.changeLinkLikes(fullname, likes); }
    }

    Component.onCompleted: {
        if (!linkVoteManager)
            linkVoteManager = commentVoteManager;
    }
}
