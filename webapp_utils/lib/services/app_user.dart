import 'dart:html' as html;

import 'package:jwt_decoder/jwt_decoder.dart';
// import 'package:jwt_decoder/jwt_decoder.dart';
// import 'package:kumo_analysis_app/left_menu.dart';
// import 'package:kumo_analysis_app/util/tercen_util.dart';

import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;

import 'package:webapp_utils/functions/logger.dart';

class AppUser {
  String _username = "";
  String _teamname = "";
  String _projectId = "";
  String serviceBase = "";
  String _projectName = "";

  bool get isDev => Uri.base.hasPort && (Uri.base.port > 10000);
  static final AppUser _singleton = AppUser._internal();

  factory AppUser() {
    return _singleton;
  }

  AppUser._internal();

  Future init() async {
    _projectId = _readProjectId();
    await setProject(_projectId);
  }

  Future setProject(String projectId, {String? teamId}) async {
    final factory = tercen.ServiceFactory();
    if (projectId != "") {
      final project = await factory.projectService.get(projectId);
      _projectId = projectId;
      _teamname = teamId ?? _getTeam();
      _projectName = project.name;

      _username = tercenSession.user.name;
    } else {
      _username = tercenSession.user.name;
      _teamname = teamId ?? _getTeam();
      _projectName = "";
    }
  }

  String _getTeam() {
    var team = _teamname;
    if (team == '') {
      team = Uri.base.queryParameters["teamId"] ?? '';
    }
    //If still empty
    if (team == '') {
      return tercenSession.user.name;
    } else {
      return team;
    }
  }

  sci.User _getUser() => tercenSession.user;

  sci.UserSession get tercenSession {
    final factory = tercen.ServiceFactory();
    var userService = factory.userService as sci.UserService;

    final session = userService.session;
    if (session == null) {
      throw "$this -- _getTercenSession -- session is null !!";
    }
    return session;
  }

  String get teamname => _teamname;
  String get username => _username;
  String get projectName => _projectName;
  String get projectId => _projectId;

  String get projectUrl {
    if (isDev) {
      return _buildDevProjectHref();
    } else {
      return _buildProjectHref();
    }
  }

  String _readProjectId() {
    if (isDev) {
      return const String.fromEnvironment("PROJECT_ID");
    } else {
      return Uri.base.queryParameters["projectId"] ?? '';
    }
  }

  String _buildDevProjectHref() {
    Logger().log(level: Logger.FINE, message: "Running in DEV mode");
    String devProjectId = const String.fromEnvironment("PROJECT_ID");

    _username = tercenSession.user.name;
    _projectId = devProjectId;

    var href = "${Uri.base.scheme}://";
    href = "$href${Uri.base.host}";
    var parentPort = html.document.referrer.split(":").last.split("/").first;
    href = "$href:$parentPort";
    serviceBase = href;
    href = "$href/${_getTeam()}";
    href = "$href/p/$_projectId";
    return href;
  }

  String _buildProjectHref() {
    var href = "${Uri.base.scheme}://";
    href = "$href${Uri.base.host}";
    if (Uri.base.hasPort) {
      href = "$href:${Uri.base.port}";
    }

    serviceBase = href;

    href = "$href/${_getTeam()}";

    if (_projectId != "") {
      href = "$href/p/$_projectId";
    }

    return href;
  }
}
