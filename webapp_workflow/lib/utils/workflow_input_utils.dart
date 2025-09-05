import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:tson/tson.dart' as tson;

import 'package:uuid/uuid.dart';

class WorkflowInputUtils {
  sci.Workflow documentIdToTableStep(
      sci.Workflow workflow, String stepId, String documentId, {String stepName = ""}) {
    final tableStep = workflow.steps
        .whereType<sci.TableStep>()
        .firstWhere((step) => step.id == stepId, orElse: () => sci.TableStep());

    if (tableStep.id.isEmpty) {
      throw sci.ServiceError(500, "step.not.found.documentIdToTableStep",
          "Step with id $stepId not found in the workflow during documentIdToTableStep call.");
    }

    tableStep.model.relation = _createDocumentRelation(documentId);
    tableStep.state.taskState = sci.DoneState();

    if (stepName.isNotEmpty) {
      tableStep.name = stepName;
    }

    return workflow;
  }

  sci.RenameRelation _createDocumentRelation(String documentId) {
    var uuid = const Uuid();
    sci.Table tbl = sci.Table()..nRows = 1;
    sci.Column col = sci.Column()
      ..name = "documentId"
      ..type = "string"
      ..id = "documentId"
      ..nRows = 1
      ..size = -1
      ..values = tson.CStringList.fromList([uuid.v4()]);

    tbl.columns.add(col);

    col = sci.Column()
      ..name = ".documentId"
      ..type = "string"
      ..id = ".documentId"
      ..nRows = 1
      ..size = -1
      ..values = tson.CStringList.fromList([documentId]);

    tbl.columns.add(col);

    sci.InMemoryRelation rel = sci.InMemoryRelation()
      ..id = uuid.v4()
      ..inMemoryTable = tbl;
    sci.RenameRelation rr = sci.RenameRelation();
    rr.inNames.addAll(["documentId", ".documentId"]);
    rr.outNames.addAll(["documentId", ".documentId"]);
    rr.relation = rel;
    rr.id = "rename_${rel.id}";
    return rr;
  }
}
