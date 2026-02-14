import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/entities/asset.entity.dart';
import 'package:immich_mobile/providers/gallery_permission.provider.dart';
import 'package:immich_mobile/repositories/album_media.repository.dart';
import 'package:logging/logging.dart';

final localGalleryProvider = FutureProvider<List<Asset>>((ref) async {
  final log = Logger('LocalGalleryProvider');
  final hasPermission = ref.watch(galleryPermissionNotifier.notifier).hasPermission;

  if (!hasPermission) {
    log.info('No gallery permission, returning empty list');
    return [];
  }

  final albumRepo = ref.watch(albumMediaRepositoryProvider);
  final allAssets = <Asset>[];
  final seenIds = <String>{};

  try {
    final albums = await albumRepo.getAll();
    
    for (final album in albums) {
      if (album.localId == null) continue;
      
      final assets = await albumRepo.getAssets(album.localId!);
      for (final asset in assets) {
        if (asset.localId != null && !seenIds.contains(asset.localId)) {
          seenIds.add(asset.localId!);
          allAssets.add(asset);
        }
      }
    }

    allAssets.sort((a, b) => b.fileCreatedAt.compareTo(a.fileCreatedAt));
    log.info('Loaded ${allAssets.length} local assets');
    return allAssets;
  } catch (e, stack) {
    log.severe('Failed to load local gallery', e, stack);
    return [];
  }
});

final localGalleryCountProvider = Provider<int>((ref) {
  return ref.watch(localGalleryProvider).valueOrNull?.length ?? 0;
});
