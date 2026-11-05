import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'media_placeholder.dart';

/// Recomendações de posicionamento seguro do dispositivo (texto único,
/// reutilizado no painel de captura e no modal de instruções).
const List<String> kPositioningTips = <String>[
  'Posicione o celular atrás ou ao lado da linha de tiro — nunca à frente do cano.',
  'Distância de referência: 2 a 5 m da boca do cano.',
  'Apoie o aparelho em superfície estável, com o microfone voltado para a arma.',
  'Não segure o celular durante os disparos e siga as regras do estande.',
];

/// Ilustração vetorial do posicionamento do dispositivo em relação à arma,
/// exibida dentro de um [MediaPlaceholder] de proporção fixa.
class PositioningDiagram extends StatelessWidget {
  const PositioningDiagram({super.key, this.aspectRatio = 16 / 9});

  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return MediaPlaceholder(
      icon: Icons.phone_android,
      aspectRatio: aspectRatio,
      label: 'Posicionamento do dispositivo',
      child: Semantics(
        label: 'Diagrama: celular posicionado ao lado e atrás da boca do cano, '
            'fora da linha de tiro, a cerca de 2 a 5 metros.',
        child: CustomPaint(
          painter: _PositioningPainter(),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _PositioningPainter extends CustomPainter {
  static const Color _weapon = AppColors.textSecondary;
  static const Color _danger = AppColors.recording;
  static const Color _device = AppColors.accent;
  static const Color _label = AppColors.textSecondary;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Offset muzzle = Offset(w * 0.36, h * 0.36);

    // Zona de risco (cone à frente do cano).
    final Path cone = Path()
      ..moveTo(muzzle.dx, muzzle.dy)
      ..lineTo(w, muzzle.dy - h * 0.28)
      ..lineTo(w, muzzle.dy + h * 0.28)
      ..close();
    canvas.drawPath(cone, Paint()..color = _danger.withValues(alpha: 0.08));
    canvas.drawPath(
      cone,
      Paint()
        ..color = _danger.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Linha de tiro.
    _dashedLine(
      canvas,
      muzzle,
      Offset(w * 0.97, muzzle.dy),
      Paint()
        ..color = _danger
        ..strokeWidth = 1.5,
    );

    // Silhueta simplificada da arma.
    final Paint weaponPaint = Paint()..color = _weapon;
    final Radius r = Radius.circular(h * 0.02);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.08, muzzle.dy - h * 0.05, w * 0.26, muzzle.dy + h * 0.05),
        r,
      ),
      weaponPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.24, muzzle.dy - h * 0.018, muzzle.dx, muzzle.dy + h * 0.018),
        r,
      ),
      weaponPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.15, muzzle.dy + h * 0.04, w * 0.19, muzzle.dy + h * 0.15),
        r,
      ),
      weaponPaint,
    );

    // Dispositivo (lateral e recuado em relação à boca do cano).
    final double phoneH = h * 0.22;
    final double phoneW = phoneH * 0.55;
    final Offset phoneCenter = Offset(w * 0.22, h * 0.80);
    final Rect phoneRect = Rect.fromCenter(
      center: phoneCenter,
      width: phoneW,
      height: phoneH,
    );
    final RRect phone = RRect.fromRectAndRadius(
      phoneRect,
      Radius.circular(phoneW * 0.18),
    );
    canvas.drawRRect(phone, Paint()..color = _device.withValues(alpha: 0.14));
    canvas.drawRRect(
      phone,
      Paint()
        ..color = _device
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawCircle(
      Offset(phoneCenter.dx, phoneRect.top + phoneH * 0.12),
      math.max(1.5, phoneW * 0.07),
      Paint()..color = _device,
    );

    // Distância recomendada.
    final Offset phoneTop = Offset(phoneCenter.dx, phoneRect.top - 4);
    _dashedLine(
      canvas,
      Offset(muzzle.dx - w * 0.01, muzzle.dy + h * 0.04),
      phoneTop,
      Paint()
        ..color = _device
        ..strokeWidth = 1.2,
      dash: 4,
      gap: 3,
    );

    final double fontSize = (h * 0.065).clamp(9.0, 13.0).toDouble();
    final Offset mid = Offset(
      (muzzle.dx + phoneTop.dx) / 2,
      (muzzle.dy + phoneTop.dy) / 2,
    );
    _text(canvas, '2–5 m', mid + Offset(w * 0.025, 0), _device, fontSize,
        alignLeft: true);
    _text(canvas, 'Celular', Offset(phoneRect.right + w * 0.025, phoneCenter.dy),
        _device, fontSize,
        alignLeft: true);
    _text(canvas, 'Arma', Offset(w * 0.17, muzzle.dy - h * 0.13), _label,
        fontSize);
    _text(canvas, 'Linha de tiro', Offset(w * 0.68, muzzle.dy - h * 0.07),
        _danger, fontSize);
    _text(canvas, 'Zona de risco', Offset(w * 0.78, muzzle.dy + h * 0.15),
        _danger.withValues(alpha: 0.8), fontSize);
  }

  void _dashedLine(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint paint, {
    double dash = 6,
    double gap = 4,
  }) {
    final Offset delta = to - from;
    final double total = delta.distance;
    if (total <= 0) return;
    final Offset direction = delta / total;
    double start = 0;
    while (start < total) {
      final double end = math.min(start + dash, total);
      canvas.drawLine(from + direction * start, from + direction * end, paint);
      start = end + gap;
    }
  }

  void _text(
    Canvas canvas,
    String text,
    Offset anchor,
    Color color,
    double fontSize, {
    bool alignLeft = false,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final double dx = alignLeft ? anchor.dx : anchor.dx - painter.width / 2;
    painter.paint(canvas, Offset(dx, anchor.dy - painter.height / 2));
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _PositioningPainter oldDelegate) => false;
}
