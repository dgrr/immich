import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/enums.dart';
import 'package:immich_mobile/entities/asset.entity.dart';
import 'package:immich_mobile/providers/db.provider.dart';
import 'package:immich_mobile/providers/local_gallery.provider.dart';
import 'package:immich_mobile/providers/server_connectivity.provider.dart';
import 'package:immich_mobile/providers/user.provider.dart';
import 'package:immich_mobile/widgets/asset_grid/asset_grid_data_structure.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';

// Provider that creates a merged timeline from cached DB assets and local gallery
// Used when server is offline to show all available photos
final offlineTimelineProvider = StreamProvider<RenderList>((ref) async* {
  final log = Logger('OfflineTimelineProvider');
  final db = ref.watch(dbProvider);
  final currentUser = ref.watch(currentUserProvider);
  final isOffline = ref.watch(serverConnectivityProvider) != ServerConnectivityState.connected;

  if (currentUser == null) {
    yield RenderList.empty();
    return;
  }

  // Combine cached remote assets with local gallery
  final cachedAssets = await _getCachedAssets(db, currentUser.id);
  final localAssets = isOffline ? (ref.watch(localGalleryProvider).valueOrNull ?? []) : <Asset>[];

  final mergedAssets = _mergeAssets(cachedAssets, localAssets);
  log.info('Offline timeline: ${cachedAssets.length} cached, ${localAssets.length} local, ${mergedAssets.length} merged');

  yield await RenderList.fromAssets(mergedAssets, GroupAssetsBy.auto);

  // Watch for changes in database
  await for (final _ in db.assets.watchLazy()) {
    final updatedCached = await _getCachedAssets(db, currentUser.id);
    final updatedIsOffline = ref.read(serverConnectivityProvider) != ServerConnectivityState.connected;
    final updatedLocal = updatedIsOffline ? (ref.read(localGalleryProvider).valueOrNull ?? []) : <Asset>[];
    final updatedMerged = _mergeAssets(updatedCached, updatedLocal);
    yield await RenderList.fromAssets(updatedMerged, GroupAssetsBy.auto);
  }
});

Future<List<Asset>> _getCachedAssets(Isar db, String userId) async {
  return db.assets
      .filter()
      .isTrashedEqualTo(false)
      .visibilityEqualTo(AssetVisibilityEnum.timeline)
      .sortByFileCreatedAtDesc()
      .findAll();
}

List<Asset> _mergeAssets(List<Asset> cached, List<Asset> local) {
  if (local.isEmpty) return cached;
  
  final merged = <String, Asset>{};
  
  // Add cached assets first (they have remote info)
  for (final asset in cached) {
    final key = _getAssetKey(asset);
    merged[key] = asset;
  }

  // Add local assets, merging with existing if found
  for (final asset in local) {
    final key = _getAssetKey(asset);
    if (!merged.containsKey(key)) {
      merged[key] = asset;
    } else {
      // Merge local info into existing asset
      final existing = merged[key]!;
      if (existing.localId == null && asset.localId != null) {
        merged[key] = existing.copyWith(localId: asset.localId);
      }
    }
  }

  final result = merged.values.toList();
  result.sort((a, b) => b.fileCreatedAt.compareTo(a.fileCreatedAt));
  return result;
}

String _getAssetKey(Asset asset) {
  // Use checksum for deduplication if available, otherwise use filename + date
  if (asset.checksum.isNotEmpty) return asset.checksum;
  return '${asset.fileName}_${asset.fileCreatedAt.millisecondsSinceEpoch}';
}
