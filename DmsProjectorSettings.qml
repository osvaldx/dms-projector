import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "dmsProjector"

    property string currentLanguage: "es"

    Component.onCompleted: {
        updateLanguage();
    }

    onPluginServiceChanged: {
        updateLanguage();
    }

    Connections {
        target: root.pluginService
        enabled: root.pluginService !== null
        ignoreUnknownSignals: true
        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId === root.pluginId) {
                root.updateLanguage();
            }
        }
    }

    function updateLanguage() {
        if (root.pluginService) {
            root.currentLanguage = root.pluginService.loadPluginData(root.pluginId, "language", "es");
        }
    }

    readonly property var translations: {
        "es": {
            "title": "Configuración de DMS Projector",
            "desc": "Configura el menú de proyección de pantalla rápida estilo Win + P para DankMaterialShell.",
            "generalHeader": "General",
            "languageLabel": "Idioma",
            "languageDesc": "Selecciona el idioma de la interfaz del plugin y las notificaciones.",
            "extendDirectionLabel": "Dirección de Pantalla Extendida",
            "extendDirectionDesc": "Posición en la que se ubicará la pantalla secundaria al extender el escritorio.",
            "optRight": "A la derecha",
            "optLeft": "A la izquierda",
            "optAbove": "Arriba",
            "optBelow": "Abajo",
            "behaviorHeader": "Comportamiento",
            "showNotificationsLabel": "Mostrar Notificaciones",
            "showNotificationsDesc": "Muestra una notificación OSD al cambiar el modo de proyección.",
            "hideWhenNoExternalLabel": "Ocultar si no hay pantalla externa",
            "hideWhenNoExternalDesc": "Oculta el icono de la barra cuando no hay ningún monitor HDMI o DisplayPort conectado.",
            "overridesHeader": "Salidas de Pantalla (Opcional)",
            "customInternalLabel": "Nombre Pantalla Principal",
            "customInternalDesc": "Forzar nombre del monitor interno/laptop (dejar vacío para auto-detección, ej: eDP-1).",
            "customExternalLabel": "Nombre Pantalla Secundaria",
            "customExternalDesc": "Forzar nombre del monitor externo/HDMI (dejar vacío para auto-detección, ej: HDMI-A-1)."
        },
        "en": {
            "title": "DMS Projector Settings",
            "desc": "Configure the quick display projection and screen switcher menu (Win + P style) for DankMaterialShell.",
            "generalHeader": "General",
            "languageLabel": "Language",
            "languageDesc": "Select the language for the plugin interface and notifications.",
            "extendDirectionLabel": "Extended Display Direction",
            "extendDirectionDesc": "Placement position of the external screen when extending the desktop.",
            "optRight": "To the right",
            "optLeft": "To the left",
            "optAbove": "Above",
            "optBelow": "Below",
            "behaviorHeader": "Behavior",
            "showNotificationsLabel": "Show Notifications",
            "showNotificationsDesc": "Display a system notification when changing projection mode.",
            "hideWhenNoExternalLabel": "Hide when no external display",
            "hideWhenNoExternalDesc": "Hide the bar widget when no HDMI or DisplayPort monitor is connected.",
            "overridesHeader": "Display Output Overrides (Optional)",
            "customInternalLabel": "Primary Display Name",
            "customInternalDesc": "Force internal/laptop display output name (leave empty for auto-detect, e.g. eDP-1).",
            "customExternalLabel": "Secondary Display Name",
            "customExternalDesc": "Force external/HDMI display output name (leave empty for auto-detect, e.g. HDMI-A-1)."
        }
    }

    function t(key) {
        var lang = currentLanguage === "en" ? "en" : "es";
        return translations[lang][key] || key;
    }

    StyledText {
        width: parent.width
        text: root.t("title")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: root.t("desc")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StyledText {
        width: parent.width
        text: root.t("generalHeader")
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    SelectionSetting {
        settingKey: "language"
        label: root.t("languageLabel")
        description: root.t("languageDesc")
        defaultValue: "es"
        options: [
            { label: "Español", value: "es" },
            { label: "English", value: "en" }
        ]
    }

    SelectionSetting {
        settingKey: "extendDirection"
        label: root.t("extendDirectionLabel")
        description: root.t("extendDirectionDesc")
        defaultValue: "right"
        options: [
            { label: root.t("optRight"), value: "right" },
            { label: root.t("optLeft"), value: "left" },
            { label: root.t("optAbove"), value: "above" },
            { label: root.t("optBelow"), value: "below" }
        ]
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StyledText {
        width: parent.width
        text: root.t("behaviorHeader")
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    ToggleSetting {
        settingKey: "showNotifications"
        label: root.t("showNotificationsLabel")
        description: root.t("showNotificationsDesc")
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "hideWhenNoExternal"
        label: root.t("hideWhenNoExternalLabel")
        description: root.t("hideWhenNoExternalDesc")
        defaultValue: false
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StyledText {
        width: parent.width
        text: root.t("overridesHeader")
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    StringSetting {
        settingKey: "customInternal"
        label: root.t("customInternalLabel")
        description: root.t("customInternalDesc")
        placeholder: "e.g. eDP-1"
        defaultValue: ""
    }

    StringSetting {
        settingKey: "customExternal"
        label: root.t("customExternalLabel")
        description: root.t("customExternalDesc")
        placeholder: "e.g. HDMI-A-1"
        defaultValue: ""
    }
}
