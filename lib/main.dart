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
  final lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF006874),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF97F0FF),
    onPrimaryContainer: Color(0xFF001F24),
    secondary: Color(0xFF4A6267),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFCDE7EC),
    onSecondaryContainer: Color(0xFF051F23),
    tertiary: Color(0xFF525E7D),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFDAE2FF),
    onTertiaryContainer: Color(0xFF0E1B37),
    error: Color(0xFFBA1A1A),
    errorContainer: Color(0xFFFFDAD6),
    onError: Color(0xFFFFFFFF),
    onErrorContainer: Color(0xFF410002),
    background: Color(0xFFFAFDFD),
    onBackground: Color(0xFF191C1D),
    surface: Color(0xFFFAFDFD),
    onSurface: Color(0xFF191C1D),
    surfaceVariant: Color(0xFFDBE4E6),
    onSurfaceVariant: Color(0xFF3F484A),
    outline: Color(0xFF6F797A),
    onInverseSurface: Color(0xFFEFF1F1),
    inverseSurface: Color(0xFF2E3132),
    inversePrimary: Color(0xFF4FD8EB),
    shadow: Color(0xFF000000),
    surfaceTint: Color(0xFF006874),
    outlineVariant: Color(0xFFBFC8CA),
    scrim: Color(0xFF000000),
  );

  final darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF4FD8EB),
    onPrimary: Color(0xFF00363D),
    primaryContainer: Color(0xFF004F58),
    onPrimaryContainer: Color(0xFF97F0FF),
    secondary: Color(0xFFB1CBD0),
    onSecondary: Color(0xFF1C3438),
    secondaryContainer: Color(0xFF334B4F),
    onSecondaryContainer: Color(0xFFCDE7EC),
    tertiary: Color(0xFFBAC6EA),
    onTertiary: Color(0xFF24304D),
    tertiaryContainer: Color(0xFF3B4664),
    onTertiaryContainer: Color(0xFFDAE2FF),
    error: Color(0xFFFFB4AB),
    errorContainer: Color(0xFF93000A),
    onError: Color(0xFF690005),
    onErrorContainer: Color(0xFFFFDAD6),
    background: Color(0xFF191C1D),
    onBackground: Color(0xFFE1E3E3),
    surface: Color(0xFF191C1D),
    onSurface: Color(0xFFE1E3E3),
    surfaceVariant: Color(0xFF3F484A),
    onSurfaceVariant: Color(0xFFBFC8CA),
    outline: Color(0xFF899294),
    onInverseSurface: Color(0xFF191C1D),
    inverseSurface: Color(0xFFE1E3E3),
    inversePrimary: Color(0xFF006874),
    shadow: Color(0xFF000000),
    surfaceTint: Color(0xFF4FD8EB),
    outlineVariant: Color(0xFF3F484A),
    scrim: Color(0xFF000000),
  );
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
                    useMaterial3: true,
                    colorScheme: _light ?? lightColorScheme),
                darkTheme: ThemeData.from(
                    useMaterial3: true, colorScheme: _dark ?? darkColorScheme),
                home: ChangeNotifierProvider(
                    create: (context) => QueueModel(),
                    builder: (context, child) => QueuePage()));
          });
    });
  }
}
