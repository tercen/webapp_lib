import 'package:flutter/material.dart';
import 'package:webapp_components/abstract/component.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

class ModalScreenBase with ChangeNotifier {
  dynamic newValue;
  dynamic value;

  final String title;

  final List<Component> modalComponents;

  ModalScreenBase(this.title, this.modalComponents);

  Future<void> build(BuildContext context) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (modalContext, StateSetter setState) {
            for( var c in modalComponents ){
              c.addListener(() => setState((){
                
              }));
            }
            return layoutModal(modalContext, setState);
          });
        });
  }

  Widget saveCancelButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              notifyListeners();
            },
            style: Styles()["buttonEnabled"],
            child: const Text("Save")),
        const SizedBox(
          width: 10,
        ),
        ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              
            },
            style: Styles()["buttonEnabled"],
            child: const Text("Cancel")),
      ],
    );
  }

  Widget buildWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: SingleChildScrollView(
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: modalComponents
                .map((comp) => comp.buildContent(context))
                .toList()),
      ),
    );
  }

  Widget layoutModal(BuildContext context, StateSetter setState) {
    return AlertDialog(
      title: Text(
        title,
        style: Styles()["textH2"],
      ),
      content: buildWidget(context),
      actions: [saveCancelButtons(context)],
    );
  }

  getValue() {
    return "";
  }
}
