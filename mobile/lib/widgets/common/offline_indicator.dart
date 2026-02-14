import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/providers/server_connectivity.provider.dart';

class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityState = ref.watch(serverConnectivityProvider);

    if (connectivityState == ServerConnectivityState.connected) {
      return const SizedBox.shrink();
    }

    final isChecking = connectivityState == ServerConnectivityState.checking;

    return GestureDetector(
      onTap: isChecking
          ? null
          : () => ref.read(serverConnectivityProvider.notifier).checkConnectivity(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: isChecking ? Colors.orange.shade700 : Colors.grey.shade700,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isChecking ? Icons.sync : Icons.cloud_off,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isChecking
                    ? 'Connecting to server...'
                    : 'Offline - Tap to retry',
                style: context.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
