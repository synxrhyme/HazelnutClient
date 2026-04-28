import "package:flutter/material.dart";

@immutable
class CustomShade {
  final Color? shade200;
  final Color? shade300;
  final Color? shade400;
  final Color? shade500;
  final Color? shade600;
  final Color? shade700;
  final Color? shade800;

  final Color? selected;
  final Color? unselected;
  final Color? background;

  const CustomShade({
    this.shade200,
    this.shade300,
    this.shade400,
    this.shade500,
    this.shade600,
    this.shade700,
    this.shade800,

    this.selected,
    this.unselected,
    this.background,
  });
}

class CustomColors extends ThemeExtension<CustomColors> {
  final CustomShade background;
  final CustomShade error;
  final CustomShade warning;
  final CustomShade success;
  final CustomShade info;

  final CustomShade navbar;

  final Color? basicChatColor;
  final Color? basicProfileColor;

  final List<Color>? profileColors;

  const CustomColors({
    required this.background,
    required this.error,
    required this.warning,
    required this.success,
    required this.info,

    required this.navbar,

    required this.basicChatColor,
    required this.basicProfileColor,

    required this.profileColors,
  });

  @override
  CustomColors copyWith({
    CustomShade? background,
    CustomShade? error,
    CustomShade? warning,
    CustomShade? success,
    CustomShade? info,

    CustomShade? navbar,

    Color? basicChatColor,
    Color? basicProfileColor,
    List<Color>? profileColors,

  }) {
    return CustomColors(
      background:         background        ?? this.background,
      error:              error             ?? this.error,
      warning:            warning           ?? this.warning,
      success:            success           ?? this.success,
      info:               info              ?? this.info,
       
      navbar:             navbar            ?? this.navbar,

      basicChatColor:     basicChatColor    ?? this.basicChatColor,
      basicProfileColor:  basicProfileColor ?? this.basicProfileColor,
      profileColors:      profileColors     ?? this.profileColors,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) return this;
    return t < 0.5 ? this : other;
  }
}

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.black,
  highlightColor: Colors.transparent,
  extensions: [
    CustomColors(
      background: CustomShade(
        shade200: Color(0xFFFFFFFF),
        shade300: Color(0xFFE6E6E6),
        shade400: Color(0xFFCCCCCC),
        shade500: Color(0xFFB3B3B3),
        shade600: Color(0xFF999999),
        shade700: Color(0xFF808080),
        shade800: Color(0xFF737373),
      ),
      error: CustomShade(
        shade300: Color(0xFFF37575),
        shade400: Color(0xFFEF5050),
        shade500: Color(0xFFDD2727),
        shade600: Color(0xFFB00A0A),
        shade700: Color(0xFF870000),
      ),
      warning: CustomShade(
        shade300: Color(0xFFF78D5B),
        shade400: Color(0xFFF17841),
        shade500: Color(0xFFEF550E),
        shade600: Color(0xFFC84103),
        shade700: Color(0xFFA43502),
      ),
      info: CustomShade(
        shade300: Color(0xFF7BB6F9),
        shade400: Color(0xFF4B95EB),
        shade500: Color(0xFF1074E6),
        shade600: Color(0xFF0F64C4),
        shade700: Color(0xFF0751A6)
      ),
      success: CustomShade(
        shade300: Color(0xFFA7FE6C),
        shade400: Color(0xFF8EF24B),
        shade500: Color(0xFF67E612),
        shade600: Color(0xFF51B70C),
        shade700: Color(0xFF3C9203),
      ),

      navbar: CustomShade(
        selected:   Color(0xFF4B95EB),
        unselected: Color(0xFF828282),
        background: Color(0xFF1E1E1E),
      ),

      basicChatColor:    Color(0xFF6A760C),
      basicProfileColor: Color(0xFF409991),

      profileColors: [
        Color(0xFF8A2525),
        Color(0xFFB45C36),
        Color(0xFFABB72E),
        Color(0xFF087408),
        Color(0xFF41BC1F),
        Color(0xFF409991),
        Color(0xFF4B62B8),
        Color(0xFF2248D0),
        Color(0xFF6036B4),
        Color(0xFF9F36B4),
      ],
    ),
  ]
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color.from(alpha: 1, red: 0.95, green: 0.95, blue: 0.95),
  highlightColor: Colors.transparent,
  extensions: [
    CustomColors(
      background: CustomShade(
        shade200: Color(0xFF333333),
        shade300: Color(0xFF2B2B2B),
        shade400: Color(0xFF262626),
        shade500: Color(0xFF1F1F1F),
        shade600: Color(0xFF1A1A1A),
        shade700: Color(0xFF0D0D0D),
        shade800: Color(0xFF000000),
      ),
      error: CustomShade(
        shade300: Color(0xFFF37575),
        shade400: Color(0xFFEF5050),
        shade500: Color(0xFFDD2727),
        shade600: Color(0xFFB00A0A),
        shade700: Color(0xFF870000),
      ),
      warning: CustomShade(
        shade300: Color(0xFFF78D5B),
        shade400: Color(0xFFF17841),
        shade500: Color(0xFFEF550E),
        shade600: Color(0xFFC84103),
        shade700: Color(0xFFA43502),
      ),
      info: CustomShade(
        shade300: Color(0xFF7BB6F9),
        shade400: Color(0xFF4B95EB),
        shade500: Color(0xFF1074E6),
        shade600: Color(0xFF0F64C4),
        shade700: Color(0xFF0751A6)
      ),
      success: CustomShade(
        shade300: Color(0xFFA7FE6C),
        shade400: Color(0xFF8EF24B),
        shade500: Color(0xFF67E612),
        shade600: Color(0xFF51B70C),
        shade700: Color(0xFF3C9203),
      ),

      navbar: CustomShade(
        selected:   Color(0xFF4B95EB),
        unselected: Color(0xFF828282),
        background: Color(0xFF1E1E1E),
      ),

      basicChatColor:    Color(0xFF6A760C),
      basicProfileColor: Color(0xFF409991),

      profileColors: [
        Color(0xFF8A2525),
        Color(0xFFB45C36),
        Color(0xFFABB72E),
        Color(0xFF087408),
        Color(0xFF41BC1F),
        Color(0xFF409991),
        Color(0xFF4B62B8),
        Color(0xFF2248D0),
        Color(0xFF6036B4),
        Color(0xFF9F36B4),
      ],
    ),
  ]
);