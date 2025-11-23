// lib/screens/mantenimiento/mantenimiento_detail_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import 'package:movil/main.dart' as main_app; // Import for navigatorKey, with alias

import '../../models/mantenimiento.dart';
import '../../models/mantenimiento_foto.dart';
import '../../providers/mantenimiento_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/activo_fijo_provider.dart';
import '../../providers/empleado_provider.dart';
import '../../providers/provider_state.dart';
import '../../config/constants.dart'; // For API_BASE_URL if needed for image paths
import '../../services/api_service.dart'; // For fetching single maintenance

class MantenimientoDetailScreen extends StatefulWidget {
  final String mantenimientoId;

  const MantenimientoDetailScreen({super.key, required this.mantenimientoId});

  @override
  State<MantenimientoDetailScreen> createState() => _MantenimientoDetailScreenState();
}

class _MantenimientoDetailScreenState extends State<MantenimientoDetailScreen> {
  Mantenimiento? _mantenimiento;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMantenimientoDetails();
  }

  Future<void> _fetchMantenimientoDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final Mantenimiento fetchedMantenimiento = await ApiService().getMantenimiento(widget.mantenimientoId);
      setState(() {
        _mantenimiento = fetchedMantenimiento;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'EN_PROGRESO':
      case 'APROBADO': // Assuming approved status might exist
        return Colors.blue;
      case 'COMPLETADO':
        return Colors.green;
      case 'RECHAZADO': // Assuming rejected status might exist
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  // Re-use the dialog for employee updates from mantenimiento_screen.dart
  void _showEmployeeUpdateDialog(BuildContext context, MantenimientoProvider provider, Mantenimiento mantenimiento) {
    final formKey = GlobalKey<FormState>();
    final notasController = TextEditingController(text: mantenimiento.notasSolucion ?? '');
    String estado = mantenimiento.estado;
    final List<XFile> fotosSolucionNuevas = [];
    final imagePicker = ImagePicker();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isLoading = ValueNotifier<bool>(false);

        return AlertDialog(
          title: const Text('Actualizar Tarea'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              
              Future<void> pickImage(ImageSource source) async {
                final pickedFile = await imagePicker.pickImage(source: source, imageQuality: 80, maxWidth: 1024);
                if (pickedFile != null) {
                  setState(() {
                    fotosSolucionNuevas.add(pickedFile);
                  });
                }
              }

              void showPicker(BuildContext context) {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext bc) {
                    return SafeArea(
                      child: Wrap(
                        children: <Widget>[
                          ListTile(
                            leading: const Icon(LucideIcons.camera),
                            title: const Text('Cámara'),
                            onTap: () {
                              pickImage(ImageSource.camera);
                              Navigator.of(context).pop();
                            },
                          ),
                          ListTile(
                            leading: const Icon(LucideIcons.image),
                            title: const Text('Galería'),
                            onTap: () {
                              pickImage(ImageSource.gallery);
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              }

              Widget buildPhotoGrid(String title, List<Widget> children) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    children.isEmpty
                      ? const Text('No hay fotos.', style: TextStyle(fontStyle: FontStyle.italic))
                      : Wrap(spacing: 8.0, runSpacing: 8.0, children: children),
                    const SizedBox(height: 16),
                  ],
                );
              }

              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Activo: ${mantenimiento.activo.nombre}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Problema: ${mantenimiento.descripcionProblema}'),
                      const Divider(height: 24),

                      buildPhotoGrid('Fotos del Problema', [
                        ...mantenimiento.fotosProblema.map((photo) => Image.network(photo.fotoUrl, width: 80, height: 80, fit: BoxFit.cover)),
                      ]),

                      buildPhotoGrid('Fotos de la Solución', [
                        ...mantenimiento.fotosSolucion.map((photo) => Image.network(photo.fotoUrl, width: 80, height: 80, fit: BoxFit.cover)),
                        ...fotosSolucionNuevas.map((file) => Stack(
                          children: [
                            Image.file(File(file.path), width: 80, height: 80, fit: BoxFit.cover),
                            Positioned(
                              top: 0, right: 0,
                              child: GestureDetector(
                                onTap: () => setState(() => fotosSolucionNuevas.remove(file)),
                                child: const CircleAvatar(radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white, size: 16)),
                              ),
                            ),
                          ],
                        )),
                        GestureDetector(
                          onTap: () => showPicker(context),
                          child: Container(
                            width: 80, height: 80,
                            color: Colors.grey.shade200,
                            child: const Center(child: Icon(LucideIcons.camera)),
                          ),
                        ),
                      ]),

                      DropdownButtonFormField<String>(
                        value: estado,
                        items: const [
                          DropdownMenuItem(value: 'PENDIENTE', child: Text('Pendiente')),
                          DropdownMenuItem(value: 'EN_PROGRESO', child: Text('En Progreso')),
                          DropdownMenuItem(value: 'COMPLETADO', child: Text('Completado')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => estado = value);
                        },
                        decoration: const InputDecoration(labelText: 'Actualizar Estado'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: notasController,
                        decoration: const InputDecoration(labelText: 'Notas de Solución'),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isLoading,
              builder: (context, loading, child) {
                return ElevatedButton.icon(
                  onPressed: loading ? null : () async {
                    if (formKey.currentState!.validate()) {
                      isLoading.value = true;
                      bool success = await provider.actualizarEstadoMantenimiento(
                        mantenimiento.id,
                        estado,
                        notasController.text,
                        fotosSolucionNuevas,
                      );
                      isLoading.value = false;

                      if (dialogContext.mounted) {
                        if (success) {
                          Navigator.of(dialogContext).pop();
                          main_app.navigatorKey.currentState?.pop(); // Go back to previous screen
                        } else {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(content: Text('Error: ${provider.errorMessage}'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    }
                  },
                  icon: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(LucideIcons.check),
                  label: loading ? const Text('Guardando...') : const Text('Guardar'),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando Mantenimiento...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _mantenimiento == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error al cargar mantenimiento: $_errorMessage', textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final authProvider = context.read<AuthProvider>();
    final currentEmployeeId = authProvider.user?.empleadoId;
    final isAssignedToMe = _mantenimiento?.empleadoAsignado?.id == currentEmployeeId;
    final canUpdateAssignedMantenimiento = isAssignedToMe && authProvider.hasPermission('update_assigned_mantenimiento');
    
    // Use the provider to update the list after a successful update in the dialog
    final mantenimientoProvider = Provider.of<MantenimientoProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(_mantenimiento!.activo.nombre),
        actions: [
          if (canUpdateAssignedMantenimiento)
            IconButton(
              icon: const Icon(LucideIcons.pencil),
              tooltip: 'Actualizar Tarea',
              onPressed: () {
                _showEmployeeUpdateDialog(context, mantenimientoProvider, _mantenimiento!);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: ${_mantenimiento!.tipo}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Estado: ${_mantenimiento!.estado}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _getStatusColor(_mantenimiento!.estado)),
            ),
            const SizedBox(height: 16),
            const Text('Descripción del Problema:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_mantenimiento!.descripcionProblema),
            const SizedBox(height: 16),
            if (_mantenimiento!.notasSolucion != null && _mantenimiento!.notasSolucion!.isNotEmpty) ...[
              const Text('Notas de Solución:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_mantenimiento!.notasSolucion!),
              const SizedBox(height: 16),
            ],
            const Text('Costo:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${_mantenimiento!.costo.toStringAsFixed(2)} BOB'),
            const SizedBox(height: 16),
            if (_mantenimiento!.empleadoAsignado != null) ...[
              const Text('Asignado a:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_mantenimiento!.empleadoAsignado!.nombreCompleto),
              const SizedBox(height: 16),
            ],
            const Text('Fecha de Creación:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_mantenimiento!.fechaInicio.toLocal().toString().split('.')[0]),
            const SizedBox(height: 24),
            const Text('Fotos del Problema:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _mantenimiento!.fotosProblema.isEmpty
                ? const Text('No hay fotos del problema.')
                : Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _mantenimiento!.fotosProblema.map((foto) {
                      return Image.network(foto.fotoUrl, width: 100, height: 100, fit: BoxFit.cover);
                    }).toList(),
                  ),
            const SizedBox(height: 24),
            const Text('Fotos de la Solución:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _mantenimiento!.fotosSolucion.isEmpty
                ? const Text('No hay fotos de la solución.')
                : Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _mantenimiento!.fotosSolucion.map((foto) {
                      return Image.network(foto.fotoUrl, width: 100, height: 100, fit: BoxFit.cover);
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}
