/*
    Quickddit - Reddit client for mobile phones
    Copyright (C) 2015-2016  Sander van Grieken

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see [http://www.gnu.org/licenses/].
*/

#include <QDBusConnection>
#include <QDebug>

#include "dbusapp.h"
#include "app_adaptor.h"
#include "app_interface.h"

DbusApp::DbusApp(QObject *parent) :
    QObject(parent)
{
    new ViewAdaptor(this);
    new ApplicationAdaptor(this);

    QDBusConnection c = QDBusConnection::sessionBus();
    bool ret = c.registerService("org.quickddit.Quickddit");
    Q_ASSERT(ret);
    ret = c.registerObject("/org/quickddit/Quickddit", this);
    Q_ASSERT(ret);
    Q_UNUSED(ret);
}

ApplicationAdaptor::ApplicationAdaptor(QObject *parent) :
    QDBusAbstractAdaptor(parent)
{
    setAutoRelaySignals(true);
}

void ApplicationAdaptor::Activate(const QVariantMap &platform_data)
{
    Q_UNUSED(platform_data);
    qDebug() << "Activate";
}

void ApplicationAdaptor::Open(const QStringList &uris, const QVariantMap &platform_data)
{
    Q_UNUSED(platform_data);
    qDebug() << "Open" << uris;
    QMetaObject::invokeMethod(parent(), "openURL", Q_ARG(QStringList, uris));
}

void DbusApp::showInbox()
{
    qDebug() << "showInbox";
    emit requestMessageView();
}

void DbusApp::openURL(const QString& url)
{
    qDebug() << "openURL" << url;
    if (!url.isEmpty())
        emit requestOpenURL(url);
}

void DbusApp::openURL(const QStringList& urls)
{
    qDebug() << "openURL" << urls;
    if (!urls.isEmpty())
        openURL(urls.first());
}
