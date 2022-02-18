/*
 *    SPDX-FileCopyrightText: 2022 Thiago Sueto <herzenschein@gmail.com>
 *
 *    SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "componentchoosertexteditor.h"

ComponentChooserTextEditor::ComponentChooserTextEditor(QObject *parent)
    : ComponentChooser(parent,
                       QStringLiteral("text/plain"),
                       QStringLiteral("TextEditor"),
                       QStringLiteral("org.kde.kate.desktop"),
                       i18n("Select default text editor"))
{
}

void ComponentChooserTextEditor::save()
{
    QStringList mimetypes{"text/plain", "text/x-cmake", "text/markdown", "application/x-docbook+xml", "application/json", "application/x-yaml"};
    saveMimeTypeAssociations(mimetypes, m_applications[m_index].toMap()[QStringLiteral("storageId")].toString());
}
