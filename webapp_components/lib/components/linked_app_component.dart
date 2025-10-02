import 'dart:async';
import 'dart:html';

import 'dart:ui_web';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:webapp_components/abstract/component.dart';

import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_components/mixins/infobox_component.dart';

import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:webapp_ui_commons/styles/styles.dart';

import 'package:webapp_utils/services/app_user.dart';

// Implementations Notes
// Uses a static shared iframe to embed external apps in modal dialogs,
// avoiding PlatformViewRegistry conflicts by reusing a single iframe instance across all component instances 
//and forcing reloads via src manipulation.
class LinkedAppComponent
    with ChangeNotifier, ComponentBase, ComponentInfoBox
    implements Component {
  String lastSave = "";

  final Future Function(LinkedAppComponent) onOpen;

  String baseUri;
  String? workflowId;
  String? stepId;
  String channel = const Uuid().v4();
  String? title;

  final String operatorId;
  AssetImage? appIcon;
  Future Function({required bool isCancel}) onClose;

  StreamSubscription? sub;
  bool enabled = true;

  BuildContext? dialogContext;
  static final IFrameElement _iframe = IFrameElement();
  static bool _iframeInitialized = false;

  LinkedAppComponent(id, groupId, componentLabel, this.baseUri, this.onOpen,
      this.operatorId, this.onClose,
      {infoBoxBuilder, this.appIcon, this.title}) {
    super.id = id;
    super.groupId = groupId;
    super.componentLabel = componentLabel;
    super.infoBoxBuilder = infoBoxBuilder;
  }

  @override
  void dispose() {
    super.dispose();
    sub?.cancel();
    _iframe.remove();
  }

  Future<void> appListener(
      Stream<sci.Event> stream, BuildContext context) async {
    sub = stream
        .where((evt) => evt is sci.GenericEvent)
        .cast<sci.GenericEvent>()
        .listen((evt) async {
      if (evt.type == "quit") {
        print("Received quit event: $dialogContext");
        if (dialogContext != null) {
          onClose(isCancel: false);
          Navigator.of(dialogContext!).pop();
          

          dialogContext = null;
          notifyListeners();
        }
      }
    });
  }

  @override
  void reset() {
    //No reset needed [?]
  }

  @override
  Widget buildContent(BuildContext context) {
    Color? color = enabled ? null : Styles()["gray"];
    return IconButton(
        style: ButtonStyle(
            shape: WidgetStateProperty.all(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)))),
        onPressed: () async {
          if (!enabled) {
            return;
          }
          sub?.cancel();
          await onOpen(this);
          if (workflowId == null || stepId == null) {
            throw sci.ServiceError(
                500,
                "LinkedAppComponent $id missing workflow and step",
                "'workflowId' and 'stepId' must be defined");
          }

          final cacheBreaker = "t=${DateTime.now().millisecondsSinceEpoch}";
          var src = AppUser().isDev
              ? '${AppUser().devServiceUri}/_w3op/$operatorId?mode=auto-stats&workflowId=$workflowId&stepId=$stepId&channelId=$channel&$cacheBreaker&token=${AppUser().devToken}'
              : '$baseUri/_w3op/$operatorId?mode=auto-stats&workflowId=$workflowId&stepId=$stepId&channelId=$channel&$cacheBreaker}';

          if (stepId == "") {
            src = "about:blank;";
          }
          // CLean up, build commit
          if (LinkedAppComponent._iframeInitialized == false) {
            _iframe.style.height =
                "${MediaQuery.of(context).size.height * 0.95}";
            _iframe.style.width = "${MediaQuery.of(context).size.width * 0.95}";
            _iframe.src = src;

            _iframe.style.border = 'none';
            LinkedAppComponent._iframeInitialized = true;

            PlatformViewRegistry().registerViewFactory(
              'iframeElement',
              (int viewId) => _iframe,
            );
          } else {
            // Clear up iframe to force reload
            _iframe.src = '';
            Future.microtask(() {
              _iframe.src = src;
            });
          }

          var iframeWidget = HtmlElementView(
            viewType: 'iframeElement',
            key: UniqueKey(),
          );

          final titleAdjust = title != null ? 0.9 : 0.92;
          showDialog(
              context: context,
              useRootNavigator: false,
              builder: (context) {
                dialogContext = context;
                return AlertDialog(
                    content: Column(
                  children: [
                    title != null
                        ? Text(
                            title!,
                            style: Styles()["textH2"],
                          )
                        : Container(),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * titleAdjust,
                      width: MediaQuery.of(context).size.width,
                      child: iframeWidget,
                    )
                  ],
                ));
              });

          var factory = tercen.ServiceFactory();
          var stream = factory.eventService.channel(channel);
          appListener(stream, context);
          notifyListeners();
        },
        icon: appIcon == null
            ? Icon(
                Icons.apps,
                size: 50,
                color: color,
              )
            : ImageIcon(
                appIcon,
                size: 40,
                color: color,
              ));
  }

  @override
  bool isFulfilled() {
    return true;
  }

  @override
  ComponentType getComponentType() {
    return ComponentType.simple;
  }

  @override
  getComponentValue() {
    return [workflowId, stepId];
  }

  @override
  void setComponentValue(value) {}
}
