import 'package:flutter/material.dart';


class DoubleScrollBar {


  static Widget create(Widget child) {
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