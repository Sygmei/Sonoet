import 'package:flutter_test/flutter_test.dart';
import 'package:sonoet/src/features/practice/domain/music_note.dart';
import 'package:sonoet/src/features/practice/domain/practice_clef.dart';
import 'package:sonoet/src/features/practice/domain/practice_key_signature.dart';
import 'package:sonoet/src/features/practice/domain/practice_language.dart';

void main() {
  group('MusicNote', () {
    test('calculates A4 frequency', () {
      expect(MusicNote.a4.frequency, closeTo(440, 0.001));
    });

    test('calculates cents from a detected frequency', () {
      expect(MusicNote.a4.centsFromFrequency(440), closeTo(0, 0.001));
      expect(MusicNote.a4.centsFromFrequency(466.16), closeTo(100, 0.1));
    });

    test('labels notes with pitch class and octave', () {
      expect(MusicNote.c4.label, 'C4');
      expect(MusicNote.c5.label, 'C5');
    });

    test('creates nearest note from frequency', () {
      expect(MusicNote.fromFrequency(440)?.midi, MusicNote.a4.midi);
      expect(MusicNote.fromFrequency(261.63)?.midi, MusicNote.c4.midi);
      expect(MusicNote.fromFrequency(0), isNull);
    });

    test('maps chromatic notes to a natural staff position', () {
      expect(const MusicNote(61).nearestNatural.midi, MusicNote.c4.midi);
      expect(const MusicNote(66).nearestNatural.midi, MusicNote.f4.midi);
    });

    test('builds natural ranges for practice settings', () {
      final range = MusicNote.naturalRange(
        lowest: MusicNote.c4,
        highest: MusicNote.c5,
      );

      expect(range.first.midi, MusicNote.c4.midi);
      expect(range.last.midi, MusicNote.c5.midi);
      expect(range.every((note) => note.isNatural), isTrue);
    });

    test('shifts natural notes by staff steps', () {
      expect(MusicNote.c4.shiftNatural(1).midi, MusicNote.d4.midi);
      expect(MusicNote.c4.shiftNatural(-1).label, 'B3');
    });

    test('allows practice range up to C7', () {
      expect(MusicNote.highestPracticeNote.label, 'C7');
      expect(MusicNote.highestPracticeNote.midi, 96);
    });

    test('localizes note labels', () {
      expect(MusicNote.c4.labelFor(PracticeLanguage.english), 'C4');
      expect(MusicNote.c4.labelFor(PracticeLanguage.french), 'Do4');
      expect(MusicNote.d4.labelFor(PracticeLanguage.french), 'Ré4');
    });

    test('localizes clef labels', () {
      expect(
        PracticeClef.treble.labelFor(PracticeLanguage.english),
        'Treble clef',
      );
      expect(
        PracticeClef.treble.labelFor(PracticeLanguage.french),
        'Clef de Sol',
      );
    });

    test('spells notes against key signatures', () {
      final fSharp = PracticeKeySignature.gMajor.spell(const MusicNote(66));
      expect(fSharp.staffNote.midi, MusicNote.f4.midi);
      expect(fSharp.accidental, NoteAccidental.none);

      final fNatural = PracticeKeySignature.gMajor.spell(MusicNote.f4);
      expect(fNatural.staffNote.midi, MusicNote.f4.midi);
      expect(fNatural.accidental, NoteAccidental.natural);
    });

    test('localizes key signature labels', () {
      expect(
        PracticeKeySignature.bFlatMajor.labelFor(PracticeLanguage.english),
        'Bb major',
      );
      expect(
        PracticeKeySignature.bFlatMajor.labelFor(PracticeLanguage.french),
        'Si bémol majeur',
      );
    });

    test('can filter practice range to notes inside a key signature', () {
      final range = PracticeKeySignature.gMajor.practiceRange(
        lowest: MusicNote.c4,
        highest: MusicNote.c5,
        includeAccidentals: false,
      );

      expect(range.any((note) => note.midi == MusicNote.f4.midi), isFalse);
      expect(range.any((note) => note.midi == 66), isTrue);
    });
  });
}
