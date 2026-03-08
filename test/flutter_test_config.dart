import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final roboto = FontLoader('Roboto');
  roboto.addFont(_loadMaterialFont('Roboto-Regular.ttf'));
  await roboto.load();

  await testMain();
}

Future<ByteData> _loadMaterialFont(String fontName) async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null || flutterRoot.isEmpty) {
    throw Exception('FLUTTER_ROOT is not set. Cannot load test font.');
  }

  final fontPath = [
    flutterRoot,
    'bin',
    'cache',
    'artifacts',
    'material_fonts',
    fontName,
  ].join(Platform.pathSeparator);

  final bytes = await File(fontPath).readAsBytes();
  return ByteData.view(bytes.buffer);
}
