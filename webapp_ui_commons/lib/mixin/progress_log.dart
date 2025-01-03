import 'dart:math';

import 'package:flutter/material.dart';
// import 'package:kumo_analysis_app/components/commons/wait_indicator.dart';
// import 'package:kumo_analysis_app/util/ui/styles.dart';
// import 'package:kumo_analysis_app/util/ui_utils.dart';
import 'package:sci_base/value.dart';
import 'package:webapp_components/widgets/wait_indicator.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

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

  final ProgressMessage _message = ProgressMessage();
  // final Value<String> _message = ValueHolder("");
  String title = "";
  late BuildContext dialogContext;

  void refresh(Function setState){
    setState(() {});
  }

  void openDialog(BuildContext context) {
    dialogContext = context;
    
    
    if( !_isOpen ){
    showDialog(

        useRootNavigator: true,
        barrierDismissible: false,
        context: dialogContext,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            _message.addListener(() => refresh(setState));

            // _message.onChange.listen((onData) {
            //   if (context.mounted) {
            //     setState(() {});
            //   }
            // });
            return AlertDialog(
              title: Text(title, style: Styles.textH2,),
              content:   _buildMessageWidget(),
            );
          });
        });
      }

        _isOpen = true;
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
          style: Styles.text,
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

  void log(String message,{String dialogTitle= ""}) {
    title = dialogTitle;
    _message.update(message);
    // _message.up = message;
    
  }

  void closeLog() {
    if( _isOpen ){
      _isOpen = false;
      Navigator.of(dialogContext, rootNavigator: true).pop();
    }
    
  }
}
