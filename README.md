Quickddit
=========

Quickddit is a free and open source Reddit client for mobile phones. Quickddit is **not** an official client
of Reddit and is not affiliated with Reddit in any way.

Quickddit is developed using Qt and currently available for MeeGo Harmattan (Qt 4.7.4), Sailfish OS (Qt 5.6) and Ubuntu-touch (Qt 5.9).
The logic part is developed in C++ while the UI is developed in QML.

The Harmattan port has been left at 1.0.0 feature level, and will not receive new features.

Reddit no longer allows anonymous access, so you need to sign in to use Quickddit.
On Sailfish OS, Quickddit opens the sign-in page at startup when no login is saved,
with a banner explaining why.

Features
========
| Feature                | SailfishOS | Ubuntu Touch | Nokia Harmattan (N9) |
|------------------------|:----------:|:------------:|:--------------------:|
| Sign into Reddit       | Y | Y | Y |
| Multi account          | Y | Y | Y |
| Compact and card post layouts | Y | | |
| Submit/edit new links and self-posts | Y | Y | Y |
| add, reply, edit, delete comments | Y | Y | Y |
| Browse your messages   | Y | Y | Y |
| Send messages          | Y | Y | Y |
| Vote on comments and posts | Y | Y | Y |
| Save comments and posts | Y | Y | Y |
| Multireddit support    | partial | partial | partial |
| integrated image viewer | Y | Y | Y |
| integrated reddit gallery viewer | Y | Y | |
| integrated Imgur album viewer | Y | Y | Y |
| integrated video player | Y | Y | |
| Use independently updated youtube-dl or yt-dlp | Y | | |
| integrated webviewer   | Y | Y | |
| search posts           | Y | | Y |
| search subreddits      | Y | Y | Y |
| inbox notifications    | Y | | Y |
| share posts            | Y | | Y |
| watch clipboard for reddit links | Y | | Y |
| TOR                    | Y | | Y |
| Post flair             | partial | partial | |
| User flair             | | | |
| Friends                | | | |
| Moderator features     | | | |

Reddit API client id and secret
----------------------------------

If you want to build Quickddit with OAuth support, remember to [get your own Reddit API client
id and secret](https://github.com/reddit/reddit/wiki/OAuth2) and fill it up in
[src/quickdditmanager.cpp](src/quickdditmanager.cpp) or define `REDDIT_CLIENT_ID`,
`REDDIT_CLIENT_SECRET` and `REDDIT_REDIRECT_URL` in project file or QtCreator.

Optionally you can also define `IMGUR_CLIENT_ID` with your own Imgur API client id.

Download
--------
- MeeGo Harmattan (Nokia N9/N950): [OpenRepos](https://openrepos.net/content/accumulator/quickddit)
- SailfishOS (Jolla): [OpenRepos](https://openrepos.net/content/abranson/quickddit)
- Ubuntu-touch: [OpenStore](https://open-store.io/app/quickddit) or build with `clickable -c ubuntu-touch/clickable.json`

Post layouts on Sailfish OS
--------------------------

In **Settings → Post Layout**, choose **Compact** (the default) or **Card**.
Card layout shows larger previews, with a thumbnail or text fallback when a preview
is unavailable. Tap a preview to open it, or tap a blurred preview to reveal it.
Long-press a post, thumbnail or card preview to open the post menu.

Video downloaders on Sailfish OS
-------------------------------

In **Settings → Media → Video downloader**, choose how Quickddit finds video streams:

| Option | Uses |
| --- | --- |
| **Bundled youtube-dl** (default) | The copy included with Quickddit; no separate installation needed. |
| **Installed youtube-dl** | A separately installed `youtube_dl` Python package. |
| **Installed yt-dlp** | A separately installed `yt_dlp` Python package. |
| **Executable** | A youtube-dl-compatible command-line program at the path you enter, such as `/usr/bin/yt-dlp`. |

The installed Python packages must be compatible with the device's Python runtime.
For **Executable**, enter just the executable path, without
arguments or shell quoting. Quickddit requests JSON metadata without downloading
the video, ignores downloader configuration files, and times out after two minutes.
Sailjail permissions are unchanged: the user is responsible for making the executable,
its interpreter (if needed), and other dependencies accessible inside Quickddit's
sandbox. Quickddit does not install downloaders or alter sandbox configuration.

Downloaders can be updated independently of Quickddit. If the selected downloader is missing or incompatible,
Quickddit reports an error instead of silently using its bundled copy.

Translations
------------

You can help translation Quickddit into different languages here:

https://hosted.weblate.org/projects/Quickddit/

License
-------
All files in this project are licensed under the GNU GPLv3+, unless otherwise stated.

    Quickddit - Reddit client for mobile phones
    Copyright (C) 2013-2014  Dickson Leong
    Copyright (C) 2015-2020  Sander van Grieken
    Copyright (C) 2025       Andrew Branson

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
