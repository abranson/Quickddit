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

#include "votemanager.h"

#include <QtNetwork/QNetworkReply>

#include "linkmodel.h"
#include "commentmodel.h"

VoteManager::VoteManager(QObject *parent) :
    AbstractManager(parent), m_model(0)
{
}

VoteManager::Type VoteManager::type() const
{
    return m_type;
}

void VoteManager::setType(VoteManager::Type type)
{
    m_type = type;
}

QObject *VoteManager::model() const
{
    return m_model;
}

void VoteManager::setModel(QObject *model)
{
    m_model = model;
}

void VoteManager::vote(const QString &fullname, VoteManager::VoteType voteType)
{
    if (m_reply != 0) {
        qWarning("VoteManager::vote(): Aborting active network request (Try to avoid!)");
        m_reply->disconnect();
        m_reply->deleteLater();
        m_reply = 0;
    }

    m_fullname = fullname;
    m_voteType = voteType;

    QHash<QString, QString> parameters;
    parameters["id"] = m_fullname;
    switch (voteType) {
    case Upvote:
        parameters["dir"] = "1"; break;
    case Downvote:
        parameters["dir"] = "-1"; break;
    case Unvote:
        parameters["dir"] = "0"; break;
    }

    connect(manager(), SIGNAL(networkReplyReceived(QNetworkReply*)),
            SLOT(onNetworkReplyReceived(QNetworkReply*)));
    manager()->createRedditRequest(QuickdditManager::POST, "/api/vote", parameters);

    setBusy(true);
}

void VoteManager::onNetworkReplyReceived(QNetworkReply *reply)
{
    disconnect(manager(), SIGNAL(networkReplyReceived(QNetworkReply*)),
               this, SLOT(onNetworkReplyReceived(QNetworkReply*)));
    if (reply != 0) {
        m_reply = reply;
        m_reply->setParent(this);
        connect(m_reply, SIGNAL(finished()), SLOT(onFinished()));
    } else {
        setBusy(false);
    }
}

void VoteManager::onFinished()
{
    if (m_reply->error() == QNetworkReply::NoError) {
        if (m_type == Link) {
            LinkModel *model = qobject_cast<LinkModel*>(m_model);
            Q_ASSERT(model != 0);
            model->changeVote(m_fullname, m_voteType);
        } else {
            CommentModel *model = qobject_cast<CommentModel*>(m_model);
            Q_ASSERT(model != 0);
            model->changeVote(m_fullname, m_voteType);
        }
    } else {
        emit error(m_reply->errorString());
    }

    m_reply->deleteLater();
    m_reply = 0;
    setBusy(false);
}