/*
    SPDX-FileCopyrightText: 2012-2016 Ivan Cukic <ivan.cukic@kde.org>
    SPDX-FileCopyrightText: 2022 Méven Car <meven.car@kdenet.net>

    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/
#include "kcm_recentFiles.h"
#include "kactivitymanagerd_plugins_settings.h"
#include "kactivitymanagerd_settings.h"
#include "resourcescoring_interface.h"

#include <QDBusConnection>
#include <QDBusPendingCall>

#include <QMenu>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlEngine>

#include <QQuickWidget>

#include <KConfigGroup>
#include <KMessageWidget>
#include <KSharedConfig>

#include "BlacklistedApplicationsModel.h"
#include "ui_RecentFiles.h"

#include <utils/d_ptr_implementation.h>

#include "recentFiles-kcm-features.h"

#include "common/dbus/common.h"
#include "kactivitiesdata.h"
#include "kcms-recentfiles-debug.h"

K_PLUGIN_FACTORY_WITH_JSON(KActivityManagerKCMFactory, "kcm_recentFiles.json", registerPlugin<RecentFilesKcm>(); registerPlugin<KActivitiesData>();)

class RecentFilesKcm::Private : public Ui::RecentFiles
{
public:
    KActivityManagerdSettings *mainConfig;
    KActivityManagerdPluginsSettings *pluginConfig;

    BlacklistedApplicationsModel *blacklistedApplicationsModel;

    explicit Private(QObject *parent)
        : mainConfig(new KActivityManagerdSettings(parent))
        , pluginConfig(new KActivityManagerdPluginsSettings(parent))
        , blacklistedApplicationsModel(new BlacklistedApplicationsModel(parent))
    {
    }
};

RecentFilesKcm::RecentFilesKcm(QObject *parent, const KPluginMetaData &data)
    : KCModule(parent, data)
    , d(this)
{
    d->setupUi(widget());

    // Keep history initialization

    d->kcfg_keepHistoryFor->setRange(0, INT_MAX);
    d->kcfg_keepHistoryFor->setSpecialValueText(i18nc("unlimited number of months", "Forever"));

    connect(d->kcfg_keepHistoryFor, SIGNAL(valueChanged(int)), this, SLOT(spinKeepHistoryValueChanged(int)));
    spinKeepHistoryValueChanged(0);

    // Clear recent history button

    auto menu = new QMenu(widget());

    connect(menu->addAction(i18n("Forget the last hour")), &QAction::triggered, this, &RecentFilesKcm::forgetLastHour);
    connect(menu->addAction(i18n("Forget the last two hours")), &QAction::triggered, this, &RecentFilesKcm::forgetTwoHours);
    connect(menu->addAction(i18n("Forget a day")), &QAction::triggered, this, &RecentFilesKcm::forgetDay);
    connect(menu->addAction(i18n("Forget everything")), &QAction::triggered, this, &RecentFilesKcm::forgetAll);

    d->buttonClearRecentHistory->setMenu(menu);

    // Blacklist applications

    d->blacklistedApplicationsModel = new BlacklistedApplicationsModel(this);
    connect(d->blacklistedApplicationsModel, &BlacklistedApplicationsModel::changed, this, &RecentFilesKcm::unmanagedWidgetChangeState);
    connect(d->blacklistedApplicationsModel, &BlacklistedApplicationsModel::defaulted, this, &RecentFilesKcm::unmanagedWidgetDefaultState);

    d->viewBlacklistedApplications->setClearColor(QGuiApplication::palette().window().color());
    d->viewBlacklistedApplications->rootContext()->setContextProperty(QStringLiteral("applicationModel"), d->blacklistedApplicationsModel);
    d->viewBlacklistedApplications->setSource(QUrl::fromLocalFile(KAMD_KCM_DATADIR + QStringLiteral("/qml/recentFiles/BlacklistApplicationView.qml")));

    // React to changes

    connect(d->radioRememberSpecificApplications, &QAbstractButton::toggled, d->blacklistedApplicationsModel, &BlacklistedApplicationsModel::setEnabled);

    // By default the KCModule (and eventually the kconfigdialogmanager) use
    // the index of checked radio button as the value of the setting. In this
    // case however we have a mismatch, the radio button "Do not remember"
    // (radioDontRememberApplications) has index 1 but in the WhatToRemember
    // enum has the value 2! So...
    // 1. Let kconfigwidgets know that this QGroupBox will be using a custom
    //    property to indicate the setting's value ("kcfg_value")
    d->kcfg_whatToRemember->setProperty("kcfg_property", QByteArray("kcfg_value"));
    // 2. Every time any radio button is clicked, we need to reset the
    //    kcfg_value and potentially set the dialog to "needs saving" state
    //    NOTE: Do not use "toggled" since it fires for two buttons each time!
    connect(d->radioRememberSpecificApplications, &QAbstractButton::clicked, this, &RecentFilesKcm::whatToRememberWidgetChanged);
    connect(d->radioRememberAllApplications, &QAbstractButton::clicked, this, &RecentFilesKcm::whatToRememberWidgetChanged);
    connect(d->radioDontRememberApplications, &QAbstractButton::clicked, this, &RecentFilesKcm::whatToRememberWidgetChanged);

    // Initial state

    d->blacklistedApplicationsModel->setEnabled(false);
    d->messageWidget->setVisible(false);

    addConfig(d->pluginConfig, widget());
    addConfig(d->mainConfig, widget());
}

RecentFilesKcm::~RecentFilesKcm()
{
}

void RecentFilesKcm::defaults()
{
    d->blacklistedApplicationsModel->defaults();
    // Click and not setChecked to trigger whatToRememberWidgetChanged()
    d->radioRememberAllApplications->click();

    KCModule::defaults();
}

void RecentFilesKcm::load()
{
    d->blacklistedApplicationsModel->load();

    KCModule::load();
}

void RecentFilesKcm::whatToRememberWidgetChanged(bool)
{
    // See ctor for details: tl;dr: reset the what-to-rememeber value
    // and set the dialog to "changed" (if save is needed)
    // clang-format off
    const auto whatToRemember =
        d->radioRememberSpecificApplications->isChecked() ? SpecificApplications :
        d->radioDontRememberApplications->isChecked()     ? NoApplications :
        /* otherwise */                                     AllApplications;
    // clang-format on
    qCDebug(LOG_KCMS_RECENTFILES) << "whatToRememberWidgetChangeState: " << whatToRemember;
    d->kcfg_whatToRemember->setProperty("kcfg_value", whatToRemember);
    KCModule::setNeedsSave(whatToRemember != d->pluginConfig->whatToRemember());
}

void RecentFilesKcm::save()
{
    d->blacklistedApplicationsModel->save();
    // clang-format off
    const auto whatToRemember =
        d->radioRememberSpecificApplications->isChecked() ? SpecificApplications :
        d->radioDontRememberApplications->isChecked()     ? NoApplications :
        /* otherwise */                                     AllApplications;
    // clang-format on
    d->mainConfig->setResourceScoringEnabled(whatToRemember != NoApplications);
    d->mainConfig->save();

    KCModule::save();
}

void RecentFilesKcm::forget(int count, const QString &what)
{
    org::kde::ActivityManager::ResourcesScoring rankingsservice(QStringLiteral(KAMD_DBUS_SERVICE),
                                                                QStringLiteral(KAMD_DBUS_RESOURCES_SCORING_PATH),
                                                                QDBusConnection::sessionBus());
    rankingsservice.DeleteRecentStats(QString(), count, what);

    d->messageWidget->animatedShow();
}

void RecentFilesKcm::forgetLastHour()
{
    forget(1, QStringLiteral("h"));
}

void RecentFilesKcm::forgetTwoHours()
{
    forget(2, QStringLiteral("h"));
}

void RecentFilesKcm::forgetDay()
{
    forget(1, QStringLiteral("d"));
}

void RecentFilesKcm::forgetAll()
{
    forget(0, QStringLiteral("everything"));
}

void RecentFilesKcm::spinKeepHistoryValueChanged(int value)
{
    static auto months = ki18ncp("unit of time. months to keep the history", " month", " months");

    if (value) {
        d->kcfg_keepHistoryFor->setPrefix(i18nc("for in 'keep history for 5 months'", "For "));
        d->kcfg_keepHistoryFor->setSuffix(months.subs(value).toString());
    }
}

#include "kcm_recentFiles.moc"
