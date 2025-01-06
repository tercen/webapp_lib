import 'dart:convert';

import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:webapp_utils/project_functions.dart';

class WorkflowFunctions {
  static Future<void> updateReadme( sci.Document readmeDocument,
       String workflowId, String text) async {
    var factory = tercen.ServiceFactory();

  
    var readmeDocument =  ProjectFunctions().getProjectFiles().firstWhere(
        (e) => e.getMeta("WORKFLOW_ID") == workflowId,
        orElse: () => sci.Document());

    if (readmeDocument.id == "") {
      print("Readme not found for workflow id $workflowId");
    } else {
      var downloadStream = factory.fileService.download(readmeDocument.id);
      var fileBytes = await downloadStream.toList();

      var readmeTxt = utf8.decode(fileBytes[0]);

      var notes = text.split("\n").map((e) => "> $e").join("  \n");
      notes += "  \n\n";
      notes = "## Run Notes  \n$notes";
      readmeTxt = notes + readmeTxt;

      var doc = await factory.fileService.get(readmeDocument.id);
      Stream<List> dataStream =
          Stream.fromIterable(Iterable.castFrom([utf8.encode(readmeTxt)]));
      factory.fileService.upload(doc, dataStream);
    }
  }

  static List<sci.SimpleRelation> getSimpleRelations(sci.Relation relation){
  List<sci.SimpleRelation> l = [];

  switch (relation.kind) {
    case "SimpleRelation":
      l.add(relation as sci.SimpleRelation);
      break;
    case "CompositeRelation":
      sci.CompositeRelation cr = relation as sci.CompositeRelation;
      List<sci.JoinOperator> joList = cr.joinOperators;
      l.addAll(getSimpleRelations(cr.mainRelation));
      for(var jo in joList){
        l.addAll(getSimpleRelations(jo.rightRelation));
      }
    case "RenameRelation":
      sci.RenameRelation rr = relation as sci.RenameRelation;
      l.addAll(getSimpleRelations(rr.relation));

      // 
    default:
  }

  return l;
}

}