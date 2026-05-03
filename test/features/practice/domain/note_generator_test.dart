import 'package:flutter_test/flutter_test.dart';
import 'package:sonoet/src/features/practice/domain/music_note.dart';
import 'package:sonoet/src/features/practice/domain/note_generator.dart';

void main() {
  group('NoteGenerator', () {
    test('generates a beginner exercise of the requested length', () {
      final notes = NoteGenerator().generate(length: 16);

      expect(notes, hasLength(16));
      expect(
        notes.every(NoteGenerator.beginnerTrebleRange.contains),
        isTrue,
      );
    });

    test('avoids adjacent duplicates when possible', () {
      final notes = NoteGenerator().generate(
        length: 40,
        range: const [MusicNote.c4, MusicNote.d4],
      );

      for (var index = 1; index < notes.length; index++) {
        expect(notes[index].midi, isNot(notes[index - 1].midi));
      }
    });

    test('avoids repeating the previous page note when possible', () {
      final notes = NoteGenerator().generate(
        length: 8,
        range: const [MusicNote.c4, MusicNote.d4],
        previousNote: MusicNote.c4,
      );

      expect(notes.first.midi, isNot(MusicNote.c4.midi));
    });
  });
}
