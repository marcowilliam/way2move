import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'device_stt_service.dart';
import 'stt_service.dart';
import 'whisper_cloud_stt_service.dart';

/// Firebase Remote Config key that enables cloud STT (Whisper).
/// Set to `true` in the Firebase console to activate Whisper for all users.
/// Defaults to `false` — device STT is used until the key is configured.
const _kUseCloudStt = 'use_cloud_stt';

final _remoteConfigProvider = Provider<FirebaseRemoteConfig>((ref) {
  return FirebaseRemoteConfig.instance;
});

/// Provides the active [SttService] implementation.
///
/// Selection is driven by the `use_cloud_stt` Remote Config flag:
/// - `false` (default): [DeviceSttService] — on-device, offline-capable.
/// - `true`: [WhisperCloudSttService] — OpenAI Whisper via Cloud Function.
final sttServiceProvider = Provider<SttService>((ref) {
  final remoteConfig = ref.watch(_remoteConfigProvider);
  final useCloud = remoteConfig.getBool(_kUseCloudStt);
  return useCloud ? WhisperCloudSttService() : DeviceSttService();
});
