// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
// --- [CORRECCIÓN] Importar el helper ---
import '../providers/theme_provider.dart' show ThemeProvider, colorToHexString;
// --- [FIN CORRECCIÓN] ---

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Función para mostrar el Color Picker
    void showColorPicker() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          Color pickerColor = themeProvider.customColor;
          return AlertDialog(
            title: const Text('Elige tu Color Primario'),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: pickerColor,
                onColorChanged: (Color color) {
                   pickerColor = color;
                },
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Guardar'),
                onPressed: () {
                  // --- [CORRECCIÓN] Usar setCustomColor ---
                  // setCustomTheme establecía el modo Y el color,
                  // setCustomColor es más directo y también actualiza el modo.
                  themeProvider.setCustomColor(pickerColor);
                  // --- [FIN CORRECCIÓN] ---
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalizar Apariencia'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          // --- Selector de Modo de Tema ---
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modo de Tema',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  RadioListTile<ThemeMode>(
                    title: const Text('Claro'),
                    value: ThemeMode.light,
                    // --- [CORRECCIÓN] Lógica del groupValue ---
                    // Si es 'system' (custom), ningún radio debe estar marcado
                    groupValue: themeProvider.themeMode == ThemeMode.system ? null : themeProvider.themeMode,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (ThemeMode? value) {
                      if (value != null) themeProvider.setThemeMode(value);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Oscuro'),
                    value: ThemeMode.dark,
                    groupValue: themeProvider.themeMode == ThemeMode.system ? null : themeProvider.themeMode,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (ThemeMode? value) {
                      if (value != null) themeProvider.setThemeMode(value);
                    },
                  ),
                   ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Personalizado'),
                      trailing: Icon(
                        themeProvider.themeMode == ThemeMode.system
                         ? Icons.radio_button_checked
                         : Icons.radio_button_unchecked,
                        color: themeProvider.themeMode == ThemeMode.system
                         ? Theme.of(context).colorScheme.primary
                         : Theme.of(context).hintColor,
                      ),
                      onTap: showColorPicker,
                   ),
                    if (themeProvider.themeMode == ThemeMode.system)
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                        child: Row(
                          children: [
                             Text('Color actual:', style: Theme.of(context).textTheme.bodySmall),
                             const SizedBox(width: 8),
                             Container(
                               width: 24,
                               height: 24,
                               decoration: BoxDecoration(
                                 color: themeProvider.customColor,
                                 borderRadius: BorderRadius.circular(4),
                                 border: Border.all(color: Theme.of(context).dividerColor),
                               ),
                             ),
                             const SizedBox(width: 8),
                             // --- [CORRECCIÓN] Usar el helper importado ---
                             Text(
                               colorToHexString(themeProvider.customColor),
                               style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace')
                             ),
                             // --- [FIN CORRECCIÓN] ---
                          ],
                        ),
                      )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // --- Efectos Visuales (Glow) ---
           Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile(
              title: const Text('Activar brillo de neón'),
              subtitle: Text(
                'Añade un efecto de brillo sutil.',
                 style: Theme.of(context).textTheme.bodySmall,
              ),
              value: themeProvider.glowEnabled,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (bool value) {
                themeProvider.setGlowEnabled(value);
              },
              secondary: const Icon(LucideIcons.sparkles),
            ),
          ),
        ],
      ),
    );
  }
}