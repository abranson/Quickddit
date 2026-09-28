/*
  Quickddit - Reddit client for mobile phones

  SPDX-FileCopyrightText:  Copyright (C) 2014  Dickson Leong
  SPDX-FileCopyrightText:  Copyright (C) 2022  Sander van Grieken
  SPDX-FileCopyrightText:  Copyright (C) 2022  Björn Bidar

  SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.WebView 1.0 as SailfishWebView
import Sailfish.WebView.Popups 1.0 as SailfishWebViewPopups

AbstractDialog {
    id: signInDialog

    // For CoverPage
    property string title: qsTr("Sign in to Reddit")
    property bool showSignInReason

    backNavigation: webView.atXBeginning && webView.atXEnd && !webView.moving && !webView.pulleyMenuActive
    canAccept: false

    DialogHeader {
        id: dialogHeader

        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter

        //% "Sign in to Reddit with Quickddit"
        title: qsTr("Sign in to Reddit")
        /* Accept text is empty since the dialog will be accepted automatically
         *  when quickdditManager.getAccessToken(url) finds the token.
         */
        acceptText: ""
        cancelText: qsTr("Cancel")
    }


    Rectangle {
        id: signInReason

        anchors.top: dialogHeader.bottom
        width: parent.width
        height: visible ? signInReasonLabel.height + 2 * Theme.paddingMedium : 0
        visible: signInDialog.showSignInReason
        color: Theme.highlightBackgroundColor

        Label {
            id: signInReasonLabel

            x: Theme.horizontalPageMargin
            y: Theme.paddingMedium
            width: parent.width - 2 * x
            text: qsTr("Reddit no longer allows anonymous access. Please sign in to continue.")
            color: Theme.primaryColor
            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.Wrap
        }
    }

    SilicaFlickable  {
        id: webViewFlickable

        property alias webView: webView

        y: signInReason.y + signInReason.height + Theme.paddingSmall
        x: parent.x +Theme.paddingSmall
        width: parent.width  - 2*Theme.paddingSmall
        height: parent.height - y - Theme.paddingSmall


        SailfishWebView.WebView {
            id: webView

            anchors.fill: parent

            url: quickdditManager.generateAuthorizationUrl();
            httpUserAgent: "Mozilla/5.0 (X11; Linux x86_64; rv:102.0) Gecko/20100101 Firefox/102.0"
            privateMode: true

            popupProvider: SailfishWebViewPopups.PopupProvider {
                // Disable the Save Password dialog
                passwordManagerPopup: null
            }

            onUrlChanged: {
                if (url.toString().indexOf("code=") > 0) {
                    quickdditManager.getAccessToken(url);
                }
            }
        }
    }

    Connections {
        target: quickdditManager
        onAccessTokenSuccess: {
            infoBanner.alert(qsTr("Sign in successful! Welcome! :)"));
            inboxManager.resetTimer();
            pageStack.pop(pageStack.find(function(page) { return page.objectName === "subredditsPage"; }));
        }
    }
}
