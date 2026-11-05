import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../services/audio_capture_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'positioning_diagram.dart';
import 'recording_badge.dart';
import 'surface_card.dart';

/// Painel de captura: estado do gravador, cronômetro, medidor de nível e ações.
class CapturePanel extends StatelessWidget {
  const CapturePanel({
    super.key,
    required this.capture,
    required this.isProcessing,
    required this.onStart,
    required this.onStop,
    required this.onCancel,
    required this.onImport,
  });

  final AudioCaptureService capture;
  final bool isProcessing;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onCancel;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final CapturePhase phase = capture.phase;
    final bool recording = phase == CapturePhase.recording;

    return SurfaceCard(
      borderColor: recording
          ? AppColors.recording.withValues(alpha: 0.5)
          : AppColors.border,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: switch (phase) {
          CapturePhase.idle => _IdleView(
              isProcessing: isProcessing,
              onStart: onStart,
              onImport: onImport,
            ),
          CapturePhase.starting => const _BusyView(
              message: 'Preparando o microfone…',
            ),
          CapturePhase.recording => _RecordingView(
              capture: capture,
              onStop: onStop,
              onCancel: onCancel,
            ),
          CapturePhase.stopping => const _BusyView(
              message: 'Finalizando a gravação…',
            ),
        },
      ),
    );
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({
    required this.isProcessing,
    required this.onStart,
    required this.onImport,
  });

  final bool isProcessing;
  final VoidCallback onStart;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const PositioningDiagram(),
        const SizedBox(height: AppSpacing.md),
        for (final String tip in kPositioningTips.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(
                    Icons.check,
                    size: 14,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(tip, style: text.bodySmall)),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: isProcessing ? null : onStart,
          icon: const Icon(Icons.mic_none),
          label: const Text('Iniciar gravação'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: isProcessing ? null : onImport,
          icon: const Icon(Icons.audio_file_outlined),
          label: const Text('Importar arquivo WAV'),
        ),
      ],
    );
  }
}

class _BusyView extends StatelessWidget {
  const _BusyView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingView extends StatelessWidget {
  const _RecordingView({
    required this.capture,
    required this.onStop,
    required this.onCancel,
  });

  final AudioCaptureService capture;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final double peak = capture.peakDb;
    final bool nearClipping = peak > -1.0;
    final Color meterColor =
        nearClipping ? AppColors.warning : AppColors.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Row(
          children: <Widget>[
            RecordingBadge(),
            Spacer(),
            Icon(Icons.graphic_eq, size: 18, color: AppColors.textMuted),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Text(
            formatClock(capture.elapsed),
            style: text.headlineMedium?.copyWith(
              fontSize: 44,
              fontWeight: FontWeight.w600,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
            semanticsLabel:
                'Tempo de captura ${capture.elapsed.inSeconds} segundos',
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Center(child: Text('Tempo de captura', style: text.bodySmall)),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: <Widget>[
            Text('Nível', style: text.labelMedium),
            const Spacer(),
            Text(
              peak <= AudioCaptureService.silenceDb
                  ? 'Pico: --'
                  : 'Pico: ${formatDecimal(peak)} dBFS',
              style: text.labelSmall?.copyWith(
                color: nearClipping ? AppColors.warning : AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: capture.levelFraction,
            minHeight: 6,
            color: meterColor,
            backgroundColor: AppColors.border,
          ),
        ),
        if (nearClipping) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Sinal no limite do microfone. Se possível, afaste o dispositivo.',
            style: text.bodySmall?.copyWith(color: AppColors.warning),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(
          'Mantenha o app aberto em primeiro plano até concluir os disparos.',
          style: text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: onStop,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.recording,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.stop_rounded),
          label: const Text('Parar e analisar'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: onCancel,
          icon: const Icon(Icons.close),
          label: const Text('Cancelar gravação'),
        ),
      ],
    );
  }
}
