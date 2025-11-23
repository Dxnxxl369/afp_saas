// lib/screens/mantenimiento/mantenimiento_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/mantenimiento.dart';
import '../../models/mantenimiento_foto.dart';
import '../../providers/mantenimiento_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/activo_fijo_provider.dart';
import '../../providers/empleado_provider.dart';
import '../../models/activo_fijo.dart';
import '../../models/empleado.dart';
import '../../providers/provider_state.dart';

class MantenimientoScreen extends StatefulWidget {
  const MantenimientoScreen({super.key});

  @override
  State<MantenimientoScreen> createState() => _MantenimientoScreenState();
}

class _MantenimientoScreenState extends State<MantenimientoScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<MantenimientoProvider>(context, listen: false);
      if (provider.loadingState == LoadingState.idle) {
        provider.fetchMantenimientos();
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'EN_PROGRESO':
        return Colors.blue;
      case 'COMPLETADO':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final canManage = authProvider.hasPermission('manage_mantenimiento');
    final currentEmployeeId = authProvider.user?.empleadoId;

    return Scaffold(
      body: Consumer<MantenimientoProvider>(
        builder: (context, provider, child) {
          if (provider.loadingState == LoadingState.loading && provider.mantenimientos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.loadingState == LoadingState.error) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: ${provider.errorMessage}', textAlign: TextAlign.center),
            ));
          }
          if (provider.loadingState == LoadingState.success && provider.mantenimientos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No hay mantenimientos para mostrar.'),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                     icon: const Icon(LucideIcons.refreshCw, size: 16),
                     label: const Text('Recargar'),
                     onPressed: () => provider.fetchMantenimientos(),
                  )
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.fetchMantenimientos,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: provider.mantenimientos.length,
              itemBuilder: (context, index) {
                final mantenimiento = provider.mantenimientos[index];
                final isAssignedToMe = mantenimiento.empleadoAsignado?.id == currentEmployeeId;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(mantenimiento.estado),
                      foregroundColor: Colors.white,
                      child: const Icon(LucideIcons.wrench, size: 20),
                    ),
                    title: Text(mantenimiento.activo.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mantenimiento.descripcionProblema, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(
                          mantenimiento.estado,
                          style: TextStyle(color: _getStatusColor(mantenimiento.estado), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: canManage
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.pencil),
                                tooltip: 'Editar (Admin)',
                                onPressed: () {
                                  _showMantenimientoDialog(context, provider, mantenimiento: mantenimiento);
                                },
                              ),
                              IconButton(
                                icon: Icon(LucideIcons.trash2, color: Theme.of(context).colorScheme.error),
                                tooltip: 'Eliminar',
                                onPressed: () {
                                  _showDeleteConfirmDialog(context, provider, mantenimiento.id);
                                },
                              ),
                            ],
                          )
                        : isAssignedToMe 
                          ? IconButton(
                              icon: const Icon(LucideIcons.pencil),
                              tooltip: 'Actualizar Tarea',
                              onPressed: () {
                                _showEmployeeUpdateDialog(context, provider, mantenimiento);
                              },
                            )
                          : null,
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () {
                _showMantenimientoDialog(context, Provider.of<MantenimientoProvider>(context, listen: false));
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: const Icon(LucideIcons.plus),
            )
          : null,
    );
  }

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
                return ElevatedButton(
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
                        } else {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(content: Text('Error: ${provider.errorMessage}'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    }
                  },
                  child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showMantenimientoDialog(BuildContext context, MantenimientoProvider provider, {Mantenimiento? mantenimiento}) {
    final isEditing = mantenimiento != null;
    final formKey = GlobalKey<FormState>();

    String? selectedActivoId = mantenimiento?.activo.id;
    String? selectedEmpleadoId = mantenimiento?.empleadoAsignado?.id;
    String tipo = mantenimiento?.tipo ?? 'CORRECTIVO';
    String estado = mantenimiento?.estado ?? 'PENDIENTE';
    final descProblemaController = TextEditingController(text: mantenimiento?.descripcionProblema ?? '');
    final notasSolucionController = TextEditingController(text: mantenimiento?.notasSolucion ?? '');
    final costoController = TextEditingController(text: mantenimiento?.costo.toString() ?? '0.0');

    // State for photos
    final List<MantenimientoFoto> currentPhotos = List.from(mantenimiento?.fotosProblema ?? []);
    final List<XFile> newPhotos = [];
    final List<String> deletedPhotoIds = [];
    final imagePicker = ImagePicker();

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Fetching data for dropdowns
        final activoProvider = Provider.of<ActivoFijoProvider>(context, listen: false);
        if(activoProvider.loadingState == LoadingState.idle) activoProvider.fetchActivos();
        
        final empleadoProvider = Provider.of<EmpleadoProvider>(context, listen: false);
        if(empleadoProvider.loadingState == LoadingState.idle) empleadoProvider.fetchEmpleados();

        final isLoading = ValueNotifier<bool>(false);
        
        return AlertDialog(
          title: Text(isEditing ? 'Editar Mantenimiento' : 'Nuevo Mantenimiento'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {

              Future<void> pickImage(ImageSource source) async {
                if (newPhotos.length + currentPhotos.length >= 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No se pueden subir más de 3 fotos.'), backgroundColor: Colors.red),
                  );
                  return;
                }
                final pickedFile = await imagePicker.pickImage(source: source, imageQuality: 80, maxWidth: 1024);
                if (pickedFile != null) {
                  setState(() {
                    newPhotos.add(pickedFile);
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

              Widget photoGrid() {
                return Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    ...currentPhotos.map((photo) => Stack(
                      children: [
                        Image.network(photo.fotoUrl, width: 80, height: 80, fit: BoxFit.cover),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                deletedPhotoIds.add(photo.id);
                                currentPhotos.remove(photo);
                              });
                            },
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    )),
                    ...newPhotos.map((file) => Stack(
                      children: [
                        Image.file(File(file.path), width: 80, height: 80, fit: BoxFit.cover),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                newPhotos.remove(file);
                              });
                            },
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    )),
                                          if (newPhotos.length + currentPhotos.length < 3)
                                          GestureDetector(
                                            onTap: () => showPicker(context),
                                            child: Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey.shade200,
                                              child: const Center(child: Icon(LucideIcons.camera)),
                                            ),
                                          ),
                                      ],
                                    );              }

              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ... (Dropdowns and TextFields remain the same)
                      Consumer<ActivoFijoProvider>(
                        builder: (context, provider, _) {
                          if (provider.loadingState == LoadingState.loading) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          return DropdownButtonFormField<String>(
                            value: selectedActivoId,
                            hint: const Text('Seleccionar Activo'),
                            items: provider.activos.map((ActivoFijo activo) {
                              return DropdownMenuItem<String>(
                                value: activo.id,
                                child: Text(activo.nombre),
                              );
                            }).toList(),
                            onChanged: (value) {
                              selectedActivoId = value;
                            },
                            validator: (value) => value == null ? 'Seleccione un activo' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Consumer<EmpleadoProvider>(
                        builder: (context, provider, _) {
                          if (provider.loadingState == LoadingState.loading) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          return DropdownButtonFormField<String>(
                            value: selectedEmpleadoId,
                            hint: const Text('Asignar a Empleado'),
                            items: provider.empleados.map((Empleado empleado) {
                              return DropdownMenuItem<String>(
                                value: empleado.id,
                                child: Text(empleado.nombreCompleto),
                              );
                            }).toList(),
                            onChanged: (value) {
                              selectedEmpleadoId = value;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: tipo,
                        items: const [
                          DropdownMenuItem(value: 'PREVENTIVO', child: Text('Preventivo')),
                          DropdownMenuItem(value: 'CORRECTIVO', child: Text('Correctivo')),
                        ],
                        onChanged: (value) {
                          if (value != null) tipo = value;
                        },
                        decoration: const InputDecoration(labelText: 'Tipo'),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: estado,
                        items: const [
                          DropdownMenuItem(value: 'PENDIENTE', child: Text('Pendiente')),
                          DropdownMenuItem(value: 'EN_PROGRESO', child: Text('En Progreso')),
                          DropdownMenuItem(value: 'COMPLETADO', child: Text('Completado')),
                        ],
                        onChanged: (value) {
                          if (value != null) estado = value;
                        },
                        decoration: const InputDecoration(labelText: 'Estado'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descProblemaController,
                        decoration: const InputDecoration(labelText: 'Descripción del Problema'),
                        validator: (value) => (value == null || value.isEmpty) ? 'La descripción es requerida' : null,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: notasSolucionController,
                        decoration: const InputDecoration(labelText: 'Notas de Solución (Opcional)'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: costoController,
                        decoration: const InputDecoration(labelText: 'Costo'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'El costo es requerido';
                          if (double.tryParse(value) == null) return 'Ingrese un número válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text('Fotos', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      photoGrid(),
                    ],
                  ),
                ),
              );
            }
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isLoading,
              builder: (context, loading, child) {
                return ElevatedButton(
                  onPressed: loading ? null : () async {
                    if (formKey.currentState!.validate()) {
                      isLoading.value = true;
                      
                      final data = {
                        'activo_id': selectedActivoId,
                        'empleado_asignado_id': selectedEmpleadoId,
                        'tipo': tipo,
                        'estado': estado,
                        'descripcion_problema': descProblemaController.text,
                        'notas_solucion': notasSolucionController.text,
                        'costo': costoController.text,
                      };

                      bool success;
                      if (isEditing) {
                        success = await provider.updateMantenimiento(mantenimiento.id, data, newPhotos, deletedPhotoIds);
                      } else {
                        success = await provider.createMantenimiento(data, newPhotos);
                      }
                      
                      isLoading.value = false;

                      if (context.mounted) {
                        if (success) {
                          Navigator.of(dialogContext).pop();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Error: ${provider.errorMessage}'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    }
                  },
                  child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, MantenimientoProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) {
        final isLoading = ValueNotifier<bool>(false);
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text('¿Estás seguro de que quieres eliminar este mantenimiento?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isLoading,
              builder: (context, loading, child) {
                return TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: loading ? null : () async {
                    isLoading.value = true;
                    bool success = await provider.deleteMantenimiento(id);
                    isLoading.value = false;
                     if (context.mounted) {
                        Navigator.of(context).pop();
                         if (!success) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text('Error: ${provider.errorMessage}'), backgroundColor: Colors.red),
                            );
                         }
                     }
                  },
                  child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)) : const Text('Eliminar'),
                );
              },
            ),
          ],
        );
      },
    );
  }
}