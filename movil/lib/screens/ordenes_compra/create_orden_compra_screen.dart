// lib/screens/ordenes_compra/create_orden_compra_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/orden_compra_provider.dart';
import '../../providers/solicitud_compra_provider.dart';
import '../../providers/proveedor_provider.dart';
import '../../providers/provider_state.dart';
import '../../models/solicitud_compra.dart';
import '../../models/proveedor.dart';

class CreateOrdenCompraScreen extends StatefulWidget {
  const CreateOrdenCompraScreen({Key? key}) : super(key: key);

  @override
  _CreateOrdenCompraScreenState createState() =>
      _CreateOrdenCompraScreenState();
}

class _CreateOrdenCompraScreenState extends State<CreateOrdenCompraScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSolicitudId;
  String? _selectedProveedorId;
  final _precioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch necessary data for the dropdowns
      Provider.of<SolicitudCompraProvider>(context, listen: false).fetchSolicitudes();
      Provider.of<ProveedorProvider>(context, listen: false).fetchProveedores();
    });
  }

  @override
  void dispose() {
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'solicitud_id': _selectedSolicitudId,
        'proveedor_id': _selectedProveedorId,
        'precio_final': _precioController.text,
      };

      try {
        await Provider.of<OrdenCompraProvider>(context, listen: false)
            .createOrdenCompra(data);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orden de Compra creada con éxito')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear la orden: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Orden de Compra'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Solicitud Dropdown
              Consumer<SolicitudCompraProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // Filter for approved solicitations that don't have an order yet
                  final asequibleSolicitudes = provider.solicitudes
                      .where((s) => s.estado == 'APROBADA' && s.ordenCompraId == null)
                      .toList();

                  return DropdownButtonFormField<String>(
                    value: _selectedSolicitudId,
                    decoration: const InputDecoration(
                      labelText: 'Solicitud de Compra Aprobada',
                      border: OutlineInputBorder(),
                    ),
                    items: asequibleSolicitudes.map((SolicitudCompra solicitud) {
                      return DropdownMenuItem<String>(
                        value: solicitud.id,
                        child: Text(solicitud.descripcion),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSolicitudId = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Seleccione una solicitud' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Proveedor Dropdown
              Consumer<ProveedorProvider>(
                builder: (context, provider, child) {
                  if (provider.loadingState == LoadingState.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return DropdownButtonFormField<String>(
                    value: _selectedProveedorId,
                    decoration: const InputDecoration(
                      labelText: 'Proveedor',
                      border: OutlineInputBorder(),
                    ),
                    items: provider.proveedores.map((Proveedor proveedor) {
                      return DropdownMenuItem<String>(
                        value: proveedor.id,
                        child: Text(proveedor.nombre),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProveedorId = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Seleccione un proveedor' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Precio Final Text Field
              TextFormField(
                controller: _precioController,
                decoration: const InputDecoration(
                  labelText: 'Precio Final',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el precio final';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingrese un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Guardar Orden'),
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
