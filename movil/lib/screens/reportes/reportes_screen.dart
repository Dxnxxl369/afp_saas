// movil/lib/screens/reportes/reportes_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart'; // For speech-to-text functionality
import 'package:speech_to_text/speech_recognition_result.dart'; // Import for SpeechRecognitionResult

import '../../providers/reportes_provider.dart';
import '../../models/reporte_activo.dart'; // For the data model

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  
  @override
  void initState() {
    super.initState();
    _initSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportesProvider>(context, listen: false).fetchReport();
    });
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    _lastWords = ''; // Clear previous words
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 5), // Listen for 5 seconds
      localeId: 'es_ES', // Spanish locale
      cancelOnError: true,
      partialResults: true,
    );
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });
    if (result.finalResult) {
      _processVoiceCommand(_lastWords);
    }
  }

  void _processVoiceCommand(String command) {
    // --- Lógica para interpretar el comando de voz y añadir pastillas ---
    // Ejemplos:
    // "marketing" -> departamento:marketing
    // "valor mayor a diez mil" -> valor>10000
    // "nombre laptop" -> nombre:laptop
    
    // Convertir a minúsculas para facilitar el procesamiento
    command = command.toLowerCase();
    final provider = Provider.of<ReportesProvider>(context, listen: false);

    // Simple keyword-based parsing for demonstration
    if (command.contains('departamento')) {
      // Intenta extraer el nombre del departamento
      final match = RegExp(r'departamento\s+(\w+)').firstMatch(command);
      if (match != null && match.group(1) != null) {
        provider.addFilter('departamento:${match.group(1)!}');
      }
    } else if (command.contains('valor mayor a')) {
      // Extrae el valor numérico
      final match = RegExp(r'valor mayor a (\d+)').firstMatch(command.replaceAll(' ', ''));
      if (match != null && match.group(1) != null) {
        provider.addFilter('valor>${match.group(1)!}');
      }
    } else if (command.contains('nombre')) {
      // Extrae el nombre del activo
      final match = RegExp(r'nombre\s+(\w+)').firstMatch(command);
      if (match != null && match.group(1) != null) {
        provider.addFilter('nombre:${match.group(1)!}');
      }
    } else {
      // Si no se reconoce un patrón específico, añadir como filtro general (búsqueda de texto)
      provider.addFilter(command);
    }
    _lastWords = ''; // Clear last words after processing
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes Dinámicos'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCcw),
            onPressed: () {
              Provider.of<ReportesProvider>(context, listen: false).fetchReport();
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2),
            tooltip: 'Limpiar Filtros',
            onPressed: () {
              Provider.of<ReportesProvider>(context, listen: false).clearFilters();
            },
          ),
        ],
      ),
      body: Consumer<ReportesProvider>(
        builder: (context, reportesProvider, child) {
          if (reportesProvider.isLoading && reportesProvider.reporteData.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (reportesProvider.errorMessage != null) {
            return Center(
              child: Text('Error: ${reportesProvider.errorMessage}'),
            );
          }
          // Display filter chips
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: reportesProvider.filters.map((filter) {
                    return Chip(
                      label: Text(filter),
                      onDeleted: () {
                        reportesProvider.removeFilter(filter);
                      },
                    );
                  }).toList(),
                ),
              ),
              // Display recognized speech for debugging
              if (_lastWords.isNotEmpty && _speechToText.isListening)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('Escuchando: "$_lastWords"', style: TextStyle(fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.secondary)),
                ),
              const Divider(),
              // Report Data Table (basic implementation)
              Expanded(
                child: reportesProvider.reporteData.isEmpty
                    ? const Center(child: Text('No hay datos para mostrar con los filtros actuales.'))
                    : ListView.builder(
                        itemCount: reportesProvider.reporteData.length,
                        itemBuilder: (context, index) {
                          final activo = reportesProvider.reporteData[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              title: Text(activo.nombre),
                              subtitle: Text('Código: ${activo.codigoInterno} | Valor: ${activo.valorActual.toStringAsFixed(2)} | Depto: ${activo.departamentoNombre}'),
                              // Add more details or navigate to active detail screen
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _speechToText.isListening ? _stopListening : _startListening,
        tooltip: 'Hablar para filtrar',
        child: Icon(_speechToText.isListening ? LucideIcons.micOff : LucideIcons.mic),
      ),
    );
  }
}
