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
    MusicNote? previousNote,
  }) {
    if (range.isEmpty) {
      return const [];
    }

    final notes = <MusicNote>[];
    for (var index = 0; index < length; index++) {
      final previous = notes.isEmpty ? previousNote : notes.last;
      final choices = previous == null || range.length == 1
          ? range
          : range
              .where((note) => note.midi != previous.midi)
              .toList(growable: false);

      notes.add(choices[_random.nextInt(choices.length)]);
    }

    return notes;
  }
}
