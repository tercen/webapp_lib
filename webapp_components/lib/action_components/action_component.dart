import 'package:flutter/material.dart';




abstract class ActionComponent {

  Widget buildContent(BuildContext context);

  bool isEnabled();
  String label();
  String getId();
  
  
}