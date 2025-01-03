import 'package:flutter/material.dart';
import 'package:webapp_components/commons/id_element.dart';

import 'package:webapp_components/extra/infobox.dart';

mixin class ComponentInfoBox {
  late InfoBoxBuilder? infoBoxBuilder;

  Widget infoBoxIcon(String id, String name, BuildContext context) {
    return IconButton(
        onPressed: () async {
          showDialog(
              context: context,
              builder: (dialogContext) {
                return StatefulBuilder(builder: (stfCtx, stfSetState) {
                  infoBoxBuilder!.notifier.addListener(() {
                    stfSetState(() {});
                  });
                  return infoBoxBuilder!.build(context, IdElement(id, name));
                });
              });
        },
        icon: const Icon(Icons.info_outline));
  }

  Widget buildInfoBoxIcon(String id, String name, BuildContext context) {
    Widget infoBoxWidget = Container();
    double infoBoxWidth = 5;
    if (infoBoxBuilder != null) {
      infoBoxWidget = infoBoxIcon(id, name, context);
      infoBoxWidth = 50;
    }
    return SizedBox(
      width: infoBoxWidth,
      child: infoBoxWidget,
    );
  }
}
