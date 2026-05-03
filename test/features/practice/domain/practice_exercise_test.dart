import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sonoet/src/features/practice/domain/music_note.dart';
import 'package:sonoet/src/features/practice/domain/practice_exercise.dart';
import 'package:sonoet/src/features/practice/domain/practice_key_signature.dart';

void main() {
  group('practice exercises', () {
    test('loads one scale exercise per supported key signature from JSON', () {
      final exercises = _loadScaleExercises();

      expect(exercises, hasLength(PracticeKeySignature.values.length));
      expect(
        exercises.map((exercise) => exercise.keySignature).toSet(),
        PracticeKeySignature.values.toSet(),
      );
    });

    test('parses exercise metadata', () {
      final exercise = scaleExerciseById(
        'd_major_scale',
        _loadScaleExercises(),
      );

      expect(exercise.name, 'D major');
      expect(exercise.difficulty, 'beginner');
      expect(exercise.labels, containsAll(['scale', 'major', 'sharp']));
      expect(exercise.keySignature, PracticeKeySignature.dMajor);
      expect(exercise.beatsPerMeasure, 4);
      expect(exercise.measuresPerPage, 4);
    });

    test('parses explicit ascending then descending scale notes', () {
      final notes = scaleExerciseById(
        'c_major_scale',
        _loadScaleExercises(),
      ).pageNotes();

      expect(notes.map((note) => note.midi), [
        MusicNote.c4.midi,
        MusicNote.d4.midi,
        MusicNote.e4.midi,
        MusicNote.f4.midi,
        MusicNote.g4.midi,
        MusicNote.a4.midi,
        MusicNote.b4.midi,
        MusicNote.c5.midi,
        MusicNote.b4.midi,
        MusicNote.a4.midi,
        MusicNote.g4.midi,
        MusicNote.f4.midi,
        MusicNote.e4.midi,
        MusicNote.d4.midi,
        MusicNote.c4.midi,
      ]);
    });

    test('rotates the next page start away from the previous note', () {
      final notes = scaleExerciseById(
        'c_major_scale',
        _loadScaleExercises(),
      ).pageNotes(previousNote: MusicNote.c4);

      expect(notes.first.midi, isNot(MusicNote.c4.midi));
      expect(notes, hasLength(15));
    });
  });
}

List<ScaleExercise> _loadScaleExercises() {
  final indexSource = File('assets/exercises/index.json').readAsStringSync();
  final references = parsePracticeExerciseIndex(indexSource);

  return references.map((reference) {
    final source = File('assets/exercises/$reference').readAsStringSync();
    return parsePracticeExercise(source);
  }).toList(growable: false);
}
