Name: jolla-kbd-flick-jp
Version: 0.02
Release: 3%{?dist}
Summary: Japanese flick layout for Sailfish OS
License: LGPLv2
Source: %{name}.tar.gz
URL: https://github.com/sleepsounds/jolla-kbd-flick-jp
BuildArch: noarch
Packager: helicalgear
Requires:   libanthy-qml-plugin
Requires:   patchmanager-ui
Requires:   jolla-anthy-jp
Requires:   jolla-keyboard
Requires:   jolla-xt9

%description
Allows you to type in Japanese by flick on Sailfish OS.

%define debug_package %{nil}

%prep
%setup -q -n %{name}

%build
# do nothing

%install
#rm -rf %{buildroot}
#make install DESTDIR=%{buildroot}
mkdir -p %{buildroot}/usr/share/maliit/plugins/com/jolla/
cp -r src/* %{buildroot}/usr/share/maliit/plugins/com/jolla/
mkdir -p %{buildroot}/usr/share/patchmanager/patches/jolla-kbd-flick-jp/
cp -r patch/* %{buildroot}/usr/share/patchmanager/patches/jolla-kbd-flick-jp/

%clean
rm -rf %{buildroot}

%files
/usr/share/maliit/plugins/com/jolla/Flicker.qml
/usr/share/maliit/plugins/com/jolla/layouts/ja_10key_flick.qml
/usr/share/maliit/plugins/com/jolla/layouts/ja_10key_flick.conf
/usr/share/maliit/plugins/com/jolla/layouts/ja_10key_flick/JaInputHandler.qml
/usr/share/maliit/plugins/com/jolla/layouts/ja_10key_flick/TenKey_CustomArrowKey.qml
/usr/share/maliit/plugins/com/jolla/layouts/ja_10key_flick/TenKey_Flick.qml
/usr/share/maliit/plugins/com/jolla/layouts/ja_10key_flick/TenKey_ShiftKey.qml
/usr/share/maliit/plugins/com/jolla/layouts/ja_10key_flick/TenKey_SymbolKey.qml
/usr/share/maliit/plugins/com/jolla/layouts/ja_10key_flick/parse_10key_flick.js
/usr/share/patchmanager/patches/jolla-kbd-flick-jp/patch.json
/usr/share/patchmanager/patches/jolla-kbd-flick-jp/unified_diff.patch

%pre
if [ -f /usr/sbin/patchmanager ]; then
    /usr/sbin/patchmanager -u %{name} || true
fi

%preun
if [ -f /usr/sbin/patchmanager ]; then
    /usr/sbin/patchmanager -u %{name} || true
fi
