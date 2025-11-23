// lib/screens/qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:movil/providers/activo_fijo_provider.dart';
import 'package:movil/models/activo_fijo.dart';
import 'asset_detail_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({Key? key}) : super(key: key);

  @override
  _QrScannerScreenState createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? qrText = barcodes.first.rawValue;
      if (qrText != null && qrText.isNotEmpty) {
        debugPrint('QR Code Detected: $qrText');

        // Parse the code to find the asset
        final String? assetCode = _parseAssetCode(qrText);
        if (assetCode != null) {
          final provider = Provider.of<ActivoFijoProvider>(context, listen: false);
          // Ensure activos are loaded
          if (provider.activos.isEmpty) {
             provider.fetchActivos().then((_) => _findAndNavigate(assetCode));
          } else {
             _findAndNavigate(assetCode);
          }
        } else {
          _showErrorAndResume('El código QR no tiene el formato esperado.');
        }
      } else {
        _showErrorAndResume('Código QR vacío o inválido.');
      }
    }
  }
  
  String? _parseAssetCode(String qrText) {
    final RegExp regExp = RegExp(r'Código:\s*([A-Za-z0-9-]+)');
    final match = regExp.firstMatch(qrText);
    return match?.group(1);
  }

  void _findAndNavigate(String assetCode) {
    final provider = Provider.of<ActivoFijoProvider>(context, listen: false);
    ActivoFijo? asset;
    try {
      asset = provider.activos.firstWhere((a) => a.codigoInterno == assetCode);
    } catch (e) {
      asset = null;
    }

    if (asset != null) {
      // Navigate to detail screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => AssetDetailScreen(assetId: asset!.id),
        ),
      );
    } else {
      _showErrorAndResume('Activo con código "$assetCode" no encontrado.');
    }
  }

  void _showErrorAndResume(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
    // Resume scanning after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código QR de Activo'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleDetection,
          ),
          // Overlay UI
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}