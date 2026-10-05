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
import 'package:flutter_flavorizr/src/processors/ios/launch_screen/ios_sync_native_splash_assets_processor.dart';
import 'package:flutter_flavorizr/src/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import '../../../test_utils.dart';

void main() {
  late Flavorizr flavorizr;
  late Logger logger;

  setUp(() {
    logger = TestUtils.quietLogger();
    flavorizr = TestUtils.parseFlavorizr('test_resources/pubspec');
  });

  test(
    'IOSSyncNativeSplashAssetsProcessor copies FNS LaunchImage{Flavor} into {flavor}LaunchImage',
    () {
      TestUtils.withTempDir((dir) {
        final previous = Directory.current;
        try {
          Directory.current = dir;

          const flavor = 'apple';
          final assets = Directory(K.iOSAssetsPath)..createSync(recursive: true);
          final runner = Directory(K.iOSRunnerPath)..createSync(recursive: true);

          // flutter_native_splash output (capitalized flavor suffix)
          final fnsImageset = Directory(
            p.join(assets.path, 'LaunchImageApple.imageset'),
          )..createSync(recursive: true);
          File(p.join(fnsImageset.path, 'LaunchImage.png'))
              .writeAsBytesSync(List<int>.filled(200, 7));
          File(p.join(fnsImageset.path, 'LaunchImage@2x.png'))
              .writeAsBytesSync(List<int>.filled(400, 8));
          File(p.join(fnsImageset.path, 'Contents.json'))
              .writeAsStringSync('{}');

          // flavorizr dummy destination + storyboard
          final flavorImageset = Directory(
            p.join(assets.path, '${flavor}LaunchImage.imageset'),
          )..createSync(recursive: true);
          File(p.join(flavorImageset.path, 'LaunchImage.png'))
              .writeAsBytesSync(List<int>.filled(68, 0));

          File(p.join(runner.path, '${flavor}LaunchScreen.storyboard'))
              .writeAsStringSync('''
<document>
  <view>
    <color key="backgroundColor" white="0.0" alpha="1" colorSpace="custom" customColorSpace="genericGamma22GrayColorSpace"/>
    <imageView image="${flavor}LaunchImage"/>
  </view>
</document>
''');

          final yamlDir = Directory('yamls')..createSync();
          File(p.join(yamlDir.path, 'flutter_native_splash-$flavor.yaml'))
              .writeAsStringSync('''
flutter_native_splash:
  color: "#112233"
  image: assets/logo.png
''');

          IOSSyncNativeSplashAssetsProcessor(
            flavor,
            splashYamlPath: 'yamls/flutter_native_splash-$flavor.yaml',
            config: flavorizr,
            logger: logger,
          ).execute();

          final synced = File(
            p.join(
              assets.path,
              '${flavor}LaunchImage.imageset',
              'LaunchImage.png',
            ),
          );
          expect(synced.existsSync(), isTrue);
          expect(synced.lengthSync(), 200);

          final storyboard = File(
            p.join(runner.path, '${flavor}LaunchScreen.storyboard'),
          ).readAsStringSync();
          expect(storyboard, contains('red="0.067"'));
          expect(storyboard, contains('green="0.133"'));
          expect(storyboard, contains('blue="0.200"'));
          expect(storyboard, isNot(contains('white="0.0"')));
        } finally {
          Directory.current = previous;
        }
      });
    },
  );

  test(
    'IOSSyncNativeSplashAssetsProcessor resolves raw flavor suffix LaunchImage{flavor}',
    () {
      TestUtils.withTempDir((dir) {
        final previous = Directory.current;
        try {
          Directory.current = dir;

          const flavor = 'bobbyDePhotography_w85';
          final assets = Directory(K.iOSAssetsPath)..createSync(recursive: true);

          final fnsImageset = Directory(
            p.join(assets.path, 'LaunchImage$flavor.imageset'),
          )..createSync(recursive: true);
          File(p.join(fnsImageset.path, 'LaunchImage.png'))
              .writeAsBytesSync(List<int>.filled(500, 1));

          Directory(p.join(assets.path, '${flavor}LaunchImage.imageset'))
              .createSync(recursive: true);

          IOSSyncNativeSplashAssetsProcessor(
            flavor,
            config: flavorizr,
            logger: logger,
          ).execute();

          expect(
            File(
              p.join(
                assets.path,
                '${flavor}LaunchImage.imageset',
                'LaunchImage.png',
              ),
            ).lengthSync(),
            500,
          );
        } finally {
          Directory.current = previous;
        }
      });
    },
  );

  test(
    'IOSSyncNativeSplashAssetsProcessor no-ops when FNS imageset is missing',
    () {
      TestUtils.withTempDir((dir) {
        final previous = Directory.current;
        try {
          Directory.current = dir;

          const flavor = 'banana';
          final assets = Directory(K.iOSAssetsPath)..createSync(recursive: true);
          final flavorImageset = Directory(
            p.join(assets.path, '${flavor}LaunchImage.imageset'),
          )..createSync(recursive: true);
          File(p.join(flavorImageset.path, 'LaunchImage.png'))
              .writeAsBytesSync(List<int>.filled(68, 0));

          IOSSyncNativeSplashAssetsProcessor(
            flavor,
            config: flavorizr,
            logger: logger,
          ).execute();

          expect(
            File(p.join(flavorImageset.path, 'LaunchImage.png')).lengthSync(),
            68,
          );
        } finally {
          Directory.current = previous;
        }
      });
    },
  );
}
