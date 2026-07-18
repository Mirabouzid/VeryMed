import 'package:flutter/material.dart';
import 'package:el_asli/core/theme/app_theme.dart';


class ScanOverlay extends StatelessWidget {
  final Animation<double> pulseAnimation;
  final bool isProcessing;
  final String statusMessage;

  const ScanOverlay({
    super.key,
    required this.pulseAnimation,
    required this.isProcessing,
    required this.statusMessage,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final frameSize = size.width * 0.75;

    return Stack(
      children: [
       
        CustomPaint(
          size: size,
          painter: _ScanFramePainter(
            frameSize: frameSize,
            centerY: size.height * 0.42,
          ),
        ),

        
        Positioned(
          left: (size.width - frameSize) / 2,
          top: size.height * 0.42 - frameSize / 2,
          child: AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: pulseAnimation.value,
                child: SizedBox(
                  width: frameSize,
                  height: frameSize,
                  child: CustomPaint(
                    painter: _CornerPainter(
                      color: isProcessing
                          ? AppTheme.warningOrange
                          : AppTheme.primaryGreen,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

      
        if (!isProcessing)
          Positioned(
            left: (size.width - frameSize) / 2 + 4,
            top: size.height * 0.42 - frameSize / 2,
            child: _ScanLine(frameSize: frameSize),
          ),

       
        if (isProcessing)
          Positioned(
            left: (size.width - frameSize) / 2,
            top: size.height * 0.42 - frameSize / 2,
            child: SizedBox(
              width: frameSize,
              height: frameSize,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.warningOrange,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),

        Positioned(
          bottom: 200,
          left: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ),

       
        Positioned(
          top: size.height * 0.42 + frameSize / 2 + 20,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CodeBadge('EAN-13'),
              const SizedBox(width: 8),
              _CodeBadge('QR Code'),
              const SizedBox(width: 8),
              _CodeBadge('Code 128'),
              const SizedBox(width: 8),
              _CodeBadge('OCR'),
            ],
          ),
        ),
      ],
    );
  }
}

class _CodeBadge extends StatelessWidget {
  final String label;
  const _CodeBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _ScanLine extends StatefulWidget {
  final double frameSize;
  const _ScanLine({required this.frameSize});

  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.frameSize - 8,
          height: widget.frameSize,
          child: Stack(
            children: [
              Positioned(
                top: _animation.value * (widget.frameSize - 4),
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppTheme.primaryGreen,
                        AppTheme.primaryGreen,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Painter pour le fond sombre avec trou
class _ScanFramePainter extends CustomPainter {
  final double frameSize;
  final double centerY;

  _ScanFramePainter({required this.frameSize, required this.centerY});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.65);
    final frameRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, centerY),
        width: frameSize,
        height: frameSize,
      ),
      const Radius.circular(12),
    );

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(frameRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ScanFramePainter old) =>
      old.frameSize != frameSize || old.centerY != centerY;
}

/// Painter pour les coins du cadre
class _CornerPainter extends CustomPainter {
  final Color color;
  const _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 28.0;
    const radius = 12.0;

    // Coins du cadre
    final corners = [
      // Haut-gauche
      [
        Offset(0, cornerLength), Offset(0, radius),
        Offset(radius, 0), Offset(cornerLength, 0),
      ],
      // Haut-droite
      [
        Offset(size.width - cornerLength, 0), Offset(size.width - radius, 0),
        Offset(size.width, radius), Offset(size.width, cornerLength),
      ],
      // Bas-gauche
      [
        Offset(0, size.height - cornerLength), Offset(0, size.height - radius),
        Offset(radius, size.height), Offset(cornerLength, size.height),
      ],
      // Bas-droite
      [
        Offset(size.width - cornerLength, size.height),
        Offset(size.width - radius, size.height),
        Offset(size.width, size.height - radius),
        Offset(size.width, size.height - cornerLength),
      ],
    ];

    for (final corner in corners) {
      final path = Path()
        ..moveTo(corner[0].dx, corner[0].dy)
        ..lineTo(corner[1].dx, corner[1].dy)
        ..arcToPoint(corner[2], radius: const Radius.circular(radius))
        ..lineTo(corner[3].dx, corner[3].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}
