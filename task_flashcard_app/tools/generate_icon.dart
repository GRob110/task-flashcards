import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

void main() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = Size(1024, 1024);
  
  // Draw background
  final paint = Paint()
    ..color = const Color(0xFF4CAF50)
    ..style = PaintingStyle.fill;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(256),
    ),
    paint,
  );

  // Draw checkmark
  final checkPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 150
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  
  final path = Path()
    ..moveTo(size.width * 0.25, size.height * 0.5)
    ..lineTo(size.width * 0.45, size.height * 0.7)
    ..lineTo(size.width * 0.75, size.height * 0.3);
  
  canvas.drawPath(path, checkPaint);

  // Convert to image
  final picture = recorder.endRecording();
  final img = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final buffer = byteData!.buffer.asUint8List();

  // Save to file
  final directory = Directory('assets/icon');
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
  final file = File('assets/icon/icon.png');
  await file.writeAsBytes(buffer);
} 