import 'package:new_version_plus/new_version_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Result of comparing the installed app version with the Play Store listing.
class AppUpdateStatus {
  final bool needsUpdate;
  final String localVersion;
  final String? storeVersion;

  const AppUpdateStatus({
    required this.needsUpdate,
    required this.localVersion,
    this.storeVersion,
  });
}

/// Checks whether a newer version is available on Google Play.
abstract final class AppUpdateService {
  static const androidPackageId = 'com.brainora.kniferush';

  static Future<AppUpdateStatus> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final localVersion = packageInfo.version;

    try {
      final checker = NewVersionPlus(androidId: androidPackageId);
      final status = await checker.getVersionStatus();

      if (status == null) {
        return AppUpdateStatus(
          needsUpdate: false,
          localVersion: localVersion,
        );
      }

      return AppUpdateStatus(
        needsUpdate: status.canUpdate,
        localVersion: status.localVersion,
        storeVersion: status.storeVersion,
      );
    } catch (_) {
      // If Play Store cannot be reached, allow the app to continue.
      return AppUpdateStatus(
        needsUpdate: false,
        localVersion: localVersion,
      );
    }
  }
}
