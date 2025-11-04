import 'dart:convert';
import 'package:web/web.dart' as html;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
// import 'package:jwt_decoder/jwt_decoder.dart';
// import 'package:kumo_analysis_app/left_menu.dart';
// import 'package:kumo_analysis_app/util/tercen_util.dart';

import 'package:sci_http_client/http_client.dart' as http_api;
import 'package:sci_http_client/http_browser_client.dart' as io_http;
import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;

import 'package:webapp_components/widgets/wait_indicator.dart';

import 'package:webapp_ui_commons/menu/menu_item.dart';
import 'package:webapp_ui_commons/menu/navigation_menu.dart';

import 'package:sci_http_client/http_auth_client.dart' as auth_http;
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_utils/services/app_user.dart';

class WebAppBase with ChangeNotifier {
  bool isInitialized = false;
  String appName = "";
  String appVersion = "";
  bool isMenuCollapsed = false;

  final List<MenuItem> menuItems = [];

  final NavigationMenu navMenu = NavigationMenu();
  final Map<String, ValueKey<int>> _menuKeys = {};

  Widget bannerContent = Container();
  Widget footerContent = Container();
  Widget navPanelContent = Container();
  Widget contentPanelContent = Container();

  bool get isDev => Uri.base.hasPort && (Uri.base.port > 10000);

  WebAppBase();

  set banner(Widget banner) => bannerContent = banner;
  set footer(Widget footer) => footerContent = footer;
  set leftPanel(Widget leftPanel) => navPanelContent = leftPanel;
  set rightPanel(Widget rightPanel) => contentPanelContent = rightPanel;

  Future<bool> initFactory(String token) async {
    if (token.isEmpty) {
      throw "A token is required";
    }

    var authClient =
        auth_http.HttpAuthClient(token, io_http.HttpBrowserClient());

    var factory = sci.ServiceFactory();

    if (isDev) {
      await factory.initializeWith(
          Uri.parse('http://127.0.0.1:5400'), authClient);
    } else {
      var uriBase = Uri.base;
      await factory.initializeWith(
          Uri(scheme: uriBase.scheme, host: uriBase.host, port: uriBase.port),
          authClient);
    }

    http_api.HttpClient.setCurrent(authClient);

    tercen.ServiceFactory.CURRENT = factory;

    return true;
  }

  Future<void> postInit() async {
    html.window.history.pushState({}, '', AppUser().projectUrl);
    isInitialized = true;
  }

  Future<void> init() async {
    if (!isInitialized) {
      await TercenWaitIndicator().init();

      http_api.HttpClient.setCurrent(io_http.HttpBrowserClient());

      var session = _createUserSession();

      await initFactory(session.token.token);

      await (tercen.ServiceFactory().userService as sci.UserService)
          .setSession(session);

      navMenu.addLink("Exit App", AppUser().projectUrl);
    }
  }

  String _getTercenToken() {
    var tercenToken = const String.fromEnvironment("TERCEN_TOKEN");
    if (tercenToken.isEmpty) {
      tercenToken = Uri.base.queryParameters["token"] ?? '';
    }
    return tercenToken;
  }

  sci.UserSession _createUserSession() {
    if (isDev) {
      var tercenToken = _getTercenToken();

      if (tercenToken.isEmpty) {
        throw 'Tercen token not found -- String.fromEnvironment("TERCEN_TOKEN")';
      }

      var decodedToken = JwtDecoder.decode(tercenToken);
      var session = sci.UserSession()
        ..user = (sci.User()
          ..id = decodedToken['data']['u']
          ..name = decodedToken['data']['u'])
        ..token = (sci.Token()..token = tercenToken);

      // print("Running in DEV mode");
      // var tok = Uri.base.queryParameters["token"] ?? '';
      // Map<String, dynamic> decodedToken = JwtDecoder.decode(tok);
      // username = decodedToken['data']['u'];
      // projectId = devProjectId;
      // session = sci.UserSession()
      //   ..user = (sci.User()..id = decodedToken['data']['u'])
      //   ..token = (sci.Token()..token = tok);

      // var href = "${Uri.base.scheme}://";
      // href = "$href${Uri.base.host}";
      // var parentPort =
      //     html.document.referrer.split(":").last.split("/").first;
      // href = "$href:$parentPort";
      // serviceBase = href;
      // href = "$href/$username";
      // href = "$href/p/$projectId";
      // projectHref = href;

      return session;
    } else {
      var authorization = html.window.localStorage['authorization'];
      if (authorization == null) {
        throw "Tercen token not found -- html.window.localStorage['authorization'] is null";
      }

      return sci.UserSession.json(json.decode(authorization));
    }
  }

  Map<String, String> getPersistentData() {
    return {"APP_selectedScreen": navMenu.getSelectedEntry().label};
  }

  void loadPersistentData(Map<String, dynamic> stateMap) {
    for (var entry in stateMap.entries) {
      if (entry.key == "APP_selectedScreen") {
        navMenu.selectedScreen = entry.value;
      }
    }
  }

  void addNavigationPage(String label, StatefulWidget screen,
      {bool Function()? enabledCheckCallback}) {
    navMenu.addItem(label, screen, enabledCheckCallback: enabledCheckCallback);
  }

  void addNavigationSpace() {
    navMenu.addSpace();
  }

  ValueKey<int> getKey(String menuLabel) {
    _menuKeys[menuLabel] = ValueKey<int>(Random().nextInt(1 << 32 - 1));

    return _menuKeys[menuLabel]!;
  }

  Widget getSelectedScreen() {
    var screen = navMenu.getSelectedEntry();
    _menuKeys[screen.label] = ValueKey<int>(Random().nextInt(1 << 32 - 1));

    return screen.screen;
  }

  Widget buildMenu(Widget banner) {
    if (isMenuCollapsed) {
      return SizedBox(
        width: 10,
        child: Container(
          color: Styles()["clear"],
        ),
      );
    } else {
      return Container(
        color: Colors.white,
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
            child: navMenu.buildMenuWidget(banner: banner),
          ),
        ),
      );
    }
  }

  Widget buildMenuSeparator() {
    var arrow = Icon(
      Icons.arrow_back_ios_rounded,
      color: Styles()["gray"],
      size: 20,
    );
    if (isMenuCollapsed) {
      arrow = Icon(
        Icons.arrow_forward_ios_rounded,
        color: Styles()["gray"],
        size: 20,
      );
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 1.5,
          child: Container(
            color: Styles()["gray"],
          ),
        ),
        InkWell(
          onTap: () {
            isMenuCollapsed = !isMenuCollapsed;

            navMenu.selectScreen(navMenu.selectedScreen); //Reload
            notifyListeners();
          },
          child: Stack(alignment: Alignment.center, children: [
            Icon(
              Icons.circle,
              color: Styles()["clear"],
              size: 40,
            ),
            Icon(Icons.circle_outlined, color: Styles()["gray"], size: 40),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
              child: arrow,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: arrow,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
              child: arrow,
            ),
          ]),
        )
      ],
    );
  }

  Scaffold buildScaffoldPage() {
    Widget banner = Container(
      color: Colors.white,
      child: Wrap(
        children: [bannerContent],
      ),
    );

    Widget leftPanelWidget = Flexible(
      flex: isMenuCollapsed ? 0 : 1,
      child: Container(
        color: Colors.white,
        child: buildMenu(banner),
      ),
      // ),
    );

    Widget contentPanelWidget = Flexible(
      flex: isMenuCollapsed ? 12 : 5,

      child: Container(
        color: Colors.white,
        child: getSelectedScreen(),
      ),
      // ),
    );

    Widget wdg = Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          leftPanelWidget,
          SizedBox(
            width: 4,
            child: Container(
              color: Colors.white,
            ),
          ),
          buildMenuSeparator(),
          SizedBox(
            width: 4,
            child: Container(
              color: Colors.white,
            ),
          ),
          contentPanelWidget
        ]);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        right: false,
        child: CustomScrollView(
          clipBehavior: Clip.none,
          slivers: [
            SliverFillRemaining(
              hasScrollBody: true,
              child: wdg,
            )
          ],
        ),
      ),
    );
  }
}
