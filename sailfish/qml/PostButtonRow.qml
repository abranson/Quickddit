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

Row {
    property variant link
    property VoteManager linkVoteManager

    height: Theme.iconSizeLarge
    spacing: constant.paddingLarge

    IconButton {
        anchors.verticalCenter: parent.verticalCenter
        icon.height: Theme.iconSizeLarge - constant.paddingMedium
        icon.width: Theme.iconSizeLarge - constant.paddingMedium
        icon.source: "image://theme/icon-m-up"
        enabled: quickdditManager.isSignedIn && !linkVoteManager.busy
        highlighted: link.likes === 1
        onClicked: {
            if (highlighted)
                linkVoteManager.vote(link.fullname, VoteManager.Unvote)
            else
                linkVoteManager.vote(link.fullname, VoteManager.Upvote)
        }
    }

    IconButton {
        anchors.verticalCenter: parent.verticalCenter
        icon.height: Theme.iconSizeLarge - constant.paddingMedium
        icon.width: Theme.iconSizeLarge - constant.paddingMedium
        icon.source: "image://theme/icon-m-down"
        enabled: quickdditManager.isSignedIn && !linkVoteManager.busy
        highlighted: link.likes === -1
        onClicked: {
            if (highlighted)
                linkVoteManager.vote(link.fullname, VoteManager.Unvote)
            else
                linkVoteManager.vote(link.fullname, VoteManager.Downvote)
        }
    }

    IconButton {
        anchors.verticalCenter: parent.verticalCenter
        icon.height: Theme.iconSizeLarge - constant.paddingMedium
        icon.width: Theme.iconSizeLarge - constant.paddingMedium
        icon.source: {
            return globalUtils.previewableVideo(link.url) ? "image://theme/icon-m-video"
                   : globalUtils.redditLink(link.url) ? "image://theme/icon-m-forward" //m-chat
                   : "image://theme/icon-m-image";
        }
        enabled: globalUtils.previewableImage(link.url)
                 || globalUtils.previewableVideo(link.url)
                 || (globalUtils.redditLink(link.url) && !link.isSelfPost)
        onClicked: {
            if (globalUtils.previewableImage(link.url)) {
                globalUtils.openImageViewPage(link.url);
            } else if (globalUtils.previewableVideo(link.url)) {
                globalUtils.openVideoViewPage(link.url);
            } else if (globalUtils.redditLink(link.url)) {
                globalUtils.openRedditLink(link.url);
            }
        }
    }

    IconButton {
        anchors.verticalCenter: parent.verticalCenter
        icon.height: Theme.iconSizeLarge - constant.paddingLarge
        icon.width: Theme.iconSizeLarge - constant.paddingLarge
        icon.source: "image://theme/icon-m-link"
        onClicked: globalUtils.openNonPreviewLink(link.url);
    }
}
