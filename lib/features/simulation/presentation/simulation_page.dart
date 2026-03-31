import 'dart:math';

import 'package:flutter/material.dart';

import '../domain/protocol.dart';
import '../domain/scheduler.dart';
import '../domain/simulation_controller.dart';
import '../../../l10n/app_localizations.dart';
import 'circle_conversation_painter.dart';

class SimulationPage extends StatefulWidget {
  const SimulationPage({
    super.key,
    this.initialPeopleCount = 6,
    this.initialMaxConcurrent = 2,
    this.initialSchedulerMode = SchedulerMode.random,
  });

  final int initialPeopleCount;
  final int initialMaxConcurrent;
  final SchedulerMode initialSchedulerMode;

  @override
  State<SimulationPage> createState() => _SimulationPageState();
}

class _SimulationPageState extends State<SimulationPage> {
  late int _peopleCount;
  late int _maxConcurrent;
  late SchedulerMode _schedulerMode;
  late SimulationController _controller;

  @override
  void initState() {
    super.initState();
    _peopleCount = widget.initialPeopleCount;
    _maxConcurrent = widget.initialMaxConcurrent;
    _schedulerMode = widget.initialSchedulerMode;
    _controller = _buildController();
  }

  SimulationController _buildController() {
    return SimulationController(
      config: SimulationConfig(
        peopleCount: _peopleCount,
        maxConcurrent: _maxConcurrent,
        schedulerMode: _schedulerMode,
      ),
      random: Random(),
    );
  }

  void _applyConfig() {
    setState(() {
      _controller.updateConfig(
        SimulationConfig(
          peopleCount: _peopleCount,
          maxConcurrent: _maxConcurrent,
          schedulerMode: _schedulerMode,
        ),
        random: Random(),
      );
    });
  }

  void _resetSimulation() {
    setState(() {
      _controller.restart(random: Random());
    });
  }

  void _advanceSimulation() {
    if (_controller.snapshot.isComplete) {
      return;
    }
    setState(() {
      _controller.advance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _controller.snapshot;
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(strings.appTitle)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final arenaHeight = max(320.0, constraints.maxHeight * 0.58);

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildControls(theme, strings),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: arenaHeight,
                      child: GestureDetector(
                        key: const Key('simulation-arena'),
                        behavior: HitTestBehavior.opaque,
                        onTap: snapshot.isComplete ? null : _advanceSimulation,
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  theme.colorScheme.surface,
                                  theme.colorScheme.surfaceContainerHighest,
                                ],
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: CircleConversationPainter(
                                      peopleCount: snapshot.peopleCount,
                                      batch: snapshot.lastBatch,
                                      colorScheme: theme.colorScheme,
                                      textStyle:
                                          theme.textTheme.bodySmall ??
                                          const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 12,
                                  right: 12,
                                  bottom: 12,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface
                                          .withValues(alpha: 0.84),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Text(
                                        snapshot.isComplete
                                            ? strings.arenaCompletedHint
                                            : strings.arenaTapHint,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildMetrics(theme, snapshot, strings),
                    if (snapshot.isComplete) ...[
                      const SizedBox(height: 10),
                      _buildCompletionBanner(theme, snapshot, strings),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildControls(ThemeData theme, AppLocalizations strings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.configuration, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(strings.peopleInCircle(_peopleCount)),
            Slider(
              min: 2,
              max: 20,
              divisions: 18,
              value: _peopleCount.toDouble(),
              label: _peopleCount.toString(),
              onChanged: (value) {
                setState(() {
                  _peopleCount = value.round();
                });
              },
              onChangeEnd: (_) => _applyConfig(),
            ),
            Text(strings.concurrentConversations(_maxConcurrent)),
            Slider(
              min: 1,
              max: 5,
              divisions: 4,
              value: _maxConcurrent.toDouble(),
              label: _maxConcurrent.toString(),
              onChanged: (value) {
                setState(() {
                  _maxConcurrent = value.round();
                });
              },
              onChangeEnd: (_) => _applyConfig(),
            ),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: strings.schedulingMode,
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<SchedulerMode>(
                        value: _schedulerMode,
                        isExpanded: true,
                        items: SchedulerMode.values
                            .map(
                              (mode) => DropdownMenuItem<SchedulerMode>(
                                value: mode,
                                child: Text(_schedulerModeLabel(strings, mode)),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          _schedulerMode = value;
                          _applyConfig();
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.tonal(
                  onPressed: _resetSimulation,
                  child: Text(strings.reset),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetrics(
    ThemeData theme,
    SimulationSnapshot snapshot,
    AppLocalizations strings,
  ) {
    final elapsed = _formatDuration(snapshot.elapsed);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            Text(
              strings.turnsLabel(snapshot.totalTurns),
              key: const Key('turn-count'),
              style: theme.textTheme.titleSmall,
            ),
            Text(
              strings.pairsLabel(snapshot.completedPairs, snapshot.totalPairs),
              style: theme.textTheme.titleSmall,
            ),
            Text(
              strings.elapsedLabel(elapsed),
              style: theme.textTheme.titleSmall,
            ),
            if (snapshot.isComplete)
              Text(
                strings.statusCompleteLabel,
                style: theme.textTheme.titleSmall,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionBanner(
    ThemeData theme,
    SimulationSnapshot snapshot,
    AppLocalizations strings,
  ) {
    return Card(
      key: const Key('completion-banner'),
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          strings.completionBanner(
            snapshot.totalTurns,
            _formatDuration(snapshot.elapsed),
          ),
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) {
      return '--:--.--';
    }
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    final centiseconds = ((duration.inMilliseconds % 1000) ~/ 10)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds.$centiseconds';
  }

  String _schedulerModeLabel(AppLocalizations strings, SchedulerMode mode) {
    switch (mode) {
      case SchedulerMode.deterministic:
        return strings.schedulerModeDeterministic;
      case SchedulerMode.random:
        return strings.schedulerModeRandom;
    }
  }
}
