import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:movil/models/activo_fijo.dart';
import 'package:movil/providers/activo_fijo_provider.dart';
import 'package:movil/providers/auth_provider.dart';
import 'package:movil/screens/mantenimiento/mantenimiento_dialog.dart';

class AssetDetailScreen extends StatelessWidget {
  static const String routeName = '/asset-detail';
  final String assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  @override
  Widget build(BuildContext context) {
    final asset = Provider.of<ActivoFijoProvider>(context, listen: false)
        .findById(assetId);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final canManageMantenimiento = authProvider.hasPermission('manage_mantenimiento');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Activo'),
      ),
      body: asset == null
          ? const Center(
              child: Text('Activo no encontrado.'),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (asset.fotoActivoUrl != null && asset.fotoActivoUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Center(child: Image.network(asset.fotoActivoUrl!)),
                    ),
                  Text(
                    asset.nombre,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Código Interno', asset.codigoInterno),
                  _buildDetailRow('Valor Actual', '\$${asset.valorActual.toStringAsFixed(2)}'),
                  _buildDetailRow('Fecha de Adquisición', DateFormat.yMd().format(asset.fechaAdquisicion.toLocal())),
                  _buildDetailRow('Vida Útil', '${asset.vidaUtil} años'),
                  _buildDetailRow('Categoría', asset.categoriaNombre),
                  _buildDetailRow('Estado', asset.estado.nombre),
                  _buildDetailRow('Ubicación', asset.ubicacionNombre ?? 'N/A'),
                  _buildDetailRow('Departamento', asset.departamentoNombre ?? 'N/A'),
                  _buildDetailRow('Proveedor', asset.proveedorNombre ?? 'N/A'),
                ],
              ),
            ),
      floatingActionButton: canManageMantenimiento && asset != null
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.build),
              label: const Text('Asignar Mantenimiento'),
              onPressed: () {
                showMantenimientoDialog(context, initialAssetId: asset.id);
              },
            )
          : null,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
