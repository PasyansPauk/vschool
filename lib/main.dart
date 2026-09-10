import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'app_android.dart';
import 'app_ios.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  if (Platform.isIOS) {
    runApp(LiquidGlassWidgets.wrap(child: const IosSchoolDiaryApp()));
  } else {
    runApp(LiquidGlassWidgets.wrap(child: const AndroidSchoolDiaryApp()));
  }
}
