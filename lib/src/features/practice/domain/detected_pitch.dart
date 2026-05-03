class DetectedPitch {
  const DetectedPitch({
    required this.frequency,
    required this.probability,
    required this.timestamp,
    required this.pitched,
  });

  final double frequency;
  final double probability;
  final DateTime timestamp;
  final bool pitched;

  bool get isPitched => pitched && frequency.isFinite && frequency > 0;
}
