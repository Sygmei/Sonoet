import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'practice_exercise_cache.dart';
import '../domain/practice_exercise.dart';

class PracticeExerciseRepository {
  PracticeExerciseRepository({
    AssetBundle? assetBundle,
    http.Client? httpClient,
    PracticeExerciseCache? cache,
    this.indexPath = 'assets/exercises/index.json',
    Uri? remoteIndexUri,
  })  : _assetBundle = assetBundle,
        _httpClient = httpClient,
        _cache = cache ?? const PracticeExerciseCache(),
        remoteIndexUri = remoteIndexUri ?? Uri.parse(_defaultRemoteIndexUrl);

  static const _defaultRemoteIndexUrl =
      'https://raw.githubusercontent.com/Sygmei/Sonoet/main/'
      'assets/exercises/index.json';

  final AssetBundle? _assetBundle;
  final http.Client? _httpClient;
  final PracticeExerciseCache _cache;
  final String indexPath;
  final Uri remoteIndexUri;

  Future<List<PracticeExercise>> loadExercises() async {
    try {
      return await _loadRemoteExercises();
    } on Object {
      final cachedExercises = await _loadCachedExercises();
      if (cachedExercises != null) {
        return cachedExercises;
      }

      return _loadBundledExercises();
    }
  }

  Future<List<PracticeExercise>> _loadRemoteExercises() async {
    final client = _httpClient ?? http.Client();
    final closeClient = _httpClient == null;
    try {
      final indexResponse = await client.get(remoteIndexUri);
      if (indexResponse.statusCode < 200 || indexResponse.statusCode >= 300) {
        throw Exception(
          'Exercise index request failed with ${indexResponse.statusCode}.',
        );
      }

      final references = parsePracticeExerciseIndex(indexResponse.body);
      final exercises = await Future.wait(
        references.map((reference) async {
          final response = await client.get(remoteIndexUri.resolve(reference));
          if (response.statusCode < 200 || response.statusCode >= 300) {
            throw Exception(
              'Exercise request failed for "$reference" '
              'with ${response.statusCode}.',
            );
          }

          return parsePracticeExercise(response.body);
        }),
      );

      if (exercises.isEmpty) {
        return fallbackScaleExercises;
      }

      await _cache.save(jsonEncode(exercises.map((exercise) {
        return exercise.toJson();
      }).toList(growable: false)));

      return exercises;
    } finally {
      if (closeClient) {
        client.close();
      }
    }
  }

  Future<List<PracticeExercise>?> _loadCachedExercises() async {
    final source = await _cache.load();
    if (source == null) {
      return null;
    }

    try {
      final exercises = parsePracticeExercises(source);
      return exercises.isEmpty ? null : exercises;
    } on Object {
      return null;
    }
  }

  Future<List<PracticeExercise>> _loadBundledExercises() async {
    final bundle = _assetBundle ?? rootBundle;
    final source = await bundle.loadString(indexPath);
    final references = parsePracticeExerciseIndex(source);
    final exercises = await Future.wait(
      references.map((reference) async {
        final source = await bundle.loadString(_resolveAssetPath(reference));
        return parsePracticeExercise(source);
      }),
    );

    return exercises.isEmpty ? fallbackScaleExercises : exercises;
  }

  String _resolveAssetPath(String reference) {
    if (reference.startsWith('assets/')) {
      return reference;
    }

    final lastSeparator = indexPath.lastIndexOf('/');
    if (lastSeparator < 0) {
      return reference;
    }

    return '${indexPath.substring(0, lastSeparator + 1)}$reference';
  }
}
