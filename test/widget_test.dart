import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tentativa_2/audio_analyzer.dart';
import 'package:tentativa_2/main.dart';
import 'package:tentativa_2/models/weapon.dart';
import 'package:tentativa_2/theme/app_theme.dart';
import 'package:tentativa_2/utils/formatters.dart';
import 'package:tentativa_2/widgets/analysis_charts.dart';
import 'package:tentativa_2/widgets/results_panel.dart';

void main() {
  testWidgets(
      'Renderiza ArsenalWave, armamentos, histórico e instruções (8 a 15 m)',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ArsenalWaveApp());

    expect(find.text('ArsenalWave'), findsOneWidget);
    expect(find.text('FAL'), findsOneWidget);
    expect(find.text('ParaFAL'), findsOneWidget);
    expect(find.text('IA2'), findsOneWidget);
    expect(find.text('MAG'), findsOneWidget);
    expect(find.text('Histórico'), findsOneWidget);
    expect(find.text('Instruções'), findsOneWidget);

    // Abre o modal de histórico
    await tester.tap(find.text('Histórico'));
    await tester.pumpAndSettle();
    expect(find.text('Histórico de Gravações'), findsOneWidget);
    await tester.tap(find.byTooltip('Fechar histórico'));
    await tester.pumpAndSettle();

    // Abre o modal de instruções e verifica distância de 8 a 15 m
    await tester.tap(find.text('Instruções'));
    await tester.pumpAndSettle();

    expect(find.text('Instruções de Uso'), findsOneWidget);
    expect(find.text('Posicionamento seguro (8 a 15 m)'), findsOneWidget);

    await tester.tap(find.text('Entendi'));
    await tester.pumpAndSettle();
    expect(find.text('Instruções de Uso'), findsNothing);
  });

  testWidgets(
      'Exibe GDH, botão de salvamento e alterna gráficos dinamicamente',
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

    final DateTime timestamp = DateTime(2026, 11, 4, 23, 16, 52);
    bool showCharts = false;
    bool saveClicked = false;

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
                  sourceLabel: buildGdhWavFileName(
                    weaponName: kWeaponProfiles.first.name,
                    timestamp: timestamp,
                  ),
                  recordedAt: timestamp,
                  showCharts: showCharts,
                  onToggleCharts: (bool value) {
                    setModalState(() => showCharts = value);
                  },
                  onSaveWithGdh: () {
                    saveClicked = true;
                  },
                  onClear: () {},
                ),
              );
            },
          ),
        ),
      ),
    );

    // GDH e números visíveis imediatamente; gráficos ocultos por padrão
    expect(find.textContaining('GDH 042316NOV26'), findsWidgets);
    expect(find.text('600,0'), findsWidgets);
    expect(find.byType(WaveformChart), findsNothing);
    expect(find.byType(EnergyChart), findsNothing);

    // Testa o botão de salvar com GDH
    await tester.tap(find.textContaining('Salvar WAV com GDH'));
    await tester.pump();
    expect(saveClicked, isTrue);

    // Alterna o Switch para exibir os gráficos
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.byType(WaveformChart), findsOneWidget);
    expect(find.byType(EnergyChart), findsOneWidget);
  });
}
