import 'package:flutter/material.dart';
import 'dart:async';

import 'package:webapp_components/widgets/wait_indicator.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

enum DialogState { closed, opening, open, closing }

class ProgressMessage with ChangeNotifier {
  String _msg = "";

  void update(String msg){
    _msg = msg;
    notifyListeners();
  }

  String get message => _msg;
}

mixin ProgressDialog {
  bool _isOpen = false;
  DialogState _dialogState = DialogState.closed;
  Completer<void> _operationMutex = Completer<void>()..complete();
  String? _queuedMessage;
  String? _queuedTitle;

  final ProgressMessage _message = ProgressMessage();
  // final Value<String> _message = ValueHolder("");
  String title = "";
  late BuildContext dialogContext;
  VoidCallback? _currentListener;

  void refreshDialog(Function setState){
    setState(() {});
  }

  Future<void> openDialog(BuildContext context) async {
    // Ignore if dialog is already open or opening
    if (_dialogState == DialogState.open || _dialogState == DialogState.opening) {
      return;
    }
    
    // Wait for any ongoing operation to complete
    await _operationMutex.future;
    
    // Double-check state after waiting
    if (_dialogState == DialogState.open || _dialogState == DialogState.opening) {
      return;
    }
    
    // Create new operation mutex
    final newMutex = Completer<void>();
    _operationMutex = newMutex;
    
    try {
      _dialogState = DialogState.opening;
      dialogContext = context;
      
      if (!context.mounted) {
        return;
      }
      
      showDialog(
        useRootNavigator: true,
        barrierDismissible: false,
        context: dialogContext,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            // Remove any existing listener first
            if (_currentListener != null) {
              _message.removeListener(_currentListener!);
            }
            
            // Create and store the new listener
            _currentListener = () {
              if (context.mounted) {
                refreshDialog(setState);
              }
            };
            _message.addListener(_currentListener!);

            return AlertDialog(
              title: Text(title, style: Styles()["textH2"],),
              content:   _buildMessageWidget(),
            );
          });
        }).then((_) {
          // Dialog was dismissed externally
          _handleDialogDismissed();
        });
      
      _dialogState = DialogState.open;
      _isOpen = true;
      
      // Process any queued message
      if (_queuedMessage != null) {
        _message.update(_queuedMessage!);
        if (_queuedTitle != null) {
          title = _queuedTitle!;
        }
        _queuedMessage = null;
        _queuedTitle = null;
      }
      
    } catch (e) {
      _dialogState = DialogState.closed;
      _isOpen = false;
    } finally {
      newMutex.complete();
    }
  }
  
  void _handleDialogDismissed() {
    _dialogState = DialogState.closed;
    _isOpen = false;
    if (_currentListener != null) {
      _message.removeListener(_currentListener!);
      _currentListener = null;
    }
  }

  Widget _buildMessageWidget() {
    var constraints = const BoxConstraints(
        maxHeight: 700, minHeight: 250, maxWidth: 1200, minWidth: 400);
    var waitWidget = TercenWaitIndicator();
    var messageContent = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          _message.message,
          style: Styles()["text"],
        ),
        Padding(
          padding: const EdgeInsets.all(30),
          child: waitWidget.isInit ? waitWidget.indicator : const CircularProgressIndicator(),
        )
      ],
    );

    var wdg = Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.transparent),
      constraints: constraints,
      child: SingleChildScrollView(
        child: Padding( padding: const EdgeInsets.all(20), child:messageContent),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [wdg]);
  }

  Future<void> log(String message, {String dialogTitle = "", BuildContext? context}) async {
    if (_dialogState == DialogState.open) {
      // Dialog is open - update immediately
      if (dialogTitle.isNotEmpty) {
        title = dialogTitle;
      }
      _message.update(message);
    } else if (_dialogState == DialogState.opening || _dialogState == DialogState.closing) {
      // Dialog is transitioning - queue the message
      _queuedMessage = message;
      if (dialogTitle.isNotEmpty) {
        _queuedTitle = dialogTitle;
      }
    } else {
      // Dialog is closed - we need to open it
      if (dialogTitle.isNotEmpty) {
        title = dialogTitle;
      }
      _message.update(message);
      
      // Try to open dialog if context provided
      if (context != null && context.mounted) {
        await openDialog(context);
      }
    }
  }
  
  // Legacy synchronous log method for backward compatibility
  void logSync(String message, {String dialogTitle = ""}) {
    if (_dialogState == DialogState.open) {
      if (dialogTitle.isNotEmpty) {
        title = dialogTitle;
      }
      _message.update(message);
    } else {
      // Queue the message for when dialog opens
      _queuedMessage = message;
      if (dialogTitle.isNotEmpty) {
        _queuedTitle = dialogTitle;
      }
    }
  }

  Future<void> closeLog() async {
    if (_dialogState != DialogState.open) {
      return;
    }
    
    // Wait for any ongoing operation to complete
    await _operationMutex.future;
    
    // Double-check state after waiting
    if (_dialogState != DialogState.open) {
      return;
    }
    
    // Create new operation mutex
    final newMutex = Completer<void>();
    _operationMutex = newMutex;
    
    try {
      _dialogState = DialogState.closing;
      _isOpen = false;
      
      // Remove the listener before closing
      if (_currentListener != null) {
        _message.removeListener(_currentListener!);
        _currentListener = null;
      }
      
      // Clear any queued operations
      _queuedMessage = null;
      _queuedTitle = null;
      
      // Safely close the dialog
      if (dialogContext.mounted) {
        try {
          Navigator.of(dialogContext, rootNavigator: true).pop();
        } catch (e) {
          // Handle case where dialog was already closed externally
        }
      }
      
      _dialogState = DialogState.closed;
      
    } catch (e) {
      // Ensure state is reset even if closing fails
      _dialogState = DialogState.closed;
      _isOpen = false;
    } finally {
      newMutex.complete();
    }
  }
  
  // Legacy synchronous close method for backward compatibility
  void closeLogSync() {
    if (_dialogState == DialogState.open) {
      _dialogState = DialogState.closing;
      _isOpen = false;
      
      if (_currentListener != null) {
        _message.removeListener(_currentListener!);
        _currentListener = null;
      }
      
      _queuedMessage = null;
      _queuedTitle = null;
      
      if (dialogContext.mounted) {
        try {
          Navigator.of(dialogContext, rootNavigator: true).pop();
        } catch (e) {
          // Handle case where dialog was already closed externally
        }
      }
      
      _dialogState = DialogState.closed;
    }
  }
}
