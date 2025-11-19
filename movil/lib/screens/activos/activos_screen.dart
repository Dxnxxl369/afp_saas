// lib/screens/activos/activos_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // Para formatear fechas y números

import '../../providers/activo_fijo_provider.dart';
import '../../providers/departamento_provider.dart';
import '../../providers/categoria_activo_provider.dart';
import '../../providers/estados_provider.dart';
import '../../providers/ubicaciones_provider.dart';
import '../../providers/proveedor_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/provider_state.dart';
import '../../models/activo_fijo.dart';
import '../../models/departamento.dart';
import '../../models/categoria_activo.dart';
import '../../models/estado.dart';
import '../../models/ubicacion.dart';
import '../../models/proveedor.dart';

class ActivosScreen extends StatefulWidget {
  const ActivosScreen({super.key});

  @override
  State<ActivosScreen> createState() => _ActivosScreenState();
}

class _ActivosScreenState extends State<ActivosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivoFijoProvider>().fetchActivos();
      context.read<DepartamentoProvider>().fetchDepartamentos();
      context.read<CategoriaActivoProvider>().fetchCategoriasActivo();
      context.read<EstadosProvider>().fetchEstados();
      context.read<UbicacionesProvider>().fetchUbicaciones();
      context.read<ProveedorProvider>().fetchProveedores();
    });
  }

  @override
  Widget build(BuildContext context) {
    final canManage = context.read<AuthProvider>().hasPermission('manage_activo');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activos Fijos'),
      ),
      body: Consumer<ActivoFijoProvider>(
        builder: (context, activoProvider, child) {
          if (activoProvider.loadingState == LoadingState.loading && activoProvider.activos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (activoProvider.loadingState == LoadingState.error) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: ${activoProvider.errorMessage}', textAlign: TextAlign.center),
            ));
          }

          if (activoProvider.loadingState == LoadingState.success && activoProvider.activos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No hay activos fijos para mostrar.'),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                     icon: const Icon(LucideIcons.refreshCw, size: 16),
                     label: const Text('Recargar'),
                     onPressed: () => activoProvider.fetchActivos(),
                  )
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => activoProvider.fetchActivos(),
            child: ListView.builder(
              itemCount: activoProvider.activos.length,
              itemBuilder: (context, index) {
                final activo = activoProvider.activos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _showActivoDetailDialog(context, activo),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Foto del Activo
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: activo.fotoActivoUrl != null && activo.fotoActivoUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: activo.fotoActivoUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                    errorWidget: (context, url, error) => const Icon(LucideIcons.imageOff, size: 30, color: Colors.grey),
                                  )
                                : const Center(child: Icon(LucideIcons.image, size: 30, color: Colors.grey)),
                          ),
                          const SizedBox(width: 12),
                          // Detalles del Activo
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activo.nombre,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text('Código: ${activo.codigoInterno}', style: Theme.of(context).textTheme.bodySmall),
                                Text('Valor: \$${NumberFormat('#,##0.00').format(activo.valorActual)}', style: Theme.of(context).textTheme.bodySmall),
                                Text('Estado: ${activo.estadoNombre}', style: Theme.of(context).textTheme.bodySmall),
                                if (activo.departamentoNombre != null)
                                  Text('Dpto: ${activo.departamentoNombre}', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          // Acciones (Editar/Eliminar)
                          if (canManage)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(LucideIcons.pencil, size: 20),
                                  tooltip: 'Editar',
                                  onPressed: () {
                                    _showActivoDialog(context, activoProvider, activo: activo);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(LucideIcons.trash2, size: 20, color: Theme.of(context).colorScheme.error),
                                  tooltip: 'Eliminar',
                                  onPressed: () {
                                    _showDeleteConfirmDialog(context, activoProvider, activo.id);
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
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
                _showActivoDialog(context, Provider.of<ActivoFijoProvider>(context, listen: false));
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: const Icon(LucideIcons.plus),
            )
          : null,
    );
  }

  void _showActivoDialog(BuildContext context, ActivoFijoProvider activoProvider, {ActivoFijo? activo}) {
    final isEditing = activo != null;
    final formKey = GlobalKey<FormState>();
    final ImagePicker _picker = ImagePicker();

    final nombreController = TextEditingController(text: activo?.nombre ?? '');
    final codigoInternoController = TextEditingController(text: activo?.codigoInterno ?? '');
    final fechaAdquisicionController = TextEditingController(text: activo != null ? DateFormat('yyyy-MM-dd').format(activo.fechaAdquisicion) : '');
    final valorActualController = TextEditingController(text: activo?.valorActual.toString() ?? '');
    final vidaUtilController = TextEditingController(text: activo?.vidaUtil.toString() ?? '');

    String? selectedDepartamentoId = activo?.departamentoId;
    String? selectedCategoriaId = activo?.categoriaId;
    String? selectedEstadoId = activo?.estadoId;
    String? selectedUbicacionId = activo?.ubicacionId;
    String? selectedProveedorId = activo?.proveedorId;

    XFile? _pickedImage;
    bool _deleteExistingPhoto = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isLoading = ValueNotifier<bool>(false);
        
        return AlertDialog(
          title: Text(isEditing ? 'Editar Activo Fijo' : 'Nuevo Activo Fijo'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreController,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (value) => (value == null || value.isEmpty) ? 'El nombre es requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: codigoInternoController,
                        decoration: const InputDecoration(labelText: 'Código Interno'),
                        validator: (value) => (value == null || value.isEmpty) ? 'El código interno es requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: fechaAdquisicionController,
                        decoration: const InputDecoration(
                          labelText: 'Fecha de Adquisición (YYYY-MM-DD)',
                          suffixIcon: Icon(LucideIcons.calendar),
                        ),
                        readOnly: true,
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: isEditing ? activo!.fechaAdquisicion : DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              fechaAdquisicionController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                            });
                          }
                        },
                        validator: (value) => (value == null || value.isEmpty) ? 'La fecha es requerida' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: valorActualController,
                        decoration: const InputDecoration(labelText: 'Valor Actual'),
                        keyboardType: TextInputType.number,
                        validator: (value) => (value == null || value.isEmpty) ? 'El valor es requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: vidaUtilController,
                        decoration: const InputDecoration(labelText: 'Vida Útil (años)'),
                        keyboardType: TextInputType.number,
                        validator: (value) => (value == null || value.isEmpty) ? 'La vida útil es requerida' : null,
                      ),
                      const SizedBox(height: 16),
                      Consumer<DepartamentoProvider>(
                        builder: (context, depProvider, child) {
                          if (depProvider.loadingState == LoadingState.loading) {
                            return const CircularProgressIndicator();
                          }
                          return DropdownButtonFormField<String>(
                            value: selectedDepartamentoId,
                            decoration: const InputDecoration(labelText: 'Departamento'),
                            items: depProvider.departamentos.map((dep) {
                              return DropdownMenuItem(
                                value: dep.id,
                                child: Text(dep.nombre),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedDepartamentoId = value;
                              });
                            },
                            validator: (value) => (value == null || value.isEmpty) ? 'Departamento requerido' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Consumer<CategoriaActivoProvider>(
                        builder: (context, catProvider, child) {
                          if (catProvider.loadingState == LoadingState.loading) {
                            return const CircularProgressIndicator();
                          }
                          return DropdownButtonFormField<String>(
                            value: selectedCategoriaId,
                            decoration: const InputDecoration(labelText: 'Categoría'),
                            items: catProvider.categorias.map((cat) {
                              return DropdownMenuItem(
                                value: cat.id,
                                child: Text(cat.nombre),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedCategoriaId = value;
                              });
                            },
                            validator: (value) => (value == null || value.isEmpty) ? 'Categoría requerida' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Consumer<EstadosProvider>(
                        builder: (context, estProvider, child) {
                          if (estProvider.loadingState == LoadingState.loading) {
                            return const CircularProgressIndicator();
                          }
                          return DropdownButtonFormField<String>(
                            value: selectedEstadoId,
                            decoration: const InputDecoration(labelText: 'Estado'),
                            items: estProvider.estados.map((est) {
                              return DropdownMenuItem(
                                value: est.id,
                                child: Text(est.nombre),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedEstadoId = value;
                              });
                            },
                            validator: (value) => (value == null || value.isEmpty) ? 'Estado requerido' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Consumer<UbicacionesProvider>(
                        builder: (context, ubiProvider, child) {
                          if (ubiProvider.loadingState == LoadingState.loading) {
                            return const CircularProgressIndicator();
                          }
                          return DropdownButtonFormField<String>(
                            value: selectedUbicacionId,
                            decoration: const InputDecoration(labelText: 'Ubicación'),
                            items: ubiProvider.ubicaciones.map((ubi) {
                              return DropdownMenuItem(
                                value: ubi.id,
                                child: Text(ubi.nombre),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedUbicacionId = value;
                              });
                            },
                            validator: (value) => (value == null || value.isEmpty) ? 'Ubicación requerida' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Consumer<ProveedorProvider>(
                        builder: (context, provProvider, child) {
                          if (provProvider.loadingState == LoadingState.loading) {
                            return const CircularProgressIndicator();
                          }
                          return DropdownButtonFormField<String>(
                            value: selectedProveedorId,
                            decoration: const InputDecoration(labelText: 'Proveedor (Opcional)'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Ninguno')),
                              ...provProvider.proveedores.map((prov) {
                                return DropdownMenuItem(
                                  value: prov.id,
                                  child: Text(prov.nombre),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedProveedorId = value;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // Sección de Foto del Activo
                      Text('Foto del Activo (Opcional)', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (_pickedImage != null)
                            Image.network(_pickedImage!.path, width: 100, height: 100, fit: BoxFit.cover)
                          else if (isEditing && activo.fotoActivoUrl != null && activo.fotoActivoUrl!.isNotEmpty && !_deleteExistingPhoto)
                            CachedNetworkImage(
                              imageUrl: activo.fotoActivoUrl!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              errorWidget: (context, url, error) => const Icon(LucideIcons.imageOff, size: 30, color: Colors.grey),
                            )
                          else
                            Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[200],
                              child: const Icon(LucideIcons.image, size: 40, color: Colors.grey),
                            ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(LucideIcons.camera),
                                label: const Text('Seleccionar Foto'),
                                onPressed: () async {
                                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                                  if (image != null) {
                                    setState(() {
                                      _pickedImage = image;
                                      _deleteExistingPhoto = false;
                                    });
                                  }
                                },
                              ),
                              if (isEditing && activo.fotoActivoUrl != null && activo.fotoActivoUrl!.isNotEmpty)
                                TextButton.icon(
                                  icon: Icon(LucideIcons.trash2, color: Theme.of(context).colorScheme.error),
                                  label: Text('Eliminar Foto Actual', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                                  onPressed: () {
                                    setState(() {
                                      _pickedImage = null;
                                      _deleteExistingPhoto = true;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ],
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
                      
                      final data = {
                        'nombre': nombreController.text,
                        'codigo_interno': codigoInternoController.text,
                        'fecha_adquisicion': fechaAdquisicionController.text,
                        'valor_actual': double.parse(valorActualController.text),
                        'vida_util': int.parse(vidaUtilController.text),
                        'departamento': selectedDepartamentoId,
                        'categoria': selectedCategoriaId,
                        'estado': selectedEstadoId,
                        'ubicacion': selectedUbicacionId,
                        'proveedor': selectedProveedorId,
                      };

                      bool success;
                      if (isEditing) {
                        success = await activoProvider.updateActivo(
                          activo.id,
                          data,
                          fotoActivo: _pickedImage,
                          deleteExistingPhoto: _deleteExistingPhoto,
                        );
                      } else {
                        success = await activoProvider.createActivo(
                          data,
                          fotoActivo: _pickedImage,
                        );
                      }
                      
                      isLoading.value = false;

                      if (context.mounted) {
                        if (success) {
                          Navigator.of(dialogContext).pop();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Error: ${activoProvider.errorMessage}'), backgroundColor: Colors.red),
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

  void _showDeleteConfirmDialog(BuildContext context, ActivoFijoProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) {
        final isLoading = ValueNotifier<bool>(false);
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text('¿Estás seguro de que quieres eliminar este activo fijo?'),
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
                    bool success = await provider.deleteActivo(id);
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

  void _showActivoDetailDialog(BuildContext context, ActivoFijo activo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(activo.nombre),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (activo.fotoActivoUrl != null && activo.fotoActivoUrl!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: activo.fotoActivoUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Icon(LucideIcons.imageOff, size: 50),
                  ),
                const SizedBox(height: 16),
                _buildDetailRow('Código Interno:', activo.codigoInterno),
                _buildDetailRow('Fecha Adquisición:', DateFormat('dd/MM/yyyy').format(activo.fechaAdquisicion)),
                _buildDetailRow('Valor Actual:', '\$${NumberFormat('#,##0.00').format(activo.valorActual)}'),
                _buildDetailRow('Vida Útil:', '${activo.vidaUtil} años'),
                if (activo.departamentoNombre != null) _buildDetailRow('Departamento:', activo.departamentoNombre!),
                _buildDetailRow('Categoría:', activo.categoriaNombre),
                _buildDetailRow('Estado:', activo.estadoNombre),
                if (activo.ubicacionNombre != null) _buildDetailRow('Ubicación:', activo.ubicacionNombre!),
                if (activo.proveedorNombre != null) _buildDetailRow('Proveedor:', activo.proveedorNombre!),
                const SizedBox(height: 16),
                // TODO: Implementar generación de QR si es necesario, por ahora solo un placeholder
                Text('QR Code (Placeholder): ${activo.id}', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
