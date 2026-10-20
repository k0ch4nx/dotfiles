final: prev: {
  azahar = prev.azahar.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/citra_qt/util/metal_util.h \
        --replace-fail '#import "qwindowdefs.h"' '#import <QtGui/qwindowdefs.h>'
      substituteInPlace src/citra_qt/util/metal_util.mm \
        --replace-fail '#import <qwindowdefs.h>' '#import <QtGui/qwindowdefs.h>'
    '';
  });
}
