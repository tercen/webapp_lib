import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:webapp_ui_commons/menu/menu_item.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_utils/services/app_user.dart';

class NavigationMenu with ChangeNotifier {
  String selectedScreen = "";
  final List<MenuItem> _menuItems = [];
  final Map<String, String> _menuLinks = {};
  String webApp = "";

  NavigationMenu();

  MenuItem getSelectedEntry() {
    return _menuItems.firstWhere((e) => e.label == selectedScreen,
        orElse: () => _menuItems.first);
  }

  void selectScreen(String label) {
    selectedScreen = label;
    notifyListeners();
  }

  Widget _createMenuEntry(MenuItem item) {
    bool isSelected = item.label == selectedScreen;

    var bgColor = item.isEnabled() && isSelected
        ? Styles()["selectedMenuBg"]
        : Colors.white;
    var textStyle =
        isSelected ? Styles()["menuTextSelected"] : Styles()["menuText"];

    var padding = const EdgeInsets.symmetric(vertical: 5, horizontal: 5);
    if (!item.isEnabled()) {
      textStyle = Styles()["menuTextDisabled"];
    }

    var inkWll = InkWell(
        hoverColor: Colors.transparent,
        onTap: () {
          if (item.isEnabled()) {
            selectScreen(item.label);
          }
        },
        child: Padding(
            padding: padding,
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text(item.label,
                    style: textStyle,
                    textScaler: const TextScaler.linear(1.1)))));

    return Container(
        color: bgColor,
        constraints:
            const BoxConstraints(minHeight: 25, maxHeight: 50, minWidth: 150),
        child: Align(
          alignment: Alignment.topLeft,
          child: inkWll,
        ));
  }

  void addItem(String label, StatefulWidget goToScreen,
      {bool Function()? enabledCheckCallback}) {
    _menuItems.add(MenuItem(label, goToScreen, enabledCheckCallback));
    // _menuKeys[label] =  ValueKey( Random().nextInt(1<<32-1) );
    if (selectedScreen == "") {
      selectedScreen = label;
    }
  }

  void addSpace() {
    StatefulWidget a = StatefulBuilder(
      builder: (context, setState) => Container(),
    );
    _menuItems.add(MenuItem("", a, null));
  }

  void addLink(String label, String href) {
    _menuLinks[label] = href;
  }

  Widget _createExitButton(String label, String href) {
    final Uri url = Uri.parse(href);

    Widget btn = InkWell(
        onTap: () {
          //  launchUrl(url, webOnlyWindowName: "_self");
          launchUrl(url, webOnlyWindowName: "_blank");
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: Styles()["textHref"],
            ),
            Icon(
              Icons.exit_to_app_outlined,
              color: Styles()["linkBlue"],
            )
          ],
        ));

    return btn;
  }

  Widget _createSpacer() {
    return Column(
      children: [
        SizedBox(
          height: 3,
        ),
        Container(
          height: 1,
          color: Styles()["lightBlack"],
        ),
        SizedBox(
          height: 3,
        ),
      ],
    );
  }

  Widget buildMenuWidget({Widget? banner}) {
    List<Widget> entries = [];
    if (banner != null) {
      entries.add(banner);
    }
    for (var i = 0; i < _menuItems.length; i++) {
      var item = _menuItems[i];
      if (item.label == "") {
        entries.add(_createSpacer());
      } else {
        entries.add(_createMenuEntry(item));
      }
    }

    entries.add(SizedBox(
      height: 100,
    ));

    for (var entry in _menuLinks.entries) {
      entries.add(_createExitButton(entry.key, entry.value));
    }

    Widget entriesWdg = SizedBox.expand(
      child: SingleChildScrollView(child: Column(children: entries)),
    );

    var infoEntries = createInfoWidgets();

    return Column(
      children: [Expanded(child: Container(child: entriesWdg)), infoEntries],
    );
  }

  Widget createInfoWidgets() {
    List<Widget> infoEntries = [];
    if ( AppUser().projectName != "") {
      infoEntries.add(Text(
        "Project: ${AppUser().projectName}",
        style: Styles()["textGray"],
      ));
    } else {
      infoEntries.add(Text(
        "No project loaded",
        style: Styles()["textGray"],
      ));
    }

    if (AppUser().teamname != "") {
      infoEntries.add(Text(
        "${AppUser().teamname}(${AppUser().username})",
        style: Styles()["textGray"],
      ));
    } else {
      infoEntries.add(Text(
        "${AppUser().teamname}",
        style: Styles()["textGray"],
      ));
    }

    if (webApp != "") {
      infoEntries.add(Text(
        "App: $webApp",
        style: Styles()["textGray"],
      ));
    }

    return Align(
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: infoEntries,
        ));
  }

  void toggle(int index) {
    // if(_leftMenuItems[index] != null){
    // _leftMenuItems[index]?.enabled = _leftMenuItems[index]?.enabled == true ? false : true;
    // }
  }

  void setEnabled(String label) {
    // if(_leftMenuItems[index] != null){
    // _leftMenuItems[index]?.enabled = value;
    // }
  }
}
