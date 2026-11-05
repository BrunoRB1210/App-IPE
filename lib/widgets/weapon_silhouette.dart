import 'package:flutter/material.dart';

import '../models/weapon.dart';
import '../theme/app_theme.dart';

/// Ilustração vetorial minimalista (esquemática) do armamento para exibição no
/// espaço reservado de imagem ([MediaPlaceholder]) quando não há PNG externo.
class WeaponSilhouette extends StatelessWidget {
  const WeaponSilhouette({
    super.key,
    required this.kind,
    this.highlighted = false,
    this.caption,
  });

  final WeaponSilhouetteKind kind;
  final bool highlighted;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        CustomPaint(
          painter: _WeaponSilhouettePainter(
            kind: kind,
            highlighted: highlighted,
          ),
        ),
        if (caption != null)
          Positioned(
            right: 8,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                caption!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 9.5,
                      color: AppColors.textMuted,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WeaponSilhouettePainter extends CustomPainter {
  const _WeaponSilhouettePainter({
    required this.kind,
    required this.highlighted,
  });

  final WeaponSilhouetteKind kind;
  final bool highlighted;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Linhas de referência sutis de placeholder técnico.
    final Paint gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.45)
      ..strokeWidth = 0.75;
    canvas.drawLine(Offset(0, h * 0.5), Offset(w, h * 0.5), gridPaint);
    canvas.drawLine(Offset(w * 0.5, 0), Offset(w * 0.5, h), gridPaint);

    final Color strokeColor =
        highlighted ? AppColors.accent : AppColors.textSecondary;
    final Paint fillPaint = Paint()
      ..color = strokeColor.withValues(alpha: highlighted ? 0.22 : 0.14)
      ..style = PaintingStyle.fill;
    final Paint strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    switch (kind) {
      case WeaponSilhouetteKind.fal:
        _paintFal(canvas, size, fillPaint, strokePaint, foldingStock: false);
      case WeaponSilhouetteKind.parafal:
        _paintFal(canvas, size, fillPaint, strokePaint, foldingStock: true);
      case WeaponSilhouetteKind.ia2:
        _paintIa2(canvas, size, fillPaint, strokePaint);
      case WeaponSilhouetteKind.mag:
        _paintMag(canvas, size, fillPaint, strokePaint);
      case WeaponSilhouetteKind.generic:
        _paintGeneric(canvas, size, strokePaint);
    }
  }

  void _paintFal(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke, {
    required bool foldingStock,
  }) {
    final double w = size.width;
    final double h = size.height;
    final double cy = h * 0.46;

    final Path body = Path();
    if (foldingStock) {
      // Coronha tubular rebatível (ParaFAL)
      canvas.drawLine(
        Offset(w * 0.12, cy - h * 0.02),
        Offset(w * 0.30, cy - h * 0.02),
        stroke,
      );
      canvas.drawLine(
        Offset(w * 0.12, cy + h * 0.05),
        Offset(w * 0.30, cy + h * 0.03),
        stroke,
      );
      canvas.drawLine(
        Offset(w * 0.12, cy - h * 0.04),
        Offset(w * 0.12, cy + h * 0.12),
        stroke,
      );
    } else {
      // Coronha fixa (FAL M964)
      final Path stock = Path()
        ..moveTo(w * 0.09, cy - h * 0.03)
        ..lineTo(w * 0.30, cy - h * 0.03)
        ..lineTo(w * 0.30, cy + h * 0.04)
        ..lineTo(w * 0.09, cy + h * 0.13)
        ..close();
      canvas.drawPath(stock, fill);
      canvas.drawPath(stock, stroke);
    }

    // Caixa da culatra + guarda-mão longo
    body.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.30, cy - h * 0.055, w * 0.72, cy + h * 0.04),
        const Radius.circular(2),
      ),
    );
    canvas.drawPath(body, fill);
    canvas.drawPath(body, stroke);

    // Cano longo + quebra-chamas
    canvas.drawLine(
      Offset(w * 0.72, cy - h * 0.015),
      Offset(w * 0.91, cy - h * 0.015),
      stroke..strokeWidth = 2.0,
    );
    stroke.strokeWidth = 1.5;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.89, cy - h * 0.035, w * 0.04, h * 0.04),
      stroke,
    );

    // Punho e carregador reto 7,62 mm
    final Path grip = Path()
      ..moveTo(w * 0.33, cy + h * 0.04)
      ..lineTo(w * 0.30, cy + h * 0.20)
      ..lineTo(w * 0.35, cy + h * 0.20)
      ..lineTo(w * 0.38, cy + h * 0.04)
      ..close();
    final Path mag = Path()
      ..moveTo(w * 0.44, cy + h * 0.04)
      ..lineTo(w * 0.43, cy + h * 0.23)
      ..lineTo(w * 0.50, cy + h * 0.22)
      ..lineTo(w * 0.51, cy + h * 0.04)
      ..close();
    canvas.drawPath(grip, fill);
    canvas.drawPath(grip, stroke);
    canvas.drawPath(mag, fill);
    canvas.drawPath(mag, stroke);
  }

  void _paintIa2(Canvas canvas, Size size, Paint fill, Paint stroke) {
    final double w = size.width;
    final double h = size.height;
    final double cy = h * 0.46;

    // Coronha rebatível polímero IA2
    final Path stock = Path()
      ..moveTo(w * 0.12, cy - h * 0.03)
      ..lineTo(w * 0.31, cy - h * 0.04)
      ..lineTo(w * 0.31, cy + h * 0.04)
      ..lineTo(w * 0.14, cy + h * 0.11)
      ..lineTo(w * 0.12, cy + h * 0.11)
      ..close();
    canvas.drawPath(stock, fill);
    canvas.drawPath(stock, stroke);

    // Receptor + trilho superior Picatinny + guarda-mão compacto
    final RRect receiver = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.31, cy - h * 0.065, w * 0.69, cy + h * 0.045),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(receiver, fill);
    canvas.drawRRect(receiver, stroke);
    canvas.drawLine(
      Offset(w * 0.33, cy - h * 0.085),
      Offset(w * 0.66, cy - h * 0.085),
      stroke,
    );

    // Cano + quebra-chamas compacto
    canvas.drawLine(
      Offset(w * 0.69, cy - h * 0.01),
      Offset(w * 0.87, cy - h * 0.01),
      stroke..strokeWidth = 2.0,
    );
    stroke.strokeWidth = 1.5;

    // Punho e carregador levemente curvo STANAG
    final Path grip = Path()
      ..moveTo(w * 0.34, cy + h * 0.045)
      ..lineTo(w * 0.31, cy + h * 0.20)
      ..lineTo(w * 0.36, cy + h * 0.20)
      ..lineTo(w * 0.39, cy + h * 0.045)
      ..close();
    final Path mag = Path()
      ..moveTo(w * 0.46, cy + h * 0.045)
      ..quadraticBezierTo(w * 0.46, cy + h * 0.16, w * 0.50, cy + h * 0.25)
      ..lineTo(w * 0.56, cy + h * 0.23)
      ..quadraticBezierTo(w * 0.52, cy + h * 0.14, w * 0.53, cy + h * 0.045)
      ..close();
    canvas.drawPath(grip, fill);
    canvas.drawPath(grip, stroke);
    canvas.drawPath(mag, fill);
    canvas.drawPath(mag, stroke);
  }

  void _paintMag(Canvas canvas, Size size, Paint fill, Paint stroke) {
    final double w = size.width;
    final double h = size.height;
    final double cy = h * 0.42;

    // Coronha da MAG
    final Path stock = Path()
      ..moveTo(w * 0.08, cy - h * 0.02)
      ..lineTo(w * 0.25, cy - h * 0.03)
      ..lineTo(w * 0.25, cy + h * 0.05)
      ..lineTo(w * 0.08, cy + h * 0.12)
      ..close();
    canvas.drawPath(stock, fill);
    canvas.drawPath(stock, stroke);

    // Caixa da culatra robusta
    final RRect body = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.25, cy - h * 0.065, w * 0.64, cy + h * 0.06),
      const Radius.circular(2),
    );
    canvas.drawRRect(body, fill);
    canvas.drawRRect(body, stroke);

    // Cano pesado + cilindro de gases + bipé frontal
    canvas.drawLine(
      Offset(w * 0.64, cy - h * 0.025),
      Offset(w * 0.92, cy - h * 0.025),
      stroke..strokeWidth = 2.2,
    );
    stroke.strokeWidth = 1.5;
    canvas.drawLine(
      Offset(w * 0.64, cy + h * 0.02),
      Offset(w * 0.83, cy + h * 0.02),
      stroke,
    );
    // Bipé
    canvas.drawLine(
      Offset(w * 0.80, cy + h * 0.02),
      Offset(w * 0.75, cy + h * 0.28),
      stroke,
    );
    canvas.drawLine(
      Offset(w * 0.80, cy + h * 0.02),
      Offset(w * 0.85, cy + h * 0.28),
      stroke,
    );

    // Punho
    final Path grip = Path()
      ..moveTo(w * 0.30, cy + h * 0.06)
      ..lineTo(w * 0.27, cy + h * 0.22)
      ..lineTo(w * 0.32, cy + h * 0.22)
      ..lineTo(w * 0.35, cy + h * 0.06)
      ..close();
    canvas.drawPath(grip, fill);
    canvas.drawPath(grip, stroke);
  }

  void _paintGeneric(Canvas canvas, Size size, Paint stroke) {
    final Offset center = Offset(size.width * 0.5, size.height * 0.5);
    final double r = size.shortestSide * 0.24;
    canvas.drawCircle(center, r, stroke);
    canvas.drawCircle(center, r * 0.35, stroke);
    canvas.drawLine(
      Offset(center.dx - r * 1.4, center.dy),
      Offset(center.dx + r * 1.4, center.dy),
      stroke,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - r * 1.4),
      Offset(center.dx, center.dy + r * 1.4),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _WeaponSilhouettePainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.highlighted != highlighted;
}
