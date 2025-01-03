
import 'package:webapp_components/abstract/component.dart';
import 'package:webapp_components/commons/id_element.dart';


abstract class SingleValueComponent  extends Component {
  IdElement getValue();
  void setValue(IdElement value);
}