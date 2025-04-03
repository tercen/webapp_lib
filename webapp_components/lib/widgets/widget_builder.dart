import 'package:flutter/material.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

class CommonWidgets {
  static Widget waitingIndicator(
      {String prefixMsg = "", String suffixMsg = ""}) {
    Widget wdg = Center(
      child: Row(
        children: [
          Text(
            prefixMsg,
            style: Styles()["text"],
          ),
          prefixMsg != ""
              ? const SizedBox(
                  width: 10,
                )
              : Container(),
          const SizedBox(
              width: 25, height: 25, child: CircularProgressIndicator()),
          suffixMsg != ""
              ? const SizedBox(
                  width: 10,
                )
              : Container(),
          Text(
            suffixMsg,
            style: Styles()["text"],
          ),
        ],
      ),
    );

    return wdg;
  }

  static Widget checkbox(bool isSelected, void Function(Map<String, dynamic>, bool) callback, Map<String, dynamic> paramMap) {
    return Checkbox(
        checkColor: Styles()["black"],
        side: WidgetStateBorderSide.resolveWith((states) => BorderSide(
              color: Styles()["black"],
              width: 1.5,
            )),
        fillColor:
            WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          return Styles()["clear"];
        }),
        value: isSelected,
        onChanged: (value) {
          callback(paramMap, isSelected);
        });
  }

  // static IconButton checkBox(ModelHandler model, ModelKey key, String id, String name, bool isSelected, {Function? onClick}) {
  //   return IconButton(
  //       onPressed: () {
  //         isSelected
  //             ? model.updateModel(key, IdElement("", ""))
  //             : model.updateModel(key, IdElement(id, name));
  //         if( onClick != null ){
  //           onClick();
  //         }
  //       },
  //       icon: isSelected
  //           ? const Icon(Icons.check_box_outlined)
  //           : const Icon(Icons.check_box_outline_blank));
  // }

  static Widget createUnboundedDoubleScrollbarContainer(Widget child) {
    ScrollController ctrl = ScrollController();
    ScrollController hctrl = ScrollController();

    return Scrollbar(
        thumbVisibility: true,
        trackVisibility: true,
        controller: ctrl,
        child: Scrollbar(
            thumbVisibility: true,
            trackVisibility: true,
            controller: hctrl,
            notificationPredicate: (notification) => notification.depth >= 0,
            child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                controller: ctrl,
                child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: hctrl,
                    child: child))));
  }
}
