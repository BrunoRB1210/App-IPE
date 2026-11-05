import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'positioning_diagram.dart';
import 'surface_card.dart';

/// Exibe o modal passo a passo de instruções operacionais do ArsenalWave.
Future<void> showInstructionsModal(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    constraints: const BoxConstraints(maxWidth: 640),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.lg + 4),
      ),
      side: BorderSide(color: AppColors.border),
    ),
    builder: (BuildContext sheetContext) => const InstructionsModal(),
  );
}

/// Conteúdo visual do guia de uso do ArsenalWave.
class InstructionsModal extends StatelessWidget {
  const InstructionsModal({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.86,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      builder: (BuildContext context, ScrollController scrollController) {
        return Column(
          children: <Widget>[
            const SizedBox(height: AppSpacing.sm + 2),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.menu_book_outlined,
                      size: 18,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Instruções de Uso', style: text.titleLarge),
                        const SizedBox(height: 2),
                        Text(
                          'Guia rápido para medição acústica no ArsenalWave',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar instruções',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: <Widget>[
                  const _InstructionStepCard(
                    number: '01',
                    icon: Icons.gps_fixed,
                    title: 'Selecione o armamento',
                    description:
                        'Escolha no topo da tela o armamento avaliado '
                        '(FAL, ParaFAL, IA2, MAG ou Outro) para identificar '
                        'visualmente a sessão de tiro.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _InstructionStepCard(
                    number: '02',
                    icon: Icons.shield_outlined,
                    title: 'Posicionamento seguro do celular',
                    description:
                        'Mantenha o aparelho fora do cone de sopro e da linha '
                        'de tiro para preservar a segurança e evitar saturação '
                        'do microfone.',
                    extra: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SizedBox(height: AppSpacing.md),
                        const PositioningDiagram(),
                        const SizedBox(height: AppSpacing.md),
                        for (final String tip in kPositioningTips)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xs + 2,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Padding(
                                  padding: EdgeInsets.only(top: 3),
                                  child: Icon(
                                    Icons.check_circle_outline,
                                    size: 14,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(tip, style: text.bodySmall),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _InstructionStepCard(
                    number: '03',
                    icon: Icons.mic_none,
                    title: 'Inicie e encerre a gravação acústica',
                    description:
                        'Toque em "Iniciar gravação" antes dos disparos. O app '
                        'captura áudio cru (WAV PCM 16-bit / 44,1 kHz sem AGC). '
                        'Ao terminar a série, toque em "Parar e analisar" — ou '
                        'importe um arquivo WAV existente.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _InstructionStepCard(
                    number: '04',
                    icon: Icons.speed_outlined,
                    title: 'Leia a cadência (TPM) e expanda os gráficos',
                    description:
                        'Os resultados destacam imediatamente o total de '
                        'disparos e a cadência Média, Máxima e Mínima em tiros '
                        'por minuto (TPM). Ative a chave "Mostrar gráficos" '
                        'quando desejar inspecionar a forma de onda e o limiar '
                        'de energia.',
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendi'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InstructionStepCard extends StatelessWidget {
  const _InstructionStepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
    this.extra,
  });

  final String number;
  final IconData icon;
  final String title;
  final String description;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return SurfaceCard(
      backgroundColor: AppColors.background,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'PASSO $number',
                  style: text.labelSmall?.copyWith(
                    color: AppColors.accent,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              Icon(icon, size: 18, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(title, style: text.titleMedium),
          const SizedBox(height: AppSpacing.xs + 2),
          Text(description, style: text.bodyMedium),
          if (extra != null) extra!,
        ],
      ),
    );
  }
}
