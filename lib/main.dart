import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'features/splashScreen/view/splashScreen.view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: []);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: MediaQuery.of(context).textScaler.clamp(minScaleFactor: 1, maxScaleFactor: 1)),
      child: GetMaterialApp(
        title: 'Power Tag',
        debugShowCheckedModeBanner: false,
        locale: const Locale('en', 'IN'),
        builder: (context, child) {
          return Overlay(
            initialEntries: [OverlayEntry(builder: (context) => SafeArea(top: false, child: child ?? Container()))],
          );
        },
        home: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: MediaQuery.of(context).textScaler.clamp(minScaleFactor: 1, maxScaleFactor: 1)),
          child: SplashScreenView(),
        ),
      ),
    );
  }
}
