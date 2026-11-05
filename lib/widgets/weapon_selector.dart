import 'package:flutter/material.dart';

import '../models/weapon.dart';
import '../theme/app_theme.dart';
import 'media_placeholder.dart';
import 'surface_card.dart';
import 'weapon_silhouette.dart';

/// Seletor visual de armamento (FAL, ParaFAL, IA2, MAG, Outro) com espaços
/// padronizados de imagem/placeholder. Apenas identificação visual na UI.
class WeaponSelector extends StatelessWidget {
  const WeaponSelector({
    super.key,
    required this.weapons,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
  });

  final List<WeaponProfile> weapons;
  final WeaponProfile selected;
  final ValueChanged<WeaponProfile> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int i = 0; i < weapons.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: AppSpacing.md),
                _WeaponCard(
                  weapon: weapons[i],
                  selected: weapons[i].id == selected.id,
                  enabled: enabled,
                  onTap: () => onSelected(weapons[i]),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SurfaceCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 68,
                child: MediaPlaceholder(
                  icon: selected.icon,
                  aspectRatio: 16 / 10,
                  imageAsset: selected.imageAsset,
                  highlighted: true,
                  child: WeaponSilhouette(
                    kind: selected.silhouette,
                    highlighted: true,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      selected.fullName,
                      style: text.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selected.imageAsset == null
                          ? 'Placeholder ilustrativo • ${selected.caliber}'
                          : selected.caliber,
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  selected.caliber,
                  style: text.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeaponCard extends StatelessWidget {
  const _WeaponCard({
    required this.weapon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  static const double _width = 136;

  final WeaponProfile weapon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    final TextTheme text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Armamento ${weapon.name}',
      child: Opacity(
        opacity: enabled || selected ? 1 : 0.45,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: _width,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.08)
                : AppColors.surface,
            borderRadius: radius,
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radius,
              onTap: enabled ? onTap : null,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    MediaPlaceholder(
                      icon: weapon.icon,
                      aspectRatio: 16 / 10,
                      imageAsset: weapon.imageAsset,
                      highlighted: selected,
                      child: WeaponSilhouette(
                        kind: weapon.silhouette,
                        highlighted: selected,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            weapon.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleSmall,
                          ),
                        ),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: selected ? 1 : 0,
                          child: const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      weapon.caliber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
