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
import 'package:webapp_ui_commons/menu/menu_item.dart';
import 'package:webapp_ui_commons/menu/navigation_menu.dart';

import 'package:sci_http_client/http_auth_client.dart' as auth_http;
import 'package:webapp_ui_commons/styles/styles.dart';

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

  Future setProject(String projectId) async {
    final factory = tercen.ServiceFactory();
    final project = await factory.projectService.get(projectId);

    _teamname = project.acl.owner;
    _username = _teamname;
    _projectName = project.name;
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

  String _readProjectId(){
    if(isDev){
      return const String.fromEnvironment("PROJECT_ID")
    }else{
      return Uri.base.queryParameters["projectId"] ?? '';
    }
  }

  String _buildDevProjectHref() {
    Logger().log(level: Logger.FINE, message: "Running in DEV mode");
    String devProjectId = const String.fromEnvironment("PROJECT_ID");

    var tok = Uri.base.queryParameters["token"] ?? '';
    Map<String, dynamic> decodedToken = JwtDecoder.decode(tok);
    _username = decodedToken['data']['u'];
    _projectId = devProjectId;

    var href = "${Uri.base.scheme}://";
    href = "$href${Uri.base.host}";
    var parentPort = html.document.referrer.split(":").last.split("/").first;
    href = "$href:$parentPort";
    serviceBase = href;
    href = "$href/$username";
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

    href = "$href/$_username";
    if (_projectId != "") {
      href = "$href/p/$_projectId";
    }

    return href;
  }


}
