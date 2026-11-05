import 'package:flutter/material.dart';

import '../models/weapon.dart';
import '../theme/app_theme.dart';

/// Ilustração vetorial técnica realista de cada armamento (FAL, ParaFAL, IA2,
/// MAG e Outro), usada no [MediaPlaceholder] quando a imagem externa não
/// estiver carregada.
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
    final Rect bounds = Offset.zero & size;

    // Fundo de estúdio escuro com iluminação central sutil
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: <Color>[
            highlighted
                ? AppColors.accent.withValues(alpha: 0.14)
                : const Color(0xFF252A32),
            const Color(0xFF14171B),
          ],
        ).createShader(bounds),
    );

    // Linhas de grade técnica discreta
    final Paint gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.32)
      ..strokeWidth = 0.6;
    canvas.drawLine(Offset(0, h * 0.50), Offset(w, h * 0.50), gridPaint);
    canvas.drawLine(Offset(w * 0.50, 0), Offset(w * 0.50, h), gridPaint);

    final Color rimColor =
        highlighted ? AppColors.accent : const Color(0xFFD1D5DB);
    final Paint bodyFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: highlighted
            ? <Color>[
                const Color(0xFF5EEAD4).withValues(alpha: 0.45),
                const Color(0xFF134E4A).withValues(alpha: 0.65),
              ]
            : <Color>[
                const Color(0xFF6B7280),
                const Color(0xFF374151),
              ],
      ).createShader(bounds);

    final Paint darkPartFill = Paint()
      ..color = highlighted
          ? const Color(0xFF115E59)
          : const Color(0xFF262B33);

    final Paint stroke = Paint()
      ..color = rimColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    switch (kind) {
      case WeaponSilhouetteKind.fal:
        _paintFal(
          canvas,
          size,
          bodyFill,
          darkPartFill,
          stroke,
          foldingStock: false,
        );
      case WeaponSilhouetteKind.parafal:
        _paintFal(
          canvas,
          size,
          bodyFill,
          darkPartFill,
          stroke,
          foldingStock: true,
        );
      case WeaponSilhouetteKind.ia2:
        _paintIa2(canvas, size, bodyFill, darkPartFill, stroke);
      case WeaponSilhouetteKind.mag:
        _paintMag(canvas, size, bodyFill, darkPartFill, stroke);
      case WeaponSilhouetteKind.generic:
        _paintGeneric(canvas, size, stroke);
    }
  }

  void _paintFal(
    Canvas canvas,
    Size size,
    Paint metalFill,
    Paint polymerFill,
    Paint stroke, {
    required bool foldingStock,
  }) {
    final double w = size.width;
    final double h = size.height;
    final double cy = h * 0.44;

    if (foldingStock) {
      // Coronha tubular dupla rebatível do ParaFAL M964A1
      final Path buttplate = Path()
        ..moveTo(w * 0.09, cy - h * 0.04)
        ..lineTo(w * 0.12, cy - h * 0.04)
        ..lineTo(w * 0.12, cy + h * 0.14)
        ..lineTo(w * 0.09, cy + h * 0.12)
        ..close();
      canvas.drawPath(buttplate, polymerFill);
      canvas.drawPath(buttplate, stroke);
      canvas.drawLine(
        Offset(w * 0.12, cy - h * 0.015),
        Offset(w * 0.29, cy - h * 0.015),
        stroke..strokeWidth = 1.8,
      );
      canvas.drawLine(
        Offset(w * 0.12, cy + h * 0.06),
        Offset(w * 0.29, cy + h * 0.03),
        stroke..strokeWidth = 1.5,
      );
      stroke.strokeWidth = 1.25;
    } else {
      // Coronha fixa com caída característica do FAL M964
      final Path stock = Path()
        ..moveTo(w * 0.07, cy - h * 0.02)
        ..lineTo(w * 0.29, cy - h * 0.03)
        ..lineTo(w * 0.29, cy + h * 0.045)
        ..lineTo(w * 0.08, cy + h * 0.16)
        ..lineTo(w * 0.06, cy + h * 0.14)
        ..close();
      canvas.drawPath(stock, polymerFill);
      canvas.drawPath(stock, stroke);
    }

    // Caixa da culatra (receiver superior + inferior)
    final RRect receiver = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.29, cy - h * 0.06, w * 0.50, cy + h * 0.045),
      const Radius.circular(2),
    );
    canvas.drawRRect(receiver, metalFill);
    canvas.drawRRect(receiver, stroke);

    // Alça de transporte e massa/alça de mira
    canvas.drawArc(
      Rect.fromLTRB(w * 0.44, cy - h * 0.11, w * 0.50, cy - h * 0.05),
      3.14,
      3.14,
      false,
      stroke,
    );

    // Guarda-mão longo com as 3 janelas de ventilação do FAL
    final Path handguard = Path()
      ..moveTo(w * 0.50, cy - h * 0.05)
      ..lineTo(w * 0.72, cy - h * 0.038)
      ..lineTo(w * 0.72, cy + h * 0.035)
      ..lineTo(w * 0.50, cy + h * 0.045)
      ..close();
    canvas.drawPath(handguard, polymerFill);
    canvas.drawPath(handguard, stroke);
    for (int i = 0; i < 3; i++) {
      final double sx = w * (0.535 + i * 0.055);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(sx, cy - h * 0.015, w * 0.035, h * 0.022),
          const Radius.circular(2),
        ),
        stroke,
      );
    }

    // Bloco de gases e massa de mira triangular
    final Path sightBlock = Path()
      ..moveTo(w * 0.72, cy - h * 0.03)
      ..lineTo(w * 0.74, cy - h * 0.10)
      ..lineTo(w * 0.76, cy - h * 0.03)
      ..close();
    canvas.drawPath(sightBlock, metalFill);
    canvas.drawPath(sightBlock, stroke);

    // Cano + quebra-chamas longo
    final double barrelEnd = foldingStock ? w * 0.89 : w * 0.94;
    canvas.drawLine(
      Offset(w * 0.72, cy - h * 0.01),
      Offset(barrelEnd, cy - h * 0.01),
      stroke..strokeWidth = 2.2,
    );
    stroke.strokeWidth = 1.25;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barrelEnd - w * 0.05, cy - h * 0.03, w * 0.055, h * 0.04),
        const Radius.circular(1.5),
      ),
      metalFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barrelEnd - w * 0.05, cy - h * 0.03, w * 0.055, h * 0.04),
        const Radius.circular(1.5),
      ),
      stroke,
    );

    // Guarda-mato + punho ergonômico
    final Path grip = Path()
      ..moveTo(w * 0.32, cy + h * 0.045)
      ..lineTo(w * 0.28, cy + h * 0.22)
      ..lineTo(w * 0.335, cy + h * 0.22)
      ..lineTo(w * 0.37, cy + h * 0.045)
      ..close();
    canvas.drawPath(grip, polymerFill);
    canvas.drawPath(grip, stroke);

    // Carregador metálico reto 20 tiros (7,62x51 mm)
    final Path mag = Path()
      ..moveTo(w * 0.425, cy + h * 0.045)
      ..lineTo(w * 0.41, cy + h * 0.26)
      ..lineTo(w * 0.485, cy + h * 0.245)
      ..lineTo(w * 0.495, cy + h * 0.045)
      ..close();
    canvas.drawPath(mag, metalFill);
    canvas.drawPath(mag, stroke);
  }

  void _paintIa2(
    Canvas canvas,
    Size size,
    Paint metalFill,
    Paint polymerFill,
    Paint stroke,
  ) {
    final double w = size.width;
    final double h = size.height;
    final double cy = h * 0.44;

    // Coronha rebatível em polímero da IMBEL IA2 com soleira de borracha
    final Path stock = Path()
      ..moveTo(w * 0.10, cy - h * 0.035)
      ..lineTo(w * 0.30, cy - h * 0.045)
      ..lineTo(w * 0.30, cy + h * 0.035)
      ..lineTo(w * 0.13, cy + h * 0.14)
      ..lineTo(w * 0.095, cy + h * 0.13)
      ..close();
    canvas.drawPath(stock, polymerFill);
    canvas.drawPath(stock, stroke);

    // Receptor com trilho Picatinny superior contínuo
    final RRect receiver = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.30, cy - h * 0.068, w * 0.52, cy + h * 0.05),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(receiver, metalFill);
    canvas.drawRRect(receiver, stroke);

    // Guarda-mão moderno do IA2 com defletor térmico
    final Path handguard = Path()
      ..moveTo(w * 0.52, cy - h * 0.062)
      ..lineTo(w * 0.71, cy - h * 0.05)
      ..lineTo(w * 0.71, cy + h * 0.042)
      ..lineTo(w * 0.52, cy + h * 0.05)
      ..close();
    canvas.drawPath(handguard, polymerFill);
    canvas.drawPath(handguard, stroke);

    // Dentes do trilho Picatinny superior
    for (double x = w * 0.32; x < w * 0.68; x += w * 0.03) {
      canvas.drawLine(
        Offset(x, cy - h * 0.082),
        Offset(x + w * 0.015, cy - h * 0.082),
        stroke,
      );
    }

    // Massa de mira + cano + quebra-chamas tipo gaiola
    final Path frontSight = Path()
      ..moveTo(w * 0.71, cy - h * 0.04)
      ..lineTo(w * 0.73, cy - h * 0.105)
      ..lineTo(w * 0.75, cy - h * 0.04)
      ..close();
    canvas.drawPath(frontSight, metalFill);
    canvas.drawPath(frontSight, stroke);

    canvas.drawLine(
      Offset(w * 0.71, cy - h * 0.01),
      Offset(w * 0.89, cy - h * 0.01),
      stroke..strokeWidth = 2.2,
    );
    stroke.strokeWidth = 1.25;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.87, cy - h * 0.03, w * 0.045, h * 0.04),
        const Radius.circular(1.5),
      ),
      metalFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.87, cy - h * 0.03, w * 0.045, h * 0.04),
        const Radius.circular(1.5),
      ),
      stroke,
    );

    // Punho anatômico e carregador curvo STANAG 30 tiros
    final Path grip = Path()
      ..moveTo(w * 0.33, cy + h * 0.05)
      ..lineTo(w * 0.295, cy + h * 0.22)
      ..lineTo(w * 0.35, cy + h * 0.22)
      ..lineTo(w * 0.38, cy + h * 0.05)
      ..close();
    final Path mag = Path()
      ..moveTo(w * 0.445, cy + h * 0.05)
      ..quadraticBezierTo(w * 0.45, cy + h * 0.18, w * 0.50, cy + h * 0.28)
      ..lineTo(w * 0.565, cy + h * 0.255)
      ..quadraticBezierTo(w * 0.515, cy + h * 0.15, w * 0.515, cy + h * 0.05)
      ..close();
    canvas.drawPath(grip, polymerFill);
    canvas.drawPath(grip, stroke);
    canvas.drawPath(mag, metalFill);
    canvas.drawPath(mag, stroke);
  }

  void _paintMag(
    Canvas canvas,
    Size size,
    Paint metalFill,
    Paint polymerFill,
    Paint stroke,
  ) {
    final double w = size.width;
    final double h = size.height;
    final double cy = h * 0.40;

    // Coronha clássica da FN MAG M971
    final Path stock = Path()
      ..moveTo(w * 0.06, cy - h * 0.015)
      ..lineTo(w * 0.24, cy - h * 0.03)
      ..lineTo(w * 0.24, cy + h * 0.05)
      ..lineTo(w * 0.07, cy + h * 0.14)
      ..lineTo(w * 0.055, cy + h * 0.12)
      ..close();
    canvas.drawPath(stock, polymerFill);
    canvas.drawPath(stock, stroke);

    // Caixa da culatra rebitada da MAG + tampa de alimentação
    final RRect receiver = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.24, cy - h * 0.075, w * 0.62, cy + h * 0.065),
      const Radius.circular(2),
    );
    canvas.drawRRect(receiver, metalFill);
    canvas.drawRRect(receiver, stroke);

    // Punho da MAG
    final Path grip = Path()
      ..moveTo(w * 0.29, cy + h * 0.065)
      ..lineTo(w * 0.255, cy + h * 0.23)
      ..lineTo(w * 0.31, cy + h * 0.23)
      ..lineTo(w * 0.34, cy + h * 0.065)
      ..close();
    canvas.drawPath(grip, polymerFill);
    canvas.drawPath(grip, stroke);

    // Cano pesado + tubo cilindro de gases inferior
    canvas.drawLine(
      Offset(w * 0.62, cy - h * 0.025),
      Offset(w * 0.94, cy - h * 0.025),
      stroke..strokeWidth = 2.4,
    );
    canvas.drawLine(
      Offset(w * 0.62, cy + h * 0.022),
      Offset(w * 0.84, cy + h * 0.022),
      stroke..strokeWidth = 1.7,
    );
    stroke.strokeWidth = 1.25;

    // Bipé frontal aberto
    final Path bipodLeft = Path()
      ..moveTo(w * 0.82, cy + h * 0.022)
      ..lineTo(w * 0.76, cy + h * 0.32)
      ..lineTo(w * 0.79, cy + h * 0.32);
    final Path bipodRight = Path()
      ..moveTo(w * 0.82, cy + h * 0.022)
      ..lineTo(w * 0.87, cy + h * 0.32)
      ..lineTo(w * 0.90, cy + h * 0.32);
    canvas.drawPath(bipodLeft, stroke);
    canvas.drawPath(bipodRight, stroke);
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
