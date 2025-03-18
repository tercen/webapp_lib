import 'package:flutter/material.dart';
import 'package:webapp_components/definitions/component.dart';


abstract class Component with ChangeNotifier {
  Widget buildContent(BuildContext context);

  String label();
  String getId();
  String getGroupId();

  bool isActive();
  bool isFulfilled();

  void addUiListener( VoidCallback listener );

  dynamic getComponentValue();
  void setComponentValue(dynamic value);

  ComponentType getComponentType();
}
