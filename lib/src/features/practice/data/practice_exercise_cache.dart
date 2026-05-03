import 'package:shared_preferences/shared_preferences.dart';

class PracticeExerciseCache {
  const PracticeExerciseCache();

  static const _exerciseSourceKey = 'practice.exercises.cache.source';

  Future<String?> load() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getString(_exerciseSourceKey);
  }

  Future<void> save(String source) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_exerciseSourceKey, source);
  }
}
