// lib/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Colores base (ajusta si quieres)
  static const Color _primaryLight = Color(0xFFFFFFFF); // Fondo claro
  static const Color _secondaryLight = Color(0xFFF3F4F6); // Fondo secundario claro
  static const Color _tertiaryLight = Color(0xFFE5E7EB); // Hover claro
  static const Color _textPrimaryLight = Color(0xFF111827); // Texto oscuro
  static const Color _textSecondaryLight = Color(0xFF6B7280); // Texto gris

  static const Color _primaryDark = Color(0xFF111827); // Fondo oscuro
  static const Color _secondaryDark = Color(0xFF1F2937); // Fondo secundario oscuro
  static const Color _tertiaryDark = Color(0xFF374151); // Hover oscuro
  static const Color _textPrimaryDark = Color(0xFFF9FAFB); // Texto claro
  static const Color _textSecondaryDark = Color(0xFF9CA3AF); // Texto gris claro

  static const Color _defaultAccent = Color(0xFF6366F1); // Indigo por defecto

  // Tema Claro
  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      primaryColor: _primaryLight,
      secondaryColor: _secondaryLight,
      tertiaryColor: _tertiaryLight,
      textPrimaryColor: _textPrimaryLight,
      textSecondaryColor: _textSecondaryLight,
      accentColor: _defaultAccent, // Acento por defecto para light
    );
  }

  // Tema Oscuro
  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      primaryColor: _primaryDark,
      secondaryColor: _secondaryDark,
      tertiaryColor: _tertiaryDark,
      textPrimaryColor: _textPrimaryDark,
      textSecondaryColor: _textSecondaryDark,
      accentColor: _defaultAccent, // Acento por defecto para dark
    );
  }

  // Tema Personalizado (basado en el Oscuro, pero cambia el Acento)
  static ThemeData getCustomTheme(Color customAccentColor) {
     return _buildTheme(
      brightness: Brightness.dark, // O base claro si prefieres: Brightness.light
      primaryColor: _primaryDark,
      secondaryColor: _secondaryDark,
      tertiaryColor: _tertiaryDark,
      textPrimaryColor: _textPrimaryDark,
      textSecondaryColor: _textSecondaryDark,
      accentColor: customAccentColor, // Usa el color personalizado
    );
  }

  // Función base para construir ThemeData
  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primaryColor,
    required Color secondaryColor,
    required Color tertiaryColor,
    required Color textPrimaryColor,
    required Color textSecondaryColor,
    required Color accentColor,
  }) {
    final base = brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();

    return base.copyWith(
      primaryColor: accentColor, // Color principal de Material
      scaffoldBackgroundColor: primaryColor, // Fondo principal
      cardColor: secondaryColor, // Color de tarjetas, fondos secundarios
      hintColor: textSecondaryColor, // Color para hints, textos secundarios
      dividerColor: tertiaryColor, // Color de bordes/divisores
      highlightColor: tertiaryColor.withAlpha(128), // Color al presionar
      splashColor: accentColor.withAlpha(26), // Efecto splash

      colorScheme: base.colorScheme.copyWith(
         brightness: brightness,
         primary: accentColor,
         secondary: accentColor, // Puedes definir un color secundario distinto si quieres
         surface: secondaryColor, // Fondo de componentes elevados
         error: Colors.red.shade400,
         onPrimary: Colors.white, // Texto sobre color primario
         onSecondary: Colors.white, // Texto sobre color secundario
         onSurface: textPrimaryColor, // Texto sobre 'surface'
         onError: Colors.white,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: secondaryColor,
        foregroundColor: textPrimaryColor, // Color de íconos y título
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimaryColor),
        titleTextStyle: TextStyle(color: textPrimaryColor, fontSize: 20, fontWeight: FontWeight.bold),
      ),

      textTheme: base.textTheme.apply(
        bodyColor: textPrimaryColor,
        displayColor: textPrimaryColor,
      ).copyWith(
         bodyMedium: TextStyle(color: textPrimaryColor),
         titleMedium: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
         labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // Para botones
         bodySmall: TextStyle(color: textSecondaryColor),
      ),

       buttonTheme: ButtonThemeData(
         buttonColor: accentColor,
         textTheme: ButtonTextTheme.primary,
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
       ),
       elevatedButtonTheme: ElevatedButtonThemeData(
         style: ElevatedButton.styleFrom(
           backgroundColor: accentColor,
           foregroundColor: Colors.white,
           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
           textStyle: const TextStyle(fontWeight: FontWeight.bold)
         ),
       ),

       inputDecorationTheme: InputDecorationTheme(
         filled: true,
         fillColor: tertiaryColor,
         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
         border: OutlineInputBorder(
           borderRadius: BorderRadius.circular(8),
           borderSide: BorderSide.none,
         ),
         enabledBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(8),
           borderSide: BorderSide.none,
         ),
         focusedBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(8),
           borderSide: BorderSide(color: accentColor, width: 2),
         ),
         hintStyle: TextStyle(color: textSecondaryColor.withAlpha(179)),
       ),

       listTileTheme: ListTileThemeData(
         iconColor: textSecondaryColor,
         textColor: textPrimaryColor,
         // selectedTileColor: accentColor.withOpacity(0.1), // Color al seleccionar
       ),

       drawerTheme: DrawerThemeData(
          backgroundColor: secondaryColor,
       ),

       // Define extensiones si necesitas colores específicos no cubiertos
       // extensions: <ThemeExtension<dynamic>>[
       //   AppColorExtensions(tertiary: tertiaryColor),
       // ],
    );
  }
}

// Opcional: Clase para definir colores extra si ThemeData no es suficiente
// @immutable
// class AppColorExtensions extends ThemeExtension<AppColorExtensions> {
//   const AppColorExtensions({required this.tertiary});
//   final Color? tertiary;
//   // Implementa copyWith y lerp si la usas
// }