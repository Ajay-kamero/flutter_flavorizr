import 'package:json_annotation/json_annotation.dart';

mixin BuildSettingsMixin {
  static final Map<String, dynamic> iosDefaultBuildSettings = {
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon-\$(ASSET_PREFIX)",
    "LD_RUNPATH_SEARCH_PATHS": "\$(inherited) @executable_path/Frameworks",
    "SWIFT_OBJC_BRIDGING_HEADER": "Runner/Runner-Bridging-Header.h",
    "SWIFT_VERSION": "5.0",
    "FRAMEWORK_SEARCH_PATHS": ['\$(inherited)', '\$(PROJECT_DIR)/Flutter'],
    "LIBRARY_SEARCH_PATHS": ['\$(inherited)', '\$(PROJECT_DIR)/Flutter'],
    "INFOPLIST_FILE": "Runner/Info.plist",
    "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
    "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES": "YES",
    "SUPPORTED_PLATFORMS": "iphonesimulator iphoneos",
    "TARGETED_DEVICE_FAMILY": "1",
  };

  static final Map<String, dynamic> macosDefaultBuildSettings = {
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon-\$(ASSET_PREFIX)",
    "LD_RUNPATH_SEARCH_PATHS": "\$(inherited) @executable_path/../Frameworks",
    "SWIFT_VERSION": "5.0",
    "FRAMEWORK_SEARCH_PATHS": ['\$(inherited)', '\$(PROJECT_DIR)/Flutter'],
    "LIBRARY_SEARCH_PATHS": ['\$(inherited)', '\$(PROJECT_DIR)/Flutter'],
    "INFOPLIST_FILE": "Runner/Info.plist",
  };

  @JsonKey(defaultValue: {})
  late Map<String, dynamic> buildSettings;
}
