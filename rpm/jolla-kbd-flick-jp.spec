Name: jolla-kbd-flick-jp
Version: 0.01
Release: 1%{?dist}
Summary: Japanese flick keyboard layout and input method for Sailfish OS
License: LGPLv2
Source: %{name}-%{version}.tar.gz
URL: https://github.com/sleepsounds/jolla-kbd-flick-jp
Requires:   libanthy-qml-plugin
Requires:   jolla-keyboard
Requires:   jolla-xt9

%description
Sailfish implementation of the popular Japanese Flick keyboard.

%define debug_package %{nil}

%prep
%setup -q

%build
# do nothing

%install
#rm -rf %{buildroot}
#make install DESTDIR=%{buildroot}
mkdir -p %{buildroot}/usr/share/maliit/plugins/com/jolla/
mkdir -p %{buildroot}/usr/share/maliit/plugins/com/jolla/layouts
mkdir -p %{buildroot}/usr/share/maliit/plugins/com/jolla/layouts/ja_10key_flick
cp -r src/* %{buildroot}/usr/share/maliit/plugins/com/jolla/

%clean
rm -rf %{buildroot}

%files
/usr/share/maliit/plugins/com/jolla/Flicker.qml
/usr/share/maliit/plugins/com/jolla/KeyboardBase_Flick.qml
/usr/share/maliit/plugins/com/jolla/layouts/ja_10key_flick.qml
/usr/share/maliit/plugins/com/jolla/layouts/ja_10key_flick.conf
/usr/share/maliit/plugins/com/jolla/layouts/ja_10key_flick/JaInputHandler.qml
/usr/share/maliit/plugins/com/jolla/layouts/ja_10key_flick/TenKey_CustomArrowKey.qml
/usr/share/maliit/plugins/com/jolla/layouts/ja_10key_flick/TenKey_Flick.qml
/usr/share/maliit/plugins/com/jolla/layouts/ja_10key_flick/TenKey_ShiftKey.qml
/usr/share/maliit/plugins/com/jolla/layouts/ja_10key_flick/TenKey_SymbolKey.qml
/usr/share/maliit/plugins/com/jolla/layouts/ja_10key_flick/parse_10key_flick.js
