import 'package:flutter/material.dart';

import '../practice_controller.dart';

class PitchReadout extends StatelessWidget {
  const PitchReadout({
    required this.state,
    this.compact = false,
    super.key,
  });

  final PracticeState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pitch = state.lastPitch;
    final cents = state.lastCents;
    final error = state.errorMessage;

    if (error != null) {
      return _ReadoutSurface(
        icon: Icons.warning_rounded,
        text: error,
        color: theme.colorScheme.error,
        compact: compact,
      );
    }

    if (pitch == null || cents == null) {
      return _ReadoutSurface(
        icon: Icons.graphic_eq_rounded,
        text: 'Waiting for pitch',
        color: theme.colorScheme.onSurfaceVariant,
        compact: compact,
      );
    }

    return _TuningMeter(
      frequency: pitch.frequency,
      cents: cents,
      compact: compact,
    );
  }
}

class _TuningMeter extends StatelessWidget {
  const _TuningMeter({
    required this.frequency,
    required this.cents,
    required this.compact,
  });

  final double frequency;
  final double cents;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final absCents = cents.abs();
    final color = absCents <= 10
        ? const Color(0xFF167A48)
        : absCents <= 35
            ? const Color(0xFF9B5B00)
            : const Color(0xFFC8372D);
    final centsText = cents >= 0 ? '+${cents.round()}' : '${cents.round()}';
    final direction = absCents <= 10
        ? 'In tune'
        : cents < 0
            ? 'Flat'
            : 'Sharp';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        border: Border.all(color: const Color(0xFFE0D9C8)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: color, size: compact ? 18 : 22),
              SizedBox(width: compact ? 6 : 9),
              Expanded(
                child: Text(
                  '$direction  $centsText cents',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (compact
                          ? theme.textTheme.bodyMedium
                          : theme.textTheme.bodyLarge)
                      ?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                ),
              ),
              Text(
                '${frequency.toStringAsFixed(1)} Hz',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 8),
          SizedBox(
            height: compact ? 20 : 26,
            child: CustomPaint(
              painter: _TuningMeterPainter(
                cents: cents,
                color: color,
                textColor: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TuningMeterPainter extends CustomPainter {
  const _TuningMeterPainter({
    required this.cents,
    required this.color,
    required this.textColor,
  });

  final double cents;
  final Color color;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height * 0.54;
    final left = 6.0;
    final right = size.width - 6.0;
    final centerX = size.width / 2;
    final trackPaint = Paint()
      ..color = const Color(0xFFE0D9C8)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(left, centerY), Offset(right, centerY), trackPaint);

    final centerPaint = Paint()
      ..color = const Color(0xFF167A48)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centerX, centerY - 9),
      Offset(centerX, centerY + 9),
      centerPaint,
    );

    for (final tick in const [-50, -25, 25, 50]) {
      final x = centerX + (tick / 50) * (right - left) / 2;
      final tickPaint = Paint()
        ..color = textColor.withValues(alpha: 0.45)
        ..strokeWidth = tick.abs() == 50 ? 1.5 : 1
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x, centerY - 5),
        Offset(x, centerY + 5),
        tickPaint,
      );
    }

    final clampedCents = cents.clamp(-50.0, 50.0).toDouble();
    final needleX = centerX + (clampedCents / 50) * (right - left) / 2;
    final needlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final needle = Path()
      ..moveTo(needleX, centerY - 10)
      ..lineTo(needleX - 6, centerY + 7)
      ..lineTo(needleX + 6, centerY + 7)
      ..close();

    canvas.drawPath(needle, needlePaint);
  }

  @override
  bool shouldRepaint(covariant _TuningMeterPainter oldDelegate) {
    return cents != oldDelegate.cents ||
        color != oldDelegate.color ||
        textColor != oldDelegate.textColor;
  }
}

class _ReadoutSurface extends StatelessWidget {
  const _ReadoutSurface({
    required this.icon,
    required this.text,
    required this.color,
    required this.compact,
  });

  final IconData icon;
  final String text;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        border: Border.all(color: const Color(0xFFE0D9C8)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: compact ? 19 : 24),
          SizedBox(width: compact ? 7 : 10),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (compact
                      ? Theme.of(context).textTheme.bodyMedium
                      : Theme.of(context).textTheme.bodyLarge)
                  ?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
