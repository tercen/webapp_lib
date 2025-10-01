import 'package:flutter/material.dart';

import 'package:webapp_components/widgets/wait_indicator.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_utils/functions/logger.dart';

enum DialogState { closed, opening, open, closing }

class ProgressMessage with ChangeNotifier {
  String _msg = "";

  void update(String msg) {
    _msg = msg;
    notifyListeners();
  }

  String get message => _msg;
}

class LogObject{
  final BuildContext context;
  final ProgressMessage message = ProgressMessage();


  LogObject({required this.context});

  void dispose(){
    message.dispose();
  }
}

mixin ProgressDialog {
  // DialogState _dialogState = DialogState.closed;
  // bool _isOpen = false;
  final Map<String, LogObject> dialogMap = {};

  final ProgressMessage _message = ProgressMessage();
  String title = "";
  late BuildContext dialogContext;
  VoidCallback? _currentListener;

  void refreshDialog(Function setState) {
    setState(() {});
  }

  Future<void> openDialog(BuildContext context, {required String id}) async {
    if( dialogMap.containsKey(id) || !context.mounted) {
      // Dialog with this ID is already open or context is not mounted
      return;
    }
    dialogMap[id] = LogObject(context: context);

    showDialog(
        useRootNavigator: true,
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            // Remove any existing listener first
            // if (_currentListener != null) {
              // _message.removeListener(_currentListener!);
            // }

            // Create and store the new listener
            dialogMap[id]?.message.addListener(() {
              if (context.mounted) {
                refreshDialog(setState);
              }
            });
            // _currentListener = () {
            //   if (context.mounted) {
            //     refreshDialog(setState);
            //   }
            // };
            // _message.addListener(_currentListener!);

            return AlertDialog(
              title: Text(
                title,
                style: Styles()["textH2"],
              ),
              content: _buildMessageWidget(id: id),
            );
          });
        }).then((_) {
      // Dialog was dismissed externally
      _handleDialogDismissed(id: id);
    });

    // _dialogState = DialogState.open;
    // _isOpen = true;
  }

  void _handleDialogDismissed({required String id}) {
    dialogMap[id]?.dispose();
    dialogMap.remove(id);
    // _dialogState = DialogState.closed;
    // _isOpen = false;
    // if (_currentListener != null) {
    //   _message.removeListener(_currentListener!);
    //   _currentListener = null;
    // }
  }

  Widget _buildMessageWidget({required String id}) {
    var constraints = const BoxConstraints(
        maxHeight: 700, minHeight: 250, maxWidth: 1200, minWidth: 400);
    var waitWidget = TercenWaitIndicator();
    var messageContent = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          dialogMap[id]?.message.message ?? "Message not available",
          // _message.message,
          style: Styles()["text"],
        ),
        Padding(
          padding: const EdgeInsets.all(30),
          child: waitWidget.isInit
              ? waitWidget.indicator
              : const CircularProgressIndicator(),
        )
      ],
    );

    var wdg = Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15), color: Colors.transparent),
      constraints: constraints,
      child: SingleChildScrollView(
        child:
            Padding(padding: const EdgeInsets.all(20), child: messageContent),
      ),
    );

    return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [wdg]);
  }

  Future<void> log(String id, String message,
      {String dialogTitle = "", BuildContext? context}) async {
    if (dialogTitle.isNotEmpty) {
      title = dialogTitle;
    }

    if( !dialogMap.containsKey(id) ) {
      Logger().log(level:Logger.WARN, message: "Dialog with id $id not found. Cannot log message.");
      return;
    }
    // _message.update(message);
    dialogMap[id]?.message.update(message);

    // if (_dialogState == DialogState.closed && context != null && context.mounted) {
      // await openDialog(context);
    // }
  }

  // void logSync(String message, {String dialogTitle = ""}) {
  //   if (dialogTitle.isNotEmpty) {
  //     title = dialogTitle;
  //   }
  //   _message.update(message);
  // }

  Future<void> closeLog({required String id}) async {
    if( !dialogMap.containsKey(id) ) {
      Logger().log(level:Logger.WARN, message: "Dialog with id $id not found. Cannot close dialog.");
      return;
    }
    // if (_dialogState != DialogState.open) {
      // return;
    // }



    // _dialogState = DialogState.closing;
    // _isOpen = false;

    // Remove the listener before closing
    // if (_currentListener != null) {
    //   _message.removeListener(_currentListener!);
    //   _currentListener = null;
    // }

    // Safely close the dialog
    if (dialogMap[id]!.context.mounted) {
      // try {
      Navigator.of(dialogMap[id]!.context, rootNavigator: true).pop();
      // } catch (e) {
        // Handle case where dialog was already closed externally
      // }
    }

    dialogMap[id]?.dispose();
    dialogMap.remove(id);

    // _dialogState = DialogState.closed;
  }



  // void closeLogSync() {
  //   if (_dialogState != DialogState.open) {
  //     return;
  //   }

  //   _dialogState = DialogState.closing;
  //   _isOpen = false;

  //   // Remove the listener before closing
  //   if (_currentListener != null) {
  //     _message.removeListener(_currentListener!);
  //     _currentListener = null;
  //   }

  //   // Safely close the dialog
  //   if (dialogContext.mounted) {
  //     try {
  //       Navigator.of(dialogContext, rootNavigator: true).pop();
  //     } catch (e) {
  //       // Handle case where dialog was already closed externally
  //     }
  //   }

  //   _dialogState = DialogState.closed;
  // }

  // void disposeDialog() {
  //   try {
  //     // Clean up listeners
  //     if (_currentListener != null) {
  //       _message.removeListener(_currentListener!);
  //       _currentListener = null;
  //     }

  //     // Reset state
  //     _dialogState = DialogState.closed;
  //     _isOpen = false;
  //   } catch (e) {
  //     // Ignore errors during cleanup
  //   }
  // }
}
