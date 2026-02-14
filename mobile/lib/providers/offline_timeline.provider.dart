import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/enums.dart';
import 'package:immich_mobile/entities/asset.entity.dart';
import 'package:immich_mobile/providers/db.provider.dart';
import 'package:immich_mobile/providers/local_gallery.provider.dart';
import 'package:immich_mobile/providers/user.provider.dart';
import 'package:immich_mobile/widgets/asset_grid/asset_grid_data_structure.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';

final offlineTimelineProvider = StreamProvider<RenderList>((ref) async* {
  final log = Logger('OfflineTimelineProvider');
  final db = ref.watch(dbProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    yield RenderList.empty();
    return;
  }

  // Combine cached remote assets with local gallery
  final cachedAssets = await _getCachedAssets(db, currentUser.id);
  final localAssets = ref.watch(localGalleryProvider).valueOrNull ?? [];

  final mergedAssets = _mergeAssets(cachedAssets, localAssets);
  log.info('Offline timeline: ${cachedAssets.length} cached, ${localAssets.length} local, ${mergedAssets.length} merged');

  yield await RenderList.fromAssets(mergedAssets, GroupAssetsBy.auto);

  // Watch for changes in database
  await for (final _ in db.assets.watchLazy()) {
    final updatedCached = await _getCachedAssets(db, currentUser.id);
    final updatedLocal = ref.read(localGalleryProvider).valueOrNull ?? [];
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
  final merged = <String, Asset>{};
  
  // Add cached assets first (they have remote info)
  for (final asset in cached) {
    final key = asset.checksum.isNotEmpty ? asset.checksum : '${asset.fileName}_${asset.fileCreatedAt.millisecondsSinceEpoch}';
    merged[key] = asset;
  }

  // Add local assets, merging with existing if found
  for (final asset in local) {
    final key = asset.checksum.isNotEmpty ? asset.checksum : '${asset.fileName}_${asset.fileCreatedAt.millisecondsSinceEpoch}';
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
