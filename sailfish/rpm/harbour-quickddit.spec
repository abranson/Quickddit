%define __requires_exclude ^/usr/bin/env$
%{!?qtc_qmake:%define qtc_qmake %qmake}
%{!?qtc_qmake5:%define qtc_qmake5 %qmake5}
%{!?qtc_make:%define qtc_make make}
%{?qtc_builddir:%define _builddir %qtc_builddir}

Name:       harbour-quickddit
Summary:    Reddit client for mobile phones
Version:    1.14.5
Release:    1
Group:      Qt/Qt
License:    GPLv3+
URL:        https://github.com/abranson/Quickddit
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5
Requires:   mapplauncherd-booster-silica-qt5
Requires:   qt5-plugin-imageformat-gif
Requires:   pyotherside-qml-plugin-python3-qt5
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(Qt5Network)
BuildRequires:  pkgconfig(sailfishapp)
BuildRequires:  pkgconfig(nemonotifications-qt5)
BuildRequires:  pkgconfig(keepalive)
BuildRequires:  pkgconfig(qt5embedwidget)
BuildRequires:  qt5-qttools-linguist
BuildRequires:  librsvg-tools

%description
Quickddit is a free and open source Reddit client for mobile phones.


%prep
%setup -q -n %{name}-%{version}

%build

%qtc_qmake5  \
    VERSION='%{version}' \
    %{?quickddit_reddit_client_id: REDDIT_CLIENT_ID=%{quickddit_reddit_client_id}} \
    %{?quickddit_reddit_client_secret: REDDIT_CLIENT_SECRET=%{quickddit_reddit_client_secret}} \
    %{?quickddit_reddit_redirect_url: REDDIT_REDIRECT_URL=%{quickddit_reddit_redirect_url}}

%qtc_make %{?_smp_mflags}

%install
%qmake5_install

for size in 86 108 128 172; do
    icon_dir="%{buildroot}%{_datadir}/icons/hicolor/${size}x${size}/apps";
    mkdir -p "${icon_dir}";
    rsvg-convert -w ${size} -h ${size} -o "${icon_dir}/%{name}.png" %{name}.svg;
done

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
# Make sure python files aren't executable or they'll fail harbour validation
%defattr(0644,root,root,-)
%{_datadir}/applications/%{name}.desktop
%{_datadir}/%{name}
%{_datadir}/icons/hicolor/86x86/apps/%{name}.png
%{_datadir}/icons/hicolor/108x108/apps/%{name}.png
%{_datadir}/icons/hicolor/128x128/apps/%{name}.png
%{_datadir}/icons/hicolor/172x172/apps/%{name}.png

