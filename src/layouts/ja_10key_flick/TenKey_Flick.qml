/*
 * Copyright (C) 2011 Nokia Corporation and/or its subsidiary(-ies). All rights reserved.
 * Copyright (C) 2012-2013 Jolla Ltd.
 *
 * Contact: Pekka Vuorela <pekka.vuorela@jollamobile.com>
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this list
 * of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list
 * of conditions and the following disclaimer in the documentation and/or other materials
 * provided with the distribution.
 * Neither the name of Nokia Corporation nor the names of its contributors may be
 * used to endorse or promote products derived from this software without specific
 * prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 * THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

import QtQuick 2.0
import com.jolla.keyboard 1.0
import Sailfish.Silica 1.0
import ".."
import "../.."

KeyBase {
    id: aCharKey

    implicitHeight: portraitMode == false ? geometry.keyHeightLandscape
                     :  geometry.keyHeightPortrait
    implicitWidth: portraitMode == false ? geometry.keyboardWidthLandscape / 5
                     : geometry.keyboardWidthPortrait / 5

    property string flickerText
    property string captionShifted
    property string captionShifted2
    property string symView
    property string symView2
    property int separator: SeparatorState.AutomaticSeparator
    property bool implicitSeparator: true // set by layouting
//    property bool separator: true
    property bool showHighlight: true
    property string accents
    property string accentsShifted
    property bool fixedWidth
    property alias useBoldFont: keyText.font.bold
    property alias  _keyText: keyText.text

    property int flickerIndex: 0
    property bool enableFlicker: true
    property bool symbolOnly: false

//    showPopper: false
    keyType: KeyType.CharacterKey
    text: keyText.text.length === 1 ? keyText.text : (keyText.text.charAt(flickerIndex) ? keyText.text.charAt(flickerIndex) : keyText.text.chaAt(0))

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        Text {
            id: keyText
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: Theme.fontFamily
//            font.pixelSize: !pressed && symbolOnly ? Theme.fontSizeExtraSmall : Theme.fontSizeMedium
            font.pixelSize: !pressed && symbolOnly ? Theme.fontSizeExtraSmall : (portraitMode === false || attributes.isShifted || attributes.inSymView) ? Theme.fontSizeMedium : Theme.fontSizeLarge
            font.letterSpacing: (portraitMode === true && !attributes.isShifted && !attributes.inSymView && symbolOnly && flickerText.length > 3) ? -10 : 0
            color: pressed ? Theme.highlightColor : Theme.primaryColor
            text: attributes.inSymView && symView.length > 0 ? (!pressed ? (symbolOnly ? symView : symView.charAt(0)) : (symView.charAt(flickerIndex) !== "" ? symView.charAt(flickerIndex) : symView.charAt(0))) : (attributes.isShifted ? (!pressed ? (captionShifted === " " ? "" : (textCaptState && captionShifted2 !== "" ? captionShifted2 : captionShifted)) : (textCaptState && captionShifted2 !== "" ? (captionShifted2.charAt(flickerIndex) !== "" ? captionShifted2.charAt(flickerIndex) : captionShifted2.charAt(0)) : (captionShifted.charAt(flickerIndex) !== "" ? captionShifted.charAt(flickerIndex) : captionShifted.charAt(0)))) : !pressed && symbolOnly ? flickerText : (flickerText.charAt(flickerIndex) !== "" ? flickerText.charAt(flickerIndex) : flickerText.charAt(0)))
        }
        Text {
            id: secondaryLabel
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: (leftPadding - rightPadding) / 2
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: Theme.fontFamily
            font.pixelSize: !symbolOnly ? Theme.fontSizeExtraSmall : Theme.fontSizeSmall
            color: pressed ? Theme.highlightColor : Theme.primaryColor
            opacity: (!pressed && attributes.isShifted && captionShifted === " ") ? .8 : .6
            text: !pressed && attributes.inSymView && symView.length > 0 ? (symbolOnly ? "" : symView.slice(1)) : (!pressed && attributes.isShifted && captionShifted === " " ? "Space" : "")
        }
    }

    Image {
        source: "../../graphic-keyboard-highlight-top.png"
        anchors.right: parent.right
        visible: (separator === SeparatorState.AutomaticSeparator && implicitSeparator)
                 || separator === SeparatorState.VisibleSeparator
//        visible: separator
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: Theme.paddingSmall
        z: -1
        color: Theme.highlightBackgroundColor
        opacity: 0.5
        visible: pressed && showHighlight
    }

    onPressedChanged: {
        if (!pressed){
            flickerIndex = 0
            textCaptState = (!shiftShifted || !attributes.isShifted ? false : true)
        } else if (pressed) {
            if (attributes.isShifted && aCharKey.text === "\u2191" && !textCaptState) {
                shiftShifted = true
            } else if (attributes.isShifted && aCharKey.text !== "\u2191" || aCharKey.text === "\u2191" && shiftShifted) {
                shiftShifted = false
            }
        }
    }

}
