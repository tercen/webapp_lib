import 'package:async/async.dart';
import 'package:webapp_utils/functions/logger.dart';

mixin AsyncManager  {
  Map<String, CancelableOperation> operations = {};

  void startFuture(String id, Future op) {
    if( operations.keys.contains(id)){
      cancelOperation(id);
    }

    operations[id] = CancelableOperation.fromFuture(op,
        onCancel: () => Logger().log(level: Logger.FINER, message: "OP $id was cancelled")  );
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
