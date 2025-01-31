/*
    SPDX-FileCopyrightText: 2012 Gregor Taetzner <gregor@freenet.de>
    SPDX-FileCopyrightText: 2020 Ivan Čukić <ivan.cukic at kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.draganddrop as DND

import org.kde.plasma.activityswitcher as ActivitySwitcher
import org.kde.kirigami as Kirigami
import org.kde.activities as Activities

PlasmoidItem {
    id: root

    width: Kirigami.Units.iconSizes.large
    height: Kirigami.Units.iconSizes.large

    Layout.maximumWidth: Infinity
    Layout.maximumHeight: Infinity

    Layout.preferredWidth : icon.width + Kirigami.Units.smallSpacing + (root.showActivityName ? name.implicitWidth + Kirigami.Units.smallSpacing : 0)

    Layout.minimumWidth: 0
    Layout.minimumHeight: 0

    readonly property bool inVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool showActivityName: Plasmoid.configuration.showActivityName
    readonly property bool showActivityIcon: Plasmoid.configuration.showActivityIcon

    Plasmoid.onActivated: ActivitySwitcher.Backend.toggleActivityManager()
    preferredRepresentation: fullRepresentation

    DND.DropArea {
        id: dropArea
        anchors.fill: parent

        onDragEnter: ActivitySwitcher.Backend.setDropMode(true)
        onDragLeave: ActivitySwitcher.Backend.setDropMode(false)

        Activities.ActivityInfo {
            id: currentActivity
            activityId: ":current"
        }

        MouseArea {
            anchors.fill: parent

            activeFocusOnTab: true

            Keys.onPressed: {
                switch (event.key) {
                case Qt.Key_Space:
                case Qt.Key_Enter:
                case Qt.Key_Return:
                case Qt.Key_Select:
                    Plasmoid.activated();
                    break;
                }
            }
            Accessible.name: name.text ? i18nc("@info:tooltip", "Current activity is %1", name.text) : ""
            Accessible.description: tooltip.subText
            Accessible.role: Accessible.Button

            onClicked: Plasmoid.activated()
        }

        PlasmaCore.ToolTipArea {
            id: tooltip
            anchors.fill: parent
            mainText: i18n("Show Activity Manager")
            subText: i18n("Click to show the activity manager")
        }

        Kirigami.Icon {
            id: icon
            height: Math.min(parent.height, parent.width)
            width: height

            source: !root.showActivityIcon ? "activities" :
                    currentActivity.icon === "" ? "activities" :
                    currentActivity.icon
        }

        PlasmaComponents3.Label {
            id: name

            anchors {
                left: icon.right
                leftMargin: Kirigami.Units.smallSpacing
            }
            height: parent.height
            width: implicitWidth
            visible: root.showActivityName && !root.inVertical

            verticalAlignment: Text.AlignVCenter

            text: currentActivity.name
        }
    }
}
