import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root
    pluginId: "dmsProjector"

    // --- State Properties ---
    property string internalMonitor: "eDP-1"
    property string externalMonitor: ""
    property bool hasExternalMonitor: false
    property string activeMode: "internal" // "internal" | "mirror" | "extend" | "external" | "unknown"
    property bool isInitialized: false

    // --- Configurable Settings ---
    property string language: "en"
    property string extendDirection: "right"
    property bool showNotifications: true
    property bool hideWhenNoExternal: false
    property string customInternal: ""
    property string customExternal: ""
    property bool autoKeybind: false

    // --- IPC Handler for CLI and Keyboard Shortcuts (Win + P) ---
    IpcHandler {
        target: "dmsProjector"

        function open(): string {
            root.refreshOutputs();
            if (pluginPopout) pluginPopout.open();
            else root.triggerPopout();
            return "DMS_PROJECTOR_OPEN_SUCCESS";
        }

        function close(): string {
            root.closePopout();
            return "DMS_PROJECTOR_CLOSE_SUCCESS";
        }

        function toggle(): string {
            root.refreshOutputs();
            if (pluginPopout) {
                pluginPopout.toggle();
            } else {
                root.triggerPopout();
            }
            return "DMS_PROJECTOR_TOGGLE_SUCCESS";
        }
    }

    // Visibility in DankBar
    visible: !(hideWhenNoExternal && !hasExternalMonitor)

    // --- React to Screen Connection Changes (Wayland wl_output & Hyprland IPC Events) ---
    Timer {
        id: hotplugRetryTimer1
        interval: 200
        repeat: false
        onTriggered: root.refreshOutputs()
    }

    Timer {
        id: hotplugRetryTimer2
        interval: 600
        repeat: false
        onTriggered: root.refreshOutputs()
    }

    Timer {
        id: hotplugRetryTimer3
        interval: 1200
        repeat: false
        onTriggered: root.refreshOutputs()
    }

    function triggerHotplugScan() {
        root.refreshOutputs();
        hotplugRetryTimer1.restart();
        hotplugRetryTimer2.restart();
        hotplugRetryTimer3.restart();
    }

    Connections {
        target: (typeof WlrOutputService !== "undefined") ? WlrOutputService : null
        ignoreUnknownSignals: true
        function onStateChanged() {
            root.triggerHotplugScan();
        }
    }

    Connections {
        target: Quickshell
        ignoreUnknownSignals: true
        function onScreensChanged() {
            root.triggerHotplugScan();
        }
    }

    Connections {
        target: Hyprland
        ignoreUnknownSignals: true
        function onRawEvent(event) {
            root.triggerHotplugScan();
        }
    }

    Connections {
        target: (typeof HyprlandService !== "undefined") ? HyprlandService : null
        ignoreUnknownSignals: true
        function onMonitorLayoutChanged() {
            root.triggerHotplugScan();
        }
    }

    // Fast polling only while the popout menu is visible
    Timer {
        id: activeOpenPollTimer
        interval: 2000
        repeat: true
        running: pluginPopout ? pluginPopout.visible : false
        onTriggered: {
            root.refreshOutputs();
        }
    }

    function autoRegisterKeybind(force) {
        if (!pluginService || !autoKeybind)
            return;
        var status = pluginService.loadPluginData(root.pluginId, "autoKeybindConfigured", "");
        if (!force && status === "v2")
            return;

        // Auto configure Win+P for user opting into the shortcut
        var setupScript = 'DESKTOP="$(echo $XDG_CURRENT_DESKTOP | tr "[:upper:]" "[:lower:]")"; ' +
                          'if [ "$DESKTOP" = "niri" ]; then ' +
                          '  dms keybinds set niri "Mod+P" "exec dms ipc call widget toggle dmsProjector" --desc "Project Display (Win+P)" 2>/dev/null; ' +
                          'elif [ "$DESKTOP" = "sway" ]; then ' +
                          '  dms keybinds set sway "Mod4+p" "exec dms ipc call widget toggle dmsProjector" --desc "Project Display (Win+P)" 2>/dev/null; ' +
                          'else ' +
                          '  dms keybinds set hyprland "SUPER + P" "exec dms ipc call widget toggle dmsProjector" --desc "Project Display (Win+P)" 2>/dev/null; ' +
                          '  hyprctl reload 2>/dev/null; ' +
                          'fi';

        Quickshell.execDetached(["bash", "-c", setupScript]);
        pluginService.savePluginData(root.pluginId, "autoKeybindConfigured", "v2");
    }

    function removeKeybind() {
        var removeScript = 'DESKTOP="$(echo $XDG_CURRENT_DESKTOP | tr "[:upper:]" "[:lower:]")"; ' +
                           'if [ "$DESKTOP" = "niri" ]; then ' +
                           '  dms keybinds reset niri "Mod+P" 2>/dev/null; ' +
                           'elif [ "$DESKTOP" = "sway" ]; then ' +
                           '  dms keybinds reset sway "Mod4+p" 2>/dev/null; ' +
                           'else ' +
                           '  dms keybinds reset hyprland "SUPER + P" 2>/dev/null; ' +
                           '  hyprctl reload 2>/dev/null; ' +
                           'fi';

        Quickshell.execDetached(["bash", "-c", removeScript]);
        if (pluginService)
            pluginService.savePluginData(root.pluginId, "autoKeybindConfigured", "removed");
    }

    // --- Initialization & Settings Sync ---
    Component.onCompleted: {
        loadSettings();
        refreshOutputs();
        Qt.callLater(function() { autoRegisterKeybind(false); });
    }

    onPluginServiceChanged: {
        if (pluginService)
            loadSettings();
    }

    Connections {
        target: pluginService
        enabled: pluginService !== null
        ignoreUnknownSignals: true

        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId === root.pluginId) {
                root.loadSettings();
                root.refreshOutputs();
            }
        }
    }

    function loadSettings() {
        if (!pluginService)
            return;
        language = pluginService.loadPluginData(root.pluginId, "language", "en");
        extendDirection = pluginService.loadPluginData(root.pluginId, "extendDirection", "right");
        showNotifications = pluginService.loadPluginData(root.pluginId, "showNotifications", true);
        hideWhenNoExternal = pluginService.loadPluginData(root.pluginId, "hideWhenNoExternal", false);
        customInternal = pluginService.loadPluginData(root.pluginId, "customInternal", "");
        customExternal = pluginService.loadPluginData(root.pluginId, "customExternal", "");

        var prevAutoKeybind = autoKeybind;
        autoKeybind = pluginService.loadPluginData(root.pluginId, "autoKeybind", false);
        if (prevAutoKeybind && !autoKeybind) {
            removeKeybind();
        } else if (!prevAutoKeybind && autoKeybind) {
            autoRegisterKeybind(true);
        }
    }

    // Map to preserve detected monitor attributes (scales, modes, other monitors)
    property var monitorsMap: ({})
    property var otherMonitorsList: []

    // --- Monitor Detection Logic ---
    Process {
        id: monitorDetectionProcess
        command: ["hyprctl", "monitors", "all", "-j"]
        running: false
        stdout: StdioCollector {
            id: monitorCollector
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) return;
            var raw = monitorCollector.text ? monitorCollector.text.trim() : "";
            if (!raw) return;

            var jsonStart = raw.indexOf('[');
            if (jsonStart !== -1) {
                raw = raw.substring(jsonStart);
            }

            try {
                var monitors = JSON.parse(raw);
                var foundInternal = "";
                var foundExternal = "";
                var externalDisabled = false;
                var internalDisabled = false;
                var mirrorTarget = "none";
                var newMonMap = {};
                var others = [];

                for (var i = 0; i < monitors.length; i++) {
                    var mon = monitors[i];
                    var name = mon.name || "";
                    if (!name) continue;

                    newMonMap[name] = {
                        scale: (mon.scale !== undefined && mon.scale > 0) ? mon.scale : 1,
                        width: mon.width || 0,
                        height: mon.height || 0,
                        refreshRate: mon.refreshRate || 60,
                        disabled: !!mon.disabled,
                        mirrorOf: mon.mirrorOf || "none"
                    };

                    // Check if internal laptop display (eDP, LVDS, DSI)
                    if (name.indexOf("eDP") !== -1 || name.indexOf("LVDS") !== -1 || name.indexOf("DSI") !== -1) {
                        foundInternal = name;
                        if (mon.disabled) internalDisabled = true;
                    } else if (foundExternal === "") {
                        // External candidate (HDMI, DP, VGA, Type-C, Virtual)
                        foundExternal = name;
                        if (mon.disabled) {
                            externalDisabled = true;
                        } else {
                            if (mon.mirrorOf && mon.mirrorOf !== "none" && mon.mirrorOf !== "") {
                                mirrorTarget = mon.mirrorOf;
                            }
                        }
                    } else {
                        others.push(mon);
                    }
                }

                // Fallback for Desktop PCs without eDP/LVDS laptop screens (e.g. DP-1 + HDMI-A-1)
                if (foundInternal === "" && monitors.length > 0) {
                    foundInternal = monitors[0].name;
                    internalDisabled = monitors[0].disabled;
                    if (monitors.length > 1) {
                        foundExternal = monitors[1].name;
                        externalDisabled = monitors[1].disabled;
                        if (monitors[1].mirrorOf && monitors[1].mirrorOf !== "none" && monitors[1].mirrorOf !== "") {
                            mirrorTarget = monitors[1].mirrorOf;
                        }
                    } else {
                        foundExternal = "";
                        externalDisabled = true;
                    }
                }

                root.monitorsMap = newMonMap;
                root.otherMonitorsList = others;

                // Apply manual overrides if configured by user
                if (root.customInternal !== "") foundInternal = root.customInternal;
                if (root.customExternal !== "") foundExternal = root.customExternal;

                if (foundInternal !== "") root.internalMonitor = foundInternal;
                root.externalMonitor = foundExternal;
                root.hasExternalMonitor = (foundExternal !== "" && foundExternal !== foundInternal);

                // Determine active projection mode
                if (!root.hasExternalMonitor || externalDisabled) {
                    root.activeMode = "internal";
                } else if (internalDisabled && !externalDisabled) {
                    root.activeMode = "external";
                } else if (mirrorTarget !== "none") {
                    root.activeMode = "mirror";
                } else {
                    root.activeMode = "extend";
                }

                if (!root.isInitialized) {
                    root.isInitialized = true;
                }
            } catch (e) {
                console.error("DMS Projector: Failed to parse monitors JSON", e);
            }
        }
    }

    function refreshOutputs() {
        if (monitorDetectionProcess.running) {
            monitorDetectionProcess.running = false;
        }
        Qt.callLater(function() {
            monitorDetectionProcess.running = true;
        });
    }

    Timer {
        id: postApplyTimer
        interval: 600
        repeat: false
        onTriggered: {
            root.refreshOutputs();
        }
    }

    function applyMode(mode) {
        var intMon = root.internalMonitor || "eDP-1";
        var extMon = root.externalMonitor || "HDMI-A-1";

        var intScale = (root.monitorsMap[intMon] && root.monitorsMap[intMon].scale) ? root.monitorsMap[intMon].scale : 1;
        var extScale = (root.monitorsMap[extMon] && root.monitorsMap[extMon].scale) ? root.monitorsMap[extMon].scale : 1;

        var title = (root.language === "en") ? "Display Projector" : "Proyección de Pantalla";
        var msg = "";
        var luaFile1 = "";
        var luaFile2 = "";
        var legacyFile1 = "";
        var legacyFile2 = "";

        var needReset = false;
        var resetLua1 = "";
        var resetLua2 = "";
        var resetConf1 = "";
        var resetConf2 = "";

        if (mode === "internal") {
            // PC screen only: internal on, external disabled
            luaFile1 = 'hl.monitor({ output = "' + intMon + '", mode = "preferred", position = "0x0", scale = ' + intScale + ' })';
            luaFile2 = 'hl.monitor({ output = "' + extMon + '", disabled = true })';
            legacyFile1 = "monitor = " + intMon + ",preferred,0x0," + intScale;
            legacyFile2 = "monitor = " + extMon + ",disable";
            msg = (root.language === "en") ? "Switched to PC screen only" : "Modo activado: Solo pantalla de PC";
            root.activeMode = "internal";
        } else if (mode === "mirror") {
            // Mirror: external mirrors internal
            luaFile1 = 'hl.monitor({ output = "' + intMon + '", mode = "preferred", position = "0x0", scale = ' + intScale + ' })';
            luaFile2 = 'hl.monitor({ output = "' + extMon + '", mode = "preferred", position = "auto", scale = ' + extScale + ', mirror = "' + intMon + '" })';
            legacyFile1 = "monitor = " + intMon + ",preferred,0x0," + intScale;
            legacyFile2 = "monitor = " + extMon + ",preferred,auto," + extScale + ",mirror," + intMon;
            msg = (root.language === "en") ? "Switched to Duplicate (Mirror)" : "Modo activado: Duplicar pantalla";
            root.activeMode = "mirror";
        } else if (mode === "extend") {
            // Extend: position according to extendDirection
            var pos = "auto-right";
            if (root.extendDirection === "left") pos = "auto-left";
            else if (root.extendDirection === "above") pos = "auto-up";
            else if (root.extendDirection === "below") pos = "auto-down";

            luaFile1 = 'hl.monitor({ output = "' + intMon + '", mode = "preferred", position = "0x0", scale = ' + intScale + ' })';
            luaFile2 = 'hl.monitor({ output = "' + extMon + '", mode = "preferred", position = "' + pos + '", scale = ' + extScale + ' })';
            legacyFile1 = "monitor = " + intMon + ",preferred,0x0," + intScale;
            legacyFile2 = "monitor = " + extMon + ",preferred," + pos + "," + extScale;
            msg = (root.language === "en") ? "Switched to Extended desktop" : "Modo activado: Escritorio extendido";
            root.activeMode = "extend";

            // Detach any previous mirror pipeline by briefly cycling external output while keeping internal alive
            needReset = true;
            resetLua1 = 'hl.monitor({ output = "' + intMon + '", mode = "preferred", position = "0x0", scale = ' + intScale + ' })';
            resetLua2 = 'hl.monitor({ output = "' + extMon + '", disabled = true })';
            resetConf1 = 'monitor = ' + intMon + ',preferred,0x0,' + intScale;
            resetConf2 = 'monitor = ' + extMon + ',disable';
        } else if (mode === "external") {
            // Second screen only: external on FIRST, internal disabled
            luaFile1 = 'hl.monitor({ output = "' + extMon + '", mode = "preferred", position = "0x0", scale = ' + extScale + ' })';
            luaFile2 = 'hl.monitor({ output = "' + intMon + '", disabled = true })';
            legacyFile1 = "monitor = " + extMon + ",preferred,0x0," + extScale;
            legacyFile2 = "monitor = " + intMon + ",disable";
            msg = (root.language === "en") ? "Switched to Second screen only" : "Modo activado: Solo segunda pantalla";
            root.activeMode = "external";
        }

        // Preserve any additional 3rd/4th monitors so their config is never wiped
        var extraLuaLines = "";
        var extraConfLines = "";
        if (root.otherMonitorsList && root.otherMonitorsList.length > 0) {
            for (var m = 0; m < root.otherMonitorsList.length; m++) {
                var oMon = root.otherMonitorsList[m];
                var oScale = (oMon.scale !== undefined && oMon.scale > 0) ? oMon.scale : 1;
                if (!oMon.disabled) {
                    extraLuaLines += '\\nhl.monitor({ output = "' + oMon.name + '", mode = "preferred", position = "auto", scale = ' + oScale + ' })';
                    extraConfLines += '\\nmonitor = ' + oMon.name + ',preferred,auto,' + oScale;
                }
            }
        }

        var applyScript = 'OUT_LUA="$HOME/.config/hypr/dms/outputs.lua"; ' +
                          'OUT_CONF="$HOME/.config/hypr/dms/outputs.conf"; ' +
                          'mkdir -p "$HOME/.config/hypr/dms"; ' +
                          'WP=$(dms ipc call wallpaper get 2>/dev/null); ';

        if (needReset) {
            applyScript += 'printf "%s\\n%s\\n%s\\n" "-- Auto-generated by DMS — do not edit manually" "' + resetLua1.replace(/"/g, '\\"') + '" "' + resetLua2.replace(/"/g, '\\"') + '" > "$OUT_LUA"; ' +
                           'printf "%s\\n%s\\n%s\\n" "# Auto-generated by DMS — do not edit manually" "' + resetConf1.replace(/"/g, '\\"') + '" "' + resetConf2.replace(/"/g, '\\"') + '" > "$OUT_CONF"; ' +
                           'hyprctl reload 2>/dev/null; ' +
                           'sleep 0.15; ';
        }

        applyScript += 'printf "%s\\n%s\\n%s' + extraLuaLines + '\\n" "-- Auto-generated by DMS — do not edit manually" "' + luaFile1.replace(/"/g, '\\"') + '" "' + luaFile2.replace(/"/g, '\\"') + '" > "$OUT_LUA"; ' +
                       'printf "%s\\n%s\\n%s' + extraConfLines + '\\n" "# Auto-generated by DMS — do not edit manually" "' + legacyFile1.replace(/"/g, '\\"') + '" "' + legacyFile2.replace(/"/g, '\\"') + '" > "$OUT_CONF"; ' +
                       'hyprctl reload 2>/dev/null; ' +
                       '(sleep 0.35; if [ -n "$WP" ]; then dms ipc call wallpaper set "$WP" 2>/dev/null; fi; sleep 0.45; if [ -n "$WP" ]; then dms ipc call wallpaper set "$WP" 2>/dev/null; fi) &';

        Quickshell.execDetached(["bash", "-c", applyScript]);

        if (root.showNotifications) {
            Quickshell.execDetached(["notify-send", "-a", "DMS Projector", "-i", "video-display", title, msg]);
        }

        postApplyTimer.restart();
    }

    // --- DankBar Presentation & Popout ---
    popoutWidth: 380
    popoutHeight: 460
    popoutContent: Component {
        DmsProjectorPopout {
            widget: root
        }
    }

    function getBarIcon() {
        if (!root.hasExternalMonitor) return "desktop_windows";
        if (root.activeMode === "mirror") return "content_copy";
        if (root.activeMode === "extend") return "splitscreen";
        if (root.activeMode === "external") return "tv";
        return "screen_share";
    }

    horizontalBarPill: Component {
        RowLayout {
            spacing: Theme.spacingS ? Theme.spacingS : 6
            opacity: root.hasExternalMonitor ? 1.0 : 0.75

            DankIcon {
                name: root.getBarIcon()
                size: (Theme.iconSize ? Theme.iconSize : 16) * 0.9
                color: root.hasExternalMonitor ? Theme.primary : Theme.surfaceVariantText

                Behavior on color { ColorAnimation { duration: 200 } }
            }

            StyledText {
                visible: root.hasExternalMonitor
                text: (root.activeMode === "mirror") ? "Duplicar" : (root.activeMode === "extend" ? "Extendido" : (root.activeMode === "external" ? "Segunda" : "PC"))
                font.pixelSize: Theme.fontSizeSmall ? Theme.fontSizeSmall : 12
                color: Theme.surfaceText
            }
        }
    }

    verticalBarPill: Component {
        ColumnLayout {
            spacing: Theme.spacingS ? Theme.spacingS : 6
            opacity: root.hasExternalMonitor ? 1.0 : 0.75

            DankIcon {
                name: root.getBarIcon()
                size: (Theme.iconSize ? Theme.iconSize : 16) * 0.9
                color: root.hasExternalMonitor ? Theme.primary : Theme.surfaceVariantText

                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }
    }
}
