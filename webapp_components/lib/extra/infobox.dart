import 'package:flutter/material.dart';
import 'package:webapp_components/widgets/double_scrollbar_widget.dart';
import 'package:webapp_components/widgets/wait_indicator.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

class InfoBoxBuilder with ChangeNotifier {
  final Function? futureCallback;
  final Function builderCallback;
  final ValueNotifier<int> notifier = ValueNotifier(0);

  InfoBoxBuilder(this.builderCallback, {this.futureCallback});

  Widget _buildDefault(BuildContext context, dynamic value,
      {String title = ""}) {
    return DoubleScrollBar.create(builderCallback(value, notifier));
  }

  Widget _buildWithFuture(BuildContext context, dynamic value,
      {String title = ""}) {
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

    var dialog = AlertDialog(
      title: Text(
        title,
        style: Styles()["textH1"],
      ),
      content: Container(
        constraints: const BoxConstraints(maxHeight: 700, maxWidth: 1200),
        child: contentWdg,
      ),
    );

    return dialog;
  }

  Widget build(BuildContext context, dynamic value, {String title = ""}) {
    if (futureCallback != null) {
      return _buildWithFuture(context, value, title: title);
    } else {
      return _buildDefault(context, value, title: title);
    }
  }
}
