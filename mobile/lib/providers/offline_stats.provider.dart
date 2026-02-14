import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/entities/asset.entity.dart';
import 'package:immich_mobile/providers/db.provider.dart';
import 'package:isar/isar.dart';

class OfflineStats {
  final int totalAssets;
  final int localOnly;
  final int remoteOnly;
  final int backedUp; // merged

  const OfflineStats({
    this.totalAssets = 0,
    this.localOnly = 0,
    this.remoteOnly = 0,
    this.backedUp = 0,
  });

  int get pendingUpload => localOnly;
  
  double get backupPercentage {
    if (totalAssets == 0) return 100.0;
    return (backedUp / (localOnly + backedUp)) * 100;
  }
}

final offlineStatsProvider = FutureProvider<OfflineStats>((ref) async {
  final db = ref.watch(dbProvider);

  final localOnly = await db.assets
      .filter()
      .localIdIsNotNull()
      .remoteIdIsNull()
      .count();

  final remoteOnly = await db.assets
      .filter()
      .remoteIdIsNotNull()
      .localIdIsNull()
      .count();

  final merged = await db.assets
      .filter()
      .localIdIsNotNull()
      .remoteIdIsNotNull()
      .count();

  return OfflineStats(
    totalAssets: localOnly + remoteOnly + merged,
    localOnly: localOnly,
    remoteOnly: remoteOnly,
    backedUp: merged,
  );
});
