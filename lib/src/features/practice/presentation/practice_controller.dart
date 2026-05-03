import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/practice_exercise_repository.dart';
import '../data/microphone_pitch_source.dart';
import '../data/practice_settings_store.dart';
import '../domain/detected_pitch.dart';
import '../domain/music_note.dart';
import '../domain/note_generator.dart';
import '../domain/pitch_source.dart';
import '../domain/practice_clef.dart';
import '../domain/practice_exercise.dart';
import '../domain/practice_key_signature.dart';
import '../domain/practice_language.dart';
import '../domain/stave_background.dart';

final noteGeneratorProvider = Provider<NoteGenerator>((ref) => NoteGenerator());

final pitchSourceProvider = Provider<PitchSource>((ref) {
  final source = MicrophonePitchSource();
  ref.onDispose(source.dispose);
  return source;
});

final practiceSettingsStoreProvider =
    Provider<PracticeSettingsStore>((ref) => PracticeSettingsStore());

final practiceExerciseRepositoryProvider = Provider<PracticeExerciseRepository>(
  (ref) => PracticeExerciseRepository(),
);

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
    required this.practiceSource,
    required this.scaleExercise,
    required this.scaleExercises,
    required this.noteTimings,
    required this.currentNoteStartedAt,
    this.lastPageAverageDuration,
    this.lastPageTotalDuration,
    this.bestPageTotalDuration,
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
  final PracticeSource practiceSource;
  final ScaleExercise scaleExercise;
  final List<ScaleExercise> scaleExercises;
  final List<NoteTimingResult?> noteTimings;
  final DateTime? currentNoteStartedAt;
  final Duration? lastPageAverageDuration;
  final Duration? lastPageTotalDuration;
  final Duration? bestPageTotalDuration;
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

    for (var index = 0;
        index < notes.length && index < noteTimings.length;
        index++) {
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
    PracticeSource? practiceSource,
    ScaleExercise? scaleExercise,
    List<ScaleExercise>? scaleExercises,
    List<NoteTimingResult?>? noteTimings,
    DateTime? currentNoteStartedAt,
    Duration? lastPageAverageDuration,
    Duration? lastPageTotalDuration,
    Duration? bestPageTotalDuration,
    DetectedPitch? lastPitch,
    double? lastCents,
    String? errorMessage,
    bool clearPitch = false,
    bool clearCents = false,
    bool clearError = false,
    bool clearCurrentNoteStartedAt = false,
    bool clearLastPageAverageDuration = false,
    bool clearLastPageTotalDuration = false,
    bool clearBestPageTotalDuration = false,
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
      practiceSource: practiceSource ?? this.practiceSource,
      scaleExercise: scaleExercise ?? this.scaleExercise,
      scaleExercises: scaleExercises ?? this.scaleExercises,
      noteTimings: noteTimings ?? this.noteTimings,
      currentNoteStartedAt: clearCurrentNoteStartedAt
          ? null
          : currentNoteStartedAt ?? this.currentNoteStartedAt,
      lastPageAverageDuration: clearLastPageAverageDuration
          ? null
          : lastPageAverageDuration ?? this.lastPageAverageDuration,
      lastPageTotalDuration: clearLastPageTotalDuration
          ? null
          : lastPageTotalDuration ?? this.lastPageTotalDuration,
      bestPageTotalDuration: clearBestPageTotalDuration
          ? null
          : bestPageTotalDuration ?? this.bestPageTotalDuration,
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
  PitchSource? _activePitchSource;
  int _stableFrames = 0;
  final math.Random _random = math.Random();

  @override
  PracticeState build() {
    ref.onDispose(() {
      final pitchSubscription = _pitchSubscription;
      final activePitchSource = _activePitchSource;
      _pitchSubscription = null;
      _activePitchSource = null;

      if (pitchSubscription != null) {
        unawaited(pitchSubscription.cancel());
      }
      if (activePitchSource != null) {
        unawaited(activePitchSource.stop());
      }
    });

    unawaited(_restoreSavedContent());

    return _stateFromSettings(_defaultSettings());
  }

  Future<void> start() async {
    if (state.isListening) {
      return;
    }

    _stableFrames = 0;
    state = state.copyWith(
      status: PracticeStatus.listening,
      clearError: true,
      currentNoteStartedAt: state.currentIndex == 0 ? null : DateTime.now(),
      clearCurrentNoteStartedAt: state.currentIndex == 0,
    );

    await _pitchSubscription?.cancel();
    final pitchSource = ref.read(pitchSourceProvider);
    _activePitchSource = pitchSource;
    _pitchSubscription = pitchSource.start().listen(
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
    final keySignature = _nextKeySignature(
      source: state.practiceSource,
      scaleExercise: state.scaleExercise,
      allowedKeySignatures: state.allowedKeySignatures,
    );
    final notes = _generatePracticeNotes(
      source: state.practiceSource,
      scaleExercise: state.scaleExercise,
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
      practiceSource: state.practiceSource,
      scaleExercise: state.scaleExercise,
      scaleExercises: state.scaleExercises,
      noteTimings: _emptyTimings(notes.length),
      currentNoteStartedAt: null,
      lastPageAverageDuration: null,
      lastPageTotalDuration: null,
      bestPageTotalDuration: null,
    );
  }

  Future<void> selectRandomPractice() async {
    if (state.practiceSource == PracticeSource.random) {
      return;
    }

    await _setPracticeSource(
      source: PracticeSource.random,
      scaleExercise: state.scaleExercise,
    );
  }

  Future<void> selectScaleExercise(ScaleExercise exercise) async {
    if (state.practiceSource == PracticeSource.scaleExercise &&
        state.scaleExercise.id == exercise.id) {
      return;
    }

    await _setPracticeSource(
      source: PracticeSource.scaleExercise,
      scaleExercise: exercise,
    );
  }

  void setDetectedOctaveShift(int value) {
    final nextValue =
        value.clamp(minDetectedOctaveShift, maxDetectedOctaveShift).toInt();

    if (nextValue == state.detectedOctaveShift) {
      return;
    }

    _stableFrames = 0;
    state = state.copyWith(
      detectedOctaveShift: nextValue,
      clearPitch: true,
    );
    _persistSettings();
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
    final nextValue =
        value.clamp(minBeatsPerMeasure, maxBeatsPerMeasure).toInt();
    if (nextValue == state.beatsPerMeasure) {
      return;
    }

    await _setExerciseSettings(beatsPerMeasure: nextValue);
  }

  Future<void> setMeasuresPerPage(int value) async {
    final nextValue =
        value.clamp(minMeasuresPerPage, maxMeasuresPerPage).toInt();
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
    _persistSettings();
  }

  void setStaveBackground(StaveBackground background) {
    if (background == state.staveBackground) {
      return;
    }

    state = state.copyWith(staveBackground: background);
    _persistSettings();
  }

  Future<void> toggleAllowedKeySignature(
      PracticeKeySignature keySignature) async {
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

  Future<void> _setPracticeSource({
    required PracticeSource source,
    required ScaleExercise scaleExercise,
  }) async {
    await _stopListening();
    _stableFrames = 0;

    final nextClef = source == PracticeSource.scaleExercise
        ? scaleExercise.clef
        : state.clef;
    final nextBeatsPerMeasure = source == PracticeSource.scaleExercise
        ? scaleExercise.beatsPerMeasure
        : state.beatsPerMeasure;
    final nextMeasuresPerPage = source == PracticeSource.scaleExercise
        ? scaleExercise.measuresPerPage
        : state.measuresPerPage;
    final keySignature = _nextKeySignature(
      source: source,
      scaleExercise: scaleExercise,
      allowedKeySignatures: state.allowedKeySignatures,
    );
    final notes = _generatePracticeNotes(
      source: source,
      scaleExercise: scaleExercise,
      lowest: state.lowestNote,
      highest: state.highestNote,
      keySignature: keySignature,
      allowAccidentals: state.allowAccidentals,
      beatsPerMeasure: nextBeatsPerMeasure,
      measuresPerPage: nextMeasuresPerPage,
    );

    state = PracticeState(
      notes: notes,
      currentIndex: 0,
      status: PracticeStatus.idle,
      detectedOctaveShift: state.detectedOctaveShift,
      lowestNote: state.lowestNote,
      highestNote: state.highestNote,
      clef: nextClef,
      beatsPerMeasure: nextBeatsPerMeasure,
      measuresPerPage: nextMeasuresPerPage,
      language: state.language,
      staveBackground: state.staveBackground,
      allowedKeySignatures: state.allowedKeySignatures,
      keySignature: keySignature,
      allowAccidentals: state.allowAccidentals,
      practiceSource: source,
      scaleExercise: scaleExercise,
      scaleExercises: state.scaleExercises,
      noteTimings: _emptyTimings(notes.length),
      currentNoteStartedAt: null,
      lastPageAverageDuration: null,
      lastPageTotalDuration: null,
      bestPageTotalDuration: null,
    );
    _persistSettings();
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
      final startedAt = state.currentNoteStartedAt;
      final noteTimings = List<NoteTimingResult?>.of(state.noteTimings);
      if (startedAt != null && state.currentIndex < noteTimings.length) {
        noteTimings[state.currentIndex] = NoteTimingResult(
          duration: completedAt.difference(startedAt),
          completedAt: completedAt,
        );
      }
      _stableFrames = 0;

      if (nextIndex >= state.notes.length) {
        final averageDuration = _averageDuration(noteTimings);
        final totalDuration =
            nextIndex <= 1 ? Duration.zero : _totalDuration(noteTimings);
        final bestDuration = _bestDuration(
          currentBest: state.bestPageTotalDuration,
          candidate: totalDuration,
        );
        final nextKeySignature = _nextKeySignature(
          source: state.practiceSource,
          scaleExercise: state.scaleExercise,
          allowedKeySignatures: state.allowedKeySignatures,
        );
        final nextNotes = _generatePracticeNotes(
          source: state.practiceSource,
          scaleExercise: state.scaleExercise,
          lowest: state.lowestNote,
          highest: state.highestNote,
          keySignature: nextKeySignature,
          allowAccidentals: state.allowAccidentals,
          beatsPerMeasure: state.beatsPerMeasure,
          measuresPerPage: state.measuresPerPage,
          previousNote: note,
        );

        state = state.copyWith(
          notes: nextNotes,
          currentIndex: 0,
          status: PracticeStatus.listening,
          keySignature: nextKeySignature,
          lastPitch: pitch,
          lastCents: cents,
          noteTimings: _emptyTimings(nextNotes.length),
          clearCurrentNoteStartedAt: true,
          lastPageAverageDuration: averageDuration,
          lastPageTotalDuration: totalDuration,
          bestPageTotalDuration: bestDuration,
        );
        return;
      }

      state = state.copyWith(
        currentIndex: nextIndex,
        status: PracticeStatus.listening,
        lastPitch: pitch,
        lastCents: cents,
        noteTimings: noteTimings,
        currentNoteStartedAt: completedAt,
      );
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
    final activePitchSource = _activePitchSource;
    _activePitchSource = null;
    await activePitchSource?.stop();
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
    final nextKeySignature =
        state.practiceSource == PracticeSource.scaleExercise
            ? state.scaleExercise.keySignature
            : nextAllowedKeySignatures.contains(state.keySignature)
                ? _chooseKeySignature(nextAllowedKeySignatures)
                : nextAllowedKeySignatures.first;

    await _stopListening();
    _stableFrames = 0;
    final notes = _generatePracticeNotes(
      source: state.practiceSource,
      scaleExercise: state.scaleExercise,
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
      practiceSource: state.practiceSource,
      scaleExercise: state.scaleExercise,
      scaleExercises: state.scaleExercises,
      noteTimings: _emptyTimings(notes.length),
      currentNoteStartedAt: null,
      lastPageAverageDuration: null,
      lastPageTotalDuration: null,
      bestPageTotalDuration: null,
    );
    _persistSettings();
  }

  List<MusicNote> _generateNotes({
    required MusicNote lowest,
    required MusicNote highest,
    required PracticeKeySignature keySignature,
    required bool allowAccidentals,
    required int beatsPerMeasure,
    required int measuresPerPage,
    MusicNote? previousNote,
  }) {
    return ref.read(noteGeneratorProvider).generate(
          length: beatsPerMeasure * measuresPerPage,
          range: keySignature.practiceRange(
            lowest: lowest,
            highest: highest,
            includeAccidentals: allowAccidentals,
          ),
          previousNote: previousNote,
        );
  }

  List<MusicNote> _generatePracticeNotes({
    required PracticeSource source,
    required ScaleExercise scaleExercise,
    required MusicNote lowest,
    required MusicNote highest,
    required PracticeKeySignature keySignature,
    required bool allowAccidentals,
    required int beatsPerMeasure,
    required int measuresPerPage,
    MusicNote? previousNote,
  }) {
    return switch (source) {
      PracticeSource.random => _generateNotes(
          lowest: lowest,
          highest: highest,
          keySignature: keySignature,
          allowAccidentals: allowAccidentals,
          beatsPerMeasure: beatsPerMeasure,
          measuresPerPage: measuresPerPage,
          previousNote: previousNote,
        ),
      PracticeSource.scaleExercise => scaleExercise.pageNotes(
          previousNote: previousNote,
        ),
    };
  }

  PracticeKeySignature _nextKeySignature({
    required PracticeSource source,
    required ScaleExercise scaleExercise,
    required Set<PracticeKeySignature> allowedKeySignatures,
  }) {
    return switch (source) {
      PracticeSource.random => _chooseKeySignature(allowedKeySignatures),
      PracticeSource.scaleExercise => scaleExercise.keySignature,
    };
  }

  Future<void> _restoreSavedContent() async {
    var exercises = fallbackScaleExercises;
    try {
      exercises =
          await ref.read(practiceExerciseRepositoryProvider).loadExercises();
    } on Object {
      exercises = fallbackScaleExercises;
    }
    final storedSettings = await ref.read(practiceSettingsStoreProvider).load();
    if (!ref.mounted || state.isListening) {
      return;
    }

    state = _stateFromSettings(
      storedSettings ?? _defaultSettings(),
      exercises: exercises,
    );
  }

  void _persistSettings() {
    unawaited(
      ref.read(practiceSettingsStoreProvider).save(_settingsFromState(state)),
    );
  }

  PracticeState _stateFromSettings(
    StoredPracticeSettings settings, {
    List<ScaleExercise> exercises = fallbackScaleExercises,
  }) {
    final normalizedSettings = _normalizeSettings(
      settings,
      exercises: exercises,
    );
    final selectedExercise = scaleExerciseById(
      normalizedSettings.scaleExerciseId,
      exercises,
    );
    final notes = _generatePracticeNotes(
      source: normalizedSettings.practiceSource,
      scaleExercise: selectedExercise,
      lowest: normalizedSettings.lowestNote,
      highest: normalizedSettings.highestNote,
      keySignature: normalizedSettings.keySignature,
      allowAccidentals: normalizedSettings.allowAccidentals,
      beatsPerMeasure: normalizedSettings.beatsPerMeasure,
      measuresPerPage: normalizedSettings.measuresPerPage,
    );

    return PracticeState(
      notes: notes,
      currentIndex: 0,
      status: PracticeStatus.idle,
      detectedOctaveShift: normalizedSettings.detectedOctaveShift,
      lowestNote: normalizedSettings.lowestNote,
      highestNote: normalizedSettings.highestNote,
      clef: normalizedSettings.clef,
      beatsPerMeasure: normalizedSettings.beatsPerMeasure,
      measuresPerPage: normalizedSettings.measuresPerPage,
      language: normalizedSettings.language,
      staveBackground: normalizedSettings.staveBackground,
      allowedKeySignatures: normalizedSettings.allowedKeySignatures,
      keySignature: normalizedSettings.keySignature,
      allowAccidentals: normalizedSettings.allowAccidentals,
      practiceSource: normalizedSettings.practiceSource,
      scaleExercise: selectedExercise,
      scaleExercises: exercises,
      noteTimings: _emptyTimings(notes.length),
      currentNoteStartedAt: null,
      lastPageAverageDuration: null,
      lastPageTotalDuration: null,
      bestPageTotalDuration: null,
    );
  }

  StoredPracticeSettings _defaultSettings() {
    return const StoredPracticeSettings(
      detectedOctaveShift: 0,
      lowestNote: MusicNote.c4,
      highestNote: MusicNote.c5,
      clef: PracticeClef.treble,
      beatsPerMeasure: 4,
      measuresPerPage: 3,
      language: PracticeLanguage.english,
      staveBackground: StaveBackground.paper,
      allowedKeySignatures: {PracticeKeySignature.cMajor},
      keySignature: PracticeKeySignature.cMajor,
      allowAccidentals: true,
      practiceSource: PracticeSource.random,
      scaleExerciseId: 'c_major_scale',
    );
  }

  StoredPracticeSettings _settingsFromState(PracticeState state) {
    return StoredPracticeSettings(
      detectedOctaveShift: state.detectedOctaveShift,
      lowestNote: state.lowestNote,
      highestNote: state.highestNote,
      clef: state.clef,
      beatsPerMeasure: state.beatsPerMeasure,
      measuresPerPage: state.measuresPerPage,
      language: state.language,
      staveBackground: state.staveBackground,
      allowedKeySignatures: state.allowedKeySignatures,
      keySignature: state.keySignature,
      allowAccidentals: state.allowAccidentals,
      practiceSource: state.practiceSource,
      scaleExerciseId: state.scaleExercise.id,
    );
  }

  StoredPracticeSettings _normalizeSettings(
    StoredPracticeSettings settings, {
    List<ScaleExercise> exercises = fallbackScaleExercises,
  }) {
    final lowestNote = _clampPracticeNote(settings.lowestNote);
    final unclampedHighestNote = _clampPracticeNote(settings.highestNote);
    final highestNote = unclampedHighestNote.midi < lowestNote.midi
        ? lowestNote
        : unclampedHighestNote;
    final allowedKeySignatures = settings.allowedKeySignatures.isEmpty
        ? const {PracticeKeySignature.cMajor}
        : settings.allowedKeySignatures;
    final keySignature = allowedKeySignatures.contains(settings.keySignature)
        ? settings.keySignature
        : allowedKeySignatures.first;
    final scaleExercise =
        scaleExerciseById(settings.scaleExerciseId, exercises);
    final isScaleExercise =
        settings.practiceSource == PracticeSource.scaleExercise;

    return StoredPracticeSettings(
      detectedOctaveShift: settings.detectedOctaveShift
          .clamp(minDetectedOctaveShift, maxDetectedOctaveShift)
          .toInt(),
      lowestNote: lowestNote,
      highestNote: highestNote,
      clef: isScaleExercise ? scaleExercise.clef : settings.clef,
      beatsPerMeasure: isScaleExercise
          ? scaleExercise.beatsPerMeasure
          : settings.beatsPerMeasure
              .clamp(minBeatsPerMeasure, maxBeatsPerMeasure)
              .toInt(),
      measuresPerPage: isScaleExercise
          ? scaleExercise.measuresPerPage
          : settings.measuresPerPage
              .clamp(minMeasuresPerPage, maxMeasuresPerPage)
              .toInt(),
      language: settings.language,
      staveBackground: settings.staveBackground,
      allowedKeySignatures: allowedKeySignatures,
      keySignature: isScaleExercise ? scaleExercise.keySignature : keySignature,
      allowAccidentals: settings.allowAccidentals,
      practiceSource: settings.practiceSource,
      scaleExerciseId: scaleExercise.id,
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

  Duration? _averageDuration(List<NoteTimingResult?> timings) {
    final completed = timings.whereType<NoteTimingResult>().toList();
    if (completed.isEmpty) {
      return null;
    }

    final totalMilliseconds = completed.fold<int>(
      0,
      (total, timing) => total + timing.duration.inMilliseconds,
    );

    return Duration(milliseconds: totalMilliseconds ~/ completed.length);
  }

  Duration? _totalDuration(List<NoteTimingResult?> timings) {
    final completed = timings.whereType<NoteTimingResult>().toList();
    if (completed.isEmpty) {
      return null;
    }

    final totalMilliseconds = completed.fold<int>(
      0,
      (total, timing) => total + timing.duration.inMilliseconds,
    );

    return Duration(milliseconds: totalMilliseconds);
  }

  Duration? _bestDuration({
    required Duration? currentBest,
    required Duration? candidate,
  }) {
    if (candidate == null) {
      return currentBest;
    }
    if (currentBest == null || candidate < currentBest) {
      return candidate;
    }

    return currentBest;
  }

  PracticeKeySignature _chooseKeySignature(Set<PracticeKeySignature> allowed) {
    final choices = allowed.toList(growable: false);
    return choices[_random.nextInt(choices.length)];
  }
}
