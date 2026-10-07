/// Kamero fork: iOS build settings applied to every Runner-related Xcode
/// configuration so manual Xcode edits are not required after flavorizr runs.
class IosForkBuildSettings {
  static const List<String> normalizedKeys = [
    'IPHONEOS_DEPLOYMENT_TARGET',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES',
    'SUPPORTED_PLATFORMS',
    'TARGETED_DEVICE_FAMILY',
  ];

  static const Map<String, dynamic> values = {
    'IPHONEOS_DEPLOYMENT_TARGET': '16.0',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES': 'YES',
    'SUPPORTED_PLATFORMS': 'iphoneos',
    'TARGETED_DEVICE_FAMILY': '1',
  };

  static final RegExp runnerConfigurationName = RegExp(
    r'^(Debug|Profile|Release)(-.+)?$',
  );

  static bool shouldNormalize(String configurationName) =>
      runnerConfigurationName.hasMatch(configurationName);

  static Map<String, dynamic> mergeInto(Map<String, dynamic> existing) => {
        ...existing,
        ...values,
      };
}
