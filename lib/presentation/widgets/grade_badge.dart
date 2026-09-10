import 'package:flutter/cupertino.dart';
import '../../data/models/grade_item.dart';

/// Reusable Apple-style Grade Badge adhering to iOS HIG.
/// Provides standardized color coding, typography, and squircle shape.
class GradeBadge extends StatelessWidget {
  final int value;
  final int? weight;
  final double size;
  final double fontSize;
  final double borderRadius;
  final bool isDark;

  const GradeBadge({
    super.key,
    required this.value,
    this.weight,
    this.size = 32.0,
    this.fontSize = 16.0,
    this.borderRadius = 10.0,
    this.isDark = true,
  });

  factory GradeBadge.fromGradeItem(
    GradeItem grade, {
    double size = 32.0,
    double fontSize = 16.0,
    double borderRadius = 10.0,
    bool isDark = true,
  }) {
    return GradeBadge(
      value: grade.value,
      weight: grade.weight,
      size: size,
      fontSize: fontSize,
      borderRadius: borderRadius,
      isDark: isDark,
    );
  }

  /// 5: #4ADE80, 4: #38BDF8, 3: #FBBF24, 2/1: #F87171
  static Color getTextColor(int value) {
    switch (value) {
      case 5:
        return const Color(0xFF4ADE80);
      case 4:
        return const Color(0xFF38BDF8);
      case 3:
        return const Color(0xFFFBBF24);
      case 2:
      case 1:
        return const Color(0xFFF87171);
      default:
        return const Color(0xFFA1A1AA);
    }
  }

  /// Background: rgba(..., 0.15)
  static Color getBgColor(int value) {
    switch (value) {
      case 5:
        return const Color(0x264ADE80);
      case 4:
        return const Color(0x2638BDF8);
      case 3:
        return const Color(0x26FBBF24);
      case 2:
      case 1:
        return const Color(0x26F87171);
      default:
        return const Color(0x26A1A1AA);
    }
  }

  /// Border: rgba(..., 0.30)
  static Color getBorderColor(int value) {
    switch (value) {
      case 5:
        return const Color(0x4D4ADE80);
      case 4:
        return const Color(0x4D38BDF8);
      case 3:
        return const Color(0x4DFBBF24);
      case 2:
      case 1:
        return const Color(0x4DF87171);
      default:
        return const Color(0x4DA1A1AA);
    }
  }

  static String getWeightSuperscript(int? w) {
    if (w == null || w <= 1) return '';
    switch (w) {
      case 2:
        return '²';
      case 3:
        return '³';
      case 4:
        return '⁴';
      case 5:
        return '⁵';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = getTextColor(value);
    final bgColor = getBgColor(value);
    final borderColor = getBorderColor(value);
    final weightStr = getWeightSuperscript(weight);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      alignment: Alignment.center,
      child: RichText(
        text: TextSpan(
          text: '$value',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: textColor,
            fontFamily: '.SF Pro Display',
          ),
          children: [
            if (weightStr.isNotEmpty)
              TextSpan(
                text: weightStr,
                style: TextStyle(
                  fontSize: fontSize * 0.65,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Helper to render multiple grade badges in a compact horizontal row.
class GradeBadgeRow extends StatelessWidget {
  final List<GradeItem> grades;
  final double size;
  final double fontSize;
  final double borderRadius;
  final bool isDark;

  const GradeBadgeRow({
    super.key,
    required this.grades,
    this.size = 32.0,
    this.fontSize = 16.0,
    this.borderRadius = 10.0,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    if (grades.isEmpty) return const SizedBox.shrink();
    if (grades.length == 1) {
      return GradeBadge.fromGradeItem(
        grades.first,
        size: size,
        fontSize: fontSize,
        borderRadius: borderRadius,
        isDark: isDark,
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: grades
          .map((g) => GradeBadge.fromGradeItem(
                g,
                size: size,
                fontSize: fontSize,
                borderRadius: borderRadius,
                isDark: isDark,
              ))
          .toList(),
    );
  }
}
