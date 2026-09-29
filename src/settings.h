/*
    Quickddit - Reddit client for mobile phones
    Copyright (C) 2014  Dickson Leong
    Copyright (C) 2015-2018  Sander van Grieken

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

#ifndef APPSETTINGS_H
#define APPSETTINGS_H

#include <QtCore/QObject>
#include <QtCore/QStringList>
#include <QtCore/QUrl>

class QSettings;

class Settings : public QObject
{
    Q_OBJECT
    Q_ENUMS(FontSize)
    Q_ENUMS(OrientationProfile)
    Q_ENUMS(ThumbnailScale)
    Q_ENUMS(PostLayout)
    Q_ENUMS(VideoSize)
    Q_ENUMS(VideoDownloader)
    Q_PROPERTY(bool commentsTapToHide READ commentsTapToHide WRITE setCommentsTapToHide NOTIFY commentsTapToHideChanged)
    Q_PROPERTY(FontSize fontSize READ fontSize WRITE setFontSize NOTIFY fontSizeChanged)
    Q_PROPERTY(QString redditUsername READ redditUsername NOTIFY usernameChanged)
    Q_PROPERTY(OrientationProfile orientationProfile READ orientationProfile WRITE setOrientationProfile NOTIFY orientationProfileChanged)
    Q_PROPERTY(bool pollUnread READ pollUnread WRITE setPollUnread NOTIFY pollUnreadChanged)
    Q_PROPERTY(ThumbnailScale thumbnailScale READ thumbnailScale WRITE setThumbnailScale NOTIFY thumbnailScaleChanged)
    Q_PROPERTY(PostLayout postLayout READ postLayout WRITE setPostLayout NOTIFY postLayoutChanged)
    Q_PROPERTY(bool showLinkType READ showLinkType WRITE setShowLinkType NOTIFY showLinkTypeChanged)
    Q_PROPERTY(bool blurSpoilers READ blurSpoilers WRITE setBlurSpoilers NOTIFY blurSpoilersChanged)
    Q_PROPERTY(bool blurNSFW READ blurNSFW WRITE setBlurNSFW NOTIFY blurNSFWChanged)
    Q_PROPERTY(bool loopVideos READ loopVideos WRITE setLoopVideos NOTIFY loopVideosChanged)
    Q_PROPERTY(bool preferAdaptive READ preferAdaptive WRITE setPreferAdaptive NOTIFY preferAdaptiveChanged)
    Q_PROPERTY(int subredditSection READ subredditSection WRITE setSubredditSection NOTIFY subredditSectionChanged)
    Q_PROPERTY(int messageSection READ messageSection WRITE setMessageSection NOTIFY messageSectionChanged)
    Q_PROPERTY(int commentSort READ commentSort WRITE setCommentSort NOTIFY commentSortChanged)
    Q_PROPERTY(bool useTor READ useTor WRITE setUseTor NOTIFY useTorChanged)
    Q_PROPERTY(VideoSize preferredVideoSize READ preferredVideoSize WRITE setPreferredVideoSize NOTIFY preferredVideoSizeChanged)
    Q_PROPERTY(VideoDownloader videoDownloader READ videoDownloader WRITE setVideoDownloader NOTIFY videoDownloaderChanged)
    Q_PROPERTY(QString videoDownloaderExecutable READ videoDownloaderExecutable WRITE setVideoDownloaderExecutable NOTIFY videoDownloaderExecutableChanged)
    Q_PROPERTY(QStringList accountNames READ accountNames NOTIFY accountsChanged)

public:
    enum FontSize {
        TinyFontSize = -1,
        SmallFontSize,
        MediumFontSize,
        LargeFontSize
    };

    enum OrientationProfile {
        DynamicProfile = 0,
        PortraitOnlyProfile,
        LandscapeOnlyProfile
    };

    enum ThumbnailScale {
        ScaleAuto,
        Scale100,
        Scale125,
        Scale150,
        Scale175,
        Scale200,
        Scale250
    };

    enum PostLayout {
        CompactLayout,
        CardLayout
    };

    enum VideoSize {
        VS360,
        VS720
    };

    enum VideoDownloader {
        BundledYoutubeDl,
        InstalledYoutubeDl,
        InstalledYtDlp,
        DownloaderExecutable
    };

    struct AccountData {
        QString accountName;
        QByteArray refreshToken;
        QString lastSeenMessage;
        QUrl iconImg;
    };

    struct SubredditPrefs {
        QString relPath;
        int section;
        int sectionTimeRange;
    };

    explicit Settings(QObject *parent = 0);

    bool commentsTapToHide() const;
    void setCommentsTapToHide(bool commentsTapToHide);

    FontSize fontSize() const;
    void setFontSize(FontSize fontSize);

    QString redditUsername() const;
    void setRedditUsername(const QString &username);

    QByteArray refreshToken() const;
    void setRefreshToken(const QByteArray &token);
    Q_INVOKABLE bool hasRefreshToken() const;

    OrientationProfile orientationProfile() const;
    void setOrientationProfile(const OrientationProfile profile);

    QString lastSeenMessage() const;
    void setLastSeenMessage(const QString &lastSeenMessage);

    bool pollUnread() const;
    void setPollUnread(const bool pollUnread);

    ThumbnailScale thumbnailScale() const;
    void setThumbnailScale(const ThumbnailScale scale);

    PostLayout postLayout() const;
    void setPostLayout(const PostLayout postLayout);

    bool showLinkType() const;
    void setShowLinkType(const bool showLinkType);

    bool blurSpoilers() const;
    void setBlurSpoilers(const bool blurSpoilers);

    bool blurNSFW() const;
    void setBlurNSFW(const bool blurNSFW);

    bool loopVideos() const;
    void setLoopVideos(const bool loopVideos);

    bool preferAdaptive() const;
    void setPreferAdaptive(const bool preferAdaptive);

    int subredditSection() const;
    void setSubredditSection(const int subredditSection);

    int messageSection() const;
    void setMessageSection(const int messageSection);

    int commentSort() const;
    void setCommentSort(const int commentSort);

    bool useTor() const;
    void setUseTor(const bool useTor);

    VideoSize preferredVideoSize() const;
    void setPreferredVideoSize(const VideoSize preferredVideoSize);

    VideoDownloader videoDownloader() const;
    void setVideoDownloader(VideoDownloader videoDownloader);

    QString videoDownloaderExecutable() const;
    void setVideoDownloaderExecutable(const QString &executable);

    QList<SubredditPrefs> subredditPrefs() const;
    void setSubredditPrefs(const QList<SubredditPrefs> subredditPrefs);

    QList<AccountData> accounts() const;
    QStringList accountNames() const;
    void setAccounts(const QList<AccountData> accounts);
    Q_INVOKABLE QUrl accountIcon(const QString &accountName) const;
    Q_INVOKABLE void removeAccount(const QString& accountName);

    QStringList filteredSubreddits() const;

signals:
    void commentsTapToHideChanged();
    void fontSizeChanged();
    void usernameChanged();
    void orientationProfileChanged();
    void pollUnreadChanged();
    void thumbnailScaleChanged();
    void postLayoutChanged();
    void showLinkTypeChanged();
    void blurSpoilersChanged();
    void blurNSFWChanged();
    void loopVideosChanged();
    void preferAdaptiveChanged();
    void subredditSectionChanged();
    void messageSectionChanged();
    void commentSortChanged();
    void useTorChanged();
    void preferredVideoSizeChanged();
    void videoDownloaderChanged();
    void videoDownloaderExecutableChanged();
    void subredditPrefsChanged();
    void accountsChanged();

private:
    QSettings *m_settings;

    bool m_commentsTapToHide;
    FontSize m_fontSize;
    QString m_redditUsername;
    QByteArray m_refreshToken;
    OrientationProfile m_orientationProfile;
    QString m_lastSeenMessage;
    bool m_pollUnread;
    ThumbnailScale m_thumbnailScale;
    PostLayout m_postLayout;
    bool m_showLinkType;
    bool m_blurSpoilers;
    bool m_blurNSFW;
    bool m_loopVideos;
    bool m_preferAdaptive;
    QStringList m_filteredSubreddits;
    int m_subredditSection;
    int m_messageSection;
    int m_commentSort;
    bool m_useTor;
    VideoSize m_preferredVideoSize;
    VideoDownloader m_videoDownloader;
    QString m_videoDownloaderExecutable;
    QList<SubredditPrefs> m_subredditPrefs;
    QList<AccountData> m_accounts;
};

#endif // APPSETTINGS_H
