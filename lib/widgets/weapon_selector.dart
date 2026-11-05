import 'package:flutter/material.dart';

import '../models/weapon.dart';
import '../theme/app_theme.dart';
import 'media_placeholder.dart';

/// Carrossel horizontal de seleção do armamento (somente UI).
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
        Row(
          children: <Widget>[
            const Icon(
              Icons.info_outline,
              size: 16,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                selected.description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
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

  static const double _width = 128;

  final WeaponProfile weapon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
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
                      imageAsset: weapon.imageAsset,
                      highlighted: selected,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            weapon.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
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
