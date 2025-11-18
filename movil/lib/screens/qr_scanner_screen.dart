import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:movil/screens/asset_detail_screen.dart'; // Asumimos que esta pantalla existirá

class QrScannerScreen extends StatefulWidget {
  static const String routeName = '/qr-scanner';

  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código QR'),
        actions: [
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state as TorchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            iconSize: 32.0,
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                switch (state as CameraFacing) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            iconSize: 32.0,
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          if (!_isScanning) return; // Evitar múltiples detecciones
          setState(() {
            _isScanning = false;
          });

          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? code = barcodes.first.rawValue;
            if (code != null) {
              _handleQrCode(code);
            }
          }
        },
      ),
    );
  }

  void _handleQrCode(String qrCodeData) {
    // El formato esperado es "/app/activos-fijos/{asset_id}"
    final RegExp regex = RegExp(r'\/app\/activos-fijos\/([a-f0-9-]+)');
    final match = regex.firstMatch(qrCodeData);

    if (match != null && match.groupCount >= 1) {
      final String assetId = match.group(1)!;
      Navigator.of(context).pushReplacementNamed(
        AssetDetailScreen.routeName,
        arguments: assetId,
      );
    } else {
      // Si el formato no coincide, mostrar un error o mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código QR no válido para un activo fijo.')),
      );
      setState(() {
        _isScanning = true; // Reanudar escaneo si el QR no es válido
      });
    }
  }
}
