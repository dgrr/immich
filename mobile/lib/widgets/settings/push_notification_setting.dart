import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/services/app_settings.service.dart';
import 'package:immich_mobile/utils/hooks/app_settings_update_hook.dart';
import 'package:immich_mobile/widgets/settings/settings_sub_page_scaffold.dart';
import 'package:immich_mobile/widgets/settings/settings_switch_list_tile.dart';

class PushNotificationSetting extends HookConsumerWidget {
  const PushNotificationSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabledValue = useAppSettingsState(AppSettingsEnum.pushNotificationsEnabled);
    final memoriesValue = useAppSettingsState(AppSettingsEnum.pushNotificationsMemories);

    final settings = [
      SettingsSwitchListTile(
        valueNotifier: enabledValue,
        title: 'Push Notifications',
        subtitle: 'Enable push notifications',
      ),
      SettingsSwitchListTile(
        enabled: enabledValue.value,
        valueNotifier: memoriesValue,
        title: 'Memories',
        subtitle: 'Receive weekly notifications about memories',
      ),
    ];

    return SettingsSubPageScaffold(settings: settings);
  }
}
