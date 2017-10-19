/* Copyright (c) 2014 Janne Edelman <janne.edelman@gmail.com>
 * Copyright (C) 2012-2013 Jolla Ltd.
 * All rights reserved.
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
 */

import QtQuick 2.0
import com.meego.maliitquick 1.0
import Sailfish.Silica 1.0
import ".."
import "../.."

FunctionKey {
    property string direction
    property int arrowKeyWidth: 52
    icon.source: ((direction === "up") ? "image://theme/icon-m-up"
               :  (direction === "down") ? "image://theme/icon-m-down"
               :  (direction === "left") ? "image://theme/icon-m-left"
               :  (direction === "right") ? "image://theme/icon-m-right" : "")
    icon.opacity: pressed ? 0.6 : 1
    repeat: true
    key: ((direction === "up") ? Qt.Key_Up
               :  (direction === "down") ? Qt.Key_Down
               :  (direction === "left") ? Qt.Key_Left
               :  (direction === "right") ? Qt.Key_Right : Qt.Key_Unknown)
    implicitWidth: arrowKeyWidth
    background.visible: false
    
    onPressedChanged: {
	if(pressed) {
	    arrowKeyPress()
	    if(repeat) {
		autorepeatTimer.interval = 800
		autorepeatTimer.start()
	    }
	} else {
	    autorepeatTimer.stop();
	}
    }

    Timer {
        id: autorepeatTimer
        repeat: true

        onTriggered: {
            interval = 80
            if (pressed) {
                arrowKeyPress()
            } else {
                stop()
            }
        }
    }
    
    function arrowKeyPress() {
/*	switch(direction) {
            case "up":
            MInputMethodQuick.sendKey(Qt.Key_Up, 0, "", Maliit.KeyClick)
            break
            case "down":
            MInputMethodQuick.sendKey(Qt.Key_Down, 0, "", Maliit.KeyClick)
            break
            case "left":
            MInputMethodQuick.sendKey(Qt.Key_Left, 0, "", Maliit.KeyClick)
            break
            case "right":
            MInputMethodQuick.sendKey(Qt.Key_Right, 0, "", Maliit.KeyClick)
            break;
            default:
            break;
        }*/
    }
}
