import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webapp_components/abstract/component.dart';
import 'package:webapp_components/abstract/serializable_component.dart';
import 'package:webapp_components/components/label_component.dart';
import 'package:webapp_components/definitions/component.dart';
// import 'package:webapp_components/abstract/multi_value_component.dart';
// import 'package:webapp_components/abstract/single_value_component.dart';
import 'package:webapp_components/action_components/action_component.dart';
import 'package:webapp_components/components/horizontal_bar.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_components/mixins/input_validator.dart';

import 'package:webapp_model/webapp_data_base.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

class Action {
  final String actionName;
  final Function actionCallback;
  final Function? enabledCallback;

  Action(this.actionName, this.actionCallback, this.enabledCallback);

  Widget build() {
    bool enabled = enabledCallback != null ? enabledCallback!() : true;
    return ElevatedButton(
      style: enabled ? Styles()["buttonEnabled"] : Styles()["buttonDisabled"],
      onPressed: () {
        if (enabled) {
          actionCallback();
        }
      },
      child: Text(
        actionName,
        style: Styles()["textButton"],
      ),
    );
  }
}

enum ComponentBlockType { simple, expanded, collapsed }

class ComponentEntry {
  final Component component;
  final String componentName;
  final ComponentType componentType;

  ComponentEntry(this.component, this.componentName, this.componentType);
}

mixin ScreenBase {
  final List<ActionComponent> _actionComponents = [];

  final List<String> blockOrder = [];
  final List<ComponentBlockType> blockTypes = [];
  final Map<String, List<ComponentEntry>> componentBlocks = {};
  late final WebAppDataBase modelLayer;
  Timer? updateTimer;
  bool isMenuCollapsed = false;
  void addActionComponent(ActionComponent component) {
    _actionComponents.add(component);
  }

  void refresh() {
    throw Exception(
        "Method refresh() must be overriden in classes with ScreenBase");
  }

  void addHorizontalBar(String blockId,
      {Component? parent, double thickness = 1.5}) {
    var horizBar = HorizontalBarComponent(thickness: thickness);
    if (parent != null) {
      horizBar.addParent(parent);
    }

    addComponent(blockId, horizBar);
  }

  void addHeading(String blockId, String text, {Component? parent}) {
    var headingComp = LabelComponent(text);
    if (parent != null) {
      headingComp.addParent(parent);
    }

    addComponent(blockId, headingComp);
  }

  void updateModel() {
    var comps = getAllComponents();
    for (var comp in comps) {
      if (comp is SerializableComponent && comp.shouldSaveState()) {
        modelLayer.setData(
            comp.getId(), comp.getGroupId(), comp.getStateValue());
      }
      // if (comp.getGroupId() != LAYOUT_GROUP) {
      //   // Remove components like horizontal bar and spacing, which have no value

      //   if (comp is SingleValueComponent) {
      //     modelLayer.setData(comp.getId(), comp.getGroupId(), comp.getValue());
      //   }

      //   if (comp is MultiValueComponent) {
      //     var values = comp.getValue();
      //     modelLayer.clearData(comp.getId(), comp.getGroupId());

      //     for (var v in values) {
      //       modelLayer.setData(comp.getId(), comp.getGroupId(), v,
      //           multiple: true);
      //     }
      //   }
      // }
    }
  }

  void addComponent(String blockId, Component component,
      {ComponentBlockType blockType = ComponentBlockType.simple}) {
    component.addListener(refresh);
    component.addListener(updateModel);

    if (component is ComponentBase) {
      (component as ComponentBase).addUiListener(refresh);
    }

    var entry = ComponentEntry(
        component, component.getId(), component.getComponentType());

    if (componentBlocks.containsKey(blockId)) {
      componentBlocks[blockId]!.add(entry);
    } else {
      blockOrder.add(blockId);
      blockTypes.add(blockType);
      componentBlocks[blockId] = [entry];
    }
  }

  void checkMenuCollapse(){
    isMenuCollapsed = modelLayer.app.isMenuCollapsed;
    print("Checking menu collapse: $isMenuCollapsed");
    refresh();
    
  }

  void initScreen(WebAppDataBase modelLayer) {
    List<Component> components = getAllComponents();
    this.modelLayer = modelLayer;
    modelLayer.app.addListener(checkMenuCollapse);
    for (var comp in components) {
      if (comp is ComponentBase) {
        (comp as ComponentBase).setActive();
        (comp as ComponentBase)
            .init()
            .then((val) => (comp as ComponentBase).postInit());
      }

      if (comp is SerializableComponent && comp.shouldSaveState()) {
        var modelValue = modelLayer.getData(comp.getId(), comp.getGroupId());
        if (modelValue != null) {
          comp.setStateValue(modelValue);
        }
      }
    }

    updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      updateModel();
    });
  }

  List<Component> getAllComponents() {
    List<Component> components = [];
    for (var block in componentBlocks.values) {
      for (var comp in block) {
        components.add(comp.component);
      }
    }

    return components;
  }

  void disposeScreen() {
    if (updateTimer != null && updateTimer!.isActive) {
      updateTimer!.cancel();
    }

    var comps = getAllComponents();
    for (var comp in comps) {
      comp.dispose();
    }
  }

  String getScreenId() {
    return "";
  }

  ActionComponent? getActionComponent(String name) {
    return _actionComponents
        .whereType<ActionComponent>()
        .where((comp) => comp.getId() == name)
        .firstOrNull;
  }

  Component? getComponent(String name, {String? groupId}) {
    Component? comp;

    for (var bi = 0; bi < blockOrder.length; bi++) {
      var componentEntryList = componentBlocks[blockOrder[bi]]!;

      var blockComp =
          componentEntryList.where((e) => e.componentName == name).toList();
      if (groupId != null) {
        blockComp = blockComp
            .where((e) => e.component.getGroupId() == groupId)
            .toList();
      }
      if (blockComp.isNotEmpty) {
        comp = blockComp.first.component;
      }
    }

    return comp;
  }

  List<Component> getComponentsPerBlock(String blockId) {
    var componentEntryList = componentBlocks[blockId]!;
    return componentEntryList.map((e) => e.component).toList();
  }

  void disposeComponents() {
    for (var bi = 0; bi < blockOrder.length; bi++) {
      var componentEntryList = componentBlocks[blockOrder[bi]]!;

      for (var entry in componentEntryList) {
        entry.component.dispose();
      }
    }
  }

  Widget _wrap(Widget wdg) {
    return Flex(
      direction: Axis.horizontal,
      children: [
        Expanded(
            child: Container(
                constraints: const BoxConstraints(
                    minHeight: 30, maxHeight: double.maxFinite),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [wdg],
                )))
      ],
    );
  }

  String breakLabel(String label){
    var lblLen =  isMenuCollapsed ? 36 : 26;
    
    if( label.length <= lblLen ){
      return label;
    }
    var chars = label.split('');


    var origLen = chars.length;
    var off = 0;
    for( var i = lblLen; i < origLen; i = i + lblLen){
      chars.insert(i+off, '\n');
      off = off + 1;
    }

    return chars.join('');

  }

  Widget _buildLabel(Component comp, {bool shouldBreakLabel = false}) {
    var style = Styles()["textH2"];
    if (comp is InputValidator) {
      var validateResults = (comp as InputValidator).results;

      if (validateResults.any((t) => !t.isValid)) {
        style = style.merge(TextStyle(color: Colors.red[400]));

        return Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[400],
            ),
            SizedBox(
              width: 10,
            ),
            Text(
              shouldBreakLabel ? breakLabel( comp.label() ) : comp.label(),
              style: style,
              softWrap: true,
            )
          ],
        );
      }
    }
    if (comp is ComponentBase) {
      var msg = (comp as ComponentBase).getDescription();

      final questionIcon = Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.circle,
            color: Styles()["tooltipBg"],
            size: 15,
          ),
          Icon(
            Icons.question_mark,
            color: Styles()["white"],
            size: 10,
          )
        ],
      );
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            shouldBreakLabel ? breakLabel( comp.label() ) : comp.label(),
            style: Styles()["textH2"],
          ),
          msg.isEmpty
              ? Container()
              : Padding(
                  padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                  child: Tooltip(
                    message: msg,
                    child: questionIcon,
                  )),
        ],
      );

    } else {
      return Text(
        shouldBreakLabel ? breakLabel( comp.label() ) : comp.label(),
        style: Styles()["textH2"],
      );
    }
  }

  Widget buildContent(Component comp, BuildContext context) {
    List<Widget> compMessages = [comp.buildContent(context)];
    if (comp is InputValidator) {
      var validateResults = (comp as InputValidator).results;
      if (validateResults.any((t) => !t.isValid)) {
        for (var vr in validateResults) {
          if (!vr.isValid) {
            compMessages.add(Padding(
              padding: EdgeInsets.fromLTRB(0, 5, 0, 5),
              child: Text(
                vr.message,
                style: TextStyle(fontSize: 13, color: Colors.red[400]),
              ),
            ));
          }
        }
      }
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: compMessages,
    );
  }

  Widget? _buildBlockRow(
      Component comp, ComponentType compType, BuildContext context,
      {bool addPadding = true}) {
    Widget paddingWdg = Container();
    var width = isMenuCollapsed ? 350.0 : 250.0;
    if (addPadding) {
      paddingWdg = const SizedBox(
        width: 50,
      );
      width = width + 50;
    }
    
    

    if (comp.isActive()) {
      if (compType == ComponentType.simple) {
        return Row(children: [
          paddingWdg,
          ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width),
              child: _wrap(_buildLabel(comp, shouldBreakLabel: true))),
          Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.63),
              child: _wrap(buildContent(comp, context))),
        ]);
      }

      if (compType == ComponentType.list || compType == ComponentType.table) {
        return Column(
          children: [
            paddingWdg,
            Align(
                alignment: Alignment.topLeft,
                child: Container(
                    constraints: BoxConstraints(maxWidth: modelLayer.app.isMenuCollapsed ? 350 : 250),
                    child: _wrap(_buildLabel(comp)))),
            Align(
                alignment: Alignment.topLeft,
                child: Container(
                  child: _wrap(buildContent(comp, context)),
                )),
            paddingWdg,
          ],
        );
      }

      if (compType == ComponentType.simpleNoLabel) {
        return Column(
          children: [
            paddingWdg,
            Align(
                alignment: Alignment.topLeft,
                child: Container(
                  child: _wrap(comp.buildContent(context)),
                )),
            paddingWdg,
          ],
        );
      }
    }
    return null;
  }

  Widget buildComponents(BuildContext context) {
    List<Widget> widgetRows = [];
    for (var bi = 0; bi < blockOrder.length; bi++) {
      List<Widget> blockWidgets = [];
      var componentList = componentBlocks[blockOrder[bi]]!;
      var blockType = blockTypes[bi];
      var isExpBlock = blockType == ComponentBlockType.expanded ||
          blockType == ComponentBlockType.collapsed;
      for (var ci = 0; ci < componentList.length; ci++) {
        var comp = componentList[ci];

        if (comp.component is InputValidator) {
          (comp.component as InputValidator).validate();
        }

        var row = _buildBlockRow(comp.component, comp.componentType, context,
            addPadding: isExpBlock);
        if (row != null) {
          blockWidgets.add(row);
          blockWidgets.add(const SizedBox(
            height: 15,
          ));
        }
      }

      if (isExpBlock) {
        widgetRows.add(ExpansionTile(
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            blockOrder[bi],
            style: Styles()["textH2"],
          ),
          initiallyExpanded: blockType == ComponentBlockType.expanded,
          children: blockWidgets,
        ));
      } else {
        widgetRows.addAll(blockWidgets);
      }
    }

    var actionRow = Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children:
            _actionComponents.map((e) => e.buildContent(context)).toList());

    return Padding(
        padding: const EdgeInsets.all(5),
        child: SizedBox.expand(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...widgetRows,
                const SizedBox(
                  height: 25,
                ),
                actionRow
              ],
            ),
          ),
        ));
  }
}
