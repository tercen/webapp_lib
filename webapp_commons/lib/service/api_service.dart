import 'dart:convert';

import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sci_http_client/http_client.dart' as http_api;
import 'package:sci_http_client/http_browser_client.dart' as io_http;
import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'dart:html' as html;
import 'package:sci_http_client/http_auth_client.dart' as auth_http;
import 'package:webapp_commons/model/id_label.dart';
import 'package:webapp_commons/utils/logger.dart';
import 'package:webapp_commons/service/project_service.dart';

class ApiService {
  static final ApiService _singleton = ApiService._internal();

  factory ApiService() {
    return _singleton;
  }

  ApiService._internal();

  late sci.UserSession session;
  bool _sessionInitialized = false;

  String get user {
    if (!_sessionInitialized) {
      print('Warning: Accessing user before session is initialized');
      return 'Session not initialized';
    }
    return session.user.id;
  }
  
  String get team {
    if (!_sessionInitialized) {
      print('Warning: Accessing team before session is initialized');
      return 'Session not initialized';
    }
    return ProjectService().projectOwner.isEmpty ? session.user.teamAcl.owner : ProjectService().projectOwner;
  }

  bool get isDev => Uri.base.hasPort && (Uri.base.port > 10000);

  Future<void> _initTercenFactory(String token) async {
    if (token.isEmpty) {
      throw sci.ServiceError(403, "Unauthorized",
          "A Token is required to initialize the service.");
    }

    try {
      var authClient =
          auth_http.HttpAuthClient(token, io_http.HttpBrowserClient());

      var factory = sci.ServiceFactory();

      if (isDev) {
        Logger()
            .log(level: Logger.INFO, message: "Running in development mode");

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

      Logger().log(
          level: Logger.FINE, message: "Tercen service factory initialized");
    } catch (e) {
      throw sci.ServiceError(500, "Failed: _initTercenFactory", e.toString());
    }
  }

  Future<void> connect() async {
    """
      Connects to the Tercen service and initializes the user session.

      Must be called before any other service calls during App initialization.
    """;
    http_api.HttpClient.setCurrent(io_http.HttpBrowserClient());

    try {
      if (isDev) {
        print('Running in development mode'); // Debug output
        var tok = Uri.base.queryParameters["token"] ?? '';
        print('Token from URL: ${tok.isNotEmpty ? "present" : "missing"}'); // Debug output
        
        if (tok.isEmpty) {
          throw sci.ServiceError(401, "Token Missing", 
              "Development mode requires a token parameter in the URL");
        }
        
        var decodedToken = JwtDecoder.decode(tok);
        session = sci.UserSession()
          ..user = (sci.User()..id = decodedToken['data']['u'] ..name = decodedToken['data']['u'])
          ..token = (sci.Token()..token = tok);
      } else {
        print('Running in production mode'); // Debug output
        var authData = html.window.localStorage['authorization'];
        print('Auth data from localStorage: ${authData != null ? "present" : "missing"}'); // Debug output
        
        if (authData == null || authData.isEmpty) {
          throw sci.ServiceError(401, "Authorization Missing", 
              "No authorization data found in localStorage. Please ensure you're accessing this app through Tercen.");
        }
        
        var auth = json.decode(authData);
        session = sci.UserSession.json(auth);
      }
      
      print('Session initialized successfully'); // Debug output
      _sessionInitialized = true;
      
      // navMenu.addLink("Exit App", AppUser().projectUrl);

      await _initTercenFactory(session.token.token);
      var factory = tercen.ServiceFactory();
      var userService = factory.userService as sci.UserService;

      await userService.setSession(session);
      
      print('Tercen connection completed successfully'); // Debug output
    } catch (e) {
      print('Error in connect(): $e'); // Debug output
      rethrow; // Re-throw the error to be handled by the caller
    }
  }

  Future<Map<String, String>> getPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return {
        'appName': packageInfo.appName.isNotEmpty
            ? packageInfo.appName
            : 'webapp_ai_template',
        'version':
            packageInfo.version.isNotEmpty ? packageInfo.version : '1.0.0',
      };
    } catch (e) {
      return {
        'appName': 'No App Information'
      };
    }
  }


  Future<List<IdLabel>> fetchTeamsForCurrentUser() async {
    if (!_sessionInitialized) {
      throw sci.ServiceError(500, "Session not initialized", "Session must be initialized before fetching teams.");
    }
    
    final currentUser = session.user;
    if( currentUser.name.isEmpty ){
      throw sci.ServiceError(500, "User not defined", "No user information in current session.");
    }

    final teams = <IdLabel>[];
    final userTeam = sci.Team()..name = currentUser.id;
    teams.add(IdLabel(id: userTeam.name, label: userTeam.name, kind: "team"));
      
    // Get teams from user's teamAcl

    for (final ace in currentUser.teamAcl.aces) {
      try {
        if (ace.principals.isNotEmpty) {
          final teamName = ace.principals[0].principalId;
          if ( teamName.isNotEmpty ) {
            teams.add(IdLabel(id: teamName, label: teamName, kind: "team"));
          }
        }
      } catch (e) {
        // Silently continue on error
      }
    }

    return teams;
  }
}
