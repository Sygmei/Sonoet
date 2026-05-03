import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/music_note.dart';
import '../../domain/practice_clef.dart';
import '../../domain/practice_key_signature.dart';
import '../practice_controller.dart';

class StaffPainter extends CustomPainter {
  StaffPainter({
    required this.notes,
    required this.currentIndex,
    required this.playedNote,
    required this.clef,
    required this.keySignature,
    required this.beatsPerMeasure,
    required this.noteTimings,
    required this.now,
    required this.colorScheme,
  });

  final List<MusicNote> notes;
  final int currentIndex;
  final MusicNote? playedNote;
  final PracticeClef clef;
  final PracticeKeySignature keySignature;
  final int beatsPerMeasure;
  final List<NoteTimingResult?> noteTimings;
  final DateTime now;
  final ColorScheme colorScheme;

  static const _lineCount = 5;
  static const _defaultStaffLineSpacing = 16.0;
  static const _minimumStaffLineSpacing = 12.0;
  static const _noteWidthRatio = 1.26;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF2F2A24)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final staffLayout = _StaffLayout.fixed(size);
    final topLineY = staffLayout.topLineY;
    final bottomLineY = staffLayout.bottomLineY;
    final lineSpacing = staffLayout.lineSpacing;
    const staffLeft = 18.0;
    const staffRightPadding = 18.0;
    final keySignatureWidth = keySignature.accidentalCount.abs() * 13.0;
    final notesLeft = math.max(
      staffLeft + 82 + keySignatureWidth,
      size.width * 0.18,
    );
    final right = size.width - staffRightPadding;

    _drawClefLabel(
      canvas,
      Offset(staffLeft + 30, bottomLineY - lineSpacing * 2),
    );
    _drawKeySignature(
      canvas,
      staffLeft + 62,
      bottomLineY,
      lineSpacing,
    );

    for (var i = 0; i < _lineCount; i++) {
      final y = topLineY + i * lineSpacing;
      canvas.drawLine(Offset(staffLeft, y), Offset(right, y), linePaint);
    }

    _drawBarLines(
      canvas,
      notesLeft,
      right,
      topLineY,
      bottomLineY,
      linePaint,
    );

    if (notes.isEmpty) {
      return;
    }

    final spacing = (right - notesLeft) / notes.length;
    for (var index = 0; index < notes.length; index++) {
      final note = notes[index];
      final spelling = keySignature.spell(note);
      final x = notesLeft + spacing * (index + 0.5);
      final y = _noteY(spelling.staffNote, bottomLineY, lineSpacing);
      final status = _NoteStatus.from(index, currentIndex);

      if (status == _NoteStatus.current) {
        _drawCurrentHalo(canvas, Offset(x, y));
      }

      _drawTimingScore(canvas, index, Offset(x, y));
      _drawAccidental(canvas, Offset(x - 22, y), spelling.accidental);
      _drawLedgerLines(
        canvas,
        Offset(x, y),
        topLineY,
        bottomLineY,
        lineSpacing,
        linePaint,
      );
      _drawNoteHead(canvas, Offset(x, y), status, lineSpacing);
      _drawStem(canvas, Offset(x, y), status, lineSpacing);
    }

    final played = playedNote;
    if (played != null && currentIndex < notes.length) {
      final spelling = keySignature.spell(played);
      final x = notesLeft + spacing * (currentIndex + 0.5);
      final y = _noteY(spelling.staffNote, bottomLineY, lineSpacing);
      final isCorrect = played.midi == notes[currentIndex].midi;

      _drawAccidental(canvas, Offset(x - 24, y), spelling.accidental);
      _drawLedgerLines(
        canvas,
        Offset(x, y),
        topLineY,
        bottomLineY,
        lineSpacing,
        linePaint,
      );
      _drawPlayedNote(
        canvas,
        Offset(x, y),
        isCorrect: isCorrect,
        lineSpacing: lineSpacing,
      );
    }
  }

  double _noteY(MusicNote note, double bottomLineY, double lineSpacing) {
    final stepsAboveE4 = note.diatonicIndex - clef.bottomLineDiatonicIndex;
    return bottomLineY - stepsAboveE4 * (lineSpacing / 2);
  }

  void _drawClefLabel(Canvas canvas, Offset center) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: clef.symbol,
        style: TextStyle(
          color: const Color(0xFF2F2A24),
          fontSize: clef.symbolSize,
          fontFamilyFallback: const [
            'Noto Music',
            'Noto Sans Music',
            'Noto Sans Symbols 2',
            'Noto Sans Symbols',
            'Segoe UI Symbol',
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawCurrentHalo(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 25, paint);
  }

  void _drawLedgerLines(
    Canvas canvas,
    Offset center,
    double topLineY,
    double bottomLineY,
    double lineSpacing,
    Paint linePaint,
  ) {
    final ledgerPaint = Paint()
      ..color = linePaint.color
      ..strokeWidth = linePaint.strokeWidth
      ..strokeCap = StrokeCap.round;

    for (var y = bottomLineY + lineSpacing;
        y <= center.dy + 1;
        y += lineSpacing) {
      canvas.drawLine(
        Offset(center.dx - 18, y),
        Offset(center.dx + 18, y),
        ledgerPaint,
      );
    }

    for (var y = topLineY - lineSpacing;
        y >= center.dy - 1;
        y -= lineSpacing) {
      canvas.drawLine(
        Offset(center.dx - 18, y),
        Offset(center.dx + 18, y),
        ledgerPaint,
      );
    }
  }

  void _drawNoteHead(
    Canvas canvas,
    Offset center,
    _NoteStatus status,
    double lineSpacing,
  ) {
    final noteHeight = lineSpacing;
    final noteWidth = lineSpacing * _noteWidthRatio;
    final paint = Paint()
      ..color = switch (status) {
        _NoteStatus.completed => const Color(0xFF167A48),
        _NoteStatus.current => colorScheme.primary,
        _NoteStatus.upcoming => const Color(0xFF2F2A24),
      }
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.28);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: noteWidth,
        height: noteHeight,
      ),
      paint,
    );
    canvas.restore();
  }

  void _drawStem(
    Canvas canvas,
    Offset center,
    _NoteStatus status,
    double lineSpacing,
  ) {
    final noteWidth = lineSpacing * _noteWidthRatio;
    final paint = Paint()
      ..color = switch (status) {
        _NoteStatus.completed => const Color(0xFF167A48),
        _NoteStatus.current => colorScheme.primary,
        _NoteStatus.upcoming => const Color(0xFF2F2A24),
      }
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    final stemTop = center.dy - 44;
    canvas.drawLine(
      Offset(center.dx + noteWidth / 2 - 1, center.dy),
      Offset(center.dx + noteWidth / 2 - 1, stemTop),
      paint,
    );
  }

  void _drawPlayedNote(
    Canvas canvas,
    Offset center, {
    required bool isCorrect,
    required double lineSpacing,
  }) {
    final noteWidth = lineSpacing * _noteWidthRatio;
    final noteHeight = lineSpacing;
    final color = isCorrect ? const Color(0xFF167A48) : const Color(0xFFC8372D);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.28);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: noteWidth + 9,
        height: noteHeight + 7,
      ),
      paint,
    );
    canvas.restore();

    final indicatorPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(center.dx, center.dy + 25), 4.5, indicatorPaint);
  }

  @override
  bool shouldRepaint(covariant StaffPainter oldDelegate) {
    return notes != oldDelegate.notes ||
        currentIndex != oldDelegate.currentIndex ||
        playedNote?.midi != oldDelegate.playedNote?.midi ||
        clef != oldDelegate.clef ||
        keySignature != oldDelegate.keySignature ||
        beatsPerMeasure != oldDelegate.beatsPerMeasure ||
        noteTimings != oldDelegate.noteTimings ||
        now != oldDelegate.now ||
        colorScheme != oldDelegate.colorScheme;
  }

  void _drawTimingScore(Canvas canvas, int index, Offset noteCenter) {
    if (index >= noteTimings.length) {
      return;
    }

    final timing = noteTimings[index];
    if (timing == null) {
      return;
    }

    final age = now.difference(timing.completedAt);
    const visibleDuration = Duration(milliseconds: 1800);
    if (age >= visibleDuration) {
      return;
    }

    final progress = age.inMilliseconds / visibleDuration.inMilliseconds;
    final opacity = (1 - progress).clamp(0.0, 1.0);
    final yOffset = -34.0 - progress * 22.0;
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${timing.duration.inMilliseconds} ms',
        style: TextStyle(
          color: colorScheme.primary.withValues(alpha: opacity),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        noteCenter.dx - textPainter.width / 2,
        noteCenter.dy + yOffset,
      ),
    );
  }

  void _drawKeySignature(
    Canvas canvas,
    double startX,
    double bottomLineY,
    double lineSpacing,
  ) {
    final accidental = keySignature.usesSharps
        ? NoteAccidental.sharp
        : keySignature.usesFlats
            ? NoteAccidental.flat
            : NoteAccidental.none;
    if (accidental == NoteAccidental.none) {
      return;
    }

    for (var index = 0;
        index < keySignature.alteredNaturalPitchClasses.length;
        index++) {
      final pitchClass = keySignature.alteredNaturalPitchClasses[index];
      final note = _keySignatureNoteForPitchClass(pitchClass, accidental);
      final y = _noteY(note, bottomLineY, lineSpacing);
      _drawAccidental(
        canvas,
        Offset(startX + index * 13, y),
        accidental,
        fontSize: 19,
      );
    }
  }

  MusicNote _keySignatureNoteForPitchClass(
    int pitchClass,
    NoteAccidental accidental,
  ) {
    final pattern = accidental == NoteAccidental.sharp
        ? _sharpKeySignatureSteps
        : _flatKeySignatureSteps;
    final step = pattern[pitchClass] ?? 4;

    return _noteAtStaffStep(step);
  }

  MusicNote _noteAtStaffStep(int stepAboveBottomLine) {
    final targetDiatonicIndex =
        clef.bottomLineDiatonicIndex + stepAboveBottomLine;

    for (var midi = MusicNote.lowestPracticeNote.midi;
        midi <= MusicNote.highestPracticeNote.midi;
        midi++) {
      final note = MusicNote(midi);
      if (note.isNatural && note.diatonicIndex == targetDiatonicIndex) {
        return note;
      }
    }

    return clef.bottomLine;
  }

  void _drawAccidental(
    Canvas canvas,
    Offset center,
    NoteAccidental accidental, {
    double fontSize = 18,
  }) {
    if (accidental == NoteAccidental.none) {
      return;
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: accidental.symbol,
        style: TextStyle(
          color: const Color(0xFF2F2A24),
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final opticalYOffset = switch (accidental) {
      NoteAccidental.flat => -fontSize * 0.18,
      NoteAccidental.sharp => -fontSize * 0.04,
      NoteAccidental.natural => -fontSize * 0.08,
      NoteAccidental.none => 0.0,
    };

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2 + opticalYOffset,
      ),
    );
  }

  void _drawBarLines(
    Canvas canvas,
    double left,
    double right,
    double topLineY,
    double bottomLineY,
    Paint linePaint,
  ) {
    if (notes.isEmpty || beatsPerMeasure <= 0) {
      return;
    }

    final beatWidth = (right - left) / notes.length;
    for (var beat = beatsPerMeasure;
        beat <= notes.length;
        beat += beatsPerMeasure) {
      final x = left + beatWidth * beat;
      canvas.drawLine(Offset(x, topLineY), Offset(x, bottomLineY), linePaint);
    }
  }
}

class _StaffLayout {
  const _StaffLayout({
    required this.topLineY,
    required this.bottomLineY,
    required this.lineSpacing,
  });

  final double topLineY;
  final double bottomLineY;
  final double lineSpacing;

  static _StaffLayout fixed(Size size) {
    final lineSpacing = math
        .min(StaffPainter._defaultStaffLineSpacing, size.height * 0.11)
        .clamp(
          StaffPainter._minimumStaffLineSpacing,
          StaffPainter._defaultStaffLineSpacing,
        )
        .toDouble();
    final staffHeight = (StaffPainter._lineCount - 1) * lineSpacing;
    final topLineY = (size.height - staffHeight) / 2;
    final bottomLineY = topLineY + staffHeight;

    return _StaffLayout(
      topLineY: topLineY,
      bottomLineY: bottomLineY,
      lineSpacing: lineSpacing,
    );
  }
}

const _sharpKeySignatureSteps = <int, int>{
  5: 8, // F
  0: 5, // C
  7: 9, // G
  2: 6, // D
  9: 3, // A
  4: 7, // E
  11: 4, // B
};

const _flatKeySignatureSteps = <int, int>{
  11: 4, // B
  4: 7, // E
  9: 3, // A
  2: 6, // D
  7: 2, // G
  0: 5, // C
  5: 1, // F
};

enum _NoteStatus {
  completed,
  current,
  upcoming;

  static _NoteStatus from(int index, int currentIndex) {
    if (index < currentIndex) {
      return _NoteStatus.completed;
    }

    if (index == currentIndex) {
      return _NoteStatus.current;
    }

    return _NoteStatus.upcoming;
  }
}
