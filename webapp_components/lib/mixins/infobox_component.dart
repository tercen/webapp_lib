import 'package:flutter/material.dart';

import 'package:webapp_components/extra/infobox.dart';

mixin class ComponentInfoBox {
  late InfoBoxBuilder? infoBoxBuilder;

  Widget infoBoxIcon(dynamic value, BuildContext context, {String? title}) {
    return IconButton(
        onPressed: () async {
          showDialog(
              context: context,
              builder: (dialogContext) {
                return StatefulBuilder(builder: (stfCtx, stfSetState) {
                  infoBoxBuilder!.notifier.addListener(() {
                    stfSetState(() {});
                  });
                  return infoBoxBuilder!.build(context, value, titleOverride: title);
                });
              });
        },
        icon: const Icon(Icons.info_outline));
  }

  Widget buildInfoBoxIcon(dynamic value, BuildContext context,
      {String? title, double iconCellWidth = 50}) {
    Widget infoBoxWidget = Container();
    double infoBoxWidth = 5;
    if (infoBoxBuilder != null) {
      infoBoxWidget = infoBoxIcon(value, context, title: title);
      infoBoxWidth =iconCellWidth ;
    }
    return SizedBox(
      width: infoBoxWidth,
      child: infoBoxWidget,
    );
  }
}
