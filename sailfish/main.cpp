/*
    Quickddit - Reddit client for mobile phones
    Copyright (C) 2014  Dickson Leong

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

#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <QtGui/QGuiApplication>
#include <QtQml/qqml.h> // for qmlRegisterType
#include <QtQml/QQmlContext>
#include <QtQuick/QQuickView>
#include <sailfishapp.h>

#include "src/appsettings.h"
#include "src/qmlutils.h"
#include "src/quickdditmanager.h"
#include "src/linkmodel.h"
#include "src/commentmodel.h"
#include "src/subredditmodel.h"
#include "src/aboutsubredditmanager.h"
#include "src/multiredditmodel.h"
#include "src/aboutmultiredditmanager.h"
#include "src/messagemodel.h"
#include "src/messagemanager.h"
#include "src/imgurmanager.h"
#include "src/votemanager.h"
#include "src/commentmanager.h"
#include "src/captchamanager.h"
#include "src/linkmanager.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));

    app->setApplicationDisplayName("Quickddit");
    app->setApplicationName("harbour-quickddit");
    app->setOrganizationName("harbour-quickddit");
    app->setOrganizationDomain("harbour-quickddit");
    app->setApplicationVersion(APP_VERSION);

    qmlRegisterType<AppSettings>("harbour.quickddit.Core", 1, 0, "AppSettings");
    qmlRegisterType<QuickdditManager>("harbour.quickddit.Core", 1, 0, "QuickdditManager");
    qmlRegisterType<LinkModel>("harbour.quickddit.Core", 1, 0, "LinkModel");
    qmlRegisterType<CommentModel>("harbour.quickddit.Core", 1, 0, "CommentModel");
    qmlRegisterType<SubredditModel>("harbour.quickddit.Core", 1, 0, "SubredditModel");
    qmlRegisterType<AboutSubredditManager>("harbour.quickddit.Core", 1, 0, "AboutSubredditManager");
    qmlRegisterType<MultiredditModel>("harbour.quickddit.Core", 1, 0, "MultiredditModel");
    qmlRegisterType<AboutMultiredditManager>("harbour.quickddit.Core", 1, 0, "AboutMultiredditManager");
    qmlRegisterType<MessageModel>("harbour.quickddit.Core", 1, 0, "MessageModel");
    qmlRegisterType<MessageManager>("harbour.quickddit.Core", 1, 0, "MessageManager");
    qmlRegisterType<ImgurManager>("harbour.quickddit.Core", 1, 0, "ImgurManager");
    qmlRegisterType<VoteManager>("harbour.quickddit.Core", 1, 0, "VoteManager");
    qmlRegisterType<CommentManager>("harbour.quickddit.Core", 1, 0, "CommentManager");
    qmlRegisterType<CaptchaManager>("harbour.quickddit.Core", 1, 0, "CaptchaManager");
    qmlRegisterType<LinkManager>("harbour.quickddit.Core", 1, 0, "LinkManager");

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    view->rootContext()->setContextProperty("APP_VERSION", APP_VERSION);

    QMLUtils qmlUtils;
    view->rootContext()->setContextProperty("QMLUtils", &qmlUtils);

    view->setSource(SailfishApp::pathTo("qml/main.qml"));
    view->show();

    return app->exec();
}

