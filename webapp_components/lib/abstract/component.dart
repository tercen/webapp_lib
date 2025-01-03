import 'package:flutter/material.dart';
import 'package:webapp_components/abstract/definitions.dart';

abstract class Component with ChangeNotifier {
  Widget buildContent(BuildContext context);

  String label();
  String getId();
  String getGroupId();

  bool isActive();
  bool isFulfilled();

  ComponentType getComponentType();
}
