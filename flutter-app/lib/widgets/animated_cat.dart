import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated cat widget that waves paws when playing music
class AnimatedCat extends StatefulWidget {
  final bool isPlaying;
  final double size;

  const AnimatedCat({
    super.key,
    required this.isPlaying,
    this.size = 220,
  });

  @override
  State<AnimatedCat> createState() => _AnimatedCatState();
}

class _AnimatedCatState extends State<AnimatedCat>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pawLeftAnimation;
  late Animation<double> _pawRightAnimation;
  late Animation<double> _bodyBounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Left paw animation (waves up and down)
    _pawLeftAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    // Right paw animation (waves up and down with slight delay)
    _pawRightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.6, curve: Curves.easeInOut),
      ),
    );

    // Body bounce animation
    _bodyBounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Start animation if already playing
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedCat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        // Start animation when playing
        _controller.repeat();
      } else {
        // Stop animation when paused, but let it finish current cycle
        _controller.stop();
        if (_controller.value > 0 && _controller.value < 1.0) {
          // Complete the current animation cycle
          _controller.animateTo(1.0).then((_) {
            if (mounted && !widget.isPlaying) {
              _controller.reset();
            }
          });
        } else {
          _controller.reset();
        }
      }
    }
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
        final size = widget.size;
        final pawAngle = _pawLeftAnimation.value * math.pi * 0.3; // 30 degrees
        final pawAngleRight = _pawRightAnimation.value * math.pi * 0.3;
        final bounce = math.sin(_bodyBounceAnimation.value * math.pi * 2) * 2;

        return CustomPaint(
          size: Size(size, size),
          painter: CatPainter(
            pawLeftAngle: pawAngle,
            pawRightAngle: pawAngleRight,
            bodyOffset: bounce,
          ),
        );
      },
    );
  }
}

class CatPainter extends CustomPainter {
  final double pawLeftAngle;
  final double pawRightAngle;
  final double bodyOffset;

  CatPainter({
    required this.pawLeftAngle,
    required this.pawRightAngle,
    required this.bodyOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2 + bodyOffset;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF28D5D1); // Cotune highlight color

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFF1a9a96);

    // Cat body (ellipse)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY + 20),
        width: size.width * 0.6,
        height: size.height * 0.5,
      ),
      const Radius.circular(40),
    );
    canvas.drawRRect(bodyRect, paint);
    canvas.drawRRect(bodyRect, strokePaint);

    // Cat head (circle)
    final headRadius = size.width * 0.25;
    canvas.drawCircle(
      Offset(centerX, centerY - headRadius * 0.5),
      headRadius,
      paint,
    );
    canvas.drawCircle(
      Offset(centerX, centerY - headRadius * 0.5),
      headRadius,
      strokePaint,
    );

    // Ears
    final earSize = size.width * 0.12;
    final earPath = Path()
      ..moveTo(centerX - headRadius * 0.4, centerY - headRadius * 0.8)
      ..lineTo(centerX - headRadius * 0.4 - earSize * 0.5, centerY - headRadius * 1.2)
      ..lineTo(centerX - headRadius * 0.4 + earSize * 0.5, centerY - headRadius * 0.9);
    canvas.drawPath(earPath, paint);
    canvas.drawPath(earPath, strokePaint);

    final earPathRight = Path()
      ..moveTo(centerX + headRadius * 0.4, centerY - headRadius * 0.8)
      ..lineTo(centerX + headRadius * 0.4 + earSize * 0.5, centerY - headRadius * 1.2)
      ..lineTo(centerX + headRadius * 0.4 - earSize * 0.5, centerY - headRadius * 0.9);
    canvas.drawPath(earPathRight, paint);
    canvas.drawPath(earPathRight, strokePaint);

    // Eyes
    final eyeRadius = size.width * 0.04;
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(centerX - headRadius * 0.25, centerY - headRadius * 0.4),
      eyeRadius,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(centerX + headRadius * 0.25, centerY - headRadius * 0.4),
      eyeRadius,
      eyePaint,
    );

    // Eye pupils
    final pupilPaint = Paint()..color = Colors.black;
    canvas.drawCircle(
      Offset(centerX - headRadius * 0.25, centerY - headRadius * 0.4),
      eyeRadius * 0.6,
      pupilPaint,
    );
    canvas.drawCircle(
      Offset(centerX + headRadius * 0.25, centerY - headRadius * 0.4),
      eyeRadius * 0.6,
      pupilPaint,
    );

    // Nose (triangle)
    final nosePaint = Paint()..color = Colors.pink.shade300;
    final nosePath = Path()
      ..moveTo(centerX, centerY - headRadius * 0.1)
      ..lineTo(centerX - size.width * 0.02, centerY)
      ..lineTo(centerX + size.width * 0.02, centerY);
    canvas.drawPath(nosePath, nosePaint);

    // Mouth
    final mouthPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.black;
    final mouthPath = Path()
      ..moveTo(centerX, centerY)
      ..quadraticBezierTo(
        centerX - size.width * 0.08,
        centerY + size.width * 0.05,
        centerX - size.width * 0.12,
        centerY + size.width * 0.04,
      );
    canvas.drawPath(mouthPath, mouthPaint);
    final mouthPathRight = Path()
      ..moveTo(centerX, centerY)
      ..quadraticBezierTo(
        centerX + size.width * 0.08,
        centerY + size.width * 0.05,
        centerX + size.width * 0.12,
        centerY + size.width * 0.04,
      );
    canvas.drawPath(mouthPathRight, mouthPaint);

    // Left paw (animated)
    final pawSize = size.width * 0.15;
    final leftPawX = centerX - size.width * 0.25;
    final leftPawY = centerY + size.height * 0.2;
    canvas.save();
    canvas.translate(leftPawX, leftPawY);
    canvas.rotate(-pawLeftAngle);
    final leftPawRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: const Offset(0, 0),
        width: pawSize * 0.6,
        height: pawSize,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(leftPawRect, paint);
    canvas.drawRRect(leftPawRect, strokePaint);
    canvas.restore();

    // Right paw (animated)
    final rightPawX = centerX + size.width * 0.25;
    final rightPawY = centerY + size.height * 0.2;
    canvas.save();
    canvas.translate(rightPawX, rightPawY);
    canvas.rotate(pawRightAngle);
    final rightPawRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: const Offset(0, 0),
        width: pawSize * 0.6,
        height: pawSize,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(rightPawRect, paint);
    canvas.drawRRect(rightPawRect, strokePaint);
    canvas.restore();

    // Tail
    final tailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final tailPath = Path()
      ..moveTo(centerX - size.width * 0.3, centerY + size.height * 0.15)
      ..quadraticBezierTo(
        centerX - size.width * 0.4,
        centerY + size.height * 0.05,
        centerX - size.width * 0.35,
        centerY - size.height * 0.1,
      );
    canvas.drawPath(tailPath, tailPaint);
  }

  @override
  bool shouldRepaint(CatPainter oldDelegate) {
    return oldDelegate.pawLeftAngle != pawLeftAngle ||
        oldDelegate.pawRightAngle != pawRightAngle ||
        oldDelegate.bodyOffset != bodyOffset;
  }
}
