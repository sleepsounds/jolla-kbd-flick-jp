
import QtQuick 2.0
import com.meego.maliitquick 1.0
import Sailfish.Silica 1.0
import com.jolla.keyboard 1.0
import se.behold.anthy 1.0
import ".."
import "../.."

import "parse_10key_flick.js" as Parser

InputHandler {

    property string preedit
    property var trie
    property bool trie_built: false
    property bool wasShifted: false
    property string preedit_oldlastchar
    property int nonCandLen: 0
    Component.onCompleted: init()

    function init() {
        if (!Parser.trie_built) {
            Parser.build_hiragana_trie()
        }

        anthy.update_candidates('')
    }

    Anthy {
        id: anthy

        property var candidates: ListModel { }

        function update_candidates(str) {
            if (nonCandLen > 0 && nonCandLen < preedit.length) {
                str = str.slice(0, str.length-nonCandLen)
            }
            console.debug("Setting anthy string to '" + str + "'")
            candidates.clear()

            // WARNING: Before committing a segment or a prediction, the corresponding
            // set function (set_string/set_prediction_string) must be run.
            // We run set_prediction_string first here, followed by set_string,
            // so we don't need to re-run set_string when committing a segment.
            anthy.set_prediction_string(str)
            var pred = anthy.predictions()
            var predictions = []
            // don't add more than 15 predictions
            for (var i = 0; i < pred && i < 15; i++) {
                predictions.push(anthy.get_prediction(i))
            }

            anthy.set_string(str)
            var prim = ""
            var len = anthy.segments()

            // keep track of candidates already in the list
            // so we don't add duplicates
            var included_phrases = {}

            // the "primary" choice is the concatenation of the first candidate
            // for all segments
            for (var i = 0; i < len; i++) {
                prim += anthy.get_candidate(i, 0)
            }
            if (prim.length > 0 && !keyboard.isShifted || prim !== str) {
                candidates.append({text: prim, type: "full", segment: len, candidate: 0})
                included_phrases[prim] = true
            }

            var katakana = Parser.hiragana_to_katakana(str)
            if (keyboard.isShifted) {
                katakana = Parser.alphabet_to_uppercase(str.slice(0, 1)) + str.slice(1)
            }
            var katakana_item = {text: katakana, type: "full", segment: -1, candidate: -1}

            if (!(katakana in included_phrases) && katakana !== "" && keyboard.isShifted) {
                candidates.insert(Math.min(5, candidates.count), katakana_item)
                katakana = Parser.alphabet_to_uppercase(str)
                katakana_item = {text: katakana, type: "full", segment: -1, candidate: -1}
            }

            len = anthy.segment_candidates(0)
            for (var i = 0; i < len; i++) {
                var s = anthy.get_candidate(0, i)
                if (s == katakana && i > 10) {
                    // move the katakana option ahead if included but more than 10 elements away
                    katakana_item.segment = 0
                    katakana_item.candidate = i
                    katakana_item.type = "partial"
                    continue
                }
                if (s != prim) {
                    included_phrases[s] = true
                    candidates.append({text: s, type: "partial", segment: 0, candidate: i})
                }
            }

            if (!(katakana in included_phrases) && katakana !== "") {
                candidates.insert(Math.min(5, candidates.count), katakana_item)
            }

            for (var i = 0; i < predictions.length; i++) {
                var cand = predictions[i]
                if (!(cand in included_phrases)) {
                    included_phrases[cand] = true
                    // add predictions after the primary choice
                    // (or first if there is no primary choice, i.e. preedit is empty)
                    candidates.insert(Math.min(i + 1, candidates.count), {text: cand, type: "prediction", segment: 0, candidate: i})
                }
            }

            candidatesUpdated()
        }

        function acceptPhrase(index, preedit) {
            var item = candidates.get(index)
            console.debug("accepting", index)
            console.debug("which is of the type", item.type, "and has the text", item.text)
            console.debug("segment", item.segment, "candidate", item.candidate)
            if (item.type == "full") {
                if (item.segment >= 0 && item.candidate >= 0) {
                    for (var i = 0; i < item.segment; i++) {
                        anthy.commit_segment(i, item.candidate)
                    }
                }
                    (nonCandLen > 0 && nonCandLen < preedit.length) ? commit_partial(item.text, preedit.slice(preedit.length-nonCandLen)) : commit(item.text)
//                    commit(item.text)
            } else if (item.type == "prediction") {
                // NOTE: set_string was run before this, so we need to
                // re-run set_prediction_string to avoid a segfault
//                anthy.set_prediction_string(preedit)
                if (preedit !== "") {
                    anthy.set_prediction_string(preedit.slice(0, preedit.length-nonCandLen))
                    anthy.commit_prediction(item.candidate)
                }
//                (nonCandLen > 0 && nonCandLen < preedit.length) ? commit_partial(item.text, preedit.slice(preedit.length-nonCandLen)) : commit(item.text)
                if (nonCandLen >= preedit.length) {
                    nonCandLen = 0
                }
                commit_partial(item.text, preedit.slice(preedit.length-nonCandLen))
//                commit(item.text)
            } else {
                console.debug("getting legment length")
                var len = anthy.segment_length(item.segment)
                console.debug("segment length was", len)
                console.debug("commiting segment")
                // NOTE: no need to re-run set_string here since
                // we already ran it once following set_prediction_string
                anthy.commit_segment(item.segment, item.candidate)
                console.debug("commited segment")
                commit_partial(item.text, preedit.slice(len))
                console.debug("commited to text editor")
            }
        }

        signal candidatesUpdated
    }

    topItem: Component {
        TopItem {
            id: topItem
            Row {
                SilicaListView {
                    id: listView
                    model: anthy.candidates
                    orientation: ListView.Horizontal
                    width: topItem.width
                    height: topItem.height
                    boundsBehavior: !keyboard.expandedPaste && Clipboard.hasText ? Flickable.DragOverBounds : Flickable.StopAtBounds
                    header: pasteComponent
                    delegate: BackgroundItem {
                        id: backGround
                        onClicked: accept(model.index)
                        width: candidateText.width + Theme.paddingLarge * 2
                        height: topItem.height

                        Text {
                            id: candidateText
                            anchors.centerIn: parent
//                            color: (backGround.down || index === 0) ? Theme.highlightColor : Theme.primaryColor
                            color: Theme.primaryColor
                            font { pixelSize: Theme.fontSizeSmall; family: Theme.fontFamily }
                            text: model.text
                        }
                    }
                    onCountChanged: positionViewAtBeginning()
                    onDraggingChanged: {
                        if (!dragging && !keyboard.expandedPaste && contentX < -(headerItem.width + Theme.paddingLarge)) {
                            keyboard.expandedPaste = true
                            positionViewAtBeginning()
                        }
                    }

                    Connections {
                        target: anthy
                        onCandidatesUpdated: listView.positionViewAtBeginning()
                    }

                    Connections {
                        target: Clipboard
                        onTextChanged: {
                            if (Clipboard.hasText) {
                                // need to have updated width before repositioning view
                                positionerTimer.restart()
                            }
                        }
                    }

                    Timer {
                        id: positionerTimer
                        interval: 10
                        onTriggered: listView.positionViewAtBeginning()
                    }
                }
            }
        }
    }

    Component {
        id: pasteComponent
        PasteButton {
            onClicked: {
                if (preedit.length > 0) {
                    commit(preedit)
                }
                MInputMethodQuick.sendCommit(Clipboard.text)
                keyboard.expandedPaste = false
            }
        }
    }

    verticalItem: Component {
        Item {
            id: verticalContainer

            SilicaListView {
                id: verticalList

                model: anthy.candidates
                anchors.fill: parent
                clip: true
                header: Component {
                    PasteButtonVertical {
                        visible: Clipboard.hasText
                        width: verticalList.width
                        height: visible ? geometry.keyHeightLandscape : 0
                        popupParent: verticalContainer
                        popupAnchor: 2 // center

                        onClicked: {
                            commit(preedit)
                            MInputMethodQuick.sendCommit(Clipboard.text)
                        }
                    }
                }

                delegate: BackgroundItem {
                    onClicked: accept(model.index)
                    width: parent.width
                    height: geometry.keyHeightLandscape // assuming landscape!

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        anchors.verticalCenter: parent.verticalCenter
                        color: index === 0 ? Theme.highlightColor : Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        fontSizeMode: Text.HorizontalFit
//                        textFormat: Text.StyledText
                        text: model.text
                    }
                }

                Connections {
                    target: anthy
                    onCandidatesUpdated: {
                        if (!clipboardChange.running) {
                            verticalList.positionViewAtIndex(0, ListView.Beginning)
                        }
                    }
                }
                Connections {
                    target: Clipboard
                    onTextChanged: {
                        verticalList.positionViewAtBeginning()
                        clipboardChange.restart()
                    }
                }
                Timer {
                    id: clipboardChange
                    interval: 1000
                }
            }
        }
    }

    onActiveChanged: {
        if (!active && preedit !== "") {
//            accept(preedit)
            commit(preedit)
        }
    }

    function handleKeyClick() {
        var handled = false
        keyboard.expandedPaste = false

        if (pressedKey.key === Qt.Key_Space) {
            if (preedit === "") {
                if (canvas.layoutModel.enabledCount === 2) {
                    for (var i = canvas.layoutModel.count-1; i >= 0; --i) {
                        if (canvas.layoutModel.get(i).enabled && i !== canvas.activeIndex) {
                            canvas.switchLayout(i)
                            break
                        }
                    }
                }
            } else {
                MInputMethodQuick.sendPreedit(preedit)
            }
            handled = true
        } else if (pressedKey.key === Qt.Key_Return) {
            if (preedit !== "") {
                (nonCandLen > 0 && nonCandLen < preedit.length) ? commit_partial(preedit.slice(0, preedit.length-nonCandLen), preedit.slice(preedit.length-nonCandLen)) : commit(preedit)
//                commit(preedit)
                handled = true
            }
        } else if (pressedKey.key === Qt.Key_Backspace && preedit !== "") {
            if (nonCandLen > 0 && nonCandLen < preedit.length) {
                preedit = preedit.slice(0, preedit.length-nonCandLen-1) + preedit.slice(preedit.length-nonCandLen)
            } else {
                preedit = preedit.slice(0, preedit.length-1)
            }
            anthy.update_candidates(preedit)
            MInputMethodQuick.sendPreedit(preedit)
            preedit_oldlastchar = ""
            if (preedit === "") {
                nonCandLen = 0
            }
            handled = true
        } else if (pressedKey.key === Qt.Key_Left || pressedKey.key === Qt.Key_Right || pressedKey.key === Qt.Key_Up || pressedKey.key === Qt.Key_down) {
            if (preedit !== "") {
                if (pressedKey.key === Qt.Key_Left) {
                    nonCandLen = (nonCandLen < preedit.length ? nonCandLen+1 : (nonCandLen+1 > preedit.length ?  0 : preedit.length))
//                    MInputMethodQuick.cursorPosition = MInputMethodQuick.cursorPosition-1
                } else if (pressedKey.key === Qt.Key_Right) {
                    nonCandLen = (nonCandLen > 0 ? nonCandLen-1 : 0)
//                    MInputMethodQuick.cursorPosition = MInputMethodQuick.cursorPosition+1
                }
                anthy.update_candidates(preedit)
//                MInputMethodQuick.sendPreedit(preedit+MInputMethodQuick.cursorPosition)
                preedit_oldlastchar = ""
                handled = true
            } else {
                MInputMethodQuick.sendKey(pressedKey.key, 0, "", Maliit.KeyClick)
            } 
        } else if (pressedKey.key === Qt.Key_Shift || pressedKey.keyType === KeyType.SymbolKey && wasShifted) {
            if (preedit !== "") {
//                (nonCandLen > 0 && nonCandLen < preedit.length) ? commit_partial(preedit.slice(0, preedit.length-nonCandLen), preedit.slice(preedit.length-nonCandLen)) : commit(preedit)
                commit(preedit)
                handled = true
            }
        } else if (pressedKey.text === "\u2191" && keyboard.isShifted) {
            handled = true
        } else if (pressedKey.text.length !== 0) {
            var preedit_old = ""
            if (nonCandLen > 0 && nonCandLen < preedit.length) {
                preedit_old = preedit.slice(0, preedit.length-nonCandLen)
            } else {
                preedit_old = preedit
            }
            var preedit_lastchar = ""
            if (preedit === "") {
                wasShifted = keyboard.isShifted
                preedit_oldlastchar = ""
                nonCandLen = 0
            }
            preedit = preedit.slice(0, preedit.length-nonCandLen) + pressedKey.text + preedit.slice(preedit.length-nonCandLen)
            preedit = Parser.parse_char(preedit)
            if (nonCandLen > 0 && nonCandLen < preedit.length+1) {
//                preedit_lastchar = preedit.slice(preedit_old.length, preedit_old.length+1)
                preedit_lastchar = ""
            } else {
                preedit_lastchar = preedit.slice(preedit.length-1)
            }

/*            if (preedit_oldlastchar === "\u30FB") {
                preedit = preedit.slice(preedit_old.length)
                commit_partial(preedit_old, preedit)
                preedit_oldlastchar = ""
            } else*//* if (preedit_lastchar === " " || preedit_lastchar === "\u3002" || preedit_lastchar === "\u300D" || preedit_lastchar === "\uFF1F" || preedit_lastchar === "\uFF01" || preedit_lastchar === "\u2026" || preedit_lastchar === "\u3001" || preedit_lastchar === "\u300C" || preedit_lastchar === "(" || preedit_lastchar === ")") {
                (nonCandLen > 0 && nonCandLen < preedit.length) ? commit_partial(preedit.slice(0, preedit.length-nonCandLen), preedit.slice(preedit.length-nonCandLen)) : commit(preedit)
//                commit(preedit)
                preedit_oldlastchar = ""
            } else {*/
                anthy.update_candidates(preedit)
                MInputMethodQuick.sendPreedit(preedit)

                preedit_oldlastchar = preedit_lastchar
//            }

            handled = true
        }

        return handled
    }

    function accept(index) {
        console.debug("attempting to accept", index)
        anthy.acceptPhrase(index, preedit)
    }

    function reset() {
        preedit = ""
        preedit_oldlastchar = ""
        nonCandLen = 0
        anthy.update_candidates(preedit)
    }

    function commit(text) {
        MInputMethodQuick.sendCommit(text)
        reset()
    }

    function commit_partial(text, pe) {
        MInputMethodQuick.sendCommit(text)
        preedit = pe
        MInputMethodQuick.sendPreedit(preedit)
        nonCandLen = 0
        anthy.update_candidates(preedit)
    }
}
