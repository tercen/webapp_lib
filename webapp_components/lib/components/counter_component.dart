import 'dart:async';
import 'package:flutter/material.dart';

import 'package:webapp_components/abstract/component.dart';
import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_utils/functions/string_utils.dart';

class CounterComponent extends Component with ComponentBase {
  Timer? _countdownTimer;
  int _secondsRemaining = 3;
  final VoidCallback? onCountdownComplete;
  
  CounterComponent({this.onCountdownComplete}) {
    super.id = StringUtils.getRandomString(4);
    super.groupId = LAYOUT_GROUP;
    super.componentLabel = "";
    _startCountdown();
  }

  void _startCountdown() {
    _secondsRemaining = 3;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        _secondsRemaining = 3;
        onCountdownComplete?.call();
      }
    });
  }

  @override
  Widget buildContent(BuildContext context) {
    return Text(
      "Next reload in: ${_secondsRemaining}s",
      style: Styles()["textH2"],
    );
  }

  @override
  ComponentType getComponentType() {
    return ComponentType.simpleNoLabel;
  }

  

  @override
  void reset(){
    _countdownTimer?.cancel();
    _secondsRemaining = 3;
  }

  void restartCountdown() {
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  } 

  // @override
  // bool isActive() {
  //   return true;
  // }

  @override
  bool isFulfilled() {
    return true;
  }

  @override
  String label() {
    return "";
  }
  
  @override
  getComponentValue() {
    return _secondsRemaining;
  }
  
  @override
  void setComponentValue(value) {
    if (value is int) {
      _secondsRemaining = value;
      notifyListeners();
    }
  }

  

}