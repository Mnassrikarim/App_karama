import 'package:flutter/material.dart';

class AppStyles {
  static const Color primaryColor = Color(0xFF6200EA);
  static const Color accentColor = Color(0xFF03DAC6);
  static const Color backgroundGradientStart = Color(0xFFF3E5F5);
  static const Color backgroundGradientEnd = Color(0xFFE1BEE7);

  static LinearGradient backgroundGradient = const LinearGradient(
    colors: [backgroundGradientStart, backgroundGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxDecoration glassMorphismDecoration = BoxDecoration(
    color: Colors.white.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.white.withOpacity(0.2)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        spreadRadius: 2,
      ),
    ],
  );

  static TextStyle headlineStyle(BuildContext context) =>
      Theme.of(context).textTheme.headlineSmall!.copyWith(
            fontWeight: FontWeight.bold,
            color: primaryColor,
            fontSize: 28,
          );

  static InputDecoration textFieldDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
      );

  static ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: accentColor,
    textStyle: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
  );
}
