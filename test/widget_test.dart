import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:solulab_assignment/main.dart';
import 'package:solulab_assignment/features/splashScreen/view/splashScreen.view.dart';
import 'package:solulab_assignment/features/splashScreen/controller/splashScreen.controller.dart';

void main() {
  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.delete<SplashScreenController>();
    Get.reset();
  });

  testWidgets('App starts with SplashScreenView smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our SplashScreenView is present.
    expect(find.byType(SplashScreenView), findsOneWidget);
    expect(find.text('DocuScan'), findsOneWidget);
    expect(find.text('Smart Document Scanner'), findsOneWidget);

    // Fast-forward 3 seconds to allow the timer to fire and navigate
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
