
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_string/json_string.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webapp_ui_commons/globals.dart' as globals;
import 'package:webapp_ui_commons/styles/styles.dart';

class ErrorScreen extends StatelessWidget {
  static const String missingTemplate = "ERR_MISSING_TEMPLATE";
  final FlutterErrorDetails? errorDetails;

  const ErrorScreen({
    super.key,
    this.errorDetails,
  }) : assert(errorDetails != null);

  @override
  Widget build(BuildContext context) {
    return getErrorMessage(errorDetails!.exceptionAsString());
  }

  Widget getErrorMessage(String errorString) {
    switch (errorString.replaceAll("Exception: ", "")) {
      case ErrorScreen.missingTemplate:
        return _buildTemplateErrorScreen(errorString);
      default:
        return _buildDefaultErrorScreen(errorString);
    }
  }

  Widget _buildErrorDialog(String errorString) {
    return AlertDialog(
      icon: const Icon(
        Icons.error,
        size: 70,
        color: Colors.red,
      ),
      backgroundColor: const Color.fromARGB(255, 247, 194, 194),
      title:  SelectableText(
        "An Unexpected Error Occurred",
        style: Styles()["textH2"],
      ),
      content: SingleChildScrollView(
        child: SelectableText(
          errorString,
          style: Styles()["text"],
        ),
      ),
      actions: [
        TextButton(
            style: const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll<Color>(
                  Color.fromARGB(255, 20, 20, 20)),
            ),
            onPressed: () {
              Uri tercenLink = Uri(
                  scheme: Uri.base.scheme,
                  host: Uri.base.host,
                  path:  "${globals.States.projectUser}/p/${globals.States.loadedProject}");
              if (Uri.base.hasPort) {
                tercenLink = Uri(
                    scheme: Uri.base.scheme,
                    host: '127.0.0.1',
                    port: 5400,
                    path:
                        "${globals.States.projectUser}/p/${globals.States.loadedProject}");
              }

              launchUrl(tercenLink, webOnlyWindowName: "_self");
            },
            child:  Center(
                child: Text(
              "Exit",
              style: Styles()["textButton"],
            )))
      ],
    );
  }

  Widget _buildDefaultErrorScreen(String errorString) {
    return _buildErrorDialog(errorString);
  }

  Future<String> _buildWorkflowErrorMessage() async {
    String settingsStr = await rootBundle.loadString("assets/repos.json");
    String msg = "";
    try {
      final jsonString = JsonString(settingsStr);
      final repoInfoMap = jsonString.decodedValueAsMap;

      msg = "${msg}Required Templates are not Installed";
      msg =
          "$msg\nPlease ensure that the following templates are installed:\n\n";

      for (int i = 0; i < repoInfoMap["repos"].length; i++) {
        Map<String, dynamic> jsonEntry = repoInfoMap["repos"][i];
        msg = "$msg\n- ${jsonEntry['url']} - version ${jsonEntry['version']}";
      }
    } on Exception catch (e) {
      throw ('Invalid assets/repos.json: $e');
    }

    msg = "$msg\n\n";

    return msg;
  }

  Widget _buildTemplateErrorScreen(String errorString) {
    return FutureBuilder(
        future: _buildWorkflowErrorMessage(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return _buildErrorDialog(snapshot.data!);
          } else {
            return const Row(
              children: [
                CircularProgressIndicator(),
                Text("Retrieving error information")
              ],
            );
          }
        });
  }
}
