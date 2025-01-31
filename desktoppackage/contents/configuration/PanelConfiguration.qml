/*
    SPDX-FileCopyrightText: 2023 Niccolò Venerandi <niccolo.venerandi@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.4 as QQC2
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kirigami 2.20 as Kirigami
import org.kde.ksvg 1.0 as KSvg
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.shell.panel 0.1 as Panel
import org.kde.kquickcontrols 2.0
import "panelconfiguration"

ColumnLayout {
    id: dialogRoot
    spacing: Kirigami.Units.largeSpacing * 2

    signal closeContextMenu
    implicitWidth: Kirigami.Units.gridUnit * 27

    required property QtObject panelConfiguration

    property bool vertical: (panel.location === PlasmaCore.Types.LeftEdge || panel.location === PlasmaCore.Types.RightEdge)

    readonly property int headingLevel: 2

    property Item panelRuler: Ruler {
        id: ruler

        prefix: {
            switch (panel.location) {
            case PlasmaCore.Types.TopEdge:
                return "north"
            case PlasmaCore.Types.LeftEdge:
                return "west"
            case PlasmaCore.Types.RightEdge:
                return "east"
            case PlasmaCore.Types.BottomEdge:
            default:
                return "south"
            }
        }
        Item {
            activeFocusOnTab: true
            onActiveFocusChanged: {
                if (activeFocus && dialogRoot.Window.window && dialogRoot.Window.window.visible) {
                    dialogRoot.Window.window.requestActivate()
                }
            }
        }
        // This item is used to "pass" focus to the main window when we're at the last of the control of the ruler
        Item {
            parent: dialogRoot.parent // Used to not take space in the ColumnLayout
            activeFocusOnTab: true
            onActiveFocusChanged: {
                let window = dialogRoot.Window.window
                if (activeFocus && window && window.visible) {
                    window.requestActivate()
                }
            }
        }
    }

    Connections {
        target: panel
        function onOffsetChanged() {
            ruler.offset = panel.offset
        }
        function onMinimumLengthChanged() {
            ruler.minimumLength = panel.minimumLength
        }
        function onMaximumLengthChanged() {
            ruler.maximumLength = panel.maximumLength
        }
    }



    PlasmaExtras.PlasmoidHeading {
        RowLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Heading {
                Layout.leftMargin: Kirigami.Units.smallSpacing
                text: i18nd("plasma_shell_org.kde.plasma.desktop", "Panel Settings")
            }

            Item { Layout.fillWidth: true }

            PC3.ToolButton {
                text: i18nd("plasma_shell_org.kde.plasma.desktop", "Add Spacer")
                icon.name: "distribute-horizontal-x"

                PC3.ToolTip.text: i18nd("plasma_shell_org.kde.plasma.desktop", "Add spacer widget to the panel")
                PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
                PC3.ToolTip.visible: hovered
                onClicked: configDialog.addPanelSpacer()
            }

            PC3.ToolButton {
                text: i18nd("plasma_shell_org.kde.plasma.desktop", "Add Widgets…")
                icon.name: "list-add"

                PC3.ToolTip.text: i18nd("plasma_shell_org.kde.plasma.desktop", "Open the widget selector to drag and drop widgets to the panel")
                PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
                PC3.ToolTip.visible: hovered
                onClicked: {
                    configDialog.close()
                    configDialog.showAddWidgetDialog()
                }
            }

        }
    }

    RowLayout {
        spacing: Kirigami.Units.smallSpacing
        Layout.fillWidth: true

        ColumnLayout {
            Layout.preferredWidth: dialogRoot.width / 3
            spacing: Kirigami.Units.mediumSpacing
            Kirigami.Heading {
                Layout.alignment: Qt.AlignHCenter
                level: dialogRoot.headingLevel
                text: i18nd("plasma_shell_org.kde.plasma.desktop", "Position")
            }
            PanelRepresentation {
                id: positionRepresentation
                text: (panel.location === PlasmaCore.Types.TopEdge ? i18nd("plasma_shell_org.kde.plasma.desktop", "Top") :
                       panel.location === PlasmaCore.Types.RightEdge ? i18nd("plasma_shell_org.kde.plasma.desktop", "Right") :
                       panel.location === PlasmaCore.Types.LeftEdge ? i18nd("plasma_shell_org.kde.plasma.desktop", "Left") :
                       i18nd("plasma_shell_org.kde.plasma.desktop", "Bottom"))
                Layout.alignment: Qt.AlignHCenter
                alignment: (panel.location === PlasmaCore.Types.TopEdge ? Qt.AlignHCenter | Qt.AlignTop :
                            panel.location === PlasmaCore.Types.RightEdge ? Qt.AlignVCenter | Qt.AlignRight :
                            panel.location === PlasmaCore.Types.LeftEdge ? Qt.AlignVCenter | Qt.AlignLeft :
                            Qt.AlignHCenter | Qt.AlignBottom)
                isVertical: dialogRoot.vertical
                mainIconSource: (panel.location === PlasmaCore.Types.TopEdge ? "arrow-top" :
                                 panel.location === PlasmaCore.Types.RightEdge ? "arrow-right" :
                                 panel.location === PlasmaCore.Types.LeftEdge ? "arrow-left": "arrow-down")
                onClicked: setPositionButton.checked = !setPositionButton.checked
            }
            PC3.Button {
                id: setPositionButton
                Layout.minimumHeight: transparencyBox.height
                Layout.alignment: Qt.AlignHCenter
                text: i18nd("plasma_shell_org.kde.plasma.desktop", "Set Position...")
                checkable: true
            }
        }
        Repeater {
            model: Application.screens
            Item {
                required property var modelData

                component Indicator : PlasmaCore.Dialog {
                    id: root
                    property string iconSource
                    property var onClickedLocation
                    flags: Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus | Qt.BypassWindowManagerHint
                    location: PlasmaCore.Types.Floating
                    visible: setPositionButton.checked && panel.location !== onClickedLocation

                    x: modelData.virtualX + Kirigami.Units.largeSpacing
                    y: modelData.virtualY + modelData.height / 2 - mainItem.height / 2 - margins.top

                    mainItem: PC3.ToolButton {
                        width: Kirigami.Units.iconSizes.enormous
                        height: Kirigami.Units.iconSizes.enormous
                        icon.name: root.iconSource

                        onClicked: {
                            setPositionButton.checked = false
                            panel.location = root.onClickedLocation
                        }
                    }
                }

                Indicator {
                    x: modelData.virtualX + Kirigami.Units.largeSpacing
                    y: modelData.virtualY + modelData.height / 2 - mainItem.height / 2 - margins.top
                    iconSource: "arrow-left"
                    onClickedLocation: PlasmaCore.Types.LeftEdge
                }
                Indicator {
                    x: modelData.virtualX + modelData.width - Kirigami.Units.largeSpacing - margins.left - margins.right - mainItem.width
                    y: modelData.virtualY + modelData.height / 2 - mainItem.height / 2 - margins.top
                    iconSource: "arrow-right"
                    onClickedLocation: PlasmaCore.Types.RightEdge
                }
                Indicator {
                    x: modelData.virtualX + modelData.width / 2 - mainItem.width / 2 - margins.left
                    y: modelData.virtualY + Kirigami.Units.largeSpacing
                    iconSource: "arrow-up"
                    onClickedLocation: PlasmaCore.Types.TopEdge
                }
                Indicator {
                    x: modelData.virtualX + modelData.width / 2 - mainItem.width / 2 - margins.left
                    y: modelData.virtualY + modelData.height - mainItem.height - margins.top - margins.bottom - Kirigami.Units.largeSpacing
                    iconSource: "arrow-down"
                    onClickedLocation: PlasmaCore.Types.BottomEdge
                }
            }
        }

        ColumnLayout {
            Layout.preferredWidth: dialogRoot.width / 3
            spacing: Kirigami.Units.mediumSpacing
            Kirigami.Heading {
                Layout.alignment: Qt.AlignHCenter
                level: dialogRoot.headingLevel
                text: i18nd("plasma_shell_org.kde.plasma.desktop", "Alignment")
            }
            PanelRepresentation {
                Layout.alignment: Qt.AlignHCenter
                mainIconSource: {
                    if (dialogRoot.vertical) {
                        if (alignmentBox.previewIndex === 0) {
                            return "align-vertical-top"
                        } else if (alignmentBox.previewIndex === 1) {
                            return "align-vertical-center"
                        } else {
                            return "align-vertical-bottom"
                        }
                    } else {
                        if (alignmentBox.previewIndex === 0) {
                            return "align-horizontal-left"
                        } else if (alignmentBox.previewIndex === 1) {
                            return "align-horizontal-center"
                        } else {
                            return "align-horizontal-right"
                        }
                    }
                }
                alignment: {
                    let first, second;
                    if (dialogRoot.vertical) {
                        if (alignmentBox.previewIndex === 0) {
                            first = Qt.AlignTop
                        } else if (alignmentBox.previewIndex === 1) {
                            first = Qt.AlignVCenter
                        } else {
                            first = Qt.AlignBottom
                        }
                        if (panel.location === PlasmaCore.Types.LeftEdge) {
                            second = Qt.AlignLeft
                        } else {
                            second = Qt.AlignRight
                        }
                    } else {
                        if (alignmentBox.previewIndex === 0) {
                            first = Qt.AlignLeft
                        } else if (alignmentBox.previewIndex === 1) {
                            first = Qt.AlignHCenter
                        } else {
                            first = Qt.AlignRight
                        }
                        if (panel.location === PlasmaCore.Types.TopEdge) {
                            second = Qt.AlignTop
                        } else {
                            second = Qt.AlignBottom
                        }
                    }
                    return first | second;
                }
                onClicked: alignmentBox.popup.visible = true
                isVertical: dialogRoot.vertical
            }
            PC3.ComboBox {
                id: alignmentBox
                Layout.alignment: Qt.AlignHCenter
                property int previewIndex: highlightedIndex > -1 ? highlightedIndex : currentIndex
                model: [
                    dialogRoot.vertical ? i18nd("plasma_shell_org.kde.plasma.desktop", "Top") : i18nd("plasma_shell_org.kde.plasma.desktop", "Left"),
                    i18nd("plasma_shell_org.kde.plasma.desktop", "Center"),
                    dialogRoot.vertical ? i18nd("plasma_shell_org.kde.plasma.desktop", "Bottom") : i18nd("plasma_shell_org.kde.plasma.desktop", "Right")
                ]
                currentIndex: (panel.alignment === Qt.AlignLeft ? 0 :
                                panel.alignment === Qt.AlignCenter ? 1 : 2)
                onActivated: (index) => {
                    if (index === 0) {
                        panel.alignment = Qt.AlignLeft
                    } else if (index === 1) {
                        panel.alignment = Qt.AlignCenter
                    } else {
                        panel.alignment = Qt.AlignRight
                    }
                }
            }
        }

        ColumnLayout {
            Layout.preferredWidth: dialogRoot.width / 3
            spacing: Kirigami.Units.mediumSpacing
            Kirigami.Heading {
                level: dialogRoot.headingLevel
                Layout.alignment: Qt.AlignHCenter
                text: i18nd("plasma_shell_org.kde.plasma.desktop", "Length")
            }
            PanelRepresentation {
                Layout.alignment: Qt.AlignHCenter
                mainIconSource: (widthBox.previewIndex === 1 ? "gnumeric-ungroup" :
                                 widthBox.previewIndex === 0 ? (dialogRoot.vertical ? "panel-fit-height" : "panel-fit-width") : "kdenlive-custom-effect")
                isVertical: dialogRoot.vertical
                alignment: positionRepresentation.alignment
                fillAvailable: widthBox.previewIndex === 0
                onClicked: widthBox.popup.visible = true
            }
            PC3.ComboBox {
                id: widthBox
                Layout.alignment: Qt.AlignHCenter
                property int previewIndex: highlightedIndex > -1 ? highlightedIndex : currentIndex
                model: [
                    dialogRoot.vertical ? i18nd("plasma_shell_org.kde.plasma.desktop", "Fill height") : i18nd("plasma_shell_org.kde.plasma.desktop", "Fill width"),
                    i18nd("plasma_shell_org.kde.plasma.desktop", "Fit content"),
                    i18nd("plasma_shell_org.kde.plasma.desktop", "Custom")
                ]
                currentIndex: (panel.lengthMode === Panel.Global.FillAvailable ? 0 :
                                panel.lengthMode === Panel.Global.FitContent ? 1 : 2)
                onActivated: (index) => {
                    if (index === 0) {
                        panel.lengthMode = Panel.Global.FillAvailable
                        panelConfiguration.panelRulerView.visible = false
                    } else if (index === 1) {
                        panel.lengthMode = Panel.Global.FitContent
                        panelConfiguration.panelRulerView.visible = false
                    } else {
                        panel.lengthMode = Panel.Global.Custom
                        panelConfiguration.panelRulerView.visible = true
                    }
                }
                Component.onCompleted: {
                    if (panel.lengthMode === Panel.Global.Custom) {
                        panelConfiguration.panelRulerView.visible = true
                    }
                }
            }
        }

    }

    RowLayout {
        spacing: Kirigami.Units.smallSpacing
        Layout.fillWidth: true

        ColumnLayout {
            Layout.preferredWidth: dialogRoot.width / 3
            spacing: Kirigami.Units.mediumSpacing
            Kirigami.Heading {
                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                level: dialogRoot.headingLevel
                text: i18nd("plasma_shell_org.kde.plasma.desktop", "Visibility")
            }
            PanelRepresentation {
                Layout.alignment: Qt.AlignHCenter
                sunkenPanel: autoHideSwitch.checked
                onClicked: autoHideSwitch.checked = !autoHideSwitch.checked
            }
            PC3.Switch {
                id: autoHideSwitch
                Layout.alignment: Qt.AlignHCenter
                Layout.minimumHeight: transparencyBox.height
                text: i18nd("plasma_shell_org.kde.plasma.desktop", "Auto hide")
                Component.onCompleted: checked = configDialog.visibilityMode === Panel.Global.AutoHide
                onCheckedChanged: {
                    if (checked) {
                        configDialog.visibilityMode = Panel.Global.AutoHide
                    } else {
                        configDialog.visibilityMode = Panel.Global.NormalPanel
                    }
                }
            }
        }

        ColumnLayout {
            Layout.preferredWidth: dialogRoot.width / 3
            spacing: Kirigami.Units.mediumSpacing
            Kirigami.Heading {
                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                level: dialogRoot.headingLevel
                text: i18nd("plasma_shell_org.kde.plasma.desktop", "Opacity")
            }
            PanelRepresentation {
                Layout.alignment: Qt.AlignHCenter
                adaptivePanel: transparencyBox.previewIndex === 0
                translucentPanel: transparencyBox.previewIndex === 2
                onClicked: transparencyBox.popup.visible = true
            }
            PC3.ComboBox {
                id: transparencyBox
                Layout.alignment: Qt.AlignHCenter
                property int previewIndex: popup.visible ? highlightedIndex : currentIndex
                model: [
                    i18nd("plasma_shell_org.kde.plasma.desktop", "Adaptive"),
                    i18nd("plasma_shell_org.kde.plasma.desktop", "Opaque"),
                    i18nd("plasma_shell_org.kde.plasma.desktop", "Translucent")
                ]
                currentIndex: (panel.opacityMode === Panel.Global.Adaptive ? 0 :
                                panel.opacityMode === Panel.Global.Opaque ? 1 : 2)
                onActivated: (index) => {
                    if (index === 0) {
                        panel.opacityMode = Panel.Global.Adaptive
                    } else if (index === 1) {
                        panel.opacityMode = Panel.Global.Opaque
                    } else {
                        panel.opacityMode = Panel.Global.Translucent
                    }
                }
            }
        }

        ColumnLayout {
            Layout.preferredWidth: dialogRoot.width / 3
            spacing: Kirigami.Units.mediumSpacing
            Kirigami.Heading {
                level: dialogRoot.headingLevel
                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                text: i18nd("plasma_shell_org.kde.plasma.desktop", "Style")
            }
            PanelRepresentation {
                text: "Yes"
                Layout.alignment: Qt.AlignHCenter
                floatingGap: Kirigami.Units.smallSpacing * floatingSwitch.checked
                onClicked: floatingSwitch.checked = !floatingSwitch.checked
            }
            PC3.Switch {
                id: floatingSwitch
                Layout.alignment: Qt.AlignHCenter
                Layout.minimumHeight: transparencyBox.height
                text: "Floating"
                Component.onCompleted: checked = panel.floating
                onCheckedChanged: panel.floating = checked
            }
        }

    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Kirigami.Units.largeSpacing

        PC3.Label {
            id: spinBoxLabel
            wrapMode: Text.Wrap

            text: panel.location === PlasmaCore.Types.LeftEdge || panel.location === PlasmaCore.Types.RightEdge ? i18nd("plasma_shell_org.kde.plasma.desktop", "Panel Width:") : i18nd("plasma_shell_org.kde.plasma.desktop", "Height:")
        }
        PC3.SpinBox {
            id: spinBox

            editable: true
            focus: !Kirigami.InputMethod.willShowOnActive
            from: Math.max(20, panel.minThickness) // below this size, the panel is mostly unusable
            to: panel.location === PlasmaCore.Types.LeftEdge || panel.location === PlasmaCore.Types.RightEdge ? panel.screenToFollow.geometry.width / 2 : panel.screenToFollow.geometry.height / 2

            stepSize: 2

            value: panel.thickness
            onValueModified: {
                panel.thickness = value
            }
        }
    }

    PlasmaExtras.PlasmoidHeading {
        position: PlasmaExtras.PlasmoidHeading.Footer
        Layout.topMargin: Kirigami.Units.smallSpacing
        topPadding: Kirigami.Units.smallSpacing * 2
        leftPadding: Kirigami.Units.smallSpacing
        bottomPadding: Kirigami.Units.smallSpacing

        Layout.fillWidth: true
        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Kirigami.Units.largeSpacing

            PC3.Label {
                text: i18nd("plasma_shell_org.kde.plasma.desktop", "Focus shortcut:")
                visible: panel.adaptiveOpacityEnabled

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                }

                PC3.ToolTip {
                    text: i18nd("plasma_shell_org.kde.plasma.desktop", "Press this keyboard shortcut to move focus to the Panel")
                    visible: mouseArea.containsMouse
                }
            }

            KeySequenceItem {
                id: button
                keySequence: plasmoid.globalShortcut
                onCaptureFinished: {
                    plasmoid.globalShortcut = button.keySequence
                }
            }

            Item {Layout.fillWidth: true}

            PC3.ToolButton {
                text: i18ndc("plasma_shell_org.kde.plasma.desktop", "@action:button Delete the panel", "Delete Panel")
                icon.name: "delete"

                PC3.ToolTip.text: i18nd("plasma_shell_org.kde.plasma.desktop", "Remove this panel; this action is undo-able")
                PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
                PC3.ToolTip.visible: hovered

                onClicked: plasmoid.internalAction("remove").trigger();
            }
        }
    }
    // This item is used to "pass" focus to the ruler with tab when we're at the last of the control of this window
    Item {
        parent: dialogRoot.parent // Used to not take space in the ColumnLayout
        activeFocusOnTab: true
        onActiveFocusChanged: {
            let window = ruler.Window.window
            if (activeFocus && window && window.visible) {
                window.requestActivate()
            }
        }
    }
}
