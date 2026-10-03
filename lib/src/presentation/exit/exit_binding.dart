import 'package:get/get.dart';

import '../../data/datasources/remote/exit_remote_ds.dart';
import 'exit_controller.dart';

class ExitBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ExitController(api: ExitRemoteDs()));
  }
}
