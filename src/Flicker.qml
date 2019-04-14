/*
 * Copyright (C) Jakub Pavelek <jpavelek@live.com>
 * Copyright (C) 2013 Jolla Ltd.
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

QtObject {
    id: flicker
    property Item target: null
    property bool enabled
    property bool isFlicking: false

    onTargetChanged: {
        enabled = false
        if (target && target.enableFlicker) {
            flicker.enabled = true
        }
    }

    function setIndex(point) {

        var flickerStart = keyboard.mapToItem(target, point.startX, point.startY)
        var flickerMoved = keyboard.mapToItem(target, point.x, point.y)
        var flickerKeySize = Math.floor(Math.max(target.height, target.width) + Math.min(target.height, target.width)) / 2

        var flickerKeyOuterX = Math.floor((flickerMoved.y < 0 ? flickerMoved.y * -1 : (flickerMoved.y > flickerKeySize ? flickerMoved.y - flickerKeySize : 0)) * 1)
        var flickerKeyOuterY = Math.floor((flickerMoved.x < 0 ? flickerMoved.x * -1 : (flickerMoved.x > flickerKeySize ? flickerMoved.x - flickerKeySize : 0)) * 1)

        var flickerKeyDiffX = Math.floor(Math.max(flickerKeySize, target.width) - Math.min(flickerKeySize, target.width)) / 2
        var flickerKeyDiffY = Math.floor(Math.max(flickerKeySize, target.height) - Math.min(flickerKeySize, target.height)) / 2

        if (flickerMoved.y > 0-flickerKeyDiffY-flickerKeyOuterY && flickerMoved.y < target.height+flickerKeyDiffY+flickerKeyOuterY && flickerMoved.x < flickerStart.x && flickerStart.x - flickerMoved.x > flickerKeySize * 0.4) {
            target.flickerIndex = 1
        } else if (flickerMoved.y > 0-flickerKeyDiffY-flickerKeyOuterY && flickerMoved.y < target.height+flickerKeyDiffY+flickerKeyOuterY && flickerMoved.x > flickerStart.x && flickerMoved.x - flickerStart.x > flickerKeySize * 0.4){
            target.flickerIndex = 3
        } else if (flickerMoved.x > 0-flickerKeyOuterX && flickerMoved.x < target.width+flickerKeyOuterX && flickerMoved.y < flickerStart.y && flickerStart.y - flickerMoved.y > flickerKeySize * 0.4) {
            target.flickerIndex = 2
        } else if (flickerMoved.x > 0-flickerKeyOuterX && flickerMoved.x < target.width+flickerKeyOuterX && flickerMoved.y > flickerStart.y && flickerMoved.y - flickerStart.y > flickerKeySize * 0.4){
            target.flickerIndex = 4
        } else {
            target.flickerIndex = 0
        }

        if (target.showPopper) {
            popper.setup()
        }

    }
}
