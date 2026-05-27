/*
    Quickddit - Reddit client for mobile phones
    Copyright (C) 2015  Sander van Grieken

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

#ifndef DBUSAPP_H
#define DBUSAPP_H

#include <QDBusAbstractAdaptor>
#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantMap>

class ApplicationAdaptor : public QDBusAbstractAdaptor
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.freedesktop.Application")
    Q_CLASSINFO("D-Bus Introspection", ""
"  <interface name=\"org.freedesktop.Application\">\n"
"    <method name=\"Activate\">\n"
"      <arg direction=\"in\" type=\"a{sv}\" name=\"platform_data\"/>\n"
"    </method>\n"
"    <method name=\"Open\">\n"
"      <arg direction=\"in\" type=\"as\" name=\"uris\"/>\n"
"      <arg direction=\"in\" type=\"a{sv}\" name=\"platform_data\"/>\n"
"    </method>\n"
"  </interface>\n"
        "")
public:
    explicit ApplicationAdaptor(QObject *parent);

public slots:
    void Activate(const QVariantMap &platform_data);
    void Open(const QStringList &uris, const QVariantMap &platform_data);
};

class DbusApp : public QObject
{
    Q_OBJECT
public:
    explicit DbusApp(QObject *parent = 0);

signals:
    void requestMessageView(const QString &fullname = "");
    void requestOpenURL(const QString& url);

public slots:
    void showInbox();
    void openURL(const QString& url);
    void openURL(const QStringList& urls);
};

#endif // DBUSAPP_H
