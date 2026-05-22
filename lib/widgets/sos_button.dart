import 'dart:math';
import 'package:flutter/material.dart';

class SOSButton extends StatefulWidget {
  final VoidCallback onTriggered;
  final bool isTriggered;

  const SOSButton({
    Key? key,
    required this.onTriggered,
    this.isTriggered = false,
  }) : super(key: key);

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _holdController;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    // Pulse animation for the idle state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Progress animation for holding the button
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onTriggered();
        _holdController.reset();
        setState(() {
          _isHolding = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _holdController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isTriggered) return;
    setState(() {
      _isHolding = true;
    });
    _holdController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isTriggered) return;
    _cancelHold();
  }

  void _handleTapCancel() {
    if (widget.isTriggered) return;
    _cancelHold();
  }

  void _cancelHold() {
    setState(() {
      _isHolding = false;
    });
    _holdController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = 200.0;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Center(
        child: SizedBox(
          width: size + 40,
          height: size + 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsating Background Rings (only when NOT holding)
              if (!_isHolding && !widget.isTriggered)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: size + (40 * _pulseController.value),
                          height: size + (40 * _pulseController.value),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.error.withOpacity(0.15 * (1 - _pulseController.value)),
                          ),
                        ),
                        Container(
                          width: size + (20 * _pulseController.value),
                          height: size + (20 * _pulseController.value),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.error.withOpacity(0.25 * (1 - _pulseController.value)),
                          ),
                        ),
                      ],
                    );
                  },
                ),

              // Outer Circular Hold Progress Indicator
              AnimatedBuilder(
                animation: _holdController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(size + 20, size + 20),
                    painter: SOSHoldPainter(
                      progress: _holdController.value,
                      color: widget.isTriggered
                          ? theme.colorScheme.error
                          : (_isHolding ? theme.colorScheme.error : theme.colorScheme.error.withOpacity(0.3)),
                    ),
                  );
                },
              ),

              // Inner Button Circle
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: widget.isTriggered
                        ? [theme.colorScheme.error, const Color(0xFF991B1B)]
                        : [const Color(0xFFEF4444), theme.colorScheme.error],
                    center: const Alignment(-0.2, -0.2),
                    radius: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.error.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.isTriggered ? Icons.notifications_active : Icons.warning_amber_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'SOS',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isTriggered
                          ? 'ACTIVE'
                          : (_isHolding ? 'HOLDING...' : 'HOLD 2 SECS'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SOSHoldPainter extends CustomPainter {
  final double progress;
  final Color color;

  SOSHoldPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 4;
    final strokeWidth = 8.0;

    // Draw background track
    final trackPaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Draw active indicator
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SOSHoldPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
