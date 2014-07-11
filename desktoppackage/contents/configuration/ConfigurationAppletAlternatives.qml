/*
 *  Copyright 2014 Marco Martin <mart@kde.org>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  2.010-1301, USA.
 */

import QtQuick 2.0
import QtQuick.Controls 1.0 as QtControls
import QtQuick.Layouts 1.0
import org.kde.plasma.core 2.0 as PlasmaCore

import org.kde.plasma.private.shell 2.0

Item {
    id: root

    signal configurationChanged
    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height
    enabled: !plasmoid.immutable

    property string currentPlugin: plasmoid.pluginName

    function saveConfig() {
        configDialog.loadAlternative(currentPlugin);
    }

    QtControls.ExclusiveGroup {
        id: group
    }

    WidgetExplorer {
        id: widgetExplorer
        provides: configDialog.appletProvides
    }

    Column {
        anchors {
            top: parent.top
            topMargin: 25
            horizontalCenter: parent.horizontalCenter
        }

        Repeater {
            model: widgetExplorer.widgetsModel
            MouseArea {
                width: root.width
                height: childrenRect.height
                onClicked: radio.checked = true;
                RowLayout {
                    width: root.width
                    height: childrenRect.height + units.largeSpacing
                    QtControls.RadioButton {
                        id: radio
                        exclusiveGroup: group
                        Layout.maximumWidth: height
                        checked: model.pluginName == currentPlugin
                        onCheckedChanged: {
                            if (checked) {
                                currentPlugin = model.pluginName
                            }
                            configurationChanged();
                        }
                    }
                    PlasmaCore.IconItem {
                        width: units.iconSizes.small
                        height: width
                        source: model.decoration
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        QtControls.Label {
                            Layout.fillWidth: true
                            text: model.name
                        }
                        QtControls.Label {
                            Layout.fillWidth: true
                            text: model.description
                        }
                    }
                }
            }
        }
    }

}
