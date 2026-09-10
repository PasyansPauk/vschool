import 'dart:io';
import 'package:flutter/widgets.dart';
import 'app_ios.dart';
import 'app_android.dart';

export 'app_ios.dart';
export 'app_android.dart';

/// Compatibility wrapper for SchoolDiaryApp that directs to
/// IosSchoolDiaryApp on iOS and AndroidSchoolDiaryApp on Android/other platforms.
class SchoolDiaryApp extends StatelessWidget {
  const SchoolDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return const IosSchoolDiaryApp();
    } else {
      return const AndroidSchoolDiaryApp();
    }
  }
}
