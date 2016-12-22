Name:       jolla-kbd-flick-jp
Version:    0.02
Release:    4%{?dist}
Summary:    Japanese flick layout for Sailfish OS
License:    LGPLv2
Source:     %{name}.tar.gz
URL:        https://github.com/sleepsounds/jolla-kbd-flick-jp
BuildArch:  noarch
Packager:   helicalgear,knokmki612
Requires:   libanthy-qml-plugin
Requires:   patchmanager-ui
Requires:   jolla-anthy-jp
Requires:   jolla-keyboard
Requires:   jolla-xt9
Requires:   sailfish-version >= 2.0.2

%description
Allows you to type in Japanese by flick on Sailfish OS.

%define debug_package %{nil}

%prep
%setup -q -n %{name}

%build
%qmake5

%install
rm -rf %{buildroot}
%qmake5_install

%files
/usr/share/maliit/plugins/com/jolla/Flicker.qml
/usr/share/maliit/plugins/com/jolla/layouts/ja_10key_flick.qml
/usr/share/maliit/plugins/com/jolla/layouts/ja_10key_flick.conf
/usr/share/maliit/plugins/com/jolla/layouts/ja_10key_flick/
/usr/share/patchmanager/patches/%{name}/

%pre
if [ -d /usr/share/patchmanager/patches/%{name} ]; then
/usr/sbin/patchmanager -u %{name} || true
fi

%preun
/usr/sbin/patchmanager -u %{name} || true
