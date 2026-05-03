import 'package:flutter_test/flutter_test.dart';
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
  });
}
