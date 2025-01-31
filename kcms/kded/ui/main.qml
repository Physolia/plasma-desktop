/*
    SPDX-FileCopyrightText: 2020 Kai Uwe Broulik <kde@broulik.de>

    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

import QtQuick
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.3 as QQC2
import QtQml 2.15

import org.kde.kirigami 2.10 as Kirigami
import org.kde.kirigami.delegates as KD
import org.kde.kcmutils as KCM
import org.kde.private.kcms.style 1.0 as Private

KCM.ScrollViewKCM {
    id: root

    Binding {
        target: kcm.filteredModel
        property: "query"
        value: searchField.text
        restoreMode: Binding.RestoreBinding
    }

    Binding {
        target: kcm.filteredModel
        property: "statusFilter"
        value: filterCombo.model[filterCombo.currentIndex].statusFilter
        restoreMode: Binding.RestoreBinding
    }

    header: ColumnLayout {
        Kirigami.InlineMessage {
            Layout.fillWidth: true
            text: i18n("The background services manager (kded6) is currently not running. Make sure it is installed correctly.");
            type: Kirigami.MessageType.Error
            showCloseButton: false
            visible: !kcm.kdedRunning
        }

        Kirigami.InlineMessage {
            id: selfDisablingModulesHint
            Layout.fillWidth: true
            text: i18n("Some services disable themselves again when manually started if they are not useful in the current environment.")
            type: Kirigami.MessageType.Information
            showCloseButton: true
            visible: false
        }

        Kirigami.InlineMessage {
            id: runningModulesChangedAfterSaveHint
            Layout.fillWidth: true
            text: i18n("Some services were automatically started/stopped when the background services manager (kded6) was restarted to apply your changes.")
            type: Kirigami.MessageType.Information
            showCloseButton: true
            visible: false
        }

        Kirigami.InlineMessage {
            id: errorMessage
            Layout.fillWidth: true

            type: Kirigami.MessageType.Error
            showCloseButton: true
            visible: false

            Connections {
                target: kcm
                function onErrorMessage(errorString) {
                    errorMessage.text = errorString;
                    errorMessage.visible = true;
                }
                function onShowSelfDisablingModulesHint() {
                    selfDisablingModulesHint.visible = true;
                }
                function onShowRunningModulesChangedAfterSaveHint() {
                    runningModulesChangedAfterSaveHint.visible = true;
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Kirigami.SearchField {
                id: searchField
                Layout.fillWidth: true
            }

            QQC2.ComboBox {
                id: filterCombo
                textRole: "text"
                enabled: kcm.kdedRunning || currentIndex > 0
                model: [
                    {text: i18n("All Services"), statusFilter: Private.KCM.UnknownStatus},
                    {text: i18nc("List running services", "Running"), statusFilter: Private.KCM.Running},
                    {text: i18nc("List not running services", "Not Running"), statusFilter: Private.KCM.NotRunning}
                ]

                // HACK QQC2 doesn't support icons, so we just tamper with the desktop style ComboBox's background
                // and inject a nice little filter icon.
                Component.onCompleted: {
                    if (!background || !background.hasOwnProperty("properties")) {
                        // not a KQuickStyleItem
                        return;
                    }

                    var props = background.properties || {};

                    background.properties = Qt.binding(function() {
                        var newProps = props;
                        newProps.currentIcon = "view-filter";
                        newProps.iconColor = Kirigami.Theme.textColor;
                        return newProps;
                    });
                }
            }
        }
    }

    view: ListView {
        id: list
        clip: true
        activeFocusOnTab: true
        reuseItems: true

        model: kcm.filteredModel

        section.property: "type"
        section.delegate: Kirigami.ListSectionHeader {
            width: list.width
            label: {
                switch (Number(section)) {
                    case Private.KCM.AutostartType: return i18n("Startup Services");
                    case Private.KCM.OnDemandType: return i18n("Load-on-Demand Services");
                }
            }
        }

        Component {
            id: listDelegateComponent

            // Not using KirigamiDelegates.CheckSubtitleDelegate because some
            // delegates need to be checkable, but others don't
            QQC2.ItemDelegate {
                id: delegate
                width: list.width
                text: model.display
                enabled: !model.immutable
                checkable: model.type !== Private.KCM.OnDemandType
                checked: model.autoloadEnabled === true
                hoverEnabled: checkable
                focusPolicy: Qt.ClickFocus
                Accessible.description: i18n("Toggle automatically loading this service on startup")
                onClicked: {
                    if (checkable) {
                        model.autoloadEnabled = !model.autoloadEnabled;
                    }
                }

                contentItem: RowLayout {
                    QQC2.CheckBox {
                        id: autoloadCheck
                        // Keep focus on the delegate
                        focusPolicy: Qt.NoFocus
                        checked: delegate.checked
                        visible: delegate.checkable
                        onToggled: model.autoloadEnabled = !model.autoloadEnabled

                        QQC2.ToolTip {
                            text: delegate.Accessible.description
                        }

                        KCM.SettingHighlighter {
                            highlight: !model.autoloadEnabled
                        }
                    }

                    KD.TitleSubtitle {
                        id: titleSubtitle
                        Layout.fillWidth: true
                        title: delegate.text
                        subtitle: model.description
                        selected: delegate.highlighted || delegate.pressed || delegate.down
                    }

                    QQC2.Label {
                        id: statusLabel
                        horizontalAlignment: Text.AlignRight
                        opacity: model.status === Private.KCM.Running ? 1 : delegate.hovered ? 0.8 : 0.6
                        color: model.status === Private.KCM.Running
                            ? Kirigami.Theme.positiveTextColor
                            : (titleSubtitle.selected ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor)
                        visible: kcm.kdedRunning && model.type !== Private.KCM.OnDemandType
                        text: {
                            switch (model.status) {
                            case Private.KCM.NotRunning: return i18n("Not running");
                            case Private.KCM.Running: return i18n("Running");
                            }
                            return "";
                        }
                    }

                    QQC2.Button {
                        icon.name: model.status === Private.KCM.Running ? "media-playback-pause" : "media-playback-start"
                        visible: kcm.kdedRunning && model.status !== Private.KCM.UnknownStatus && model.type !== Private.KCM.OnDemandType
                        onClicked: {
                            errorMessage.visible = false;

                            if (model.status === Private.KCM.Running) {
                                kcm.stopModule(model.moduleName);
                            } else {
                                kcm.startModule(model.moduleName);
                            }
                        }
                        Accessible.name: model.status === Private.KCM.Running ? i18n("Stop Service") : i18n("Start Service")

                        QQC2.ToolTip {
                            text: parent.Accessible.name
                        }
                    }
                }
            }
        }

        delegate: listDelegateComponent
    }
}
