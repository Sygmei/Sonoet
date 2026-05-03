import 'dart:math' as math;

import 'practice_language.dart';

const _pitchClassNames = <int, String>{
  0: 'C',
  1: 'C#',
  2: 'D',
  3: 'D#',
  4: 'E',
  5: 'F',
  6: 'F#',
  7: 'G',
  8: 'G#',
  9: 'A',
  10: 'A#',
  11: 'B',
};

const _frenchPitchClassNames = <int, String>{
  0: 'Do',
  1: 'Do#',
  2: 'Ré',
  3: 'Ré#',
  4: 'Mi',
  5: 'Fa',
  6: 'Fa#',
  7: 'Sol',
  8: 'Sol#',
  9: 'La',
  10: 'La#',
  11: 'Si',
};

const _naturalPitchClasses = <int>{0, 2, 4, 5, 7, 9, 11};
const _naturalIndexes = <int, int>{0: 0, 2: 1, 4: 2, 5: 3, 7: 4, 9: 5, 11: 6};
const _nearestNaturalByPitchClass = <int, int>{
  0: 0,
  1: 0,
  2: 2,
  3: 2,
  4: 4,
  5: 5,
  6: 5,
  7: 7,
  8: 7,
  9: 9,
  10: 9,
  11: 11,
};

class MusicNote {
  const MusicNote(this.midi);

  final int midi;

  int get pitchClass => midi % 12;

  int get octave => (midi ~/ 12) - 1;

  bool get isNatural => _naturalPitchClasses.contains(pitchClass);

  String get name => _pitchClassNames[pitchClass] ?? '?';

  String get label => '$name$octave';

  String labelFor(PracticeLanguage language) {
    final localizedName = switch (language) {
      PracticeLanguage.english => name,
      PracticeLanguage.french => _frenchPitchClassNames[pitchClass] ?? name,
    };

    return '$localizedName$octave';
  }

  double get frequency => 440 * math.pow(2, (midi - 69) / 12).toDouble();

  MusicNote get nearestNatural {
    if (isNatural) {
      return this;
    }

    final naturalPitchClass = _nearestNaturalByPitchClass[pitchClass];
    if (naturalPitchClass == null) {
      return this;
    }

    return MusicNote(midi - pitchClass + naturalPitchClass);
  }

  double centsFromFrequency(double detectedFrequency) {
    if (!detectedFrequency.isFinite || detectedFrequency <= 0) {
      return double.infinity;
    }

    return 1200 * (math.log(detectedFrequency / frequency) / math.ln2);
  }

  int get diatonicIndex {
    final naturalIndex = _naturalIndexes[pitchClass];
    if (naturalIndex == null) {
      throw StateError('Only natural notes can be placed on the staff.');
    }

    return octave * 7 + naturalIndex;
  }

  static const c4 = MusicNote(60);
  static const d3 = MusicNote(50);
  static const f3 = MusicNote(53);
  static const g2 = MusicNote(43);
  static const d4 = MusicNote(62);
  static const e4 = MusicNote(64);
  static const f4 = MusicNote(65);
  static const g4 = MusicNote(67);
  static const a4 = MusicNote(69);
  static const b4 = MusicNote(71);
  static const c5 = MusicNote(72);

  static const lowestPracticeNote = MusicNote(36);
  static const highestPracticeNote = MusicNote(96);

  static MusicNote? fromFrequency(double frequency) {
    if (!frequency.isFinite || frequency <= 0) {
      return null;
    }

    final midi = (69 + 12 * math.log(frequency / 440) / math.ln2).round();
    return MusicNote(midi);
  }

  static List<MusicNote> naturalRange({
    required MusicNote lowest,
    required MusicNote highest,
  }) {
    final start = math.min(lowest.midi, highest.midi);
    final end = math.max(lowest.midi, highest.midi);

    return List<MusicNote>.generate(
      end - start + 1,
      (index) => MusicNote(start + index),
      growable: false,
    ).where((note) => note.isNatural).toList(growable: false);
  }

  MusicNote shiftNatural(int steps) {
    final notes = naturalRange(
      lowest: lowestPracticeNote,
      highest: highestPracticeNote,
    );
    final currentIndex = notes.indexWhere((note) => note.midi == midi);
    if (currentIndex == -1) {
      return this;
    }

    final nextIndex = (currentIndex + steps).clamp(0, notes.length - 1).toInt();
    return notes[nextIndex];
  }
}
