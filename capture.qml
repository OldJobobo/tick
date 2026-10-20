//@ pragma ShellId flea-picker-visual-evidence
import QtQuick
import QtTest
import Quickshell
import "flea" as Flea

// Capture the unmodified chooser tree; QtTest delivers its pointer and wheel events.
ShellRoot {
    id: root
    property var shell: null
    property var win: null
    property var entry: null
    property var scene: null
    property var hidden: null
    property int stage: 0
    property int ticks: 0
    property bool busy: false
    property string variant: Quickshell.env("FLEA_VISUAL_VARIANT")
    function find(item, predicate) {
        if (predicate(item)) return item
        var kids = item.children || []
        for (var i = 0; i < kids.length; i++) { var found = root.find(kids[i], predicate); if (found) return found }
        return null
    }
    function named(name) { return root.find(win.contentItem, function(item) { return item.objectName === name }) }
    function click(item) { driver.mouseClick(item, item.width / 2, item.height / 2, Qt.LeftButton, Qt.NoModifier, -1) }
    function wheel(delta) {
        var grid = win.viewItem()
        driver.mouseWheel(grid, grid.width / 2, grid.height / 2, Qt.NoButton, Qt.ControlModifier, 0, delta, 1)
    }
    function capture(name) {
        root.busy = true
        scene.grabToImage(function(image) {
            var path = Quickshell.env("FLEA_CAPTURE_OUT") + "/" + root.variant + "-" + name + ".png"
            if (!image.saveToFile(path)) { console.log("VISUAL FAIL save " + path); win.cancel(); return }
            console.log("VISUAL FRAME " + JSON.stringify({variant: root.variant, frame: name,
                editing: entry.editing, hidden: win.showHidden, rows: win.rows.map(function(row) { return row.n }),
                size: Flea.ViewState.thumbnailSize, view: win.viewMode, filename: win.saveName,
                answered: win.answered, width: win.width, height: win.height}))
            root.busy = false
        })
    }
    TestEvent { id: driver }
    Timer {
        interval: 350; repeat: true; running: true
        onTriggered: {
            if (++root.ticks > 90) { console.log("VISUAL FAIL timeout stage=" + stage); if (win) win.cancel(); else Qt.quit(); return }
            if (root.busy) return
            if (stage === 0) {
                if (!Flea.ViewState.initialReadComplete) return
                Flea.Theme.applyColors('background = "#202326"\nforeground = "#e8e6df"\naccent = "#b4bd9b"\ncolor0 = "#202326"\ncolor8 = "#8c9187"')
                var component = Qt.createComponent("flea/PickerWindow.qml")
                if (component.status !== Component.Ready) { console.log("VISUAL FAIL " + component.errorString()); Qt.quit(); return }
                shell = component.createObject(root); win = shell.pickerWin
                win.implicitWidth = 840; win.implicitHeight = 560
                var chrome = root.find(win.contentItem, function(item) { return item.submissionChanged !== undefined })
                scene = chrome.parent
                entry = root.find(win.contentItem, function(item) { return item.pathField !== undefined })
                hidden = root.named("pickerHidden")
                stage++; return
            }
            if (win.pendingListings || !win.saveReady || win.listingState !== "ready") return
            if (stage === 1) { root.capture("00-start"); stage++; return }
            if (stage === 2) { root.click(entry); stage++; return }
            if (stage === 3) {
                if (entry.editing !== (variant === "after")) { console.log("VISUAL FAIL unexpected click behavior"); win.cancel(); return }
                root.capture("01-path-click"); stage++; return
            }
            if (stage === 4) { if (entry.editing) driver.keyClick(Qt.Key_Escape, Qt.NoModifier, -1); stage++; return }
            if (stage === 5) { if (hidden) root.click(hidden); stage++; return }
            if (stage === 6) {
                if (win.showHidden !== (variant === "after")) { console.log("VISUAL FAIL unexpected hidden behavior"); win.cancel(); return }
                root.capture("02-hidden-files"); stage++; return
            }
            if (stage === 7) { if (hidden && win.showHidden) root.click(hidden); root.click(root.named("pickerGridView")); stage++; return }
            if (stage === 8) { root.capture("03-grid-medium"); stage++; return }
            if (stage === 9) { root.wheel(120); stage++; return }
            if (stage === 10) { root.capture("04-grid-wheel-up"); stage++; return }
            if (stage === 11) { root.wheel(120); stage++; return }
            if (stage === 12) { root.capture("05-grid-wheel-up-again"); stage++; return }
            if (stage === 13) { root.wheel(120); stage++; return }
            if (stage === 14) {
                if (Flea.ViewState.thumbnailSize !== (variant === "after" ? "huge" : "medium")) { console.log("VISUAL FAIL unexpected wheel behavior"); win.cancel(); return }
                root.capture("06-grid-huge"); stage++; return
            }
            if (stage === 15) { root.wheel(-120); stage++; return }
            if (stage === 16) { root.capture("07-grid-wheel-down"); stage++; return }
            if (stage === 17) {
                console.log("VISUAL DONE " + variant + " captures=8 filename=" + win.saveName + " answered=" + win.answered)
                stop(); win.cancel()
            }
        }
    }
}
