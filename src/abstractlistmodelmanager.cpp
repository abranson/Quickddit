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

#include "abstractlistmodelmanager.h"

AbstractListModelManager::AbstractListModelManager(QObject *parent) :
    QAbstractListModel(parent), m_busy(false), m_canLoadMore(true), m_manager(0)
{
}

#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
QHash<int, QByteArray> AbstractListModelManager::roleNames() const
{
    return customRoleNames();
}
#endif

bool AbstractListModelManager::isBusy() const
{
    return m_busy;
}

bool AbstractListModelManager::canLoadMore() const
{
    return m_canLoadMore;
}

QuickdditManager *AbstractListModelManager::manager() const
{
    return m_manager;
}

void AbstractListModelManager::setManager(QuickdditManager *manager)
{
    m_manager = manager;
}

void AbstractListModelManager::setBusy(bool busy)
{
    if (m_busy != busy) {
        m_busy = busy;
        emit busyChanged();
    }
}

void AbstractListModelManager::setCanLoadMore(bool canLoadMore)
{
    if (m_canLoadMore != canLoadMore) {
        m_canLoadMore = canLoadMore;
        emit canLoadMoreChanged();
    }
}
