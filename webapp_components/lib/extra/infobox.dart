import 'package:flutter/material.dart';
import 'package:webapp_components/widgets/double_scrollbar_widget.dart';
import 'package:webapp_components/widgets/wait_indicator.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

class InfoBoxBuilder with ChangeNotifier {
  final Function? futureCallback;
  final Function builderCallback;
  final String title;
  final ValueNotifier<int> notifier = ValueNotifier(0);

  InfoBoxBuilder( this.title, this.builderCallback, {this.futureCallback});

  Widget createDialog( Widget contentWdg,{String? titleOverride} ){
    return AlertDialog(
      title: Text(
        titleOverride ?? title,
        style: Styles()["textH1"],
      ),
      content: Container(
        constraints: const BoxConstraints(maxHeight: 700, maxWidth: 1200),
        child: contentWdg,
      ),
    );
  }

  Widget _buildDefault(BuildContext context, dynamic value, {String? titleOverride}) {
    var contentWdg =  DoubleScrollBar.create(builderCallback(value, notifier));

    var dialog = createDialog(contentWdg, titleOverride: titleOverride);

    return dialog;
  }

  Widget _buildWithFuture(BuildContext context, dynamic value, {String? titleOverride}) {
    var contentWdg = FutureBuilder(
        future: futureCallback!(value),
        builder: (context, snapshot) {
          if (snapshot.data != null && snapshot.hasData) {
            return DoubleScrollBar.create(
                builderCallback(snapshot.data, notifier));
          } else if (snapshot.hasError) {
            throw Exception(snapshot.error);
          } else {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: TercenWaitIndicator().indicator,
                ),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Loading",
                    style: Styles()["text"],
                  ),
                )
              ],
            );
          }
        });

    var dialog = createDialog(contentWdg, titleOverride: titleOverride);

    return dialog;
  }

  Widget build(BuildContext context, dynamic value, {String? titleOverride}) {
    if (futureCallback != null) {
      return _buildWithFuture(context, value, titleOverride: titleOverride);
    } else {
      return _buildDefault(context, value, titleOverride: titleOverride);
    }
  }
}
