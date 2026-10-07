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

import 'package:dart_xcodeproj/dart_xcodeproj.dart';
import 'package:flutter_flavorizr/src/parser/models/flavorizr.dart';
import 'package:flutter_flavorizr/src/processors/commons/abstract_processor.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:flutter_flavorizr/src/processors/ios/build_configuration/ios_fork_build_settings.dart';
/// Ensures [IosForkBuildSettings] are written on the PBXProject configs and on
/// the Runner app target configs (including base Debug/Release/Profile).
class IOSNormalizeBuildSettingsProcessor extends AbstractProcessor<void> {
  final String projectPath;

  const IOSNormalizeBuildSettingsProcessor(
    this.projectPath,
    Flavorizr config, {
    required Logger logger,
  }) : super(config, logger: logger);

  @override
  Future<void> execute() async {
    final project = await XcodeProject.open(projectPath);
    var updated = 0;

    for (final config in project.buildConfigurationList.buildConfigurations) {
      final name = config.name;
      if (name == null || !IosForkBuildSettings.shouldNormalize(name)) {
        continue;
      }
      config.buildSettings =
          IosForkBuildSettings.mergeInto(config.buildSettings);
      updated++;
    }

    final runner = project.targets
        .whereType<PBXNativeTarget>()
        .cast<PBXNativeTarget>()
        .where((t) => t.name == 'Runner')
        .firstOrNull;
    if (runner != null) {
      for (final config in runner.buildConfigurationList!.buildConfigurations) {
        final name = config.name;
        if (name == null || !IosForkBuildSettings.shouldNormalize(name)) {
          continue;
        }
        config.buildSettings =
            IosForkBuildSettings.mergeInto(config.buildSettings);
        updated++;
      }
    }

    if (updated > 0) {
      await project.save();
      logger.detail('Normalized iOS build settings on $updated configurations');
    }
  }

  @override
  String toString() => 'IOSNormalizeBuildSettingsProcessor';
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
