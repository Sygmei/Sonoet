import 'dart:math';

import 'music_note.dart';
import 'practice_language.dart';

enum NoteAccidental {
  none(''),
  sharp('♯'),
  flat('♭'),
  natural('♮');

  const NoteAccidental(this.symbol);

  final String symbol;
}

class NoteSpelling {
  const NoteSpelling({
    required this.staffNote,
    required this.accidental,
  });

  final MusicNote staffNote;
  final NoteAccidental accidental;
}

enum PracticeKeySignature {
  cMajor(englishLabel: 'C major', frenchLabel: 'Do majeur', accidentalCount: 0),
  gMajor(englishLabel: 'G major', frenchLabel: 'Sol majeur', accidentalCount: 1),
  dMajor(englishLabel: 'D major', frenchLabel: 'Ré majeur', accidentalCount: 2),
  aMajor(englishLabel: 'A major', frenchLabel: 'La majeur', accidentalCount: 3),
  eMajor(englishLabel: 'E major', frenchLabel: 'Mi majeur', accidentalCount: 4),
  fMajor(englishLabel: 'F major', frenchLabel: 'Fa majeur', accidentalCount: -1),
  bFlatMajor(
    englishLabel: 'Bb major',
    frenchLabel: 'Si bémol majeur',
    accidentalCount: -2,
  ),
  eFlatMajor(
    englishLabel: 'Eb major',
    frenchLabel: 'Mi bémol majeur',
    accidentalCount: -3,
  ),
  aFlatMajor(
    englishLabel: 'Ab major',
    frenchLabel: 'La bémol majeur',
    accidentalCount: -4,
  );

  const PracticeKeySignature({
    required this.englishLabel,
    required this.frenchLabel,
    required this.accidentalCount,
  });

  final String englishLabel;
  final String frenchLabel;
  final int accidentalCount;

  String labelFor(PracticeLanguage language) {
    return switch (language) {
      PracticeLanguage.english => englishLabel,
      PracticeLanguage.french => frenchLabel,
    };
  }

  String get accidentalBadge {
    if (accidentalCount == 0) {
      return '♮';
    }

    final symbol = usesSharps ? NoteAccidental.sharp.symbol : NoteAccidental.flat.symbol;
    return symbol * accidentalCount.abs();
  }

  bool get usesSharps => accidentalCount > 0;

  bool get usesFlats => accidentalCount < 0;

  List<int> get alteredNaturalPitchClasses {
    final order = usesSharps ? _sharpOrder : _flatOrder;
    return order.take(accidentalCount.abs()).toList(growable: false);
  }

  NoteAccidental accidentalForNaturalPitchClass(int pitchClass) {
    if (!alteredNaturalPitchClasses.contains(pitchClass)) {
      return NoteAccidental.none;
    }

    return usesSharps ? NoteAccidental.sharp : NoteAccidental.flat;
  }

  bool containsSoundingPitchClass(int pitchClass) {
    return _naturalPitchClasses.any((naturalPitchClass) {
      final soundingPitchClass = _applyKeyAlteration(naturalPitchClass);
      return soundingPitchClass == pitchClass;
    });
  }

  NoteSpelling spell(MusicNote note) {
    final pitchClass = note.pitchClass;

    if (note.isNatural &&
        accidentalForNaturalPitchClass(pitchClass) != NoteAccidental.none) {
      return NoteSpelling(
        staffNote: note,
        accidental: NoteAccidental.natural,
      );
    }

    for (final naturalPitchClass in _naturalPitchClasses) {
      if (_applyKeyAlteration(naturalPitchClass) == pitchClass) {
        final staffNote = _staffNoteForNaturalPitchClass(note, naturalPitchClass);
        return NoteSpelling(
          staffNote: staffNote,
          accidental: NoteAccidental.none,
        );
      }
    }

    return usesFlats ? _spellAsFlat(note) : _spellAsSharp(note);
  }

  List<MusicNote> practiceRange({
    required MusicNote lowest,
    required MusicNote highest,
    required bool includeAccidentals,
  }) {
    final start = min(lowest.midi, highest.midi);
    final end = max(lowest.midi, highest.midi);

    return List<MusicNote>.generate(
      end - start + 1,
      (index) => MusicNote(start + index),
      growable: false,
    ).where((note) {
      return includeAccidentals || containsSoundingPitchClass(note.pitchClass);
    }).toList(growable: false);
  }

  int _applyKeyAlteration(int naturalPitchClass) {
    final accidental = accidentalForNaturalPitchClass(naturalPitchClass);
    return switch (accidental) {
      NoteAccidental.sharp => (naturalPitchClass + 1) % 12,
      NoteAccidental.flat => (naturalPitchClass - 1) % 12,
      NoteAccidental.natural => naturalPitchClass,
      NoteAccidental.none => naturalPitchClass,
    };
  }

  NoteSpelling _spellAsSharp(MusicNote note) {
    final staffNote = _staffNoteForNaturalPitchClass(
      note,
      (note.pitchClass - 1) % 12,
    );

    return staffNote.isNatural
        ? NoteSpelling(staffNote: staffNote, accidental: NoteAccidental.sharp)
        : NoteSpelling(staffNote: note.nearestNatural, accidental: NoteAccidental.sharp);
  }

  NoteSpelling _spellAsFlat(MusicNote note) {
    final staffNote = _staffNoteForNaturalPitchClass(
      note,
      (note.pitchClass + 1) % 12,
    );

    return staffNote.isNatural
        ? NoteSpelling(staffNote: staffNote, accidental: NoteAccidental.flat)
        : NoteSpelling(staffNote: note.nearestNatural, accidental: NoteAccidental.sharp);
  }

  MusicNote _staffNoteForNaturalPitchClass(
    MusicNote soundingNote,
    int naturalPitchClass,
  ) {
    final normalizedPitchClass = naturalPitchClass % 12;
    var midi = soundingNote.midi - soundingNote.pitchClass + normalizedPitchClass;
    if ((midi - soundingNote.midi).abs() > 6) {
      midi += midi > soundingNote.midi ? -12 : 12;
    }

    return MusicNote(midi);
  }
}

const _naturalPitchClasses = <int>[0, 2, 4, 5, 7, 9, 11];
const _sharpOrder = <int>[5, 0, 7, 2, 9, 4, 11];
const _flatOrder = <int>[11, 4, 9, 2, 7, 0, 5];
