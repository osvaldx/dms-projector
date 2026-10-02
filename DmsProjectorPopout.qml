import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PopoutComponent {
    id: root

    // Reference to the parent widget component if passed, or fallback
    property var widget: null

    readonly property var translations: {
        "es": {
            "title": "Proyectar pantalla",
            "subtitleSingle": "1 pantalla detectada (sin monitor externo)",
            "subtitleMulti": "Pantalla externa conectada: ",
            "pcOnlyTitle": "Solo pantalla de PC",
            "pcOnlyDesc": "Desactivar monitor externo y usar solo la pantalla principal",
            "mirrorTitle": "Duplicar",
            "mirrorDesc": "Mostrar la misma imagen en ambas pantallas",
            "extendTitle": "Extender",
            "extendDesc": "Ampliar el escritorio a lo largo de ambas pantallas",
            "secondOnlyTitle": "Solo segunda pantalla",
            "secondOnlyDesc": "Apagar pantalla principal y usar solo el monitor externo / TV",
            "activeBadge": "ACTIVO",
            "noExternalAlert": "Conectá un cable HDMI / DisplayPort para proyectar.",
            "refreshTooltip": "Volver a escanear pantallas",
            "detectedOutputs": "Salidas detectadas:"
        },
        "en": {
            "title": "Project Display",
            "subtitleSingle": "1 display detected (no external monitor)",
            "subtitleMulti": "External display connected: ",
            "pcOnlyTitle": "PC screen only",
            "pcOnlyDesc": "Disable external monitor and use primary screen only",
            "mirrorTitle": "Duplicate",
            "mirrorDesc": "Show the same desktop on both displays",
            "extendTitle": "Extend",
            "extendDesc": "Expand your desktop across both displays",
            "secondOnlyTitle": "Second screen only",
            "secondOnlyDesc": "Turn off primary screen and use external monitor / TV only",
            "activeBadge": "ACTIVE",
            "noExternalAlert": "Connect an HDMI or DisplayPort cable to project.",
            "refreshTooltip": "Rescan displays",
            "detectedOutputs": "Detected outputs:"
        }
    }

    function t(key) {
        var lang = (root.widget && root.widget.language === "en") ? "en" : "es";
        return translations[lang][key] || key;
    }

    headerText: root.t("title")
    detailsText: (root.widget && root.widget.hasExternalMonitor) 
        ? (root.t("subtitleMulti") + root.widget.externalMonitor)
        : root.t("subtitleSingle")
    showCloseButton: true

    Column {
        id: mainLayout
        width: parent.width
        spacing: Theme.spacingS

        // Warning banner when no external display is plugged in
        Rectangle {
            width: parent.width
            visible: !(root.widget && root.widget.hasExternalMonitor)
            height: bannerRow.implicitHeight + Theme.spacingS * 2
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHighest
            border.color: Theme.outlineVariant
            border.width: 1

            RowLayout {
                id: bannerRow
                anchors.fill: parent
                anchors.margins: Theme.spacingS
                spacing: Theme.spacingS

                DankIcon {
                    name: "info"
                    size: Theme.iconSize ? Theme.iconSize : 18
                    color: Theme.primary
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.t("noExternalAlert")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                }
            }
        }

        // List of Projection Modes (Cards)
        Column {
            width: parent.width
            spacing: Theme.spacingS

            // Option 1: PC Screen Only
            Rectangle {
                id: cardPcOnly
                width: parent.width
                height: 64
                radius: Theme.cornerRadius
                color: (root.widget && root.widget.activeMode === "internal") 
                    ? Theme.surfaceContainerHighest 
                    : (mousePcOnly.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainer)
                border.color: (root.widget && root.widget.activeMode === "internal") ? Theme.primary : Theme.outline
                border.width: (root.widget && root.widget.activeMode === "internal") ? 2 : 1

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingM

                    Rectangle {
                        width: (Theme.iconSize ? Theme.iconSize : 20) + 16
                        height: (Theme.iconSize ? Theme.iconSize : 20) + 16
                        radius: Theme.cornerRadius
                        color: (root.widget && root.widget.activeMode === "internal") ? Theme.primary : Theme.surfaceContainerHigh

                        DankIcon {
                            anchors.centerIn: parent
                            name: "computer"
                            size: Theme.iconSize ? Theme.iconSize : 20
                            color: (root.widget && root.widget.activeMode === "internal") ? Theme.onPrimary : Theme.primary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            text: root.t("pcOnlyTitle")
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                        }

                        StyledText {
                            text: root.t("pcOnlyDesc")
                            font.pixelSize: Theme.fontSizeSmall * 0.9
                            color: Theme.surfaceVariantText
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Rectangle {
                        visible: root.widget && root.widget.activeMode === "internal"
                        radius: Theme.cornerRadiusSmall ? Theme.cornerRadiusSmall : 4
                        color: Theme.primary
                        implicitWidth: badgeText1.implicitWidth + 10
                        implicitHeight: 20

                        StyledText {
                            id: badgeText1
                            anchors.centerIn: parent
                            text: root.t("activeBadge")
                            font.pixelSize: Theme.fontSizeExtraSmall ? Theme.fontSizeExtraSmall : (Theme.fontSizeSmall ? Theme.fontSizeSmall * 0.85 : 10)
                            font.weight: Font.Bold
                            color: Theme.onPrimary
                        }
                    }
                }

                MouseArea {
                    id: mousePcOnly
                    anchors.fill: parent
                    z: 10
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.widget) root.widget.applyMode("internal");
                    }
                }
            }

            // Option 2: Duplicate / Mirror
            Rectangle {
                id: cardMirror
                width: parent.width
                height: 64
                radius: Theme.cornerRadius
                color: (root.widget && root.widget.activeMode === "mirror") 
                    ? Theme.surfaceContainerHighest 
                    : (mouseMirror.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainer)
                border.color: (root.widget && root.widget.activeMode === "mirror") ? Theme.primary : Theme.outline
                border.width: (root.widget && root.widget.activeMode === "mirror") ? 2 : 1
                opacity: (root.widget && root.widget.hasExternalMonitor) ? 1.0 : 0.5

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingM

                    Rectangle {
                        width: (Theme.iconSize ? Theme.iconSize : 20) + 16
                        height: (Theme.iconSize ? Theme.iconSize : 20) + 16
                        radius: Theme.cornerRadius
                        color: (root.widget && root.widget.activeMode === "mirror") ? Theme.primary : Theme.surfaceContainerHigh

                        DankIcon {
                            anchors.centerIn: parent
                            name: "content_copy"
                            size: Theme.iconSize ? Theme.iconSize : 20
                            color: (root.widget && root.widget.activeMode === "mirror") ? Theme.onPrimary : Theme.primary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            text: root.t("mirrorTitle")
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                        }

                        StyledText {
                            text: root.t("mirrorDesc")
                            font.pixelSize: Theme.fontSizeSmall * 0.9
                            color: Theme.surfaceVariantText
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Rectangle {
                        visible: root.widget && root.widget.activeMode === "mirror"
                        radius: Theme.cornerRadiusSmall ? Theme.cornerRadiusSmall : 4
                        color: Theme.primary
                        implicitWidth: badgeText2.implicitWidth + 10
                        implicitHeight: 20

                        StyledText {
                            id: badgeText2
                            anchors.centerIn: parent
                            text: root.t("activeBadge")
                            font.pixelSize: Theme.fontSizeExtraSmall ? Theme.fontSizeExtraSmall : (Theme.fontSizeSmall ? Theme.fontSizeSmall * 0.85 : 10)
                            font.weight: Font.Bold
                            color: Theme.onPrimary
                        }
                    }
                }

                MouseArea {
                    id: mouseMirror
                    anchors.fill: parent
                    z: 10
                    hoverEnabled: true
                    cursorShape: (root.widget && root.widget.hasExternalMonitor) ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (root.widget && root.widget.hasExternalMonitor) root.widget.applyMode("mirror");
                    }
                }
            }

            // Option 3: Extend
            Rectangle {
                id: cardExtend
                width: parent.width
                height: 64
                radius: Theme.cornerRadius
                color: (root.widget && root.widget.activeMode === "extend") 
                    ? Theme.surfaceContainerHighest 
                    : (mouseExtend.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainer)
                border.color: (root.widget && root.widget.activeMode === "extend") ? Theme.primary : Theme.outline
                border.width: (root.widget && root.widget.activeMode === "extend") ? 2 : 1
                opacity: (root.widget && root.widget.hasExternalMonitor) ? 1.0 : 0.5

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingM

                    Rectangle {
                        width: (Theme.iconSize ? Theme.iconSize : 20) + 16
                        height: (Theme.iconSize ? Theme.iconSize : 20) + 16
                        radius: Theme.cornerRadius
                        color: (root.widget && root.widget.activeMode === "extend") ? Theme.primary : Theme.surfaceContainerHigh

                        DankIcon {
                            anchors.centerIn: parent
                            name: "splitscreen"
                            size: Theme.iconSize ? Theme.iconSize : 20
                            color: (root.widget && root.widget.activeMode === "extend") ? Theme.onPrimary : Theme.primary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            text: root.t("extendTitle")
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                        }

                        StyledText {
                            text: root.t("extendDesc")
                            font.pixelSize: Theme.fontSizeSmall * 0.9
                            color: Theme.surfaceVariantText
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Rectangle {
                        visible: root.widget && root.widget.activeMode === "extend"
                        radius: Theme.cornerRadiusSmall ? Theme.cornerRadiusSmall : 4
                        color: Theme.primary
                        implicitWidth: badgeText3.implicitWidth + 10
                        implicitHeight: 20

                        StyledText {
                            id: badgeText3
                            anchors.centerIn: parent
                            text: root.t("activeBadge")
                            font.pixelSize: Theme.fontSizeExtraSmall ? Theme.fontSizeExtraSmall : (Theme.fontSizeSmall ? Theme.fontSizeSmall * 0.85 : 10)
                            font.weight: Font.Bold
                            color: Theme.onPrimary
                        }
                    }
                }

                MouseArea {
                    id: mouseExtend
                    anchors.fill: parent
                    z: 10
                    hoverEnabled: true
                    cursorShape: (root.widget && root.widget.hasExternalMonitor) ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (root.widget && root.widget.hasExternalMonitor) root.widget.applyMode("extend");
                    }
                }
            }

            // Option 4: Second Screen Only
            Rectangle {
                id: cardSecondOnly
                width: parent.width
                height: 64
                radius: Theme.cornerRadius
                color: (root.widget && root.widget.activeMode === "external") 
                    ? Theme.surfaceContainerHighest 
                    : (mouseSecondOnly.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainer)
                border.color: (root.widget && root.widget.activeMode === "external") ? Theme.primary : Theme.outline
                border.width: (root.widget && root.widget.activeMode === "external") ? 2 : 1
                opacity: (root.widget && root.widget.hasExternalMonitor) ? 1.0 : 0.5

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingM

                    Rectangle {
                        width: (Theme.iconSize ? Theme.iconSize : 20) + 16
                        height: (Theme.iconSize ? Theme.iconSize : 20) + 16
                        radius: Theme.cornerRadius
                        color: (root.widget && root.widget.activeMode === "external") ? Theme.primary : Theme.surfaceContainerHigh

                        DankIcon {
                            anchors.centerIn: parent
                            name: "tv"
                            size: Theme.iconSize ? Theme.iconSize : 20
                            color: (root.widget && root.widget.activeMode === "external") ? Theme.onPrimary : Theme.primary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            text: root.t("secondOnlyTitle")
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                        }

                        StyledText {
                            text: root.t("secondOnlyDesc")
                            font.pixelSize: Theme.fontSizeSmall * 0.9
                            color: Theme.surfaceVariantText
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Rectangle {
                        visible: root.widget && root.widget.activeMode === "external"
                        radius: Theme.cornerRadiusSmall ? Theme.cornerRadiusSmall : 4
                        color: Theme.primary
                        implicitWidth: badgeText4.implicitWidth + 10
                        implicitHeight: 20

                        StyledText {
                            id: badgeText4
                            anchors.centerIn: parent
                            text: root.t("activeBadge")
                            font.pixelSize: Theme.fontSizeExtraSmall ? Theme.fontSizeExtraSmall : (Theme.fontSizeSmall ? Theme.fontSizeSmall * 0.85 : 10)
                            font.weight: Font.Bold
                            color: Theme.onPrimary
                        }
                    }
                }

                MouseArea {
                    id: mouseSecondOnly
                    anchors.fill: parent
                    z: 10
                    hoverEnabled: true
                    cursorShape: (root.widget && root.widget.hasExternalMonitor) ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (root.widget && root.widget.hasExternalMonitor) root.widget.applyMode("external");
                    }
                }
            }
        }

        // Bottom Info Bar & Refresh Button
        Rectangle {
            width: parent.width
            height: 36
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh
            border.color: Theme.outline
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingS
                spacing: Theme.spacingS

                DankIcon {
                    name: "display_settings"
                    size: (Theme.iconSize ? Theme.iconSize : 20) * 0.8
                    color: Theme.surfaceVariantText
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.t("detectedOutputs") + " " + 
                          ((root.widget && root.widget.internalMonitor) ? root.widget.internalMonitor : "eDP-1") +
                          ((root.widget && root.widget.hasExternalMonitor) ? (" · " + root.widget.externalMonitor) : "")
                    font.pixelSize: Theme.fontSizeSmall * 0.85
                    color: Theme.surfaceVariantText
                    elide: Text.ElideRight
                }

                Rectangle {
                    width: Theme.iconSize ? Theme.iconSize + 4 : 24
                    height: Theme.iconSize ? Theme.iconSize + 4 : 24
                    radius: (Theme.iconSize ? Theme.iconSize + 4 : 24) / 2
                    color: mouseRefresh.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                    DankIcon {
                        anchors.centerIn: parent
                        name: "refresh"
                        size: (Theme.iconSize ? Theme.iconSize : 20) * 0.8
                        color: Theme.primary
                    }

                    MouseArea {
                        id: mouseRefresh
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.widget) root.widget.refreshOutputs();
                        }
                    }
                }
            }
        }
    }
}
