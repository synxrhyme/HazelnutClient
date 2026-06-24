import "package:flutter/material.dart";

// ─────────────────────────────────────────────────────────────────────────────
// CustomShade
//
// Nullable Shades erlauben Color.lerp bei Theme-Animationen.
// Konvention: shade200 = hellster Ton, shade800 = dunkelster Ton.
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class CustomShade {
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
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomColors – ThemeExtension
//
// Zugriff im Widget:
//   final c = Theme.of(context).extension<CustomColors>()!;
//   c.accent.shade500   // Haselnuss-Grün Hauptakzent
//   c.neutral.shade300  // Hintergrundton
// ─────────────────────────────────────────────────────────────────────────────

class CustomColors extends ThemeExtension<CustomColors> {
  const CustomColors({
    required this.accent,
    required this.neutral,
    required this.error,
    required this.warning,
    required this.success,
    required this.info,
    required this.navbar,
    required this.basicChatColor,
    required this.basicProfileColor,
    required this.profileColors,
  });

  // Haselnuss-Grün – der einzige Farbakzent
  final CustomShade accent;

  // Grautöne für alle UI-Flächen, Rahmen, Texte
  final CustomShade neutral;

  // Semantische Farben
  final CustomShade error;
  final CustomShade warning;
  final CustomShade success;
  final CustomShade info;

  // Navbar
  final CustomShade navbar;

  // Chat- und Profilakzente
  final Color? basicChatColor;
  final Color? basicProfileColor;
  final List<Color>? profileColors;

  @override
  CustomColors copyWith({
    CustomShade? accent,
    CustomShade? neutral,
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
      accent:            accent            ?? this.accent,
      neutral:           neutral           ?? this.neutral,
      error:             error             ?? this.error,
      warning:           warning           ?? this.warning,
      success:           success           ?? this.success,
      info:              info              ?? this.info,
      navbar:            navbar            ?? this.navbar,
      basicChatColor:    basicChatColor    ?? this.basicChatColor,
      basicProfileColor: basicProfileColor ?? this.basicProfileColor,
      profileColors:     profileColors     ?? this.profileColors,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) return this;
    return t < 0.5 ? this : other;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Palette
//
// Alle Rohwerte hier – nie direkt in Widgets verwenden.
// ─────────────────────────────────────────────────────────────────────────────

// Haselnuss-Grün: warm, leicht gelbstichig, erdig
// Angelehnt an das Blattgrün der Corylus-Pflanze
const _accentLight = CustomShade(
  shade200: Color(0xFFDDEFB2),
  shade300: Color(0xFFBCD97A),
  shade400: Color(0xFF96BD42),
  shade500: Color(0xFF628F1C), // primärer Akzent im Light Mode
  shade600: Color(0xFF4C6E15),
  shade700: Color(0xFF39530F),
  shade800: Color(0xFF26380A),
);

const _accentDark = CustomShade(
  shade200: Color(0xFFDDEFB2),
  shade300: Color(0xFFBCD97A),
  shade400: Color(0xFF96BD42), // primärer Akzent im Dark Mode (heller für Kontrast)
  shade500: Color(0xFF628F1C),
  shade600: Color(0xFF4C6E15),
  shade700: Color(0xFF39530F),
  shade800: Color(0xFF26380A),
);

// Neutrals: reines Grau, kein Farbstich
const _neutralLight = CustomShade(
  shade200: Color(0xFFFFFFFF), // reine Fläche / Cards
  shade300: Color(0xFFF4F4F4), // App-Hintergrund
  shade400: Color(0xFFEAEAEA), // subtile Trenner
  shade500: Color(0xFFCCCCCC), // Borders
  shade600: Color(0xFFA0A0A0), // deaktiviert / Hints
  shade700: Color(0xFF6A6A6A), // Sekundärtext
  shade800: Color(0xFF1A1A1A), // Primärtext
);

const _neutralDark = CustomShade(
  shade200: Color(0xFF2E2E2E), // Cards / erhöhte Flächen
  shade300: Color(0xFF252525), // leicht erhöht
  shade400: Color(0xFF1E1E1E), // Surface
  shade500: Color(0xFF171717), // Hintergrund
  shade600: Color(0xFF111111), // tiefer Hintergrund
  shade700: Color(0xFF0A0A0A), // tiefster Grund
  shade800: Color(0xFF000000),
);

// Error: gedämpftes Rot
const _error = CustomShade(
  shade200: Color(0xFFFFD6D6),
  shade300: Color(0xFFF5A0A0),
  shade400: Color(0xFFE86060),
  shade500: Color(0xFFCC2929),
  shade600: Color(0xFFA31616),
  shade700: Color(0xFF7A0A0A),
  shade800: Color(0xFF4D0000),
);

// Warning: warmes Amber
const _warning = CustomShade(
  shade200: Color(0xFFFFEABF),
  shade300: Color(0xFFFFCA70),
  shade400: Color(0xFFEFA030),
  shade500: Color(0xFFD07808),
  shade600: Color(0xFFA85E04),
  shade700: Color(0xFF804602),
  shade800: Color(0xFF562E01),
);

// Info: ruhiges Blau
const _info = CustomShade(
  shade200: Color(0xFFD6E8FF),
  shade300: Color(0xFF96BFEF),
  shade400: Color(0xFF5593DA),
  shade500: Color(0xFF2E6DB8),
  shade600: Color(0xFF1F5290),
  shade700: Color(0xFF143A6B),
  shade800: Color(0xFF0A2244),
);

// Success: kühleres Grün, klar unterscheidbar vom Akzent
const _success = CustomShade(
  shade200: Color(0xFFD4F5D4),
  shade300: Color(0xFF97DF97),
  shade400: Color(0xFF58C458),
  shade500: Color(0xFF2E9E2E),
  shade600: Color(0xFF1F7A1F),
  shade700: Color(0xFF135A13),
  shade800: Color(0xFF083808),
);

// Profilfarben: 10 distinkte, gesättigte Töne für Avatar-Akzente
const List<Color> _profileColors = [
  Color(0xFF8A2525),
  Color(0xFFB45C36),
  Color(0xFF9C8E12),
  Color(0xFF2E7D32),
  Color(0xFF1B6B3A),
  Color(0xFF0E7490),
  Color(0xFF1E4DB7),
  Color(0xFF5C35B4),
  Color(0xFF8B2BAC),
  Color(0xFFA0266A),
];

// ─────────────────────────────────────────────────────────────────────────────
// Light Mode
// ─────────────────────────────────────────────────────────────────────────────

final ThemeData lightMode = ThemeData(
  useMaterial3:             true,
  brightness:               Brightness.light,
  fontFamily:               'IBM Plex Sans',
  scaffoldBackgroundColor:  const Color(0xFFF4F4F4),
  highlightColor:           Colors.transparent,
  splashColor:              const Color(0x0A628F1C),

  colorScheme: const ColorScheme.light(
    primary:               Color(0xFF628F1C), // accent.shade500
    onPrimary:             Colors.white,
    primaryContainer:      Color(0xFFDDEFB2), // accent.shade200
    onPrimaryContainer:    Color(0xFF26380A), // accent.shade800
    secondary:             Color(0xFF4C6E15), // accent.shade600
    onSecondary:           Colors.white,
    surface:               Color(0xFFFFFFFF),
    onSurface:             Color(0xFF1A1A1A),
    surfaceContainerHighest: Color(0xFFEAEAEA),
    onSurfaceVariant:      Color(0xFF6A6A6A),
    outline:               Color(0xFFCCCCCC),
    outlineVariant:        Color(0xFFEAEAEA),
    error:                 Color(0xFFCC2929),
    onError:               Colors.white,
  ),

  extensions: const [
    CustomColors(
      accent:  _accentLight,
      neutral: _neutralLight,
      error:   _error,
      warning: _warning,
      info:    _info,
      success: _success,

      navbar: CustomShade(
        selected:   Color(0xFF628F1C), // accent.shade500
        unselected: Color(0xFFA0A0A0), // neutral.shade600
        background: Color(0xFFFFFFFF), // neutral.shade200
      ),

      basicChatColor:    Color(0xFF4C6E15),  // accent.shade600
      basicProfileColor: Color(0xFF2E6DB8),  // info.shade500

      profileColors: _profileColors,
    ),
  ],

  appBarTheme: const AppBarTheme(
    backgroundColor:        Color(0xFFFFFFFF),
    foregroundColor:        Color(0xFF1A1A1A),
    elevation:              0,
    scrolledUnderElevation: 0,
    surfaceTintColor:       Colors.transparent,
    titleTextStyle: TextStyle(
      fontFamily:     'IBM Plex Sans',
      fontSize:       16,
      fontWeight:     FontWeight.w600,
      color:          Color(0xFF1A1A1A),
    ),
  ),

  cardTheme: CardThemeData(
    color:     const Color(0xFFFFFFFF),
    elevation: 0,
    margin:    EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side:         const BorderSide(color: Color(0xFFEAEAEA)),
    ),
  ),

  dividerTheme: const DividerThemeData(
    color:     Color(0xFFEAEAEA),
    thickness: 1,
    space:     1,
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled:    true,
    fillColor: const Color(0xFFF4F4F4),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide:   BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide:   const BorderSide(color: Color(0xFFCCCCCC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide:   const BorderSide(color: Color(0xFF628F1C), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide:   const BorderSide(color: Color(0xFFCC2929)),
    ),
    hintStyle:      const TextStyle(color: Color(0xFFA0A0A0)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor:         const Color(0xFF628F1C),
      foregroundColor:         Colors.white,
      disabledBackgroundColor: const Color(0xFFCCCCCC),
      disabledForegroundColor: const Color(0xFFA0A0A0),
      elevation:               0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF628F1C),
      side:            const BorderSide(color: Color(0xFFCCCCCC)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF628F1C),
      textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
    ),
  ),

  iconTheme: const IconThemeData(
    color: Color(0xFF6A6A6A),
    size:  20,
  ),

  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFFF4F4F4),
    side:            const BorderSide(color: Color(0xFFCCCCCC)),
    labelStyle:      const TextStyle(fontSize: 12, color: Color(0xFF6A6A6A)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  ),

  listTileTheme: const ListTileThemeData(
    tileColor:      Colors.transparent,
    iconColor:      Color(0xFF6A6A6A),
    textColor:      Color(0xFF1A1A1A),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  ),

  textTheme: const TextTheme(
    headlineLarge:  TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A), letterSpacing: -0.5),
    headlineMedium: TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A), letterSpacing: -0.3),
    headlineSmall:  TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
    titleLarge:     TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
    titleMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
    titleSmall:     TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
    bodyLarge:      TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Color(0xFF1A1A1A)),
    bodyMedium:     TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFF1A1A1A)),
    bodySmall:      TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xFF6A6A6A)),
    labelLarge:     TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6A6A6A)),
    labelMedium:    TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFA0A0A0)),
    labelSmall:     TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: Color(0xFFA0A0A0)),
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// Dark Mode
// ─────────────────────────────────────────────────────────────────────────────

final ThemeData darkMode = ThemeData(
  useMaterial3:             true,
  brightness:               Brightness.dark,
  fontFamily:               'IBM Plex Sans',
  scaffoldBackgroundColor:  const Color(0xFF171717),
  highlightColor:           Colors.transparent,
  splashColor:              const Color(0x0A96BD42),

  colorScheme: const ColorScheme.dark(
    primary:               Color(0xFF96BD42), // accent.shade400 – heller für dark bg
    onPrimary:             Color(0xFF26380A),
    primaryContainer:      Color(0xFF39530F), // accent.shade700
    onPrimaryContainer:    Color(0xFFDDEFB2), // accent.shade200
    secondary:             Color(0xFFBCD97A), // accent.shade300
    onSecondary:           Color(0xFF1A2C07),
    surface:               Color(0xFF1E1E1E),
    onSurface:             Color(0xFFF0F0F0),
    surfaceContainerHighest: Color(0xFF2E2E2E),
    onSurfaceVariant:      Color(0xFFA0A0A0),
    outline:               Color(0xFF333333),
    outlineVariant:        Color(0xFF252525),
    error:                 Color(0xFFE86060),
    onError:               Color(0xFF4D0000),
  ),

  extensions: const [
    CustomColors(
      accent:  _accentDark,
      neutral: _neutralDark,
      error:   _error,
      warning: _warning,
      info:    _info,
      success: _success,

      navbar: CustomShade(
        selected:   Color(0xFF96BD42), // accent.shade400
        unselected: Color(0xFF6A6A6A), // neutral.shade700 (dark)
        background: Color(0xFF111111), // neutral.shade600 (dark)
      ),

      basicChatColor:    Color(0xFF96BD42),  // accent.shade400
      basicProfileColor: Color(0xFF5593DA),  // info.shade400

      profileColors: _profileColors,
    ),
  ],

  appBarTheme: const AppBarTheme(
    backgroundColor:        Color(0xFF171717),
    foregroundColor:        Color(0xFFF0F0F0),
    elevation:              0,
    scrolledUnderElevation: 0,
    surfaceTintColor:       Colors.transparent,
    titleTextStyle: TextStyle(
      fontFamily:   'IBM Plex Sans',
      fontSize:     16,
      fontWeight:   FontWeight.w600,
      color:        Color(0xFFF0F0F0),
    ),
  ),

  cardTheme: CardThemeData(
    color:     const Color(0xFF1E1E1E),
    elevation: 0,
    margin:    EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side:         const BorderSide(color: Color(0xFF2E2E2E)),
    ),
  ),

  dividerTheme: const DividerThemeData(
    color:     Color(0xFF2E2E2E),
    thickness: 1,
    space:     1,
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled:    true,
    fillColor: const Color(0xFF252525),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide:   BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide:   const BorderSide(color: Color(0xFF333333)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide:   const BorderSide(color: Color(0xFF96BD42), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide:   const BorderSide(color: Color(0xFFE86060)),
    ),
    hintStyle:      const TextStyle(color: Color(0xFF6A6A6A)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor:         const Color(0xFF628F1C),
      foregroundColor:         Colors.white,
      disabledBackgroundColor: const Color(0xFF333333),
      disabledForegroundColor: const Color(0xFF6A6A6A),
      elevation:               0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF96BD42),
      side:            const BorderSide(color: Color(0xFF333333)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF96BD42),
      textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
    ),
  ),

  iconTheme: const IconThemeData(
    color: Color(0xFFA0A0A0),
    size:  20,
  ),

  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFF252525),
    side:            const BorderSide(color: Color(0xFF333333)),
    labelStyle:      const TextStyle(fontSize: 12, color: Color(0xFFA0A0A0)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  ),

  listTileTheme: const ListTileThemeData(
    tileColor:      Colors.transparent,
    iconColor:      Color(0xFFA0A0A0),
    textColor:      Color(0xFFF0F0F0),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  ),

  textTheme: const TextTheme(
    headlineLarge:  TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFFF0F0F0), letterSpacing: -0.5),
    headlineMedium: TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: Color(0xFFF0F0F0), letterSpacing: -0.3),
    headlineSmall:  TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFFF0F0F0)),
    titleLarge:     TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFF0F0F0)),
    titleMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFF0F0F0)),
    titleSmall:     TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFF0F0F0)),
    bodyLarge:      TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Color(0xFFEAEAEA)),
    bodyMedium:     TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFFEAEAEA)),
    bodySmall:      TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xFFA0A0A0)),
    labelLarge:     TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFA0A0A0)),
    labelMedium:    TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF6A6A6A)),
    labelSmall:     TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: Color(0xFF6A6A6A)),
  ),
);