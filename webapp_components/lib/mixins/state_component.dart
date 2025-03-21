import 'package:flutter/material.dart';

enum State {idle, busy}
mixin StateComponent on ChangeNotifier{
  State currentState = State.idle;

  void setComponentState(State state){
    currentState = state;
    notifyListeners();
  }

  bool get isIdle  => currentState == State.idle;
  bool get isBusy  => currentState == State.busy;

  void busy(){
    setComponentState(State.busy);
  }

  void idle(){
    setComponentState(State.idle);
  }
}