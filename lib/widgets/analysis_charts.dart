import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../audio_analyzer.dart';
import '../theme/app_theme.dart';

// Os cálculos de amostragem/eixo de tempo destes gráficos foram transferidos
// literalmente de `_buildWaveformChart` / `_buildEnergyChart` do main.dart
// original. Somente cores de borda foram ajustadas ao tema.

/// 1. Áudio e marcadores de disparos.
class WaveformChart extends StatelessWidget {
  const WaveformChart({super.key, required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final r = result;
    int step = (r.audioData.length / 500).clamp(1, double.infinity).toInt();
    List<FlSpot> spots = [];
    for (int i = 0; i < r.audioData.length; i += step) {
      double t = i / r.sampleRate;
      spots.add(FlSpot(t, r.audioData[i]));
    }

    if (spots.isEmpty) {
      return Center(
        child: Text(
          'Amostra insuficiente para exibir a forma de onda.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.border),
        ),
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
}

/// 2. Energia por janela e limiar.
class EnergyChart extends StatelessWidget {
  const EnergyChart({super.key, required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final r = result;
    int windowSize = (0.015 * r.sampleRate).round();
    int overlap = (windowSize / 2).round();
    double frameDuration = (windowSize - overlap) / r.sampleRate;

    int step = (r.frameEnergy.length / 500).clamp(1, double.infinity).toInt();
    List<FlSpot> spots = [];
    for (int i = 0; i < r.frameEnergy.length; i += step) {
      double t = i * frameDuration;
      spots.add(FlSpot(t, r.frameEnergy[i]));
    }

    if (spots.isEmpty) {
      return Center(
        child: Text(
          'Amostra insuficiente para exibir a energia por janela.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.border),
        ),
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
