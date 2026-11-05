import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'media_placeholder.dart';

/// Recomendações de posicionamento seguro do dispositivo (8 a 15 m atrás da linha de tiro).
const List<String> kPositioningTips = <String>[
  'Posicione o celular ATRÁS da linha de tiro (na retaguarda do atirador) — jamais à frente.',
  'Distância recomendada: 8 a 15 m atrás do posto de tiro para evitar saturação acústica.',
  'Apoie o aparelho em tripé ou superfície firme, com o microfone voltado para o atirador.',
  'Não segure o celular durante os disparos e cumpra as normas de segurança do estande.',
];

/// Ilustração instrutiva detalhada do posicionamento seguro do dispositivo
/// (8 a 15 m atrás da linha de tiro), exibida dentro de um [MediaPlaceholder].
class PositioningDiagram extends StatelessWidget {
  const PositioningDiagram({
    super.key,
    this.aspectRatio = 16 / 9,
    this.imageAsset = 'assets/images/positioning.png',
  });

  final double aspectRatio;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    return MediaPlaceholder(
      icon: Icons.phone_android,
      aspectRatio: aspectRatio,
      imageAsset: imageAsset,
      label: 'Posicionamento seguro: 8 a 15 m atrás da linha de tiro',
      child: Semantics(
        label:
            'Ilustração instrutiva: celular posicionado na retaguarda do '
            'atirador, atrás da linha de tiro, a uma distância de 8 a 15 metros.',
        child: CustomPaint(
          painter: _PositioningPainter(),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _PositioningPainter extends CustomPainter {
  static const Color _danger = AppColors.recording;
  static const Color _device = AppColors.accent;
  static const Color _label = AppColors.textSecondary;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Rect fullRect = Offset.zero & size;

    // Fundo escuro de estande técnico
    canvas.drawRect(
      fullRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF15181E), Color(0xFF101318)],
        ).createShader(fullRect),
    );

    // Grade métrica sutil
    final Paint gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.32)
      ..strokeWidth = 0.7;
    for (int i = 1; i < 6; i++) {
      final double x = w * (i / 6);
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (int j = 1; j < 4; j++) {
      final double y = h * (j / 4);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Linha de tiro (demarcação vertical do posto de tiro no centro-direita)
    final double firingLineX = w * 0.62;
    _dashedLine(
      canvas,
      Offset(firingLineX, h * 0.12),
      Offset(firingLineX, h * 0.88),
      Paint()
        ..color = AppColors.warning.withValues(alpha: 0.75)
        ..strokeWidth = 1.5,
      dash: 5,
      gap: 4,
    );

    // Posição da boca do cano (na linha de tiro, apontando para a direita)
    final Offset muzzle = Offset(w * 0.68, h * 0.44);
    final Offset shooterPos = Offset(w * 0.54, h * 0.44);

    // Cone de sopro e trajetória de disparo (à direita da linha de tiro)
    final Path dangerCone = Path()
      ..moveTo(muzzle.dx, muzzle.dy)
      ..lineTo(w, muzzle.dy - h * 0.28)
      ..lineTo(w, muzzle.dy + h * 0.28)
      ..close();
    canvas.drawPath(
      dangerCone,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            _danger.withValues(alpha: 0.26),
            _danger.withValues(alpha: 0.04),
          ],
        ).createShader(Rect.fromLTWH(muzzle.dx, 0, w - muzzle.dx, h)),
    );
    _dashedLine(
      canvas,
      muzzle,
      Offset(w * 0.97, muzzle.dy),
      Paint()
        ..color = _danger
        ..strokeWidth = 1.7,
    );

    // Celular posicionado ATRÁS do atirador (à esquerda da linha de tiro)
    final Offset phoneCenter = Offset(w * 0.16, h * 0.56);

    // Ondas acústicas propagando para trás (da arma até o celular na retaguarda)
    for (int ring = 1; ring <= 4; ring++) {
      final double radius = w * (0.075 * ring);
      canvas.drawArc(
        Rect.fromCircle(center: shooterPos, radius: radius),
        math.pi * 0.76,
        math.pi * 0.42,
        false,
        Paint()
          ..color = _device.withValues(alpha: 0.38 - ring * 0.07)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3,
      );
    }

    // Silhueta do fuzil no posto de tiro apontado para a direita
    _paintRifleAtFiringLine(canvas, size, shooterPos, muzzle);

    // Smartphone em tripé/suporte na retaguarda segura
    final double phoneH = h * 0.22;
    final double phoneW = phoneH * 0.54;
    final Rect phoneRect = Rect.fromCenter(
      center: phoneCenter,
      width: phoneW,
      height: phoneH,
    );
    canvas.drawCircle(
      phoneCenter,
      phoneH * 0.72,
      Paint()..color = _device.withValues(alpha: 0.09),
    );
    final RRect phoneRRect = RRect.fromRectAndRadius(
      phoneRect,
      Radius.circular(phoneW * 0.20),
    );
    canvas.drawRRect(phoneRRect, Paint()..color = const Color(0xFF0E1718));
    canvas.drawRRect(
      phoneRRect,
      Paint()
        ..color = _device
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7,
    );
    canvas.drawCircle(
      Offset(phoneRect.right - phoneW * 0.18, phoneCenter.dy),
      math.max(1.8, phoneW * 0.08),
      Paint()..color = _device,
    );

    // Cota de distância 8–15 m entre a retaguarda do atirador e o celular
    final Offset cotaStart = Offset(phoneRect.right + 6, h * 0.72);
    final Offset cotaEnd = Offset(firingLineX - 6, h * 0.72);
    _dashedLine(
      canvas,
      cotaStart,
      cotaEnd,
      Paint()
        ..color = _device
        ..strokeWidth = 1.5,
      dash: 5,
      gap: 3,
    );

    final double fontSize = (h * 0.064).clamp(9.5, 13.0).toDouble();
    final Offset midCota = Offset(
      (cotaStart.dx + cotaEnd.dx) * 0.5 - w * 0.04,
      h * 0.72,
    );
    _badgeText(canvas, '8–15 m (Atrás)', midCota, _device, fontSize);

    _text(
      canvas,
      'Celular (Retaguarda)',
      Offset(phoneCenter.dx + w * 0.02, phoneRect.top - h * 0.07),
      _device,
      fontSize,
    );
    _text(
      canvas,
      'Linha de Tiro',
      Offset(firingLineX, h * 0.08),
      AppColors.warning,
      fontSize,
    );
    _text(
      canvas,
      'Atirador',
      Offset(shooterPos.dx, muzzle.dy - h * 0.14),
      _label,
      fontSize,
    );
    _text(
      canvas,
      'Zona de Disparo',
      Offset(w * 0.84, muzzle.dy - h * 0.10),
      _danger,
      fontSize,
    );
  }

  void _paintRifleAtFiringLine(
    Canvas canvas,
    Size size,
    Offset rear,
    Offset muzzle,
  ) {
    final double w = size.width;
    final double h = size.height;
    final double cy = muzzle.dy;

    final Paint metalFill = Paint()
      ..color = const Color(0xFF6B7280)
      ..style = PaintingStyle.fill;
    final Paint stroke = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final RRect body = RRect.fromRectAndRadius(
      Rect.fromLTRB(rear.dx - w * 0.04, cy - h * 0.035, muzzle.dx - w * 0.05, cy + h * 0.03),
      const Radius.circular(2),
    );
    canvas.drawRRect(body, metalFill);
    canvas.drawRRect(body, stroke);
    canvas.drawLine(
      Offset(muzzle.dx - w * 0.05, cy - h * 0.005),
      muzzle,
      Paint()
        ..color = const Color(0xFFD1D5DB)
        ..strokeWidth = 2.3
        ..strokeCap = StrokeCap.round,
    );
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

  void _badgeText(
    Canvas canvas,
    String text,
    Offset anchor,
    Color color,
    double fontSize,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final Rect bg = Rect.fromCenter(
      center: Offset(anchor.dx + painter.width / 2, anchor.dy),
      width: painter.width + 12,
      height: painter.height + 6,
    );
    final RRect rrect = RRect.fromRectAndRadius(bg, const Radius.circular(5));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF0E1718));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = color.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    painter.paint(canvas, Offset(anchor.dx, anchor.dy - painter.height / 2));
    painter.dispose();
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
