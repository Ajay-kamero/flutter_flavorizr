/*
 * Copyright (c) 2024 Angelo Cassano
 */

import 'package:dart_xcodeproj/dart_xcodeproj.dart';
import 'package:flutter_flavorizr/src/parser/models/flavorizr.dart';
import 'package:flutter_flavorizr/src/processors/ios/build_configuration/ios_normalize_build_settings_processor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:io/io.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../../test_utils.dart';

void main() {
  late Flavorizr flavorizr;
  late Logger logger;

  const exampleProjectPath = 'example/ios/Runner.xcodeproj';

  setUp(() {
    logger = TestUtils.quietLogger();
    flavorizr = TestUtils.parseFlavorizr('test_resources/pubspec');
  });

  test(
      'IOSNormalizeBuildSettingsProcessor updates Runner base Debug and project Debug',
      () async {
    await TestUtils.withTempDir((dir) async {
      final projectPath = '${dir.path}/Runner.xcodeproj';
      copyPathSync(exampleProjectPath, projectPath);

      final project = await XcodeProject.open(projectPath);
      final runner = project.targets.first as PBXNativeTarget;
      final runnerDebug = runner.buildConfigurationList!['Debug']!;
      runnerDebug.buildSettings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0';
      runnerDebug.buildSettings['TARGETED_DEVICE_FAMILY'] = '1,2';
      await project.save();

      await IOSNormalizeBuildSettingsProcessor(
        projectPath,
        flavorizr,
        logger: logger,
      ).execute();

      final reopened = await XcodeProject.open(projectPath);
      final normalizedRunner =
          (reopened.targets.first as PBXNativeTarget).buildConfigurationList![
              'Debug']!;
      final normalizedProject = reopened.buildConfigurations
          .firstWhere((c) => c.name == 'Debug');

      expect(normalizedRunner.buildSettings['IPHONEOS_DEPLOYMENT_TARGET'],
          '16.0');
      expect(normalizedRunner.buildSettings['TARGETED_DEVICE_FAMILY'], '1');
      expect(normalizedProject.buildSettings['TARGETED_DEVICE_FAMILY'], '1');
      expect(
        normalizedRunner
            .buildSettings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'],
        'YES',
      );
    });
  });
}
