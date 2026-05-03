import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/microphone_pitch_source.dart';
import '../domain/detected_pitch.dart';
import '../domain/music_note.dart';
import '../domain/note_generator.dart';
import '../domain/pitch_source.dart';
import '../domain/practice_clef.dart';
import '../domain/practice_key_signature.dart';
import '../domain/practice_language.dart';
import '../domain/stave_background.dart';

final noteGeneratorProvider = Provider<NoteGenerator>((ref) => NoteGenerator());

final pitchSourceProvider = Provider<PitchSource>((ref) {
  final source = MicrophonePitchSource();
  ref.onDispose(source.dispose);
  return source;
});

final practiceControllerProvider =
    NotifierProvider<PracticeController, PracticeState>(PracticeController.new);

enum PracticeStatus { idle, listening, completed, permissionDenied, error }

class NoteTimingResult {
  const NoteTimingResult({
    required this.duration,
    required this.completedAt,
  });

  final Duration duration;
  final DateTime completedAt;
}

class SessionRecapNote {
  const SessionRecapNote({
    required this.note,
    required this.duration,
  });

  final MusicNote note;
  final Duration duration;
}

class SessionRecap {
  const SessionRecap({
    required this.completedNotes,
    required this.totalNotes,
    required this.averageDuration,
    required this.fastestDuration,
    required this.slowestDuration,
    required this.slowestNotes,
  });

  final int completedNotes;
  final int totalNotes;
  final Duration? averageDuration;
  final Duration? fastestDuration;
  final Duration? slowestDuration;
  final List<SessionRecapNote> slowestNotes;

  bool get hasResults => completedNotes > 0;
}

class PracticeState {
  const PracticeState({
    required this.notes,
    required this.currentIndex,
    required this.status,
    required this.detectedOctaveShift,
    required this.lowestNote,
    required this.highestNote,
    required this.clef,
    required this.beatsPerMeasure,
    required this.measuresPerPage,
    required this.language,
    required this.staveBackground,
    required this.allowedKeySignatures,
    required this.keySignature,
    required this.allowAccidentals,
    required this.noteTimings,
    required this.currentNoteStartedAt,
    this.lastPitch,
    this.lastCents,
    this.errorMessage,
  });

  final List<MusicNote> notes;
  final int currentIndex;
  final PracticeStatus status;
  final int detectedOctaveShift;
  final MusicNote lowestNote;
  final MusicNote highestNote;
  final PracticeClef clef;
  final int beatsPerMeasure;
  final int measuresPerPage;
  final PracticeLanguage language;
  final StaveBackground staveBackground;
  final Set<PracticeKeySignature> allowedKeySignatures;
  final PracticeKeySignature keySignature;
  final bool allowAccidentals;
  final List<NoteTimingResult?> noteTimings;
  final DateTime? currentNoteStartedAt;
  final DetectedPitch? lastPitch;
  final double? lastCents;
  final String? errorMessage;

  MusicNote? get currentNote {
    if (currentIndex >= notes.length) {
      return null;
    }

    return notes[currentIndex];
  }

  double get progress => notes.isEmpty ? 0 : currentIndex / notes.length;

  bool get isListening => status == PracticeStatus.listening;

  String get noteRangeLabel {
    return '${lowestNote.labelFor(language)}-${highestNote.labelFor(language)}';
  }

  double? get shiftedLastFrequency {
    final pitch = lastPitch;
    if (pitch == null || !pitch.isPitched) {
      return null;
    }

    return pitch.frequency * math.pow(2, detectedOctaveShift);
  }

  SessionRecap buildRecap() {
    final results = <SessionRecapNote>[];

    for (var index = 0; index < notes.length && index < noteTimings.length; index++) {
      final timing = noteTimings[index];
      if (timing != null) {
        results.add(
          SessionRecapNote(
            note: notes[index],
            duration: timing.duration,
          ),
        );
      }
    }

    if (results.isEmpty) {
      return SessionRecap(
        completedNotes: 0,
        totalNotes: notes.length,
        averageDuration: null,
        fastestDuration: null,
        slowestDuration: null,
        slowestNotes: const [],
      );
    }

    final durations = results.map((result) => result.duration).toList();
    final totalMilliseconds = durations.fold<int>(
      0,
      (total, duration) => total + duration.inMilliseconds,
    );
    final sortedByDuration = [...results]
      ..sort((a, b) => b.duration.compareTo(a.duration));

    return SessionRecap(
      completedNotes: results.length,
      totalNotes: notes.length,
      averageDuration: Duration(
        milliseconds: totalMilliseconds ~/ results.length,
      ),
      fastestDuration: durations.reduce(
        (a, b) => a < b ? a : b,
      ),
      slowestDuration: durations.reduce(
        (a, b) => a > b ? a : b,
      ),
      slowestNotes: sortedByDuration.take(3).toList(growable: false),
    );
  }

  PracticeState copyWith({
    List<MusicNote>? notes,
    int? currentIndex,
    PracticeStatus? status,
    int? detectedOctaveShift,
    MusicNote? lowestNote,
    MusicNote? highestNote,
    PracticeClef? clef,
    int? beatsPerMeasure,
    int? measuresPerPage,
    PracticeLanguage? language,
    StaveBackground? staveBackground,
    Set<PracticeKeySignature>? allowedKeySignatures,
    PracticeKeySignature? keySignature,
    bool? allowAccidentals,
    List<NoteTimingResult?>? noteTimings,
    DateTime? currentNoteStartedAt,
    DetectedPitch? lastPitch,
    double? lastCents,
    String? errorMessage,
    bool clearPitch = false,
    bool clearCents = false,
    bool clearError = false,
    bool clearCurrentNoteStartedAt = false,
  }) {
    return PracticeState(
      notes: notes ?? this.notes,
      currentIndex: currentIndex ?? this.currentIndex,
      status: status ?? this.status,
      detectedOctaveShift: detectedOctaveShift ?? this.detectedOctaveShift,
      lowestNote: lowestNote ?? this.lowestNote,
      highestNote: highestNote ?? this.highestNote,
      clef: clef ?? this.clef,
      beatsPerMeasure: beatsPerMeasure ?? this.beatsPerMeasure,
      measuresPerPage: measuresPerPage ?? this.measuresPerPage,
      language: language ?? this.language,
      staveBackground: staveBackground ?? this.staveBackground,
      allowedKeySignatures: allowedKeySignatures ?? this.allowedKeySignatures,
      keySignature: keySignature ?? this.keySignature,
      allowAccidentals: allowAccidentals ?? this.allowAccidentals,
      noteTimings: noteTimings ?? this.noteTimings,
      currentNoteStartedAt: clearCurrentNoteStartedAt
          ? null
          : currentNoteStartedAt ?? this.currentNoteStartedAt,
      lastPitch: clearPitch ? null : lastPitch ?? this.lastPitch,
      lastCents: clearPitch || clearCents ? null : lastCents ?? this.lastCents,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class PracticeController extends Notifier<PracticeState> {
  static const minDetectedOctaveShift = -2;
  static const maxDetectedOctaveShift = 2;
  static const minBeatsPerMeasure = 1;
  static const maxBeatsPerMeasure = 12;
  static const minMeasuresPerPage = 1;
  static const maxMeasuresPerPage = 8;

  static const _requiredStableFrames = 4;
  static const _toleranceCents = 35.0;
  static const _minimumProbability = 0.72;

  StreamSubscription<DetectedPitch>? _pitchSubscription;
  int _stableFrames = 0;
  final math.Random _random = math.Random();

  @override
  PracticeState build() {
    ref.onDispose(_stopListening);

    return PracticeState(
      notes: _generateNotes(
        lowest: MusicNote.c4,
        highest: MusicNote.c5,
        keySignature: PracticeKeySignature.cMajor,
        allowAccidentals: true,
        beatsPerMeasure: 4,
        measuresPerPage: 3,
      ),
      currentIndex: 0,
      status: PracticeStatus.idle,
      detectedOctaveShift: 0,
      lowestNote: MusicNote.c4,
      highestNote: MusicNote.c5,
      clef: PracticeClef.treble,
      beatsPerMeasure: 4,
      measuresPerPage: 3,
      language: PracticeLanguage.english,
      staveBackground: StaveBackground.paper,
      allowedKeySignatures: const {PracticeKeySignature.cMajor},
      keySignature: PracticeKeySignature.cMajor,
      allowAccidentals: true,
      noteTimings: _emptyTimings(12),
      currentNoteStartedAt: null,
    );
  }

  Future<void> start() async {
    if (state.isListening) {
      return;
    }

    _stableFrames = 0;
    state = state.copyWith(
      status: PracticeStatus.listening,
      clearError: true,
      currentNoteStartedAt: DateTime.now(),
    );

    await _pitchSubscription?.cancel();
    _pitchSubscription = ref.read(pitchSourceProvider).start().listen(
          _handlePitch,
          onError: _handlePitchError,
        );
  }

  Future<void> stop() async {
    await _stopListening();
    state = state.copyWith(
      status: PracticeStatus.idle,
      clearPitch: true,
      clearCurrentNoteStartedAt: true,
    );
  }

  Future<void> reset() async {
    await _stopListening();
    _stableFrames = 0;
    final keySignature = _chooseKeySignature(state.allowedKeySignatures);
    final notes = _generateNotes(
        lowest: state.lowestNote,
        highest: state.highestNote,
        keySignature: keySignature,
        allowAccidentals: state.allowAccidentals,
        beatsPerMeasure: state.beatsPerMeasure,
        measuresPerPage: state.measuresPerPage,
      );
    state = PracticeState(
      notes: notes,
      currentIndex: 0,
      status: PracticeStatus.idle,
      detectedOctaveShift: state.detectedOctaveShift,
      lowestNote: state.lowestNote,
      highestNote: state.highestNote,
      clef: state.clef,
      beatsPerMeasure: state.beatsPerMeasure,
      measuresPerPage: state.measuresPerPage,
      language: state.language,
      staveBackground: state.staveBackground,
      allowedKeySignatures: state.allowedKeySignatures,
      keySignature: keySignature,
      allowAccidentals: state.allowAccidentals,
      noteTimings: _emptyTimings(notes.length),
      currentNoteStartedAt: null,
    );
  }

  void setDetectedOctaveShift(int value) {
    final nextValue = value
        .clamp(minDetectedOctaveShift, maxDetectedOctaveShift)
        .toInt();

    if (nextValue == state.detectedOctaveShift) {
      return;
    }

    _stableFrames = 0;
    state = state.copyWith(
      detectedOctaveShift: nextValue,
      clearPitch: true,
    );
  }

  Future<void> setLowestNote(MusicNote note) async {
    final nextLowest = _clampPracticeNote(note);
    if (nextLowest.midi == state.lowestNote.midi) {
      return;
    }

    final nextHighest = state.highestNote.midi < nextLowest.midi
        ? nextLowest
        : state.highestNote;
    await _setExerciseSettings(
      lowestNote: nextLowest,
      highestNote: nextHighest,
    );
  }

  Future<void> setHighestNote(MusicNote note) async {
    final nextHighest = _clampPracticeNote(note);
    if (nextHighest.midi == state.highestNote.midi) {
      return;
    }

    final nextLowest = state.lowestNote.midi > nextHighest.midi
        ? nextHighest
        : state.lowestNote;
    await _setExerciseSettings(
      lowestNote: nextLowest,
      highestNote: nextHighest,
    );
  }

  Future<void> setClef(PracticeClef clef) async {
    if (clef == state.clef) {
      return;
    }

    await _setExerciseSettings(clef: clef);
  }

  Future<void> setBeatsPerMeasure(int value) async {
    final nextValue = value.clamp(minBeatsPerMeasure, maxBeatsPerMeasure).toInt();
    if (nextValue == state.beatsPerMeasure) {
      return;
    }

    await _setExerciseSettings(beatsPerMeasure: nextValue);
  }

  Future<void> setMeasuresPerPage(int value) async {
    final nextValue = value
        .clamp(minMeasuresPerPage, maxMeasuresPerPage)
        .toInt();
    if (nextValue == state.measuresPerPage) {
      return;
    }

    await _setExerciseSettings(measuresPerPage: nextValue);
  }

  void setLanguage(PracticeLanguage language) {
    if (language == state.language) {
      return;
    }

    state = state.copyWith(language: language);
  }

  void setStaveBackground(StaveBackground background) {
    if (background == state.staveBackground) {
      return;
    }

    state = state.copyWith(staveBackground: background);
  }

  Future<void> toggleAllowedKeySignature(PracticeKeySignature keySignature) async {
    final allowed = {...state.allowedKeySignatures};
    if (allowed.contains(keySignature)) {
      if (allowed.length == 1) {
        return;
      }
      allowed.remove(keySignature);
    } else {
      allowed.add(keySignature);
    }

    await _setExerciseSettings(allowedKeySignatures: allowed);
  }

  Future<void> setAllowAccidentals(bool value) async {
    if (value == state.allowAccidentals) {
      return;
    }

    await _setExerciseSettings(allowAccidentals: value);
  }

  void simulateCurrentNote() {
    final note = state.currentNote;
    if (note == null) {
      return;
    }

    _handlePitch(
      DetectedPitch(
        frequency: note.frequency,
        probability: 1,
        timestamp: DateTime.now(),
        pitched: true,
      ),
    );
  }

  void _handlePitch(DetectedPitch pitch) {
    final note = state.currentNote;
    if (note == null || state.status != PracticeStatus.listening) {
      return;
    }

    final shiftedFrequency = pitch.isPitched
        ? pitch.frequency * math.pow(2, state.detectedOctaveShift)
        : null;
    final cents = shiftedFrequency != null
        ? note.centsFromFrequency(shiftedFrequency.toDouble())
        : null;
    final isMatch = pitch.isPitched &&
        pitch.probability >= _minimumProbability &&
        cents != null &&
        cents.isFinite &&
        cents.abs() <= _toleranceCents;

    _stableFrames = isMatch ? _stableFrames + 1 : 0;

    if (_stableFrames >= _requiredStableFrames) {
      final nextIndex = state.currentIndex + 1;
      final completedAt = DateTime.now();
      final startedAt = state.currentNoteStartedAt ?? completedAt;
      final noteTimings = List<NoteTimingResult?>.of(state.noteTimings);
      if (state.currentIndex < noteTimings.length) {
        noteTimings[state.currentIndex] = NoteTimingResult(
          duration: completedAt.difference(startedAt),
          completedAt: completedAt,
        );
      }
      _stableFrames = 0;

      state = state.copyWith(
        currentIndex: nextIndex,
        status: nextIndex >= state.notes.length
            ? PracticeStatus.completed
            : PracticeStatus.listening,
        lastPitch: pitch,
        lastCents: cents,
        noteTimings: noteTimings,
        currentNoteStartedAt:
            nextIndex >= state.notes.length ? null : completedAt,
      );

      if (nextIndex >= state.notes.length) {
        _stopListening();
      }
      return;
    }

    state = state.copyWith(
      lastPitch: pitch,
      lastCents: cents,
      clearCents: cents == null,
    );
  }

  void _handlePitchError(Object error, StackTrace stackTrace) {
    _stableFrames = 0;

    if (error is MicrophonePermissionException) {
      state = state.copyWith(
        status: PracticeStatus.permissionDenied,
        errorMessage: 'Microphone permission is required.',
      );
      return;
    }

    state = state.copyWith(
      status: PracticeStatus.error,
      errorMessage: error.toString(),
    );
  }

  Future<void> _stopListening() async {
    await _pitchSubscription?.cancel();
    _pitchSubscription = null;
    await ref.read(pitchSourceProvider).stop();
  }

  Future<void> _setExerciseSettings({
    MusicNote? lowestNote,
    MusicNote? highestNote,
    PracticeClef? clef,
    int? beatsPerMeasure,
    int? measuresPerPage,
    Set<PracticeKeySignature>? allowedKeySignatures,
    bool? allowAccidentals,
  }) async {
    final nextLowest = lowestNote ?? state.lowestNote;
    final nextHighest = highestNote ?? state.highestNote;
    final nextClef = clef ?? state.clef;
    final nextBeatsPerMeasure = beatsPerMeasure ?? state.beatsPerMeasure;
    final nextMeasuresPerPage = measuresPerPage ?? state.measuresPerPage;
    final nextAllowedKeySignatures =
        allowedKeySignatures ?? state.allowedKeySignatures;
    final nextAllowAccidentals = allowAccidentals ?? state.allowAccidentals;
    final nextKeySignature = nextAllowedKeySignatures.contains(state.keySignature)
        ? _chooseKeySignature(nextAllowedKeySignatures)
        : nextAllowedKeySignatures.first;

    await _stopListening();
    _stableFrames = 0;
    final notes = _generateNotes(
        lowest: nextLowest,
        highest: nextHighest,
        keySignature: nextKeySignature,
        allowAccidentals: nextAllowAccidentals,
        beatsPerMeasure: nextBeatsPerMeasure,
        measuresPerPage: nextMeasuresPerPage,
      );
    state = PracticeState(
      notes: notes,
      currentIndex: 0,
      status: PracticeStatus.idle,
      detectedOctaveShift: state.detectedOctaveShift,
      lowestNote: nextLowest,
      highestNote: nextHighest,
      clef: nextClef,
      beatsPerMeasure: nextBeatsPerMeasure,
      measuresPerPage: nextMeasuresPerPage,
      language: state.language,
      staveBackground: state.staveBackground,
      allowedKeySignatures: nextAllowedKeySignatures,
      keySignature: nextKeySignature,
      allowAccidentals: nextAllowAccidentals,
      noteTimings: _emptyTimings(notes.length),
      currentNoteStartedAt: null,
    );
  }

  List<MusicNote> _generateNotes({
    required MusicNote lowest,
    required MusicNote highest,
    required PracticeKeySignature keySignature,
    required bool allowAccidentals,
    required int beatsPerMeasure,
    required int measuresPerPage,
  }) {
    return ref.read(noteGeneratorProvider).generate(
          length: beatsPerMeasure * measuresPerPage,
          range: keySignature.practiceRange(
            lowest: lowest,
            highest: highest,
            includeAccidentals: allowAccidentals,
          ),
        );
  }

  MusicNote _clampPracticeNote(MusicNote note) {
    final natural = note.nearestNatural;
    return MusicNote(
      natural.midi.clamp(
        MusicNote.lowestPracticeNote.midi,
        MusicNote.highestPracticeNote.midi,
      ),
    ).nearestNatural;
  }

  List<NoteTimingResult?> _emptyTimings(int length) {
    return List<NoteTimingResult?>.filled(length, null, growable: false);
  }

  PracticeKeySignature _chooseKeySignature(Set<PracticeKeySignature> allowed) {
    final choices = allowed.toList(growable: false);
    return choices[_random.nextInt(choices.length)];
  }
}
