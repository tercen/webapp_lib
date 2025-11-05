// import 'package:jwt_decoder/jwt_decoder.dart';
// import 'package:sci_http_client/http_client.dart' as http_api;
// import 'package:sci_http_client/http_browser_client.dart' as io_http;
// import 'package:sci_tercen_client/sci_client.dart' as sci;
// import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
// import 'package:sci_http_client/http_auth_client.dart' as auth_http;

// class AppSessionWeb {
//   bool get isDev =>
//       const String.fromEnvironment("DEV", defaultValue: "false") == "true";
//   String get devServiceApi => const String.fromEnvironment("TERCEN_URL",
//       defaultValue: 'http://127.0.0.1:5400');

//   AppSessionWeb._();

//   static final AppSessionWeb _instance = AppSessionWeb._();

//   factory AppSessionWeb() => _instance;

//   sci.UserSession _currentSession = sci.UserSession();
//   sci.UserSession get session => _currentSession.user.id.isNotEmpty
//       ? _currentSession
//       : throw sci.ServiceError(500, "session.not.inialized",
//           "Current session has not been initialized");
//   bool get isInitialized => _currentSession.user.id.isNotEmpty;

//   Future<void> initFactory(String token) async {
//     if (token.isEmpty) {
//       throw "A token is required";
//     }

//     var authClient =
//         auth_http.HttpAuthClient(token, io_http.HttpBrowserClient());

//     var factory = sci.ServiceFactory();

//     if (isDev) {
//       await factory.initializeWith(Uri.parse(devServiceApi), authClient);
//     } else {
//       var uriBase = Uri.base;
//       await factory.initializeWith(
//           Uri(scheme: uriBase.scheme, host: uriBase.host, port: uriBase.port),
//           authClient);
//     }

//     http_api.HttpClient.setCurrent(authClient);

//     tercen.ServiceFactory.CURRENT = factory;
//   }

//   Future<sci.UserSession> createUserSession() async {
//     var tercenToken = _getTercenToken();

//     if (tercenToken.isEmpty) {
//       throw 'Tercen token not found -- String.fromEnvironment("TERCEN_TOKEN")';
//     }

//     var decodedToken = JwtDecoder.decode(tercenToken);
//     return sci.UserSession()
//       ..user = (sci.User()
//         ..id = decodedToken['data']['u']
//         ..name = decodedToken['data']['u'])
//       ..token = (sci.Token()..token = tercenToken);
//   }

//   Future<void> initSession({bool force = false}) async {
//     if (!isInitialized || force) {
//       _currentSession = await createUserSession();
//       await initFactory(_currentSession.token.token);
//       await (tercen.ServiceFactory().userService as sci.UserService)
//           .setSession(_currentSession);
//     }
//   }

//   String _getTercenToken() {
//     var tercenToken = const String.fromEnvironment("TERCEN_TOKEN");
//     if (tercenToken.isEmpty) {
//       tercenToken = Uri.base.queryParameters["token"] ?? '';
//     }
//     return tercenToken;
//   }
// }
