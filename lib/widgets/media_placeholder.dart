import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Espaço padronizado (proporção fixa) para ilustrações.
///
/// Ordem de exibição: [child] customizado (ex.: diagrama vetorial) →
/// [imageAsset] → ícone + legenda. Enquanto a imagem não carrega, ou se ela
/// falhar, o ícone é exibido no mesmo espaço — o layout nunca "salta".
class MediaPlaceholder extends StatelessWidget {
  const MediaPlaceholder({
    super.key,
    required this.icon,
    this.aspectRatio = 4 / 3,
    this.label,
    this.imageAsset,
    this.child,
    this.highlighted = false,
  });

  final IconData icon;
  final double aspectRatio;
  final String? label;
  final String? imageAsset;
  final Widget? child;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.md);
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: radius,
          border: Border.all(
            color: highlighted
                ? AppColors.accent.withValues(alpha: 0.45)
                : AppColors.border,
          ),
        ),
        child: ClipRRect(borderRadius: radius, child: _buildContent()),
      ),
    );
  }

  Widget _buildContent() {
    final Widget fallback = child ??
        _IconFallback(
          icon: icon,
          label: label,
          highlighted: highlighted,
        );

    final String? asset = imageAsset;
    if (asset == null) return fallback;

    return Image.asset(
      asset,
      fit: BoxFit.contain,
      frameBuilder: (
        BuildContext context,
        Widget image,
        int? frame,
        bool wasSynchronouslyLoaded,
      ) {
        if (wasSynchronouslyLoaded || frame != null) return image;
        return fallback;
      },
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
          fallback,
    );
  }
}

class _IconFallback extends StatelessWidget {
  const _IconFallback({
    required this.icon,
    required this.label,
    required this.highlighted,
  });

  final IconData icon;
  final String? label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double iconSize =
            (constraints.maxHeight * 0.36).clamp(20.0, 64.0).toDouble();
        final bool showLabel = label != null && constraints.maxHeight >= 96;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: iconSize,
                color: highlighted ? AppColors.accent : AppColors.textMuted,
              ),
              if (showLabel) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(
                    label!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
