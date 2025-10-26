import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() {
      _isProcessing = true;
    });

    // Parse QR code - expecting format: "musicshare://playlist/{playlistId}"
    if (code.startsWith('musicshare://playlist/')) {
      final playlistId = code.replaceFirst('musicshare://playlist/', '');
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Playlist QR kodu bulundu!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Navigate to playlist loader page
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        context.pop();
        context.push('/playlist/$playlistId');
      }
    } else {
      // Invalid QR code
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Geçersiz QR kod!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
        
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('QR Kod Tara'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _controller.torchEnabled ? Icons.flash_on : Icons.flash_off,
            ),
            onPressed: () {
              _controller.toggleTorch();
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () {
              _controller.switchCamera();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
          ),

          // Overlay with scanning frame
          CustomPaint(
            painter: ScannerOverlayPainter(),
            child: Container(),
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Playlist QR kodunu kare içine getirin',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'QR kod otomatik olarak taranacak',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            ),
          ),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom painter for scanner overlay
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Draw dark overlay
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(size.width / 2, size.height / 2),
              width: size.width * 0.7,
              height: size.width * 0.7,
            ),
            const Radius.circular(16),
          ),
        )
        ..fillType = PathFillType.evenOdd,
      paint,
    );

    // Draw scanning frame corners
    final framePaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final frameRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.7,
      height: size.width * 0.7,
    );

    const cornerLength = 40.0;

    // Top-left corner
    canvas.drawLine(
      frameRect.topLeft,
      frameRect.topLeft + const Offset(cornerLength, 0),
      framePaint,
    );
    canvas.drawLine(
      frameRect.topLeft,
      frameRect.topLeft + const Offset(0, cornerLength),
      framePaint,
    );

    // Top-right corner
    canvas.drawLine(
      frameRect.topRight,
      frameRect.topRight + const Offset(-cornerLength, 0),
      framePaint,
    );
    canvas.drawLine(
      frameRect.topRight,
      frameRect.topRight + const Offset(0, cornerLength),
      framePaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      frameRect.bottomLeft,
      frameRect.bottomLeft + const Offset(cornerLength, 0),
      framePaint,
    );
    canvas.drawLine(
      frameRect.bottomLeft,
      frameRect.bottomLeft + const Offset(0, -cornerLength),
      framePaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      frameRect.bottomRight,
      frameRect.bottomRight + const Offset(-cornerLength, 0),
      framePaint,
    );
    canvas.drawLine(
      frameRect.bottomRight,
      frameRect.bottomRight + const Offset(0, -cornerLength),
      framePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
