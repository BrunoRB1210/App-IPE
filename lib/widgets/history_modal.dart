import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../models/recording_entry.dart';
import '../services/recording_history_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'surface_card.dart';

/// Abre o modal de histórico das gravações anteriores feitas pelo aplicativo.
Future<void> showHistoryModal(
  BuildContext context, {
  required RecordingHistoryService history,
  required ValueChanged<RecordingEntry> onSelectEntry,
  required ValueChanged<RecordingEntry> onExportEntry,
}) {
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
    builder: (BuildContext sheetContext) {
      return HistoryModal(
        history: history,
        onSelectEntry: (RecordingEntry entry) {
          Navigator.of(sheetContext).pop();
          onSelectEntry(entry);
        },
        onExportEntry: onExportEntry,
      );
    },
  );
}

/// Modal listando as gravações anteriores salvas com GDH.
class HistoryModal extends StatelessWidget {
  const HistoryModal({
    super.key,
    required this.history,
    required this.onSelectEntry,
    required this.onExportEntry,
  });

  final RecordingHistoryService history;
  final ValueChanged<RecordingEntry> onSelectEntry;
  final ValueChanged<RecordingEntry> onExportEntry;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: history,
      builder: (BuildContext context, Widget? _) {
        final List<RecordingEntry> entries = history.entries;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          minChildSize: 0.45,
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
                          Icons.history_rounded,
                          size: 18,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Histórico de Gravações',
                              style: text.titleLarge,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              entries.isEmpty
                                  ? 'Nenhum registro salvo no dispositivo'
                                  : '${entries.length} ${entries.length == 1 ? 'gravação salva' : 'gravações salvas'} com GDH',
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (entries.isNotEmpty)
                        TextButton(
                          onPressed: () => history.clearAll(),
                          child: const Text('Limpar tudo'),
                        ),
                      IconButton(
                        tooltip: 'Fechar histórico',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: entries.isEmpty
                      ? const _EmptyHistoryView()
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          itemCount: entries.length,
                          separatorBuilder: (BuildContext _, int __) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (BuildContext context, int index) {
                            final RecordingEntry entry = entries[index];
                            return _HistoryEntryCard(
                              entry: entry,
                              onOpen: () => onSelectEntry(entry),
                              onExport: () => onExportEntry(entry),
                              onDelete: () => history.deleteEntry(entry.id),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.history_toggle_off_rounded,
                size: 28,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Nenhuma gravação registrada', style: text.titleMedium),
            const SizedBox(height: AppSpacing.xs + 2),
            Text(
              'As gravações realizadas pelo aplicativo são salvas '
              'automaticamente com o Grupo Data-Hora (GDH) e listadas aqui.',
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({
    required this.entry,
    required this.onOpen,
    required this.onExport,
    required this.onDelete,
  });

  final RecordingEntry entry;
  final VoidCallback onOpen;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String meanStr = entry.meanCadence != null
        ? '${formatDecimal(entry.meanCadence!)} TPM'
        : '--';

    return SurfaceCard(
      backgroundColor: AppColors.background,
      onTap: onOpen,
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
                  color: AppColors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  entry.weaponName,
                  style: text.labelSmall?.copyWith(color: AppColors.accent),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'GDH ${entry.gdh}',
                  style: text.labelSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                formatDateTimeBr(entry.recordedAt),
                style: text.bodySmall?.copyWith(fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(
            entry.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              _StatPill(
                label: 'Disparos',
                value: '${entry.shotCount}',
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatPill(
                label: 'Cadência média',
                value: meanStr,
                highlight: entry.meanCadence != null,
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Exportar WAV com GDH',
                onPressed: onExport,
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.save_alt_rounded,
                  size: 19,
                  color: AppColors.accent,
                ),
              ),
              IconButton(
                tooltip: 'Excluir do histórico',
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('$label: ', style: text.bodySmall?.copyWith(fontSize: 11.5)),
          Text(
            value,
            style: text.labelSmall?.copyWith(
              color: highlight ? AppColors.accent : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
