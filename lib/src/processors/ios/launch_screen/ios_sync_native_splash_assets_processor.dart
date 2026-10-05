/*
 * Copyright (c) 2024 Angelo Cassano
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

import 'dart:io';

import 'package:flutter_flavorizr/src/parser/models/flavorizr.dart';
import 'package:flutter_flavorizr/src/processors/commons/abstract_processor.dart';
import 'package:flutter_flavorizr/src/utils/constants.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:yaml/yaml.dart';

/// Syncs `flutter_native_splash` iOS output into flavorizr's launch assets.
///
/// FNS writes `LaunchImage{Flavor}` / `LaunchScreen{Flavor}`; flavorizr's
/// Info.plist uses `{flavor}LaunchScreen` → `{flavor}LaunchImage`. Without
/// this sync, iOS shows the black dummy 1×1 launch image.
class IOSSyncNativeSplashAssetsProcessor extends AbstractProcessor<void> {
  final String flavorName;
  final String? splashYamlPath;

  const IOSSyncNativeSplashAssetsProcessor(
    this.flavorName, {
    this.splashYamlPath,
    required Flavorizr config,
    required Logger logger,
  }) : super(config, logger: logger);

  @override
  void execute() {
    final source = _resolveFnsLaunchImageImageset();
    if (source == null) {
      logger.warn(
        '[$IOSSyncNativeSplashAssetsProcessor] No flutter_native_splash '
        'LaunchImage* imageset found for flavor "$flavorName"; '
        'keeping flavorizr dummy launch image',
      );
      return;
    }

    final destination = Directory(
      '${K.iOSAssetsPath}/${flavorName}LaunchImage.imageset',
    );

    logger.detail(
      '[$IOSSyncNativeSplashAssetsProcessor] Syncing ${source.path} → ${destination.path}',
    );

    _replaceImageset(source, destination);
    _updateLaunchStoryboardBackground();

    logger.detail(
      '[$IOSSyncNativeSplashAssetsProcessor] Synced launch image for $flavorName',
      style: logger.theme.success,
    );
  }

  /// FNS uses `capitalize()` = first upper + rest lower; also try raw flavor.
  Directory? _resolveFnsLaunchImageImageset() {
    final candidates = <String>{
      'LaunchImage$flavorName',
      'LaunchImage${_fnsCapitalize(flavorName)}',
      if (flavorName.isNotEmpty)
        'LaunchImage${flavorName[0].toUpperCase()}${flavorName.substring(1)}',
    };

    for (final name in candidates) {
      final dir = Directory('${K.iOSAssetsPath}/$name.imageset');
      if (dir.existsSync()) {
        return dir;
      }
    }
    return null;
  }

  static String _fnsCapitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }

  void _replaceImageset(Directory source, Directory destination) {
    if (destination.existsSync()) {
      destination.deleteSync(recursive: true);
    }
    destination.createSync(recursive: true);

    for (final entity in source.listSync(recursive: false)) {
      if (entity is! File) continue;
      final fileName = entity.uri.pathSegments.last;
      entity.copySync('${destination.path}/$fileName');
    }
  }

  void _updateLaunchStoryboardBackground() {
    final storyboardPath =
        '${K.iOSRunnerPath}/${flavorName}LaunchScreen.storyboard';
    final storyboardFile = File(storyboardPath);
    if (!storyboardFile.existsSync()) {
      logger.warn(
        '[$IOSSyncNativeSplashAssetsProcessor] Missing $storyboardPath; '
        'skipped background color update',
      );
      return;
    }

    final color = _readSplashBackgroundColor();
    if (color == null) return;

    final (r, g, b) = color;
    var content = storyboardFile.readAsStringSync();

    // Replace the solid black/white backgroundColor on the launch view.
    final colorPattern = RegExp(
      r'<color key="backgroundColor"[^/]*/>',
    );
    final replacement =
        '<color key="backgroundColor" red="${r.toStringAsFixed(3)}" '
        'green="${g.toStringAsFixed(3)}" blue="${b.toStringAsFixed(3)}" '
        'alpha="1" colorSpace="custom" customColorSpace="sRGB"/>';

    if (!colorPattern.hasMatch(content)) {
      logger.warn(
        '[$IOSSyncNativeSplashAssetsProcessor] No backgroundColor in '
        '$storyboardPath; skipped color update',
      );
      return;
    }

    content = content.replaceFirst(colorPattern, replacement);
    storyboardFile.writeAsStringSync(content);
  }

  /// Reads `color_ios` then `color` from the splash yaml as 0–1 RGB.
  (double, double, double)? _readSplashBackgroundColor() {
    final path = splashYamlPath ??
        'yamls/flutter_native_splash-$flavorName.yaml';
    final file = File(path);
    if (!file.existsSync()) return null;

    try {
      final yaml = loadYaml(file.readAsStringSync());
      if (yaml is! YamlMap) return null;

      // flutter_native_splash yaml is usually nested under flutter_native_splash:
      final root = yaml['flutter_native_splash'] is YamlMap
          ? yaml['flutter_native_splash'] as YamlMap
          : yaml;

      final raw = root['color_ios'] ?? root['color'];
      if (raw is! String) return null;

      return _parseHexColor(raw);
    } catch (e) {
      logger.warn(
        '[$IOSSyncNativeSplashAssetsProcessor] Failed to parse $path: $e',
      );
      return null;
    }
  }

  static (double, double, double)? _parseHexColor(String raw) {
    var hex = raw.trim();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 3) {
      hex = hex.split('').map((c) => '$c$c').join();
    }
    if (hex.length != 6) return null;

    final value = int.tryParse(hex, radix: 16);
    if (value == null) return null;

    final r = ((value >> 16) & 0xFF) / 255.0;
    final g = ((value >> 8) & 0xFF) / 255.0;
    final b = (value & 0xFF) / 255.0;
    return (r, g, b);
  }

  @override
  String toString() => 'IOSSyncNativeSplashAssetsProcessor';
}
