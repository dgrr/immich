import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/entities/asset.entity.dart';

enum AssetSyncStatus {
  backedUp,    // Remote or merged - exists on server
  localOnly,   // Only on device, not uploaded
  remoteOnly,  // Only on server, not downloaded
}

AssetSyncStatus getAssetSyncStatus(Asset asset) {
  switch (asset.storage) {
    case AssetState.merged:
      return AssetSyncStatus.backedUp;
    case AssetState.local:
      return AssetSyncStatus.localOnly;
    case AssetState.remote:
      return AssetSyncStatus.remoteOnly;
  }
}

final assetSyncStatusProvider = Provider.family<AssetSyncStatus, Asset>((ref, asset) {
  return getAssetSyncStatus(asset);
});
