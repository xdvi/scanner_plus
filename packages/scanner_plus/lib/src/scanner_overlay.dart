import 'package:flutter/material.dart';

class ScannerPlusOverlay extends StatelessWidget {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final Color overlayColor;
  final double cutOutSize;

  const ScannerPlusOverlay({
    super.key,
    this.borderColor = Colors.white,
    this.borderRadius = 12,
    this.borderLength = 32,
    this.borderWidth = 4,
    this.overlayColor = const Color(0x88000000),
    this.cutOutSize = 250,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark overlay with a hole
        ColorFiltered(
          colorFilter: ColorFilter.mode(overlayColor, BlendMode.srcOut),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: cutOutSize,
                  height: cutOutSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Corners
        Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: cutOutSize,
            height: cutOutSize,
            child: CustomPaint(
              painter: _ScannerOverlayPainter(
                borderColor: borderColor,
                borderRadius: borderRadius,
                borderLength: borderLength,
                borderWidth: borderWidth,
              ),
            ),
          ),
        ),
        // Scanning line
        _ScanningLine(width: cutOutSize),
      ],
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;

  _ScannerOverlayPainter({
    required this.borderColor,
    required this.borderRadius,
    required this.borderLength,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path();

    // Top left
    path.moveTo(0, borderLength);
    path.lineTo(0, borderRadius);
    path.quadraticBezierTo(0, 0, borderRadius, 0);
    path.lineTo(borderLength, 0);

    // Top right
    path.moveTo(size.width - borderLength, 0);
    path.lineTo(size.width - borderRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, borderRadius);
    path.lineTo(size.width, borderLength);

    // Bottom right
    path.moveTo(size.width, size.height - borderLength);
    path.lineTo(size.width, size.height - borderRadius);
    path.quadraticBezierTo(size.width, size.height, size.width - borderRadius, size.height);
    path.lineTo(size.width - borderLength, size.height);

    // Bottom left
    path.moveTo(borderLength, size.height);
    path.lineTo(borderRadius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - borderRadius);
    path.lineTo(0, size.height - borderLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanningLine extends StatefulWidget {
  final double width;

  const _ScanningLine({required this.width});

  @override
  State<_ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<_ScanningLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: (MediaQuery.of(context).size.height / 2 - widget.width / 2) + (_controller.value * widget.width),
          left: MediaQuery.of(context).size.width / 2 - widget.width / 2,
          child: Container(
            width: widget.width,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white,
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
