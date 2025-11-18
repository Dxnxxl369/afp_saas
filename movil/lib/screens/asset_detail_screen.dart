import 'package:flutter/material.dart';
import 'package:movil/models/activo_fijo.dart'; // Asumimos que este modelo existirá
import 'package:movil/services/asset_service.dart'; // Asumimos que este servicio existirá

class AssetDetailScreen extends StatefulWidget {
  static const String routeName = '/asset-detail';
  final String assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  late Future<ActivoFijo> _assetFuture;

  @override
  void initState() {
    super.initState();
    _assetFuture = AssetService().fetchAssetDetails(widget.assetId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Activo'),
      ),
      body: FutureBuilder<ActivoFijo>(
        future: _assetFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final ActivoFijo asset = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.nombre,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Código Interno: ${asset.codigoInterno}'),
                  Text('Valor Actual: ${asset.valorActual.toStringAsFixed(2)}'),
                  Text('Fecha de Adquisición: ${asset.fechaAdquisicion.toLocal().split(' ')[0]}'),
                  Text('Vida Útil: ${asset.vidaUtil} años'),
                  Text('Categoría: ${asset.categoriaNombre}'),
                  Text('Estado: ${asset.estadoNombre}'),
                  Text('Ubicación: ${asset.ubicacionNombre}'),
                  Text('Departamento: ${asset.departamentoNombre ?? 'N/A'}'),
                  Text('Proveedor: ${asset.proveedorNombre ?? 'N/A'}'),
                  // Aquí puedes añadir más detalles o la imagen si la tienes
                  if (asset.fotoActivoUrl != null && asset.fotoActivoUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Image.network(asset.fotoActivoUrl!),
                    ),
                ],
              ),
            );
          } else {
            return const Center(child: Text('No se encontraron detalles del activo.'));
          }
        },
      ),
    );
  }
}
