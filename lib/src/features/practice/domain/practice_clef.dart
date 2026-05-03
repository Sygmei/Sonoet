import 'music_note.dart';
import 'practice_language.dart';

enum PracticeClef {
  treble(
    englishLabel: 'Treble clef',
    frenchLabel: 'Clef de Sol',
    symbol: '𝄞',
    symbolSize: 58,
    bottomLine: MusicNote.e4,
  ),
  bass(
    englishLabel: 'Bass clef',
    frenchLabel: 'Clef de Fa',
    symbol: '𝄢',
    symbolSize: 46,
    bottomLine: MusicNote.g2,
  ),
  alto(
    englishLabel: 'Alto clef',
    frenchLabel: "Clef d'Ut alto",
    symbol: '𝄡',
    symbolSize: 52,
    bottomLine: MusicNote.f3,
  ),
  tenor(
    englishLabel: 'Tenor clef',
    frenchLabel: "Clef d'Ut ténor",
    symbol: '𝄡',
    symbolSize: 52,
    bottomLine: MusicNote.d3,
  );

  const PracticeClef({
    required this.englishLabel,
    required this.frenchLabel,
    required this.symbol,
    required this.symbolSize,
    required this.bottomLine,
  });

  final String englishLabel;
  final String frenchLabel;
  final String symbol;
  final double symbolSize;
  final MusicNote bottomLine;

  int get bottomLineDiatonicIndex => bottomLine.diatonicIndex;

  String labelFor(PracticeLanguage language) {
    return switch (language) {
      PracticeLanguage.english => englishLabel,
      PracticeLanguage.french => frenchLabel,
    };
  }
}
