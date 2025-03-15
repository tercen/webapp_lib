
import 'package:webapp_components/abstract/component.dart';

abstract class SerializableComponent extends Component {
  String getStateValue();
  void setStateValue(String value);
  bool shouldSaveState();
}
