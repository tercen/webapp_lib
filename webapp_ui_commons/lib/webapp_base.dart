import 'dart:convert';
import 'dart:html' as html;
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
import 'package:webapp_model/id_element.dart';
import 'package:webapp_ui_commons/menu/menu_item.dart';
import 'package:webapp_ui_commons/menu/naviagtion_menu.dart';

import 'package:sci_http_client/http_auth_client.dart' as auth_http;

class WebAppBase with ChangeNotifier {
  bool isInitialized = false;
  String projectId = "";
  String projectName = "";
  String projectHref = "";
  String username = "";
  String teamname = "";
  

  // String selectedScreen = "";
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
    html.window.history.pushState({}, '', projectHref);
    isInitialized = true;
  }

  Future<void> init() async {
    if (!isInitialized) {
      await TercenWaitIndicator().init();

      http_api.HttpClient.setCurrent(io_http.HttpBrowserClient());
      projectId = Uri.base.queryParameters["projectId"] ?? '';
      late sci.UserSession session;
      String devProjectId = const String.fromEnvironment("PROJECT_ID");

      if (devProjectId != "") {
        print("Running in DEV mode");
        var tok = Uri.base.queryParameters["token"] ?? '';
        Map<String, dynamic> decodedToken = JwtDecoder.decode(tok);
        username = decodedToken['data']['u'];
        projectId = devProjectId;
        session = sci.UserSession()
          ..user = (sci.User()..id = decodedToken['data']['u'])
          ..token = (sci.Token()..token = tok);

        var href = "${Uri.base.scheme}://";
        href = "$href${Uri.base.host}";
        var parentPort =
            html.document.referrer.split(":").last.split("/").first;
        href = "$href:$parentPort";

        href = "$href/$username";
        href = "$href/p/$projectId";
        projectHref = href;
      } else {
        var auth = json.decode(html.window.localStorage['authorization'] ?? "");

        session = sci.UserSession.json(auth);
        // widget.handler.userSession = session;

        username = session.user
            .name; //widget.handler.getModelValue(ModelKey.selectedTeam, emptyVal: session.user.name);

        var href = "${Uri.base.scheme}://";
        href = "$href${Uri.base.host}";
        if (Uri.base.hasPort) {
          href = "$href:${Uri.base.port}";
        }

        href = "$href/$username";
        if( projectId != ""){
          href = "$href/p/$projectId";
        }
        
        projectHref = href;

        // var queryMap = Uri.base.queryParameters;
        // //teamId -- projectId, set it here
        // var newUri = Uri.base.replace(queryParameters: {"teamId":username, "projectId":projectId});
        // String newQueryAddress = '';
        // var remList = ['stepId', 'workflowId', 'token', 'gt', 'taskId'];
        // for (var entry in queryMap.entries) {
        //   if (!remList.contains(entry.key)) {
        //     newQueryAddress = "$newQueryAddress&${entry.key}=${entry.value}";
        //   }
        // }
        // print(newUri.toString());

        // html.window.history.pushState({}, '', projectHref);
      }

      navMenu.addLink("Exit App", projectHref);

      await initFactory(session.token.token);
      var factory = tercen.ServiceFactory();
      var userService = factory.userService as sci.UserService;

      await userService.setSession(session);

    

      if (projectId != "") {
        var project = await factory.projectService.get(projectId);
        projectName = project.name;
        teamname = project.acl.owner;
      }
      // if( !awaitInit ){
      //   isInitialized = true;
      // }
      
    }
  }

  Map<String, List<IdElement>> getPersistentData() {
    return {
      "APP_selectedScreen": [
        IdElement(
            navMenu.getSelectedEntry().label, navMenu.getSelectedEntry().label)
      ]
    };
  }

  void loadPersistentData(Map<String, List<IdElement>> stateMap) {
    for (var entry in stateMap.entries) {
      if (entry.key == "APP_selectedScreen") {
        navMenu.selectedScreen = entry.value.first.id;
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

  Scaffold buildScaffoldPage() {
    Widget banner = Container(
      color: Colors.white,
      child: Wrap(
        children: [bannerContent],
      ),
    );

    Widget leftPanelWidget = Flexible(
      flex: 1,
      child: Container(
        color: Colors.white,
        child: Align(
            alignment: Alignment.topLeft, child: navMenu.buildMenuWidget()),
      ),
      // ),
    );

    Widget contentPanelWidget = Flexible(
      flex: 5,

      child: Container(
        color: Colors.white,
        child: getSelectedScreen(),
      ),
      // ),
    );

    Widget wdg = Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [leftPanelWidget, contentPanelWidget]);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 125,
        titleSpacing: 0,
        title: banner,
      ),
      body: SafeArea(
        right: false,
        child: CustomScrollView(
          clipBehavior: Clip.none,
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: wdg,
            )
          ],
        ),
      ),
    );
  }
}
