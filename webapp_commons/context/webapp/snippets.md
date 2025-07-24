### Relevant code snippets for developping apps

##### Login and token reading

These snippets show a way to read the authentication token to handle login and security. 

'''dart
  import 'package:sci_tercen_client/sci_client.dart' as sci;
  import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
  Future<void> init() async {
    if (!isInitialized) {
      await TercenWaitIndicator().init();

      http_api.HttpClient.setCurrent(io_http.HttpBrowserClient());
      
      late sci.UserSession session;


      if (isDev) {
        var tok = Uri.base.queryParameters["token"] ?? '';
        var decodedToken = JwtDecoder.decode(tok);
        session = sci.UserSession()
      ..user = (sci.User()..id = decodedToken['data']['u'])
      ..token = (sci.Token()..token = tok);

      } else {
        var auth = json.decode(html.window.localStorage['authorization'] ?? "");

        session = sci.UserSession.json(auth);

      }

      navMenu.addLink("Exit App", AppUser().projectUrl);

      await initFactory(session.token.token);
      var factory = tercen.ServiceFactory();
      var userService = factory.userService as sci.UserService;

      await userService.setSession(session);

    }
  }



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
'''