import 'dart:convert';

import 'music_note.dart';
import 'practice_clef.dart';
import 'practice_key_signature.dart';
import 'practice_language.dart';

enum PracticeSource {
  random,
  scaleExercise,
}

class PracticeExercise {
  const PracticeExercise({
    required this.id,
    required this.category,
    required this.name,
    required this.difficulty,
    required this.labels,
    required this.keySignature,
    required this.clef,
    required this.measuresPerPage,
    required this.beatsPerMeasure,
    required this.notes,
  });

  final String id;
  final String category;
  final String name;
  final String difficulty;
  final List<String> labels;
  final PracticeKeySignature keySignature;
  final PracticeClef clef;
  final int measuresPerPage;
  final int beatsPerMeasure;
  final List<MusicNote> notes;

  String labelFor(PracticeLanguage language) {
    return name;
  }

  List<MusicNote> pageNotes({MusicNote? previousNote}) {
    if (previousNote == null ||
        notes.length <= 1 ||
        notes.first.midi != previousNote.midi) {
      return notes;
    }

    return [
      ...notes.skip(1),
      notes.first,
    ];
  }

  factory PracticeExercise.fromJson(Map<String, Object?> json) {
    final notes = _stringList(json['notes'])
        .map(_musicNoteFromLabel)
        .toList(growable: false);
    if (notes.isEmpty) {
      throw const FormatException('Exercise notes cannot be empty.');
    }

    return PracticeExercise(
      id: _requiredString(json, 'id'),
      category: _requiredString(json, 'category'),
      name: _requiredString(json, 'name'),
      difficulty: _requiredString(json, 'difficulty'),
      labels: _stringList(json['labels']),
      keySignature: _enumByName(
        PracticeKeySignature.values,
        _requiredString(json, 'keySignature'),
      ),
      clef: _enumByName(
        PracticeClef.values,
        _requiredString(json, 'clef'),
      ),
      measuresPerPage: _requiredInt(json, 'measuresPerPage'),
      beatsPerMeasure: _requiredInt(json, 'beatsPerMeasure'),
      notes: notes,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'category': category,
      'name': name,
      'difficulty': difficulty,
      'labels': labels,
      'keySignature': keySignature.name,
      'clef': clef.name,
      'measuresPerPage': measuresPerPage,
      'beatsPerMeasure': beatsPerMeasure,
      'notes': notes.map(_musicNoteLabel).toList(growable: false),
    };
  }
}

typedef ScaleExercise = PracticeExercise;

const fallbackScaleExercise = PracticeExercise(
  id: 'c_major_scale',
  category: 'scales',
  name: 'C major',
  difficulty: 'beginner',
  labels: ['scale', 'major', 'ascending', 'descending'],
  keySignature: PracticeKeySignature.cMajor,
  clef: PracticeClef.treble,
  measuresPerPage: 4,
  beatsPerMeasure: 4,
  notes: [
    MusicNote.c4,
    MusicNote.d4,
    MusicNote.e4,
    MusicNote.f4,
    MusicNote.g4,
    MusicNote.a4,
    MusicNote.b4,
    MusicNote.c5,
    MusicNote.b4,
    MusicNote.a4,
    MusicNote.g4,
    MusicNote.f4,
    MusicNote.e4,
    MusicNote.d4,
    MusicNote.c4,
  ],
);

const fallbackScaleExercises = <PracticeExercise>[fallbackScaleExercise];

List<PracticeExercise> parsePracticeExercises(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! List) {
    throw const FormatException('Exercise file must contain a JSON array.');
  }

  return decoded.map((item) {
    if (item is! Map<String, Object?>) {
      throw const FormatException('Exercise entries must be JSON objects.');
    }

    return PracticeExercise.fromJson(item);
  }).toList(growable: false);
}

List<String> parsePracticeExerciseIndex(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Exercise index must be a JSON object.');
  }

  final exercises = _stringList(decoded['exercises']);
  if (exercises.isEmpty) {
    throw const FormatException('Exercise index must reference exercises.');
  }

  return exercises;
}

PracticeExercise parsePracticeExercise(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Exercise file must contain a JSON object.');
  }

  return PracticeExercise.fromJson(decoded);
}

PracticeExercise scaleExerciseById(
  String? id, [
  List<PracticeExercise> exercises = fallbackScaleExercises,
]) {
  return exercises.firstWhere(
    (exercise) => exercise.id == id,
    orElse: () => exercises.isEmpty ? fallbackScaleExercise : exercises.first,
  );
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }

  throw FormatException('Missing string field "$key".');
}

int _requiredInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }

  throw FormatException('Missing integer field "$key".');
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value.whereType<String>().toList(growable: false);
}

T _enumByName<T extends Enum>(List<T> values, String name) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }

  throw FormatException('Unknown enum value "$name".');
}

MusicNote _musicNoteFromLabel(String label) {
  final match = RegExp(r'^([A-Ga-g])([#b]?)(-?\d+)$').firstMatch(label.trim());
  if (match == null) {
    throw FormatException('Invalid note label "$label".');
  }

  final naturalPitchClass = switch (match.group(1)!.toUpperCase()) {
    'C' => 0,
    'D' => 2,
    'E' => 4,
    'F' => 5,
    'G' => 7,
    'A' => 9,
    'B' => 11,
    _ => throw FormatException('Invalid note label "$label".'),
  };
  final accidentalOffset = switch (match.group(2)) {
    '#' => 1,
    'b' => -1,
    _ => 0,
  };
  final octave = int.parse(match.group(3)!);
  final midi = (octave + 1) * 12 + naturalPitchClass + accidentalOffset;

  return MusicNote(midi);
}

String _musicNoteLabel(MusicNote note) {
  final octave = (note.midi ~/ 12) - 1;
  final pitchClass = note.midi % 12;
  final label = switch (pitchClass) {
    0 => 'C',
    1 => 'C#',
    2 => 'D',
    3 => 'Eb',
    4 => 'E',
    5 => 'F',
    6 => 'F#',
    7 => 'G',
    8 => 'Ab',
    9 => 'A',
    10 => 'Bb',
    11 => 'B',
    _ => throw StateError('Invalid pitch class "$pitchClass".'),
  };

  return '$label$octave';
}
