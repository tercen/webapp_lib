import 'package:async/async.dart';
import 'package:webapp_components/mixins/state_component.dart';

mixin AsyncManager on StateComponent {
  Map<String, CancelableOperation> operations = {};

  void startFuture(String id, Future op) {
    if( operations.keys.contains(id)){
      cancelOperation(id);
    }

    operations[id] = CancelableOperation.fromFuture(op,
        onCancel: () => print("OP $id was cancelled"));
  }

  Future<dynamic> waitResult(String id) async {
    if( operations.keys.contains(id)){
      return operations[id]!.value;
    }
  }

  void cancelAllOperations(){
    for( var op in operations.values){
      op.cancel();
    }
  }

  void cancelOperation(String id){
    operations[id]!.cancel();
  }
}
