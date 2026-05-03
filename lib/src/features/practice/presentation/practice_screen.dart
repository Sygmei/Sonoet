import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/music_note.dart';
import '../domain/practice_clef.dart';
import '../domain/practice_key_signature.dart';
import '../domain/practice_language.dart';
import '../domain/stave_background.dart';
import 'practice_controller.dart';
import 'widgets/pitch_readout.dart';
import 'widgets/staff_painter.dart';

class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(practiceControllerProvider);
    final controller = ref.read(practiceControllerProvider.notifier);
    final playedNote = state.shiftedLastFrequency != null
        ? MusicNote.fromFrequency(state.shiftedLastFrequency!)?.nearestNatural
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sonoet'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'New exercise',
            onPressed: controller.reset,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => _showPracticeSettings(context),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            final staffPanel = _StaffPanel(
              state: state,
              playedNote: playedNote,
              expandToFill: isLandscape,
            );
            final sidePanel = _PracticeSidePanel(
              state: state,
              controller: controller,
            );

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: isLandscape
                  ? LayoutBuilder(
                      builder: (context, innerConstraints) {
                        const gap = 8.0;
                        return Row(
                          children: [
                            SizedBox(
                              width: innerConstraints.maxWidth * 0.70,
                              child: staffPanel,
                            ),
                            const SizedBox(width: gap),
                            Expanded(child: sidePanel),
                          ],
                        );
                      },
                    )
                  : Column(
                      children: [
                        _ProgressHeader(state: state),
                        const SizedBox(height: 18),
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            child: staffPanel,
                          ),
                        ),
                        const SizedBox(height: 18),
                        PitchReadout(state: state),
                        const SizedBox(height: 14),
                        _Controls(state: state, controller: controller),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _PracticeSidePanel extends StatelessWidget {
  const _PracticeSidePanel({
    required this.state,
    required this.controller,
  });

  final PracticeState state;
  final PracticeController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProgressHeader(state: state),
        const SizedBox(height: 12),
        PitchReadout(state: state, compact: true),
        const SizedBox(height: 10),
        _Controls(state: state, controller: controller),
      ],
    );
  }
}

class _StaffPanel extends StatefulWidget {
  const _StaffPanel({
    required this.state,
    required this.playedNote,
    required this.expandToFill,
  });

  final PracticeState state;
  final MusicNote? playedNote;
  final bool expandToFill;

  @override
  State<_StaffPanel> createState() => _StaffPanelState();
}

class _StaffPanelState extends State<_StaffPanel> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = switch (widget.state.staveBackground) {
      StaveBackground.paper => const Color(0xFFFFFCF5),
      StaveBackground.white => Colors.white,
    };

    final staff = DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0D9C8)),
      ),
      child: CustomPaint(
        painter: StaffPainter(
          notes: widget.state.notes,
          currentIndex: widget.state.currentIndex,
          playedNote: widget.playedNote,
          clef: widget.state.clef,
          keySignature: widget.state.keySignature,
          beatsPerMeasure: widget.state.beatsPerMeasure,
          noteTimings: widget.state.noteTimings,
          now: _now,
          colorScheme: Theme.of(context).colorScheme,
        ),
      ),
    );

    if (widget.expandToFill) {
      return SizedBox.expand(child: staff);
    }

    return Center(
      child: SizedBox(
        width: double.infinity,
        child: AspectRatio(
          aspectRatio: 1.45,
          child: staff,
        ),
      ),
    );
  }
}

void _showPracticeSettings(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(practiceControllerProvider);
    final controller = ref.read(practiceControllerProvider.notifier);
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Settings',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 18),
            _SettingsSection(
              title: 'Language',
              child: _LanguageControl(
                state: state,
                controller: controller,
              ),
            ),
            const SizedBox(height: 22),
            _SettingsSection(
              title: 'Appearance',
              child: _StaveBackgroundControl(
                state: state,
                controller: controller,
              ),
            ),
            const SizedBox(height: 22),
            _SettingsSection(
              title: 'Detection',
              child: _OctaveShiftControl(
                state: state,
                controller: controller,
              ),
            ),
            const SizedBox(height: 22),
            _SettingsSection(
              title: 'Measure',
              child: Column(
                children: [
                  _NumberStepper(
                    label: 'Beats per measure',
                    value: state.beatsPerMeasure,
                    min: PracticeController.minBeatsPerMeasure,
                    max: PracticeController.maxBeatsPerMeasure,
                    decrementTooltip: 'Fewer beats',
                    incrementTooltip: 'More beats',
                    onChanged: controller.setBeatsPerMeasure,
                  ),
                  const SizedBox(height: 10),
                  _NumberStepper(
                    label: 'Measures per page',
                    value: state.measuresPerPage,
                    min: PracticeController.minMeasuresPerPage,
                    max: PracticeController.maxMeasuresPerPage,
                    decrementTooltip: 'Fewer measures',
                    incrementTooltip: 'More measures',
                    onChanged: controller.setMeasuresPerPage,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _SettingsSection(
              title: 'Note range',
              trailing: state.noteRangeLabel,
              child: Column(
                children: [
                  _NoteStepper(
                    label: 'Lowest',
                    note: state.lowestNote,
                    language: state.language,
                    canDecrement: state.lowestNote.midi >
                        MusicNote.lowestPracticeNote.midi,
                    canIncrement:
                        state.lowestNote.midi < state.highestNote.midi,
                    onDecrement: () {
                      controller
                          .setLowestNote(state.lowestNote.shiftNatural(-1));
                    },
                    onIncrement: () {
                      controller
                          .setLowestNote(state.lowestNote.shiftNatural(1));
                    },
                  ),
                  const SizedBox(height: 10),
                  _NoteStepper(
                    label: 'Highest',
                    note: state.highestNote,
                    language: state.language,
                    canDecrement:
                        state.highestNote.midi > state.lowestNote.midi,
                    canIncrement: state.highestNote.midi <
                        MusicNote.highestPracticeNote.midi,
                    onDecrement: () {
                      controller.setHighestNote(
                        state.highestNote.shiftNatural(-1),
                      );
                    },
                    onIncrement: () {
                      controller.setHighestNote(
                        state.highestNote.shiftNatural(1),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _SettingsSection(
              title: 'Clef',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final clef in PracticeClef.values)
                    ChoiceChip(
                      label: Text(clef.labelFor(state.language)),
                      selected: state.clef == clef,
                      onSelected: (_) => controller.setClef(clef),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _SettingsSection(
              title: 'Key signatures',
              trailing: state.keySignature.labelFor(state.language),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Allow accidentals'),
                    value: state.allowAccidentals,
                    onChanged: controller.setAllowAccidentals,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final keySignature in PracticeKeySignature.values)
                        FilterChip(
                          label: _KeySignatureChipLabel(
                            keySignature: keySignature,
                            language: state.language,
                          ),
                          selected:
                              state.allowedKeySignatures.contains(keySignature),
                          onSelected: (_) {
                            controller.toggleAllowedKeySignature(keySignature);
                          },
                        ),
                    ],
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

class _KeySignatureChipLabel extends StatelessWidget {
  const _KeySignatureChipLabel({
    required this.keySignature,
    required this.language,
  });

  final PracticeKeySignature keySignature;
  final PracticeLanguage language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 22),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            keySignature.accidentalBadge,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(keySignature.labelFor(language)),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _LanguageControl extends StatelessWidget {
  const _LanguageControl({
    required this.state,
    required this.controller,
  });

  final PracticeState state;
  final PracticeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SegmentedButton<PracticeLanguage>(
      showSelectedIcon: false,
      segments: [
        for (final language in PracticeLanguage.values)
          ButtonSegment(
            value: language,
            label: Text(language.label),
          ),
      ],
      selected: {state.language},
      onSelectionChanged: (selection) {
        controller.setLanguage(selection.single);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(
          theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _StaveBackgroundControl extends StatelessWidget {
  const _StaveBackgroundControl({
    required this.state,
    required this.controller,
  });

  final PracticeState state;
  final PracticeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SegmentedButton<StaveBackground>(
      showSelectedIcon: false,
      segments: [
        for (final background in StaveBackground.values)
          ButtonSegment(
            value: background,
            label: Text(background.label),
          ),
      ],
      selected: {state.staveBackground},
      onSelectionChanged: (selection) {
        controller.setStaveBackground(selection.single);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(
          theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _OctaveShiftControl extends StatelessWidget {
  const _OctaveShiftControl({
    required this.state,
    required this.controller,
  });

  final PracticeState state;
  final PracticeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SegmentedButton<int>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: -2, label: Text('-2')),
        ButtonSegment(value: -1, label: Text('-1')),
        ButtonSegment(value: 0, label: Text('+0')),
        ButtonSegment(value: 1, label: Text('+1')),
        ButtonSegment(value: 2, label: Text('+2')),
      ],
      selected: {state.detectedOctaveShift},
      onSelectionChanged: (selection) {
        controller.setDetectedOctaveShift(selection.single);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(
          theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _NumberStepper extends StatelessWidget {
  const _NumberStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.decrementTooltip,
    required this.incrementTooltip,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final String decrementTooltip;
  final String incrementTooltip;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        border: Border.all(color: const Color(0xFFE0D9C8)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          IconButton(
            tooltip: decrementTooltip,
            visualDensity: VisualDensity.compact,
            onPressed: value <= min ? null : () => onChanged(value - 1),
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 34,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
          IconButton(
            tooltip: incrementTooltip,
            visualDensity: VisualDensity.compact,
            onPressed: value >= max ? null : () => onChanged(value + 1),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

class _NoteStepper extends StatelessWidget {
  const _NoteStepper({
    required this.label,
    required this.note,
    required this.language,
    required this.canDecrement,
    required this.canIncrement,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final MusicNote note;
  final PracticeLanguage language;
  final bool canDecrement;
  final bool canIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        border: Border.all(color: const Color(0xFFE0D9C8)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Lower $label',
            visualDensity: VisualDensity.compact,
            onPressed: canDecrement ? onDecrement : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 48,
            child: Text(
              note.labelFor(language),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Raise $label',
            visualDensity: VisualDensity.compact,
            onPressed: canIncrement ? onIncrement : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.state});

  final PracticeState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusText = switch (state.status) {
      PracticeStatus.permissionDenied => 'Microphone blocked',
      PracticeStatus.error => 'Audio unavailable',
      _ => '',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (statusText.isNotEmpty) ...[
          Text(
            statusText,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final metrics = [
              _ScoreMetric(
                icon: Icons.speed_rounded,
                label: 'Avg note',
                value: _formatReactionDuration(state.lastPageAverageDuration),
              ),
              _SplitScoreMetric(
                icon: Icons.timer_rounded,
                firstLabel: 'Last',
                firstValue: _formatTotalDuration(state.lastPageTotalDuration),
                secondLabel: 'Best',
                secondValue: _formatTotalDuration(state.bestPageTotalDuration),
              ),
            ];

            if (constraints.maxWidth < 320) {
              return Column(
                children: [
                  for (var index = 0; index < metrics.length; index++) ...[
                    if (index > 0) const SizedBox(height: 8),
                    metrics[index],
                  ],
                ],
              );
            }

            return Row(
              children: [
                for (var index = 0; index < metrics.length; index++) ...[
                  if (index > 0) const SizedBox(width: 8),
                  Expanded(child: metrics[index]),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  String _formatReactionDuration(Duration? duration) {
    if (duration == null) {
      return '-';
    }

    return '${duration.inMilliseconds} ms';
  }

  String _formatTotalDuration(Duration? duration) {
    if (duration == null) {
      return '-';
    }

    final seconds = duration.inMilliseconds / 1000;
    return '${seconds.toStringAsFixed(2)} s';
  }
}

class _ScoreMetric extends StatelessWidget {
  const _ScoreMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        border: Border.all(color: const Color(0xFFE0D9C8)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
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

class _SplitScoreMetric extends StatelessWidget {
  const _SplitScoreMetric({
    required this.icon,
    required this.firstLabel,
    required this.firstValue,
    required this.secondLabel,
    required this.secondValue,
  });

  final IconData icon;
  final String firstLabel;
  final String firstValue;
  final String secondLabel;
  final String secondValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        border: Border.all(color: const Color(0xFFE0D9C8)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _InlineScoreValue(
                label: firstLabel,
                value: firstValue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InlineScoreValue(
                label: secondLabel,
                value: secondValue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineScoreValue extends StatelessWidget {
  const _InlineScoreValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.state,
    required this.controller,
  });

  final PracticeState state;
  final PracticeController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton.filled(
          tooltip: state.isListening ? 'Stop listening' : 'Start listening',
          onPressed: state.isListening
              ? () => _stopAndShowRecap(context)
              : controller.start,
          icon: Icon(
            state.isListening ? Icons.stop_rounded : Icons.mic_rounded,
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          tooltip: 'Simulate note',
          onPressed: state.status == PracticeStatus.completed
              ? null
              : controller.simulateCurrentNote,
          icon: const Icon(Icons.skip_next_rounded),
        ),
      ],
    );
  }

  Future<void> _stopAndShowRecap(BuildContext context) async {
    final recap = state.buildRecap();
    await controller.stop();

    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => _SessionRecapDialog(
        recap: recap,
        language: state.language,
      ),
    );
  }
}

class _SessionRecapDialog extends StatelessWidget {
  const _SessionRecapDialog({
    required this.recap,
    required this.language,
  });

  final SessionRecap recap;
  final PracticeLanguage language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Session recap'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${recap.completedNotes}/${recap.totalNotes} notes completed',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 14),
            if (!recap.hasResults)
              Text(
                'No notes were completed yet.',
                style: theme.textTheme.bodyMedium,
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _RecapMetric(
                      label: 'Average',
                      value: _formatDuration(recap.averageDuration),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RecapMetric(
                      label: 'Fastest',
                      value: _formatDuration(recap.fastestDuration),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RecapMetric(
                      label: 'Slowest',
                      value: _formatDuration(recap.slowestDuration),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Needs work',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              for (final note in recap.slowestNotes)
                _RecapNoteRow(note: note, language: language),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) {
      return '-';
    }

    return '${duration.inMilliseconds} ms';
  }
}

class _RecapMetric extends StatelessWidget {
  const _RecapMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0D9C8)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecapNoteRow extends StatelessWidget {
  const _RecapNoteRow({
    required this.note,
    required this.language,
  });

  final SessionRecapNote note;
  final PracticeLanguage language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              note.note.labelFor(language),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
          Text(
            '${note.duration.inMilliseconds} ms',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
