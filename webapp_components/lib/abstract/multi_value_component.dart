import 'package:webapp_components/abstract/component.dart';
import 'package:webapp_components/commons/id_element.dart';


abstract class MultiValueComponent  extends Component {
  List<IdElement> getValue();
  void setValue(List<IdElement> value);
}
