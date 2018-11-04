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
import com.jolla 1.0
import QtFeedback 5.0
import com.meego.maliitquick 1.0
import org.nemomobile.configuration 1.0
import com.jolla.keyboard 1.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as SilicaPrivate
import com.jolla.keyboard.translations 1.0
import org.nemomobile.dbus 2.0
import org.nemomobile.systemsettings 1.0

Item {
    id: canvas

    KeyboardGeometry { id: geometry }

    width: MInputMethodQuick.screenWidth
    height: MInputMethodQuick.screenHeight

    property bool portraitRotated: width > height
    property bool portraitLayout: portraitRotated ?
                                      (MInputMethodQuick.appOrientation == 90 || MInputMethodQuick.appOrientation == 270) :
                                      (MInputMethodQuick.appOrientation == 0 || MInputMethodQuick.appOrientation == 180)

    property int activeIndex: -1
    property var layoutModel: _layoutModel
    property var layoutRow: _layoutRow

    property Item phraseEngine // for hwr

    Component.onCompleted: {
        activeIndex = Math.max(_layoutModel.getLayoutIndex(layoutConfig.value), 0)
    }

    onPortraitLayoutChanged: keyboard.updateLayoutIfAllowed(true)

    function updateIMArea() {
        if (!MInputMethodQuick.active)
            return

        var x = 0, y = 0, width = 0, height = 0;
        var angle = MInputMethodQuick.appOrientation

        var columnHeight = inputItems.effectiveHeight

        switch (angle) {
        case 0:
            y = MInputMethodQuick.screenHeight - columnHeight
        case 180:
            x = (MInputMethodQuick.screenWidth - inputItems.width) / 2
            width = inputItems.width
            height = columnHeight
            break;

        case 270:
            x = MInputMethodQuick.screenWidth - columnHeight
        case 90:
            y = (MInputMethodQuick.screenHeight - inputItems.width) / 2
            width = columnHeight
            height = inputItems.width
            break;
        }

        MInputMethodQuick.setInputMethodArea(Qt.rect(x, y, width, height))
        MInputMethodQuick.setScreenRegion(Qt.rect(x, y, width, height))
    }
    function captureFullScreen() {
        if (!MInputMethodQuick.active)
            return

        MInputMethodQuick.setScreenRegion(Qt.rect(x, y, width, height))
    }
    function saveCurrentLayoutSetting() {
        layoutConfig.value = _layoutModel.get(activeIndex).layout
    }

    function switchLayout(index) {
        layoutRow.switchLayout(index)
        keyboard.overriddenLayoutFile = ""
    }

    function switchToPreviousCharacterLayout() {
        layoutRow.switchToPreviousCharacterLayout()
    }


    InputHandlerManager {
        id: handlerManager
    }

    DBusAdaptor {
        service: "com.jolla.keyboard"
        path: "/com/jolla/keyboard"
        iface: "com.jolla.keyboard"

        function clearData() {
            console.log("got clear data request from dbus")
            _layoutModel.useHandlers([])
            handlerManager.clearHandlerData()
            _layoutModel.updateInputHandlers()
            keyboard.inputHandler = basicInputHandler // just to make sure
        }
    }

    ProfileControl { id: soundSettings}

    Binding {
        // explicitly turn off playing sound with pulseaudio so bluetooth sets don't try to play sound with zero volume
        // TODO: follow currently active profile so if e.g. silent overrides touchscreen tones, playing is not tried.
        target: SampleCache
        property: "outputEnabled"
        value: soundSettings.touchscreenToneLevel !== 0
    }

    LayoutModel {
        id: _layoutModel

        property var inputHandlers: new Array

        onEnabledLayoutsChanged: {
            if (MInputMethodQuick.active) {
                _layoutRow.updateLoadersToLayoutAndNeighbours(canvas.activeIndex)
            }

            updateInputHandlers()
        }

        Component.onCompleted: updateInputHandlers()

        function updateInputHandlers() {
            var newHandlers = new Array
            var i

            for (i = 0; i < count; ++i) {
                var layout = get(i)
                if (layout.enabled && layout.handler !== "") {
                    newHandlers.push(layout.handler)
                }
            }

            // Hack for handwriting: if handwriting is enabled, enable also pinyin
            if (newHandlers.indexOf("HwrInputHandler.qml") >= 0 && newHandlers.indexOf("Xt9CpInputHandler.qml") == -1) {
                newHandlers.push("Xt9CpInputHandler.qml")
            }

            useHandlers(newHandlers)
        }

        function useHandlers(newHandlers) {
            var oldHandlers = Object.keys(inputHandlers)
            var i

            // delete unusused handlers
            for (i = 0; i < oldHandlers.length; ++i) {
                if (newHandlers.indexOf(oldHandlers[i]) == -1) {
                    var deletable = oldHandlers[i]
                    handlerManager.deleteInstance(inputHandlers[deletable])
                    delete inputHandlers[deletable]

                    if (deletable === "Xt9CpInputHandler.qml") {
                        canvas.phraseEngine = null
                    }
                }
            }

            for (i = 0; i < newHandlers.length; ++i) {
                var handler = newHandlers[i]
                if (inputHandlers[handler] !== undefined) {
                    continue // already exists
                }

                var component = Qt.createComponent("/usr/share/maliit/plugins/com/jolla/" + handler)

                if (component.status === Component.Ready) {
                    // using separate creator so instances can be deleted instantly
                    var object = handlerManager.createInstance(component, canvas)
                    inputHandlers[handler] = object

                    // hack for hwr, if pinyin, make sure it's reachable
                    if (handler === "Xt9CpInputHandler.qml") {
                        canvas.phraseEngine = object
                    }
                } else {
                    console.warn("input handler instantiation failed for " + handler + ": " + component.errorString())
                }
            }
        }
    }

    ConfigurationValue {
        id: layoutConfig

        key: "/sailfish/text_input/active_layout"
        defaultValue: "en.qml"

        onValueChanged: {
            var index = _layoutModel.getLayoutIndex(value)
            if (index >= 0) {
                _layoutRow.switchLayout(index)
            }
        }
    }

    ConfigurationValue {
        id: splitConfig

        key: "/sailfish/text_input/split_landscape"
        defaultValue: false
    }

    Item {
        // container at the of current orientation. allows actual keyboard to show relative to that.
        id: root

        width: MInputMethodQuick.appOrientation == 0 || MInputMethodQuick.appOrientation == 180
               ? parent.width : parent.height
        height: 1
        transformOrigin: Item.TopLeft
        rotation: MInputMethodQuick.appOrientation
        x: MInputMethodQuick.appOrientation == 180 || MInputMethodQuick.appOrientation == 270
           ? parent.width : 0
        y: MInputMethodQuick.appOrientation == 0 || MInputMethodQuick.appOrientation == 270
           ? parent.height : 0

        onRotationChanged: updateIMArea()

        ThemeEffect {
            id: buttonPressEffect
            effect: ThemeEffect.PressWeak
        }

        SilicaPrivate.GlassBackground {
            width: keyboard.width
            height: inputItems.effectiveHeight
            anchors.bottom: parent.bottom
            opacity: inputItems.opacity
        }

        Column {
            id: inputItems
            width: keyboard.width
            anchors.bottom: parent.bottom

            // column height doesn't instantly change when topItem changes. workaround by calculating height ourselves
            property int effectiveHeight: keyboard.height + (topItem.item && topItem.visible ? topItem.item.height : 0)

            onEffectiveHeightChanged: {
                if (!showAnimation.running) {
                    updateIMArea()
                }
            }

            // FIXME: don't unload item when changing temporarily to basic handler
            Loader {
                id: topItem
                sourceComponent: keyboard.inputHandler && layoutRow.layout && layoutRow.layout.useTopItem
                                 ? keyboard.inputHandler.topItem : null
                width: parent.width
                visible: item !== null
            }

            KeyboardBase {
                id: keyboard

                property bool allowLayoutChanges
                property string mode: "common"

                property bool fullyOpen
                property bool expandedPaste: true
                 // override based on content type, e.g. for chinese revert to english layout on url
                property int overrideContentType: -1
                property string overriddenLayoutFile
                property alias splitEnabled: splitConfig.value

                width: root.width
                portraitMode: portraitLayout
                layout: mode === "common" ? _layoutRow.layout
                                          : mode === "number" ? (number_portrait.visible ? number_portrait
                                                                                         : number_landscape.item)
                                                              : (phone_portrait.visible ? phone_portrait
                                                                                        : phone_landscape.item)
                layoutChangeAllowed: mode === "common"
                thresholdX: swipeGestureIsSafe ? (Theme.startDragDistance * 4.0) : (Theme.startDragDistance * 6.0)
                thresholdY: Theme.startDragDistance * 1.8
                swipeEnabled: layoutChangeAllowed && (canvas.layoutModel.enabledCount > 1)
                allowedDirections: SwipeGestureArea.DirectionLeft | SwipeGestureArea.DirectionRight
                onSwipeAmountChanged: {
                    if (gestureInProgress) {
                        layoutRow.updateManualTransition(swipeAmount)
                    }
                }
                onGestureInProgressChanged: {
                    if (gestureInProgress) {
                        // Start loading the new layout
                        layoutRow.switchLayout(getGestureNextLayoutIndex(), true)

                        // Hide all current popups and prevent key presses during the gesture
                        cancelAllTouchPoints()
                    } else {
                        layoutRow.endManualTransition()
                    }
                }
                onDirectionChanged: {
                    if (gestureInProgress) {
                        layoutRow.updateTransitionDirection(getGestureNextLayoutIndex())
                    }
                }
                onModeChanged: layoutRow.layout.visible = mode === "common"

                function getGestureNextLayoutIndex() {
                    return (direction === SwipeGestureArea.DirectionLeft) ? getRightAdjacentLayoutIndex() : getLeftAdjacentLayoutIndex()
                }

                function getRightAdjacentLayoutIndex(index) {
                    // If not argument is provided, work with the current layout index
                    if (typeof(index) === "undefined") {
                        index = canvas.activeIndex
                    }

                    // Try searching for the next one
                    for (var i = index + 1; i < canvas.layoutModel.count; i++) {
                        if (canvas.layoutModel.get(i).enabled) {
                            return i
                        }
                    }

                    // Try the lower indexes
                    for (i = 0; i < index; i++) {
                        if (canvas.layoutModel.get(i).enabled) {
                            return i
                        }
                    }

                    // Oopsie, there are no other layouts
                    return index
                }

                function getLeftAdjacentLayoutIndex(index) {
                    // If not argument is provided, work with the current layout index
                    if (typeof(index) === "undefined") {
                        index = canvas.activeIndex
                    }

                    // Try searching for the next one
                    for (var i = index - 1; i >= 0; i--) {
                        if (canvas.layoutModel.get(i).enabled) {
                            return i
                        }
                    }

                    // Try the lower indexes
                    for (i = canvas.layoutModel.count - 1; i > index; i--) {
                        if (canvas.layoutModel.get(i).enabled) {
                            return i
                        }
                    }

                    // Oopsie, there are no other layouts
                    return index
                }

                function updateLayoutIfAllowed(denyOverride) {
                    if (allowLayoutChanges) {
                        updateLayout(denyOverride)
                    }
                }

                function updateLayout(denyOverride) {
                    var newMode = mode

                    if (MInputMethodQuick.contentType === Maliit.NumberContentType) {
                        newMode = "number"
                    } else if (MInputMethodQuick.contentType === Maliit.PhoneNumberContentType) {
                        newMode = "phone"
                    } else {
                        newMode = "common"

                        if (!denyOverride) {
                            var preferNonComposing = (MInputMethodQuick.contentType !== Maliit.FreeTextContentType
                                                      || MInputMethodQuick.hiddenText)

                            var newIndex
                            if (!preferNonComposing && overrideContentType >= 0) {
                                // Remove override
                                if (overriddenLayoutFile.length > 0) {
                                    newIndex = layoutModel.getLayoutIndex(overriddenLayoutFile)
                                    if (newIndex >= 0) {
                                        _layoutRow.switchLayout(newIndex)
                                    }
                                    overriddenLayoutFile = ""
                                    inputHandler.active = false
                                }

                                overrideContentType = -1
                            } else if (preferNonComposing && overrideContentType != MInputMethodQuick.contentType
                                       && _layoutRow.layout && _layoutRow.layout.type !== "") {
                                // apply override, always using english layout.
                                // do only once per content type to avoid change when focus out+in on an editor
                                newIndex = layoutModel.getLayoutIndex("en.qml")
                                if (newIndex >= 0) {
                                    overrideContentType = MInputMethodQuick.contentType
                                    overriddenLayoutFile = layoutModel.get(canvas.activeIndex).layout
                                    _layoutRow.switchLayout(newIndex)
                                    inputHandler.active = false
                                }
                            }
                        }
                    }

                    if (newMode !== mode) {
                        inputHandler.active = false
                        mode = newMode
                    }

                    updateInputHandler()
                }

                function updateInputHandler() {
                    var previousInputHandler = inputHandler

                    if (MInputMethodQuick.contentType === Maliit.NumberContentType
                            || MInputMethodQuick.contentType === Maliit.PhoneNumberContentType) {
                        inputHandler = basicInputHandler

                    } else {
                        var handler = layoutModel.get(canvas.activeIndex).handler
                        var advancedInputHandler =  _layoutModel.inputHandlers[handler]
                        var _layout = _layoutRow.layout

                        if (advancedInputHandler == undefined) {
                            console.warn("invalid inputhandler for " + handler + ", forcing paste input handler")
                            advancedInputHandler = pasteInputHandler
                        }

                        if (handler === "") {
                            inputHandler = pasteInputHandler
                        } else if (_layout && _layout.type == "") {
                            // non-composing
                            if (MInputMethodQuick.contentType === Maliit.FreeTextContentType
                                    && !MInputMethodQuick.hiddenText
                                    && MInputMethodQuick.predictionEnabled) {
                                inputHandler = advancedInputHandler
                            } else {
                                inputHandler = pasteInputHandler
                            }
                        } else {
                            // composing
                            inputHandler = advancedInputHandler
                        }
                    }

                    if ((previousInputHandler !== inputHandler) && previousInputHandler) {
                        previousInputHandler.active = false
                    }

                    inputHandler.active = true
                }

                InputHandler {
                    id: basicInputHandler
                }

                PasteInputHandler {
                    id: pasteInputHandler
                }

                NumberLayoutPortrait {
                    id: number_portrait
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: geometry.isLargeScreen ? 0.6 * geometry.keyboardWidthPortrait
                                                  : geometry.keyboardWidthPortrait
                    visible: keyboard.mode === "number" && (keyboard.portraitMode || geometry.isLargeScreen)
                }

                Loader {
                    id: number_landscape
                    sourceComponent: (keyboard.mode === "number" && !geometry.isLargeScreen)
                                     ? landscapeNumberComponent : undefined
                }

                Component {
                    id: landscapeNumberComponent
                    NumberLayoutLandscape {
                        visible: keyboard.mode === "number" && !number_portrait.visible
                    }
                }

                PhoneNumberLayoutPortrait {
                    id: phone_portrait
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: geometry.isLargeScreen ? 0.6 * geometry.keyboardWidthPortrait
                                                  : geometry.keyboardWidthPortrait
                    visible: keyboard.mode === "phone" && (keyboard.portraitMode || geometry.isLargeScreen)
                }

                Loader {
                    id: phone_landscape
                    sourceComponent: (keyboard.mode === "phone" && !geometry.isLargeScreen)
                                     ? phoneLandscapeComponent : undefined
                }

                Component {
                    id: phoneLandscapeComponent
                    PhoneNumberLayoutLandscape {
                        visible: keyboard.mode === "phone" && !phone_portrait.visible
                    }
                }

                LayoutRow {
                    id: _layoutRow
                }

                Connections {
                    target: Clipboard
                    onTextChanged: {
                        if (Clipboard.text) {
                            keyboard.expandedPaste = true
                        }
                    }
                }

                Loader {
                    sourceComponent: keyboard.inputHandler && layoutRow.layout && layoutRow.layout.splitActive
                                     ? keyboard.inputHandler.verticalItem : null
                    width: geometry.middleBarWidth
                    height: keyboard.height
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: item !== null && !layoutRow.transitionRunning
                }
            }
        }

        Connections {
            target: MInputMethodQuick
            onActiveChanged: {
                if (MInputMethodQuick.active) {
                    hideAnimation.stop()
                    if (!_layoutRow.loading) {
                        showAnimation.start()
                    }
                } else {
                    showAnimation.stop()
                    hideAnimation.start()
                }
            }
            onContentTypeChanged: keyboard.updateLayoutIfAllowed()
            onHiddenTextChanged: keyboard.updateLayoutIfAllowed()
            onPredictionEnabledChanged: keyboard.updateLayoutIfAllowed()

            onFocusTargetChanged: keyboard.allowLayoutChanges = activeEditor
        }

        Connections {
            target: _layoutRow
            onLoadingChanged: {
                if (!_layoutRow.loading
                      && MInputMethodQuick.active
                      && !showAnimation.running
                      && !keyboard.fullyOpen) {
                    showAnimation.start()
                }
            }
        }

        SequentialAnimation {
            id: hideAnimation

            ScriptAction {
                script: {
                    MInputMethodQuick.setInputMethodArea(Qt.rect(0, 0, 0, 0))
                    keyboard.fullyOpen = false
                }
            }

            NumberAnimation {
                target: inputItems
                property: "opacity"
                to: 0
                duration: 300
            }

            ScriptAction {
                script: {
                    MInputMethodQuick.setScreenRegion(Qt.rect(0, 0, 0, 0))
                    keyboard.resetKeyboard()

                    // If there is a stuck transition, stop it
                    if (keyboard.gestureInProgress) {
                        keyboard.cancelGesture()
                    }

                    // Unload neighbours of current layout to save memory
                    _layoutRow.updateLoaders([canvas.activeIndex])
                }
            }
        }

        SequentialAnimation {
            id: showAnimation

            ScriptAction {
                script: {
                    // If there is a stuck transition, stop it
                    if (keyboard.gestureInProgress) {
                        keyboard.cancelGesture()
                    }

                    // Load neighbours of current layouts to ensure smooth swipe
                    _layoutRow.updateLoadersToLayoutAndNeighbours(canvas.activeIndex)

                    canvas.visible = true // framework currently initially hides. Make sure visible
                    keyboard.updateLayout()
                    areaUpdater.start() // ensure height has updated before sending it
                }
            }

            PauseAnimation { duration: 200 }

            NumberAnimation {
                target: inputItems
                property: "opacity"
                to: 1.0
                duration: 200
            }
            PropertyAction {
                target: keyboard
                property: "fullyOpen"
                value: true
            }
        }

        Timer {
            id: areaUpdater
            interval: 1
            onTriggered: canvas.updateIMArea()
        }
        Component.onCompleted: {
            MInputMethodQuick.actionKeyOverride.setDefaultIcon("image://theme/icon-m-enter")
            MInputMethodQuick.actionKeyOverride.setDefaultLabel("")
        }
    }
}

