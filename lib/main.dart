import 'dart:ui';
import 'package:YT_H264/Models/QueueModel.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
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
  final _defaultLightColorScheme =
      ColorScheme.fromSwatch(primarySwatch: Colors.blue);

  final _defaultDarkColorScheme = ColorScheme.fromSwatch(
      primarySwatch: Colors.blue, brightness: Brightness.dark);
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top]);
    return DynamicColorBuilder(builder: (_light, _dark) {
      return ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) {
            return MaterialApp(
                debugShowCheckedModeBanner: false,
                themeMode: ThemeMode.system,
                theme: ThemeData.from(
                    colorScheme: _light ?? _defaultLightColorScheme),
                darkTheme: ThemeData.from(
                    colorScheme: _dark ?? _defaultDarkColorScheme),
                home: ChangeNotifierProvider(
                    create: (context) => QueueModel(),
                    builder: (context, child) => QueuePage()));
          });
    });
  }
}
