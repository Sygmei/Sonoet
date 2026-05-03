import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonoet/src/features/practice/data/practice_settings_store.dart';
import 'package:sonoet/src/features/practice/domain/music_note.dart';
import 'package:sonoet/src/features/practice/domain/practice_clef.dart';
import 'package:sonoet/src/features/practice/domain/practice_exercise.dart';
import 'package:sonoet/src/features/practice/domain/practice_key_signature.dart';
import 'package:sonoet/src/features/practice/domain/practice_language.dart';
import 'package:sonoet/src/features/practice/domain/stave_background.dart';

void main() {
  group('PracticeSettingsStore', () {
    test('returns null when settings were never saved', () async {
      SharedPreferences.setMockInitialValues({});

      final settings = await PracticeSettingsStore().load();

      expect(settings, isNull);
    });

    test('saves and loads practice settings', () async {
      SharedPreferences.setMockInitialValues({});
      const savedSettings = StoredPracticeSettings(
        detectedOctaveShift: -1,
        lowestNote: MusicNote.d4,
        highestNote: MusicNote.c5,
        clef: PracticeClef.bass,
        beatsPerMeasure: 6,
        measuresPerPage: 4,
        language: PracticeLanguage.french,
        staveBackground: StaveBackground.white,
        allowedKeySignatures: {
          PracticeKeySignature.gMajor,
          PracticeKeySignature.dMajor,
        },
        keySignature: PracticeKeySignature.dMajor,
        allowAccidentals: false,
        practiceSource: PracticeSource.scaleExercise,
        scaleExerciseId: 'd_major_scale',
      );

      final store = PracticeSettingsStore();
      await store.save(savedSettings);
      final loadedSettings = await store.load();

      expect(loadedSettings, isNotNull);
      expect(loadedSettings!.detectedOctaveShift,
          savedSettings.detectedOctaveShift);
      expect(loadedSettings.lowestNote.midi, savedSettings.lowestNote.midi);
      expect(loadedSettings.highestNote.midi, savedSettings.highestNote.midi);
      expect(loadedSettings.clef, savedSettings.clef);
      expect(loadedSettings.beatsPerMeasure, savedSettings.beatsPerMeasure);
      expect(loadedSettings.measuresPerPage, savedSettings.measuresPerPage);
      expect(loadedSettings.language, savedSettings.language);
      expect(loadedSettings.staveBackground, savedSettings.staveBackground);
      expect(
        loadedSettings.allowedKeySignatures,
        savedSettings.allowedKeySignatures,
      );
      expect(loadedSettings.keySignature, savedSettings.keySignature);
      expect(loadedSettings.allowAccidentals, savedSettings.allowAccidentals);
      expect(loadedSettings.practiceSource, savedSettings.practiceSource);
      expect(loadedSettings.scaleExerciseId, savedSettings.scaleExerciseId);
    });
  });
}
