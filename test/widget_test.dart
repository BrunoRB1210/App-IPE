import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tentativa_2/audio_analyzer.dart';
import 'package:tentativa_2/main.dart';
import 'package:tentativa_2/models/weapon.dart';
import 'package:tentativa_2/theme/app_theme.dart';
import 'package:tentativa_2/widgets/analysis_charts.dart';
import 'package:tentativa_2/widgets/results_panel.dart';

void main() {
  testWidgets('Renderiza cabeçalho ArsenalWave, armamentos e modal de instruções',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ArsenalWaveApp());

    expect(find.text('ArsenalWave'), findsOneWidget);
    expect(find.text('FAL'), findsOneWidget);
    expect(find.text('ParaFAL'), findsOneWidget);
    expect(find.text('IA2'), findsOneWidget);
    expect(find.text('MAG'), findsOneWidget);
    expect(find.text('Iniciar gravação'), findsOneWidget);

    // Abre o modal de instruções
    await tester.tap(find.text('Instruções'));
    await tester.pumpAndSettle();

    expect(find.text('Instruções de Uso'), findsOneWidget);
    expect(find.text('Entendi'), findsOneWidget);

    // Fecha o modal de instruções
    await tester.tap(find.text('Entendi'));
    await tester.pumpAndSettle();

    expect(find.text('Instruções de Uso'), findsNothing);
  });

  testWidgets('Exibe números com prioridade e alterna gráficos dinamicamente',
      (WidgetTester tester) async {
    final AnalysisResult mockResult = AnalysisResult(
      audioData: List<double>.filled(1000, 0.1),
      sampleRate: 44100,
      frameEnergy: List<double>.filled(20, 0.05),
      energyThreshold: 0.02,
      shootingTimes: const <double>[0.10, 0.20, 0.30],
      meanCadence: 600.0,
      maxCadence: 620.0,
      minCadence: 580.0,
    );

    bool showCharts = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return SingleChildScrollView(
                child: ResultsPanel(
                  result: mockResult,
                  weapon: kWeaponProfiles.first,
                  sourceLabel: 'ensaio_fal.wav',
                  showCharts: showCharts,
                  onToggleCharts: (bool value) {
                    setModalState(() => showCharts = value);
                  },
                  onClear: () {},
                ),
              );
            },
          ),
        ),
      ),
    );

    // Números visíveis imediatamente e gráficos ocultos por padrão
    expect(find.text('600,0'), findsWidgets);
    expect(find.byType(WaveformChart), findsNothing);
    expect(find.byType(EnergyChart), findsNothing);

    // Alterna o Switch para exibir os gráficos
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.byType(WaveformChart), findsOneWidget);
    expect(find.byType(EnergyChart), findsOneWidget);

    // Alterna novamente para recolher os gráficos
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.byType(WaveformChart), findsNothing);
    expect(find.byType(EnergyChart), findsNothing);
  });
}
