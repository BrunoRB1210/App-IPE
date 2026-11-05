import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'audio_analyzer.dart';
import 'models/recording_entry.dart';
import 'models/weapon.dart';
import 'services/audio_capture_service.dart';
import 'services/recording_history_service.dart';
import 'theme/app_theme.dart';
import 'utils/formatters.dart';
import 'widgets/capture_panel.dart';
import 'widgets/history_modal.dart';
import 'widgets/instructions_modal.dart';
import 'widgets/results_panel.dart';
import 'widgets/surface_card.dart';
import 'widgets/weapon_selector.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ArsenalWaveApp());
}

/// Alias mantido para compatibilidade com importações existentes de `MyApp`.
typedef MyApp = ArsenalWaveApp;

class ArsenalWaveApp extends StatelessWidget {
  const ArsenalWaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArsenalWave',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final AudioCaptureService _capture;
  late final RecordingHistoryService _history;
  final GlobalKey _resultsAnchorKey = GlobalKey();

  WeaponProfile _selectedWeapon = kWeaponProfiles.first;
  AnalysisResult? _result;
  String? _sourceLabel;
  String? _activeWavPath;
  DateTime _recordedAt = DateTime.now();
  bool _isAnalyzing = false;
  bool _showCharts = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _capture = AudioCaptureService()..addListener(_handleCaptureUpdate);
    _history = RecordingHistoryService();
    unawaited(_history.load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _capture
      ..removeListener(_handleCaptureUpdate)
      ..dispose();
    _history.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Libera imediatamente o microfone caso a engine seja encerrada pelo SO.
    if (state == AppLifecycleState.detached && _capture.isRecording) {
      unawaited(_capture.cancel());
    }
  }

  void _handleCaptureUpdate() {
    final String? interruption = _capture.consumeInterruptionMessage();
    if (interruption != null && mounted) {
      _showMessage(interruption);
    }
  }

  Future<void> _startRecording() async {
    if (_isAnalyzing || _capture.isBusy || _capture.isRecording) return;

    try {
      await _capture.start();
      if (!mounted) return;
      if (_capture.isRecording) {
        setState(() {
          _result = null;
          _sourceLabel = null;
          _activeWavPath = null;
          _showCharts = false;
        });
      }
    } on CaptureException catch (error) {
      if (!mounted) return;
      _showCaptureError(error);
    } catch (error) {
      if (!mounted) return;
      _showMessage('Erro inesperado ao iniciar gravação: $error');
    }
  }

  Future<void> _stopAndAnalyze() async {
    if (!_capture.isRecording) return;

    String? recordedPath;
    try {
      recordedPath = await _capture.stop();
    } on CaptureException catch (error) {
      if (!mounted) return;
      _showCaptureError(error);
      return;
    } catch (error) {
      if (!mounted) return;
      _showMessage('Erro ao encerrar gravação: $error');
      return;
    }

    final DateTime captureTime = DateTime.now();
    final String gdhName = buildGdhWavFileName(
      weaponName: _selectedWeapon.name,
      timestamp: captureTime,
    );

    await _analyzeWavFile(
      recordedPath,
      label: gdhName,
      timestamp: captureTime,
      saveToHistoryOnSuccess: true,
      deleteTempAfterAnalysis: true,
    );
  }

  Future<void> _cancelRecording() async {
    await _capture.cancel();
    if (!mounted) return;
    _showMessage('Gravação cancelada.');
  }

  Future<void> _pickAndAnalyzeFile() async {
    if (_isAnalyzing || _capture.isRecording || _capture.isBusy) return;

    try {
      final PlatformFile? picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: <String>['wav'],
      );
      if (picked == null || picked.path == null) return;

      await _analyzeWavFile(
        picked.path!,
        label: picked.name,
        timestamp: DateTime.now(),
        saveToHistoryOnSuccess: false,
        deleteTempAfterAnalysis: false,
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage('Não foi possível abrir o seletor de arquivos: $error');
    }
  }

  /// Entrega o arquivo WAV diretamente ao `AudioAnalyzer.processWavFile`,
  /// preservando integralmente o contrato de entrada e saída do módulo DSP.
  Future<void> _analyzeWavFile(
    String path, {
    required String label,
    required DateTime timestamp,
    required bool saveToHistoryOnSuccess,
    required bool deleteTempAfterAnalysis,
  }) async {
    if (!mounted) {
      if (deleteTempAfterAnalysis) {
        await AudioCaptureService.deleteRecording(path);
      }
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _sourceLabel = label;
      _recordedAt = timestamp;
      _showCharts = false;
    });

    try {
      final AnalysisResult result = await AudioAnalyzer.processWavFile(path);

      String finalPath = path;
      String finalLabel = label;
      if (saveToHistoryOnSuccess) {
        try {
          final RecordingEntry entry = await _history.saveRecording(
            sourcePath: path,
            weapon: _selectedWeapon,
            timestamp: timestamp,
            result: result,
          );
          finalPath = entry.filePath;
          finalLabel = entry.fileName;
        } catch (_) {
          // Mantém o resultado na tela mesmo se o armazenamento local falhar.
        }
      }

      if (!mounted) return;
      setState(() {
        _result = result;
        _sourceLabel = finalLabel;
        _activeWavPath = finalPath;
        _isAnalyzing = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final BuildContext? anchor = _resultsAnchorKey.currentContext;
        if (anchor != null) {
          Scrollable.ensureVisible(
            anchor,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      _showMessage('Erro ao analisar arquivo WAV: $error');
    } finally {
      if (deleteTempAfterAnalysis) {
        await AudioCaptureService.deleteRecording(path);
      }
    }
  }

  Future<void> _saveCurrentWavWithGdh() async {
    final String? path = _activeWavPath;
    final AnalysisResult? result = _result;
    if (path == null || result == null) return;

    try {
      // Garante que também esteja salvo no histórico interno com GDH
      final RecordingEntry saved = await _history.saveRecording(
        sourcePath: path,
        weapon: _selectedWeapon,
        timestamp: _recordedAt,
        result: result,
      );
      if (mounted) {
        setState(() {
          _activeWavPath = saved.filePath;
          _sourceLabel = saved.fileName;
        });
      }

      final String? exported = await _history.exportWavWithGdh(
        sourcePath: saved.filePath,
        weapon: _selectedWeapon,
        timestamp: _recordedAt,
      );
      if (!mounted) return;
      if (exported != null) {
        _showMessage('Arquivo salvo com GDH: ${saved.fileName}');
      } else {
        _showMessage('Salvo no histórico interno: ${saved.fileName}');
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage('Não foi possível salvar o arquivo com GDH: $error');
    }
  }

  Future<void> _openHistoryEntry(RecordingEntry entry) async {
    if (_isAnalyzing || _capture.isRecording || _capture.isBusy) return;

    final WeaponProfile matchedWeapon = kWeaponProfiles.firstWhere(
      (WeaponProfile w) => w.id == entry.weaponId,
      orElse: () => _selectedWeapon,
    );
    setState(() => _selectedWeapon = matchedWeapon);

    await _analyzeWavFile(
      entry.filePath,
      label: entry.fileName,
      timestamp: entry.recordedAt,
      saveToHistoryOnSuccess: false,
      deleteTempAfterAnalysis: false,
    );
  }

  Future<void> _exportHistoryEntry(RecordingEntry entry) async {
    final WeaponProfile matchedWeapon = kWeaponProfiles.firstWhere(
      (WeaponProfile w) => w.id == entry.weaponId,
      orElse: () => _selectedWeapon,
    );
    try {
      final String? exported = await _history.exportWavWithGdh(
        sourcePath: entry.filePath,
        weapon: matchedWeapon,
        timestamp: entry.recordedAt,
      );
      if (!mounted || exported == null) return;
      _showMessage('Arquivo exportado: ${entry.fileName}');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Erro ao exportar gravação: $error');
    }
  }

  void _clearResults() {
    setState(() {
      _result = null;
      _sourceLabel = null;
      _activeWavPath = null;
      _showCharts = false;
    });
  }

  void _showCaptureError(CaptureException error) {
    final bool denied = error.kind == CaptureErrorKind.permissionDenied;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(error.message),
        action: denied
            ? SnackBarAction(
                label: 'Configurações',
                onPressed: () {
                  unawaited(openAppSettings());
                },
              )
            : null,
      ),
    );
  }

  void _showMessage(String message) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[_capture, _history]),
      builder: (BuildContext context, Widget? _) {
        final bool busy =
            _isAnalyzing || _capture.isRecording || _capture.isBusy;

        return PopScope(
          canPop: !_capture.isRecording && !_capture.isBusy,
          onPopInvokedWithResult: (bool didPop, Object? _) {
            if (!didPop && _capture.isRecording) {
              unawaited(_cancelRecording());
            }
          },
          child: Scaffold(
            appBar: _ArsenalWaveAppBar(
              historyCount: _history.entries.length,
              onOpenHistory: () => showHistoryModal(
                context,
                history: _history,
                onSelectEntry: _openHistoryEntry,
                onExportEntry: _exportHistoryEntry,
              ),
              onOpenInstructions: () => showInstructionsModal(context),
            ),
            body: SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SectionHeader(
                          step: 'Etapa 1',
                          title: 'Armamento do ensaio',
                          subtitle:
                              'Identifique o armamento avaliado (FAL, ParaFAL, IA2, MAG)',
                        ),
                        WeaponSelector(
                          weapons: kWeaponProfiles,
                          selected: _selectedWeapon,
                          enabled: !busy,
                          onSelected: (WeaponProfile weapon) {
                            setState(() => _selectedWeapon = weapon);
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const SectionHeader(
                          step: 'Etapa 2',
                          title: 'Posicionamento (8 a 15 m) e captura acústica',
                          subtitle:
                              'Grave pelo microfone com salvamento GDH ou importe um WAV',
                        ),
                        CapturePanel(
                          capture: _capture,
                          isProcessing: _isAnalyzing,
                          onStart: _startRecording,
                          onStop: _stopAndAnalyze,
                          onCancel: _cancelRecording,
                          onImport: _pickAndAnalyzeFile,
                        ),
                        if (_isAnalyzing) ...<Widget>[
                          const SizedBox(height: AppSpacing.xl),
                          _ProcessingCard(sourceLabel: _sourceLabel),
                        ] else if (_result != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.xl),
                          SectionHeader(
                            key: _resultsAnchorKey,
                            step: 'Etapa 3',
                            title: 'Resultados de cadência',
                            subtitle:
                                'Métricas em tiros por minuto (TPM) e detecção de picos',
                          ),
                          ResultsPanel(
                            result: _result!,
                            weapon: _selectedWeapon,
                            sourceLabel: _sourceLabel ?? 'Áudio analisado',
                            recordedAt: _recordedAt,
                            showCharts: _showCharts,
                            onToggleCharts: (bool value) {
                              setState(() => _showCharts = value);
                            },
                            onSaveWithGdh: _activeWavPath != null
                                ? _saveCurrentWavWithGdh
                                : null,
                            onClear: _clearResults,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ArsenalWaveAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ArsenalWaveAppBar({
    required this.historyCount,
    required this.onOpenHistory,
    required this.onOpenInstructions,
  });

  final int historyCount;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenInstructions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return AppBar(
      toolbarHeight: 64,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1),
      ),
      titleSpacing: AppSpacing.lg,
      title: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.graphic_eq_rounded,
              size: 18,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'ArsenalWave',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(letterSpacing: -0.2),
                ),
                Text(
                  'Cadência Acústica',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: <Widget>[
        OutlinedButton.icon(
          onPressed: onOpenHistory,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 38),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 4,
              vertical: AppSpacing.sm,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm + 2),
            ),
            side: const BorderSide(color: AppColors.borderStrong),
            textStyle: text.labelMedium,
          ),
          icon: const Icon(
            Icons.history_rounded,
            size: 16,
            color: AppColors.accent,
          ),
          label: Text(
            historyCount > 0 ? 'Histórico ($historyCount)' : 'Histórico',
            style: const TextStyle(
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          child: OutlinedButton.icon(
            onPressed: onOpenInstructions,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 4,
                vertical: AppSpacing.sm,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm + 2),
              ),
              side: const BorderSide(color: AppColors.borderStrong),
              textStyle: text.labelMedium,
            ),
            icon: const Icon(
              Icons.help_outline_rounded,
              size: 16,
              color: AppColors.accent,
            ),
            label: const Text('Instruções'),
          ),
        ),
      ],
    );
  }
}

class _ProcessingCard extends StatelessWidget {
  const _ProcessingCard({required this.sourceLabel});

  final String? sourceLabel;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: <Widget>[
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Analisando sinal acústico…', style: text.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    sourceLabel ?? 'Processando arquivo WAV',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
