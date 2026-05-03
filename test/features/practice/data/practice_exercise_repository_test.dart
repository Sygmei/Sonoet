import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonoet/src/features/practice/data/practice_exercise_cache.dart';
import 'package:sonoet/src/features/practice/data/practice_exercise_repository.dart';
import 'package:sonoet/src/features/practice/domain/practice_key_signature.dart';

void main() {
  group('PracticeExerciseRepository', () {
    test('loads exercises from the remote repository index', () async {
      SharedPreferences.setMockInitialValues({});
      final requestedPaths = <String>[];
      final repository = PracticeExerciseRepository(
        remoteIndexUri: Uri.parse(
          'https://example.test/assets/exercises/index.json',
        ),
        httpClient: MockClient((request) async {
          requestedPaths.add(request.url.path);

          return switch (request.url.path) {
            '/assets/exercises/index.json' => http.Response(
                '{"exercises":["c_major_scale.json","d_major_scale.json"]}',
                200,
              ),
            '/assets/exercises/c_major_scale.json' => http.Response(
                _cMajorExerciseSource,
                200,
              ),
            '/assets/exercises/d_major_scale.json' => http.Response(
                _dMajorExerciseSource,
                200,
              ),
            _ => http.Response('', 404),
          };
        }),
      );

      final exercises = await repository.loadExercises();

      expect(
        requestedPaths,
        [
          '/assets/exercises/index.json',
          '/assets/exercises/c_major_scale.json',
          '/assets/exercises/d_major_scale.json',
        ],
      );
      expect(exercises.map((exercise) => exercise.id), [
        'c_major_scale',
        'd_major_scale',
      ]);
      expect(exercises.last.keySignature, PracticeKeySignature.dMajor);
    });

    test('caches remote exercises and reuses them when remote loading fails',
        () async {
      SharedPreferences.setMockInitialValues({});
      final cache = const PracticeExerciseCache();
      final firstRepository = PracticeExerciseRepository(
        remoteIndexUri: Uri.parse(
          'https://example.test/assets/exercises/index.json',
        ),
        cache: cache,
        httpClient: MockClient((request) async {
          return switch (request.url.path) {
            '/assets/exercises/index.json' => http.Response(
                '{"exercises":["c_major_scale.json"]}',
                200,
              ),
            '/assets/exercises/c_major_scale.json' => http.Response(
                _cMajorExerciseSource,
                200,
              ),
            _ => http.Response('', 404),
          };
        }),
      );

      await firstRepository.loadExercises();

      final secondRepository = PracticeExerciseRepository(
        remoteIndexUri: Uri.parse(
          'https://example.test/assets/exercises/index.json',
        ),
        cache: cache,
        httpClient: MockClient((request) async => http.Response('', 500)),
      );

      final exercises = await secondRepository.loadExercises();

      expect(exercises, hasLength(1));
      expect(exercises.single.id, 'c_major_scale');
    });
  });
}

const _cMajorExerciseSource = '''
{
  "id": "c_major_scale",
  "category": "scales",
  "name": "C major",
  "difficulty": "beginner",
  "labels": ["scale", "major"],
  "keySignature": "cMajor",
  "clef": "treble",
  "measuresPerPage": 4,
  "beatsPerMeasure": 4,
  "notes": ["C4", "D4", "E4", "F4"]
}
''';

const _dMajorExerciseSource = '''
{
  "id": "d_major_scale",
  "category": "scales",
  "name": "D major",
  "difficulty": "beginner",
  "labels": ["scale", "major", "sharp"],
  "keySignature": "dMajor",
  "clef": "treble",
  "measuresPerPage": 4,
  "beatsPerMeasure": 4,
  "notes": ["D4", "E4", "F#4", "G4"]
}
''';
