import 'package:flutter/material.dart';
import 'package:webapp_model/model_handler_base.dart';

import '../commons/id_element.dart';
import '../commons/id_element_table.dart';


typedef InfoBoxBuilderCallback = Container Function(ModelHandlerBase model, IdElement element);
typedef WebappCallback = void Function(dynamic data);
typedef DataFetchCallback = Future<IdElementTable> Function( List<String> parentKeys, String groupId );


enum ComponentType {simple, simpleNoLabel, list, multiOption, table}
