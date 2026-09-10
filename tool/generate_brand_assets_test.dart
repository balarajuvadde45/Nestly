import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Reuses Nestly's existing Material storefront mark for native launcher artwork.
void main() {
  test('generate launcher assets', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final font = FontLoader('MaterialIcons');
    font.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await font.load();
    Future<void> render(String path, int size) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(const Color(0xFF7C6AF7), BlendMode.src);
      final painter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.home_work_rounded.codePoint),
          style: TextStyle(
            fontFamily: 'MaterialIcons',
            fontSize: size * 0.55,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset((size - painter.width) / 2, (size - painter.height) / 2),
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(size, size);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
      painter.dispose();
    }

    await render('assets/brand/app-icon.png', 1024);
    const densities = {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };
    for (final entry in densities.entries) {
      await render(
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
        entry.value,
      );
    }
    final contents =
        jsonDecode(
              await File(
                'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',
              ).readAsString(),
            )
            as Map;
    for (final entry in contents['images'] as List) {
      final size = double.parse((entry['size'] as String).split('x').first);
      final scale = double.parse(
        (entry['scale'] as String).replaceAll('x', ''),
      );
      await render(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/${entry['filename']}',
        (size * scale).round(),
      );
    }
    for (final size in [192, 512]) {
      await render('web/icons/Icon-$size.png', size);
      await render('web/icons/Icon-maskable-$size.png', size);
    }
    await render('web/favicon.png', 32);
  });
}
