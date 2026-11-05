import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../audio_analyzer.dart';
import '../models/weapon.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'analysis_charts.dart';
import 'metric_tile.dart';
import 'surface_card.dart';

/// Painel de resultados da análise acústica: prioriza as métricas numéricas
/// (cadência em TPM e disparos detectados), permite salvar/exportar o arquivo
/// WAV com o GDH e oferece controle dinâmico (`Switch`) para mostrar ou ocultar
/// os gráficos de forma de onda e energia.
class ResultsPanel extends StatelessWidget {
  const ResultsPanel({
    super.key,
    required this.result,
    required this.weapon,
    required this.sourceLabel,
    required this.recordedAt,
    required this.showCharts,
    required this.onToggleCharts,
    required this.onSaveWithGdh,
    required this.onClear,
  });

  final AnalysisResult result;
  final WeaponProfile weapon;
  final String sourceLabel;
  final DateTime recordedAt;
  final bool showCharts;
  final ValueChanged<bool> onToggleCharts;
  final VoidCallback? onSaveWithGdh;
  final VoidCallback onClear;

  String _formatTpm(double? value) =>
      value != null ? formatDecimal(value) : '--';

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final int shotCount = result.shootingTimes.length;
    final String gdhCode = formatGdh(recordedAt);
    final String gdhFileName = buildGdhWavFileName(
      weaponName: weapon.name,
      timestamp: recordedAt,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Cabeçalho contextual do ensaio com GDH e botão Salvar WAV com GDH
        SurfaceCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(weapon.icon, size: 18, color: AppColors.accent),
                  const SizedBox(width: AppSpacing.sm + 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                '${weapon.name} • ${weapon.caliber}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.titleSmall,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceRaised,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                'GDH $gdhCode',
                                style: text.labelSmall?.copyWith(
                                  color: AppColors.accent,
                                  fontFeatures: const <FontFeature>[
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          sourceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Limpar'),
                  ),
                ],
              ),
              if (onSaveWithGdh != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: onSaveWithGdh,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    side: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.45),
                    ),
                  ),
                  icon: const Icon(
                    Icons.save_alt_rounded,
                    size: 18,
                    color: AppColors.accent,
                  ),
                  label: Text(
                    'Salvar WAV com GDH ($gdhFileName)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Cartão principal (Hero): Cadência Média + Total de Disparos
        SurfaceCard(
          borderColor: AppColors.accent.withValues(alpha: 0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('CADÊNCIA MÉDIA', style: text.labelSmall),
                        const SizedBox(height: AppSpacing.xs + 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: <Widget>[
                              Text(
                                _formatTpm(result.meanCadence),
                                style: text.headlineMedium?.copyWith(
                                  fontSize: 40,
                                  color: AppColors.accent,
                                  fontFeatures: const <FontFeature>[
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'TPM',
                                style: text.titleSmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text('tiros por minuto', style: text.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text('DISPAROS', style: text.labelSmall),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '$shotCount',
                          style: text.headlineMedium?.copyWith(
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                        Text('detectados', style: text.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              if (shotCount < 2) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        shotCount == 0
                            ? 'Nenhum disparo acima do limiar de energia foi detectado neste áudio.'
                            : 'Apenas 1 disparo detectado. São necessários ao menos 2 disparos para calcular a cadência em TPM.',
                        style: text.bodySmall?.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Grid limpo de métricas numéricas
        MetricGrid(
          children: <Widget>[
            MetricTile(
              label: 'Total de disparos',
              value: '$shotCount',
              unit: shotCount == 1 ? 'tiro' : 'tiros',
              icon: Icons.bolt_outlined,
            ),
            MetricTile(
              label: 'Cadência média',
              value: _formatTpm(result.meanCadence),
              unit: result.meanCadence != null ? 'TPM' : null,
              icon: Icons.speed_outlined,
            ),
            MetricTile(
              label: 'Cadência máxima',
              value: _formatTpm(result.maxCadence),
              unit: result.maxCadence != null ? 'TPM' : null,
              icon: Icons.north_east_rounded,
            ),
            MetricTile(
              label: 'Cadência mínima',
              value: _formatTpm(result.minCadence),
              unit: result.minCadence != null ? 'TPM' : null,
              icon: Icons.south_east_rounded,
            ),
          ],
        ),

        // Instantes de cada disparo (diretamente do AnalysisResult.shootingTimes)
        if (result.shootingTimes.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          SurfaceCard(
            padding: const EdgeInsets.all(AppSpacing.md + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.schedule_outlined,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Text(
                      'Instantes dos disparos detectados',
                      style: text.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      for (int i = 0;
                          i < result.shootingTimes.length;
                          i++) ...<Widget>[
                        if (i > 0) const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm + 2,
                            vertical: AppSpacing.xs + 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceRaised,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            '#${i + 1}  ${formatSeconds(result.shootingTimes[i], decimals: 2)}',
                            style: text.labelSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.md),

        // Controle interativo (Switch) para expandir ou recolher os gráficos
        SurfaceCard(
          onTap: () => onToggleCharts(!showCharts),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: showCharts
                      ? AppColors.accent.withValues(alpha: 0.14)
                      : AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: showCharts
                        ? AppColors.accent.withValues(alpha: 0.4)
                        : AppColors.border,
                  ),
                ),
                child: Icon(
                  Icons.ssid_chart_rounded,
                  size: 18,
                  color:
                      showCharts ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      showCharts ? 'Ocultar gráficos' : 'Mostrar gráficos',
                      style: text.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      showCharts
                          ? 'Forma de onda e energia por janela visíveis'
                          : 'Toque para inspecionar forma de onda e limiar',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch(
                value: showCharts,
                onChanged: onToggleCharts,
              ),
            ],
          ),
        ),

        // Área expansível dos gráficos (oculta por padrão para priorizar números)
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: showCharts
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _ChartCard(
                        title: '1. Forma de Onda e Marcadores de Disparos',
                        subtitle:
                            'Sinal normalizado (azul) e picos detectados (vermelho)',
                        child: SizedBox(
                          height: 200,
                          child: WaveformChart(result: result),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ChartCard(
                        title: '2. Energia por Janela e Limiar',
                        subtitle:
                            'Envoltória de energia por janela e linha tracejada de limiar',
                        child: SizedBox(
                          height: 200,
                          child: EnergyChart(result: result),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: text.titleSmall),
          const SizedBox(height: 2),
          Text(subtitle, style: text.bodySmall),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
