import 'package:shared_preferences/shared_preferences.dart';

import '../domain/music_note.dart';
import '../domain/practice_clef.dart';
import '../domain/practice_key_signature.dart';
import '../domain/practice_language.dart';
import '../domain/stave_background.dart';

class StoredPracticeSettings {
  const StoredPracticeSettings({
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
  });

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
}

class PracticeSettingsStore {
  static const _hasSettingsKey = 'practice.hasSettings';
  static const _detectedOctaveShiftKey = 'practice.detectedOctaveShift';
  static const _lowestNoteMidiKey = 'practice.lowestNoteMidi';
  static const _highestNoteMidiKey = 'practice.highestNoteMidi';
  static const _clefKey = 'practice.clef';
  static const _beatsPerMeasureKey = 'practice.beatsPerMeasure';
  static const _measuresPerPageKey = 'practice.measuresPerPage';
  static const _languageKey = 'practice.language';
  static const _staveBackgroundKey = 'practice.staveBackground';
  static const _allowedKeySignaturesKey = 'practice.allowedKeySignatures';
  static const _keySignatureKey = 'practice.keySignature';
  static const _allowAccidentalsKey = 'practice.allowAccidentals';

  Future<StoredPracticeSettings?> load() async {
    final preferences = await SharedPreferences.getInstance();
    if (!(preferences.getBool(_hasSettingsKey) ?? false)) {
      return null;
    }

    final allowedKeySignatures =
        (preferences.getStringList(_allowedKeySignaturesKey) ??
                const <String>[])
            .map((name) => _enumByName(PracticeKeySignature.values, name))
            .whereType<PracticeKeySignature>()
            .toSet();

    return StoredPracticeSettings(
      detectedOctaveShift: preferences.getInt(_detectedOctaveShiftKey) ?? 0,
      lowestNote: MusicNote(
        preferences.getInt(_lowestNoteMidiKey) ?? MusicNote.c4.midi,
      ),
      highestNote: MusicNote(
        preferences.getInt(_highestNoteMidiKey) ?? MusicNote.c5.midi,
      ),
      clef: _enumByName(
            PracticeClef.values,
            preferences.getString(_clefKey),
          ) ??
          PracticeClef.treble,
      beatsPerMeasure: preferences.getInt(_beatsPerMeasureKey) ?? 4,
      measuresPerPage: preferences.getInt(_measuresPerPageKey) ?? 3,
      language: _enumByName(
            PracticeLanguage.values,
            preferences.getString(_languageKey),
          ) ??
          PracticeLanguage.english,
      staveBackground: _enumByName(
            StaveBackground.values,
            preferences.getString(_staveBackgroundKey),
          ) ??
          StaveBackground.paper,
      allowedKeySignatures: allowedKeySignatures.isEmpty
          ? const {PracticeKeySignature.cMajor}
          : allowedKeySignatures,
      keySignature: _enumByName(
            PracticeKeySignature.values,
            preferences.getString(_keySignatureKey),
          ) ??
          PracticeKeySignature.cMajor,
      allowAccidentals: preferences.getBool(_allowAccidentalsKey) ?? true,
    );
  }

  Future<void> save(StoredPracticeSettings settings) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_hasSettingsKey, true);
    await preferences.setInt(
      _detectedOctaveShiftKey,
      settings.detectedOctaveShift,
    );
    await preferences.setInt(_lowestNoteMidiKey, settings.lowestNote.midi);
    await preferences.setInt(_highestNoteMidiKey, settings.highestNote.midi);
    await preferences.setString(_clefKey, settings.clef.name);
    await preferences.setInt(_beatsPerMeasureKey, settings.beatsPerMeasure);
    await preferences.setInt(_measuresPerPageKey, settings.measuresPerPage);
    await preferences.setString(_languageKey, settings.language.name);
    await preferences.setString(
      _staveBackgroundKey,
      settings.staveBackground.name,
    );
    await preferences.setStringList(
      _allowedKeySignaturesKey,
      settings.allowedKeySignatures
          .map((keySignature) => keySignature.name)
          .toList(growable: false),
    );
    await preferences.setString(_keySignatureKey, settings.keySignature.name);
    await preferences.setBool(
      _allowAccidentalsKey,
      settings.allowAccidentals,
    );
  }

  T? _enumByName<T extends Enum>(List<T> values, String? name) {
    if (name == null) {
      return null;
    }

    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }

    return null;
  }
}
