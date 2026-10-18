import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/design.dart';
import '../domain/models.dart';

class EvidencePreview extends StatelessWidget {
  const EvidencePreview({
    super.key,
    required this.evidence,
    this.selectedLineId,
  });
  final Evidence evidence;
  final String? selectedLineId;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Stack(
      children: [
        Image.file(
          File(evidence.imagePath),
          width: double.infinity,
          fit: BoxFit.fitWidth,
          semanticLabel: 'Original source image for ${evidence.title}',
          errorBuilder: (context, error, stack) => const AspectRatio(
            aspectRatio: 0.82,
            child: ColoredBox(
              color: Palette.mint,
              child: Center(
                child: Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: Palette.ink,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _Regions(evidence.lines, selectedLineId),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Regions extends CustomPainter {
  const _Regions(this.lines, this.selected);
  final List<EvidenceLine> lines;
  final String? selected;
  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      if (selected != null && line.id != selected) continue;
      final box = line.region;
      final rect = Rect.fromLTWH(
        box.x * size.width,
        box.y * size.height,
        box.width * size.width,
        box.height * size.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = Palette.accent.withValues(alpha: 0.12),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()
          ..color = Palette.accent
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_Regions oldDelegate) =>
      lines != oldDelegate.lines || selected != oldDelegate.selected;
}
