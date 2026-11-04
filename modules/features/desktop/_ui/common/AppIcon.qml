import Quickshell
import Quickshell.Widgets
import QtQuick

// A full-colour application icon from the theme's icon set. name may be an
// icon name or a path; an app without one gets a generic icon.
IconImage {
  property string name
  property int size: Theme.iconLarge

  implicitSize: size
  asynchronous: true
  source: {
    if (name.startsWith("/") || name.startsWith("file:") || name.startsWith("image:"))
      return name;
    return Quickshell.iconPath(name, "application-x-executable");
  }
}
