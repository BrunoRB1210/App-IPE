import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'audio_analyzer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Análise de Disparos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AnalysisResult? _result;
  bool _isLoading = false;
  String? _fileName;

  // Controlador de gravação
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  /// Seleciona um arquivo WAV existente
  Future<void> _pickAndProcessFile() async {
    PlatformFile? picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['wav'],
    );

    if (picked != null && picked.path != null) {
      await _processFile(picked.path!, picked.name);
    }
  }

  /// Inicia ou para a gravação de áudio em PCM Raw / Sem DSP
  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        // Parar a gravação
        final path = await _audioRecorder.stop();
        setState(() => _isRecording = false);

        if (path != null) {
          await _processFile(path, 'audio_gravado.wav');
        }
      } else {
        // Verificar e solicitar permissão de microfone
        if (await _audioRecorder.hasPermission()) {
          final dir = await getTemporaryDirectory();
          final filePath =
              '${dir.path}/audio_disparos_${DateTime.now().millisecondsSinceEpoch}.wav';

          await _audioRecorder.start(
            const RecordConfig(
              encoder: AudioEncoder
                  .pcm16bits, // PCM 16-bit nativo sem perda/compressão
              sampleRate: 44100, // Amostragem de 44.1 kHz
              numChannels: 2, // Estéreo (use 1 caso prefira Mono)
              autoGain: false, // Desativa Ganho Automático (AGC)
              echoCancel: false, // Desativa Cancelamento de Eco
              noiseSuppress: false, // Desativa Supressão de Ruído
              // Configurações do Android: força áudio cru (UNPROCESSED)
              androidConfig: AndroidRecordConfig(
                audioSource: AndroidAudioSource.unprocessed,
              ),

              // Configurações do iOS: modo de medição (MEASUREMENT) para evitar DSP de voz
              iosConfig: IosRecordConfig(),
            ),
            path: filePath,
          );

          setState(() {
            _isRecording = true;
            _result = null; // Limpa resultado anterior
          });
        }
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro na gravação: $e')));
      }
    }
  }

  /// Processa o arquivo de áudio (seja gravado ou escolhido)
  Future<void> _processFile(String path, String name) async {
    setState(() {
      _isLoading = true;
      _fileName = name;
    });

    try {
      final result = await AudioAnalyzer.processWavFile(path);
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao analisar arquivo: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise de Disparos'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Botões de Ação lado a lado (Selecionar Arquivo vs Gravar Áudio)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isLoading || _isRecording)
                        ? null
                        : _pickAndProcessFile,
                    icon: const Icon(Icons.audio_file),
                    label: Text(_fileName ?? 'Arquivo WAV'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _toggleRecording,
                    icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                    label: Text(_isRecording ? 'Parar' : 'Gravar Áudio'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Indicador de Gravação Ativa
            if (_isRecording)
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fiber_manual_record, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Gravando áudio... Dispare próximo ao microfone.'),
                  ],
                ),
              ),

            // Conteúdo Principal / Carregamento
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Analisando sinal de áudio...'),
                    ],
                  ),
                ),
              )
            else if (_result != null) ...[
              _buildStatsCard(),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    const Text(
                      '1. Áudio e Marcadores de Disparos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(height: 200, child: _buildWaveformChart()),
                    const SizedBox(height: 24),
                    const Text(
                      '2. Energia por Janela e Limiar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(height: 200, child: _buildEnergyChart()),
                  ],
                ),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Text(
                    'Selecione um arquivo WAV ou grave um áudio para começar.',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final r = _result!;
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Disparos Detectados: ${r.shootingTimes.length}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('Cadência Máx', r.maxCadence),
                _statItem('Cadência Média', r.meanCadence),
                _statItem('Cadência Mín', r.minCadence),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, double? val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          val != null ? '${val.toStringAsFixed(1)}\ntiros/min' : '--',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildWaveformChart() {
    final r = _result!;
    int step = (r.audioData.length / 500).clamp(1, double.infinity).toInt();
    List<FlSpot> spots = [];
    for (int i = 0; i < r.audioData.length; i += step) {
      double t = i / r.sampleRate;
      spots.add(FlSpot(t, r.audioData[i]));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: Colors.lightBlueAccent,
            barWidth: 1,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: r.shootingTimes.map((t) => FlSpot(t, 0.9)).toList(),
            isCurved: false,
            color: Colors.red,
            barWidth: 0,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: Colors.red,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyChart() {
    final r = _result!;
    int windowSize = (0.015 * r.sampleRate).round();
    int overlap = (windowSize / 2).round();
    double frameDuration = (windowSize - overlap) / r.sampleRate;

    int step = (r.frameEnergy.length / 500).clamp(1, double.infinity).toInt();
    List<FlSpot> spots = [];
    for (int i = 0; i < r.frameEnergy.length; i += step) {
      double t = i * frameDuration;
      spots.add(FlSpot(t, r.frameEnergy[i]));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: true),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: r.energyThreshold,
              color: Colors.amber,
              strokeWidth: 1.5,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                labelResolver: (line) => ' Limiar',
              ),
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: Colors.redAccent,
            barWidth: 1.2,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
