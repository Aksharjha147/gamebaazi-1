import 'package:flutter/material.dart';

class AppColors {
  // Ultra Modern Dark Palette
  static const Color background = Color(0xFF060606); // Deeper Black
  static const Color cardColor = Color(0xFF141414);  // Sleek Gray-Black
  static const Color cardDark = Color(0xFF0F0F0F);
  
  // Neon Accents
  static const Color primary = Color(0xFF00FFA3);     // Electric Spring Green
  static const Color primaryHover = Color(0xFF52FFC3);
  static const Color secondary = Color(0xFF00D1FF);   // Deep Sky Blue
  static const Color danger = Color(0xFFFF3B30);      // Vivid Red
  static const Color warning = Color(0xFFFFCC00);     // Bright Gold
  static const Color info = Color(0xFF5856D6);        // Royal Purple
  
  // Text & Borders
  static const Color textLight = Color(0xFFF2F2F7);
  static const Color textMuted = Color(0xFF8E8E93);
  static const Color inputBackground = Color(0xFF1C1C1E);
  static const Color inputBorder = Color(0xFF2C2C2E);

  // Advanced Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00FFA3), Color(0xFF00D1FF)], // Green to Cyan
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFFF3B30), Color(0xFFFF2D55)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF5856D6), Color(0xFFAF52DE)], // Purple to Pink
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1C1C1E), Color(0xFF141414)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Colors.white10, Colors.transparent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Glows
  static List<BoxShadow> glowPrimary = [
    BoxShadow(color: primary.withOpacity(0.4), blurRadius: 20, spreadRadius: 1),
  ];
  
  static List<BoxShadow> glowSecondary = [
    BoxShadow(color: secondary.withOpacity(0.4), blurRadius: 20, spreadRadius: 1),
  ];

  static List<BoxShadow> glowDanger = [
    BoxShadow(color: danger.withOpacity(0.3), blurRadius: 20, spreadRadius: 1),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black, blurRadius: 15, offset: const Offset(0, 8)),
  ];

  static List<BoxShadow> neonGlow(Color color) => [
    BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, spreadRadius: 2),
  ];
}
