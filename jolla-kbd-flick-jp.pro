TEMPLATE = aux
OTHER_FILES = \
        diff/ \
        patch/ \
        rpm/ \
        src/

src.files = \
        src/Flicker.qml \
        src/layouts
src.path = /usr/share/maliit/plugins/com/jolla

patch.files = patch/*
patch.path = /usr/share/patchmanager/patches/jolla-kbd-flick-jp

original = original$${src.path}/KeyboardBase.qml
patched = patched$${src.path}/KeyboardBase.qml

system((cd diff; diff -uprN $$original $$patched) > patch/unified_diff.patch)

INSTALLS += \
        src \
        patch
