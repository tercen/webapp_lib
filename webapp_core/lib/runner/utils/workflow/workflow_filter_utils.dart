import 'package:sci_tercen_client/sci_client.dart' as sci;
// import 'package:webapp_utils/functions/logger.dart';

class WorkflowFilterUtils {
  sci.FilterExpr _createFilterExpr(String factorName, dynamic factorValue,
      {String filterOp = "equals"}) {
    var factorType = "string";
    if (factorValue is int) {
      factorType = "int";
    }
    if (factorValue is double) {
      factorType = "double";
    }

    sci.Factor filterFactor = sci.Factor()
      ..type = factorType
      ..name = factorName;
    var filterExpr = sci.FilterExpr()
      ..filterOp = filterOp
      ..stringValue = factorValue
      ..factor = filterFactor;

    return filterExpr;
  }


  sci.Workflow removeFilter(
      {required sci.Workflow workflow,
      required String stepId,
      required String filterName}) {
    final step = workflow.steps
        .whereType<sci.DataStep>()
        .firstWhere((step) => step.id == stepId, orElse: () => sci.DataStep());

    if (step.id.isEmpty) {
      throw sci.ServiceError(500, "step.not.found.filter",
          "Step with id $stepId not found in the workflow during addToFilter call.");
    }

    final filterList = step.model.filters.namedFilters;

    filterList.removeWhere((f) => f.name == filterName);

    return workflow;
  }

  sci.Workflow updateFilterValue(
      {required sci.Workflow workflow,
      required String stepId,
      required String filterName,
      required String factorName,
      required dynamic newValue}) {
    final step = workflow.steps
        .whereType<sci.DataStep>()
        .firstWhere((step) => step.id == stepId, orElse: () => sci.DataStep());

    if (step.id.isEmpty) {
      throw sci.ServiceError(500, "step.not.found.filter",
          "Step with id $stepId not found in the workflow during addToFilter call.");
    }

    final filterList = step.model.filters.namedFilters;

    final namedFilter = filterList.firstWhere((f) => f.name == filterName,
        orElse: () => sci.NamedFilter());
    if (namedFilter.name.isEmpty) {
      // Logger().log(
      //     level: Logger.WARN,
      //     message:
      //         "Filter with name $filterName not found in step $stepId. Ignoring updateFilterValue call.");
      return workflow;
    }

    final fExpr = namedFilter.filterExprs.whereType<sci.FilterExpr>().firstWhere((fExpr) => fExpr.factor.name == factorName,
        orElse: () => sci.FilterExpr());

    if (namedFilter.name.isEmpty) {
      // Logger().log(
      //     level: Logger.WARN,
      //     message:
      //         "Filter expression for factor $factorName in filter $filterName of step $stepId. Ignoring updateFilterValue call.");
      return workflow;
    }

    fExpr.stringValue = newValue;

    return workflow;
  }

  sci.Workflow addToFilter(
      {required sci.Workflow workflow,
      required String filterName,
      required String stepId,
      required String factorName,
      required dynamic filterValue,
      String filterBoolOp = "and",
      String factorBoolOp = "and",
      String filterOp = "equals",
      bool notFilter = false,
      List<sci.Pair> metas = const []}) {
    final step = workflow.steps
        .whereType<sci.DataStep>()
        .firstWhere((step) => step.id == stepId, orElse: () => sci.DataStep());
    if (step.id.isEmpty) {
      throw sci.ServiceError(500, "step.not.found.filter",
          "Step with id $stepId not found in the workflow during addToFilter call.");
    }

    final filterList = step.model.filters.namedFilters;

    final namedFilter = filterList.firstWhere((f) => f.name == filterName,
        orElse: () => sci.NamedFilter());
    if (namedFilter.name.isEmpty) {
      // Logger().log(
      //     level: Logger.WARN,
      //     message:
      //         "Filter with name $filterName not found in step $stepId. Ignoring addToFilter call.");
      return workflow;
    }

    final filterExpr =
        _createFilterExpr(factorName, filterValue, filterOp: filterOp);

    namedFilter.filterExprs.add(filterExpr);

    return workflow;
  }

  // Create a new empty NamedFilter. Use addToFilter to add expressions to it.
  sci.Workflow createFilter(
      {required sci.Workflow workflow,
      required String filterName,
      required String stepId,
      String filterBoolOp = "or",
      bool notFilter = false,
      List<sci.Pair> metas = const []}) {
    final step = workflow.steps
        .whereType<sci.DataStep>()
        .firstWhere((step) => step.id == stepId, orElse: () => sci.DataStep());
    if (step.id.isEmpty) {
      throw sci.ServiceError(500, "step.not.found.filter",
          "Step with id $stepId not found in the workflow during addToFilter call.");
    }

    final filterList = step.model.filters.namedFilters;

    final namedFilterCheck = filterList.firstWhere((f) => f.name == filterName,
        orElse: () => sci.NamedFilter());

    if (namedFilterCheck.name.isNotEmpty) {
      // Logger().log(
      //     level: Logger.FINE,
      //     message:
      //         "Filter with name $filterName already exists in step $stepId. Ignoring createFilter call.");
      return workflow;
    }

    final namedFilter = sci.NamedFilter()
      ..logical = filterBoolOp
      ..not = notFilter
      ..name = filterName;

    step.model.filters.namedFilters.add(namedFilter);

    return workflow;
  }
}
