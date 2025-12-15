import 'package:flutter/material.dart';
import 'package:webapp_components/abstract/component.dart';
import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_components/definitions/list_action.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

class ActionBarComponent
    with ComponentBase, ChangeNotifier
    implements Component {
  final List<ListAction> actions;

  ActionBarComponent(id, groupId, this.actions) {
    super.id = id;
    super.groupId = groupId;
    super.componentLabel = "";
  }

  Widget createButtonLabel(String label) {
    return Text(
      label,
      style: Styles()["textH1"],
    );
  }

  Widget buildActionWidget(ListAction action, BuildContext context) {
    var icon = action.getIcon();
    var rszIcon = Icon(icon.icon, size: 32, color: icon.color);

    // Build the icon widget (either with or without underLabel)
    Widget iconWidget;
    if (action.underLabel != null) {
      // Column layout: icon on top, underLabel below
      iconWidget = InkWell(
        onTap: () async {
          if (action.isEnabled(WebappTable())) {
            action.callAction(WebappTable(), context: context);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              rszIcon,
              const SizedBox(height: 4),
              Text(
                action.underLabel!,
                style: TextStyle(
                  fontSize: 12,
                  color: icon.color,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Original IconButton without underLabel
      iconWidget = IconButton(
        onPressed: () async {
          if (action.isEnabled(WebappTable())) {
            action.callAction(WebappTable(), context: context);
          }
        },
        icon: rszIcon,
        tooltip: action.description,
      );
    }

    List<Widget> row = [];
    row.add(iconWidget);

    if (action.buttonLabel != null) {
      row.add(createButtonLabel(action.buttonLabel!));
    }

    return wrapActionWidget(Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: row,
    ));
  }

  Widget wrapActionWidget(Widget wdg) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: wdg,
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: actions.map((action) => buildActionWidget(action, context)).toList(),
    );
  }

  @override
  void reset() {
    
  }

  @override
  ComponentType getComponentType() {
    return ComponentType.simpleNoLabel;
  }

  @override
  getComponentValue() {
    return "";
  }

  @override
  bool isFulfilled() {
    return true;
  }

  @override
  void setComponentValue(value) {}
}
