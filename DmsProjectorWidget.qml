import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
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
    property string language: "es"
    property string extendDirection: "right"
    property bool showNotifications: true
    property bool hideWhenNoExternal: false
    property string customInternal: ""
    property string customExternal: ""

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

    // --- Initialization & Settings Sync ---
    Component.onCompleted: {
        loadSettings();
        refreshOutputs();
        monitorPollTimer.start();
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
        language = pluginService.loadPluginData(root.pluginId, "language", "es");
        extendDirection = pluginService.loadPluginData(root.pluginId, "extendDirection", "right");
        showNotifications = pluginService.loadPluginData(root.pluginId, "showNotifications", true);
        hideWhenNoExternal = pluginService.loadPluginData(root.pluginId, "hideWhenNoExternal", false);
        customInternal = pluginService.loadPluginData(root.pluginId, "customInternal", "");
        customExternal = pluginService.loadPluginData(root.pluginId, "customExternal", "");
    }

    // --- Monitor Detection Logic ---
    function refreshOutputs() {
        if (!monitorDetectionProcess.running) {
            monitorDetectionProcess.exec(["hyprctl", "monitors", "all", "-j"]);
        }
    }

    Timer {
        id: monitorPollTimer
        interval: 4000
        repeat: true
        running: true
        onTriggered: {
            root.refreshOutputs();
        }
    }

    Timer {
        id: postApplyTimer
        interval: 600
        repeat: false
        onTriggered: {
            root.refreshOutputs();
        }
    }

    Process {
        id: monitorDetectionProcess
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = text.trim();
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

                    for (var i = 0; i < monitors.length; i++) {
                        var mon = monitors[i];
                        var name = mon.name || "";

                        // Check if internal (eDP, LVDS, DSI)
                        if (name.indexOf("eDP") !== -1 || name.indexOf("LVDS") !== -1 || name.indexOf("DSI") !== -1) {
                            foundInternal = name;
                            if (mon.disabled) internalDisabled = true;
                        } else {
                            // External candidate (HDMI, DP, VGA, Type-C)
                            foundExternal = name;
                            if (mon.disabled) {
                                externalDisabled = true;
                            } else {
                                if (mon.mirrorOf && mon.mirrorOf !== "none" && mon.mirrorOf !== "") {
                                    mirrorTarget = mon.mirrorOf;
                                }
                            }
                        }
                    }

                    // Apply manual overrides if configured
                    if (root.customInternal !== "") foundInternal = root.customInternal;
                    if (root.customExternal !== "") foundExternal = root.customExternal;

                    if (foundInternal !== "") root.internalMonitor = foundInternal;
                    root.externalMonitor = foundExternal;
                    root.hasExternalMonitor = (foundExternal !== "");

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
    }

    // --- Mode Execution Logic ---
    Process {
        id: executorProcess
    }

    function applyMode(mode) {
        var intMon = root.internalMonitor || "eDP-1";
        var extMon = root.externalMonitor || "HDMI-A-1";

        var cmd1 = "";
        var cmd2 = "";

        var title = (root.language === "en") ? "Display Projector" : "Proyección de Pantalla";
        var msg = "";

        if (mode === "internal") {
            // PC screen only: internal on, external disabled
            cmd1 = "hyprctl keyword monitor " + intMon + ",preferred,auto,1";
            if (extMon) {
                cmd2 = "hyprctl keyword monitor " + extMon + ",disable";
            }
            msg = (root.language === "en") ? "Switched to PC screen only" : "Modo activado: Solo pantalla de PC";
            root.activeMode = "internal";
        } else if (mode === "mirror") {
            // Mirror: external mirrors internal
            cmd1 = "hyprctl keyword monitor " + intMon + ",preferred,auto,1";
            cmd2 = "hyprctl keyword monitor " + extMon + ",preferred,auto,1,mirror," + intMon;
            msg = (root.language === "en") ? "Switched to Duplicate (Mirror)" : "Modo activado: Duplicar pantalla";
            root.activeMode = "mirror";
        } else if (mode === "extend") {
            // Extend: position according to extendDirection
            var pos = "auto-right";
            if (root.extendDirection === "left") pos = "auto-left";
            else if (root.extendDirection === "above") pos = "auto-up";
            else if (root.extendDirection === "below") pos = "auto-down";

            cmd1 = "hyprctl keyword monitor " + intMon + ",preferred,0x0,1";
            cmd2 = "hyprctl keyword monitor " + extMon + ",preferred," + pos + ",1";
            msg = (root.language === "en") ? "Switched to Extended desktop" : "Modo activado: Escritorio extendido";
            root.activeMode = "extend";
        } else if (mode === "external") {
            // Second screen only: internal disabled, external on
            cmd1 = "hyprctl keyword monitor " + intMon + ",disable";
            cmd2 = "hyprctl keyword monitor " + extMon + ",preferred,auto,1";
            msg = (root.language === "en") ? "Switched to Second screen only" : "Modo activado: Solo segunda pantalla";
            root.activeMode = "external";
        }

        var fullCmd = cmd1 + (cmd2 ? (" && " + cmd2) : "");
        executorProcess.exec(["bash", "-c", fullCmd]);

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
