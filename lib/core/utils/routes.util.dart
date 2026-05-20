import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class RoutesUtil {
  static Future<dynamic>? to(Widget Function() page) => Get.to(page, transition: Transition.rightToLeft, duration: const Duration(milliseconds: 300));
  static Future<dynamic>? off(Widget Function() page) => Get.off(page, transition: Transition.rightToLeft, duration: const Duration(milliseconds: 300));
  static Future<dynamic>? offAll(Widget Function() page) => Get.offAll(page, transition: Transition.rightToLeft, duration: const Duration(milliseconds: 300));
}