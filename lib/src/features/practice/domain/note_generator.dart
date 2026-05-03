import 'dart:math';

import 'music_note.dart';

class NoteGenerator {
  NoteGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const beginnerTrebleRange = <MusicNote>[
    MusicNote.c4,
    MusicNote.d4,
    MusicNote.e4,
    MusicNote.f4,
    MusicNote.g4,
    MusicNote.a4,
    MusicNote.b4,
    MusicNote.c5,
  ];

  List<MusicNote> generate({
    int length = 12,
    List<MusicNote> range = beginnerTrebleRange,
  }) {
    return List<MusicNote>.generate(
      length,
      (_) => range[_random.nextInt(range.length)],
      growable: false,
    );
  }
}
