import 'detected_pitch.dart';

abstract interface class PitchSource {
  Stream<DetectedPitch> start();

  Future<void> stop();
}
