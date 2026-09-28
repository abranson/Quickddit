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

Flow {
    property variant link

    readonly property bool empty: link.flairText === "" && !link.isSticky && !link.isNSFW && !link.isSpoiler
                              && !link.isPromoted && !(link.gilded > 0) && !link.isArchived && !link.isLocked

    spacing: constant.paddingMedium

    Bubble {
        visible: link.flairText !== ""
        text: link.flairText
    }

    Bubble {
        color: "green"
        visible: !!link.isSticky
        text: qsTr("Sticky")
        font.bold: true
    }

    Bubble {
        color: "red"
        visible: !!link.isNSFW
        text: qsTr("NSFW")
        font.bold: true
    }

    Bubble {
        color: "grey"
        visible: !!link.isSpoiler
        text: qsTr("Spoiler")
        font.bold: true
    }

    Bubble {
        color: "green"
        visible: !!link.isPromoted
        text: qsTr("Promoted")
        font.bold: true
    }

    Bubble {
        visible: !!link.gilded && link.gilded > 0
        text: link.gilded > 1 ? qsTr("Gilded") + " " + link.gilded + "x" : qsTr("Gilded")
        color: "gold"
        font.bold: true
    }

    Bubble {
        color: constant.colorDisabled
        visible: !!link.isArchived
        text: qsTr("Archived")
        font.bold: true
    }

    Bubble {
        color: Qt.lighter("purple", 1.5)
        visible: !!link.isLocked
        text: qsTr("Locked")
        font.bold: true
    }
}
