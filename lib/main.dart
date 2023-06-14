import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'Screens/Queue.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  runApp(const VividApp());
}

class VividApp extends StatefulWidget {
  const VividApp({super.key});

  @override
  State<VividApp> createState() => _VividAppState();
}

class _VividAppState extends State<VividApp> {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top]);
    return ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) {
          return MaterialApp(
              debugShowCheckedModeBanner: false,
              themeMode: ThemeMode.light,
              theme: ThemeData(
                  appBarTheme: const AppBarTheme(backgroundColor: Colors.white),
                  colorScheme: ColorScheme(
                      brightness: Brightness.light,
                      primary: Colors.white,
                      onPrimary: const Color.fromARGB(100, 235, 235, 235),
                      secondary: Colors.black,
                      onSecondary: Colors.white,
                      error: Colors.red[700]!,
                      onError: Colors.white,
                      background: Colors.white,
                      onBackground: Color.fromARGB(150, 235, 235, 235),
                      surface: Colors.white,
                      onSurface: const Color.fromARGB(100, 235, 235, 235))),
              home: QueuePage());
        });
  }
}
