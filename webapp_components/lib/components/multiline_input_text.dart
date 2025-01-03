import 'package:flutter/material.dart';

import 'package:webapp_components/components/input_text_component.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

class MultiLineInputTextComponent extends InputTextComponent {
  MultiLineInputTextComponent(super.id, super.groupId, super.componentLabel);

  @override
  Widget buildContent(BuildContext context) {
    return SizedBox(
        height: 125,
        child: TextField(
            expands: true,
            minLines: null,
            maxLines: null,
            controller: controller,
            onTapOutside: (event) {
              for (var func in onFocusLostFunctions) {
                func();
              }
            },
            style: Styles.text,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: Styles.borderRounding),
            )));
  }
}
