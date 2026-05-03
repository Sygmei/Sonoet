import 'dart:async';
import 'dart:typed_data';

import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:record/record.dart';

import '../domain/detected_pitch.dart';
import '../domain/pitch_source.dart';

class MicrophonePitchSource implements PitchSource {
  MicrophonePitchSource({
    AudioRecorder? recorder,
    int sampleRate = 44100,
    int bufferSize = 2048,
  })  : _recorder = recorder ?? AudioRecorder(),
        _sampleRate = sampleRate,
        _bufferSize = bufferSize,
        _detector = PitchDetector(
          audioSampleRate: sampleRate.toDouble(),
          bufferSize: bufferSize,
        );

  final AudioRecorder _recorder;
  final int _sampleRate;
  final int _bufferSize;
  final PitchDetector _detector;

  StreamController<DetectedPitch>? _controller;
  StreamSubscription<Uint8List>? _audioSubscription;
  bool _isStarting = false;
  bool _isAnalyzing = false;

  @override
  Stream<DetectedPitch> start() {
    final existingController = _controller;
    if (existingController != null && !existingController.isClosed) {
      return existingController.stream;
    }

    final controller = StreamController<DetectedPitch>.broadcast();
    _controller = controller;
    _startRecording(controller);
    return controller.stream;
  }

  Future<void> _startRecording(StreamController<DetectedPitch> controller) async {
    if (_isStarting) {
      return;
    }

    _isStarting = true;
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        controller.addError(MicrophonePermissionException());
        return;
      }

      final audioStream = await _recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
        ),
      );

      final frames = _Pcm16FrameAccumulator(
        frameBytes: _bufferSize * 2,
        hopBytes: _bufferSize,
      );

      _audioSubscription = audioStream.listen(
        (chunk) {
          for (final frame in frames.add(chunk)) {
            _detectPitch(frame, controller);
          }
        },
        onError: controller.addError,
        onDone: controller.close,
      );
    } catch (error, stackTrace) {
      controller.addError(error, stackTrace);
    } finally {
      _isStarting = false;
    }
  }

  Future<void> _detectPitch(
    Uint8List pcm16Frame,
    StreamController<DetectedPitch> controller,
  ) async {
    if (_isAnalyzing || controller.isClosed) {
      return;
    }

    _isAnalyzing = true;
    try {
      final result = await _detector.getPitchFromIntBuffer(pcm16Frame);
      if (!controller.isClosed) {
        controller.add(
          DetectedPitch(
            frequency: result.pitch,
            probability: result.probability,
            timestamp: DateTime.now(),
            pitched: result.pitched,
          ),
        );
      }
    } catch (error, stackTrace) {
      if (!controller.isClosed) {
        controller.addError(error, stackTrace);
      }
    } finally {
      _isAnalyzing = false;
    }
  }

  @override
  Future<void> stop() async {
    await _audioSubscription?.cancel();
    _audioSubscription = null;

    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }

    await _controller?.close();
    _controller = null;
  }

  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
  }
}

class MicrophonePermissionException implements Exception {
  @override
  String toString() => 'Microphone permission is required.';
}

class _Pcm16FrameAccumulator {
  _Pcm16FrameAccumulator({
    required this.frameBytes,
    required this.hopBytes,
  });

  final int frameBytes;
  final int hopBytes;
  final List<int> _buffer = <int>[];

  Iterable<Uint8List> add(Uint8List chunk) sync* {
    _buffer.addAll(chunk);

    while (_buffer.length >= frameBytes) {
      yield Uint8List.fromList(_buffer.take(frameBytes).toList(growable: false));
      final removeCount = hopBytes < _buffer.length ? hopBytes : _buffer.length;
      _buffer.removeRange(0, removeCount);
    }
  }
}
