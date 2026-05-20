import 'dart:async';
import 'package:get/get.dart';
import '../../../core/utils/routes.util.dart';
import '../../home/view/homeScreen.view.dart';

class SplashScreenController extends GetxController {
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _timer = Timer(const Duration(seconds: 3), () {
      RoutesUtil.offAll(() => const HomeScreenView());
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}