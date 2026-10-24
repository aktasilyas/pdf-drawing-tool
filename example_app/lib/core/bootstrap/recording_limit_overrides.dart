import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drawing_core/drawing_core.dart' show AudioRecording;
import 'package:drawing_ui/drawing_ui.dart' as drawing_ui;

import 'package:example_app/core/routing/route_names.dart';
import 'package:example_app/features/premium/premium.dart';

const _freeRecordingLimit = Duration(minutes: 5);

Duration _totalUsed(List<AudioRecording> recordings) =>
    recordings.fold<Duration>(Duration.zero, (sum, r) => sum + r.duration);

/// Free-tier recording limits and export watermark (premium flag only).
List<Override> premiumRecordingOverrides() => [
      drawing_ui.recordingMaxDurationProvider.overrideWith((ref) {
        final tier = ref.watch(currentTierProvider);
        if (tier != SubscriptionTier.free) return null; // unlimited
        final remaining = _freeRecordingLimit -
            _totalUsed(ref.watch(drawing_ui.audioRecordingsProvider));
        if (remaining <= Duration.zero) return Duration.zero;
        return remaining;
      }),
      drawing_ui.canStartRecordingProvider.overrideWith((ref) {
        final tier = ref.watch(currentTierProvider);
        if (tier != SubscriptionTier.free) return true;
        return _totalUsed(ref.watch(drawing_ui.audioRecordingsProvider)) <
            _freeRecordingLimit;
      }),
      drawing_ui.onRecordingBlockedProvider.overrideWith((ref) {
        return (BuildContext ctx) {
          final recordings = ref.read(drawing_ui.audioRecordingsProvider);
          final usedMinutes = (_totalUsed(recordings).inSeconds / 60).ceil();
          showModalBottomSheet(
            context: ctx,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (sheetCtx) => UpgradePromptSheet(
              access: FeatureAccess.blocked(
                currentUsage: usedMinutes,
                maxUsage: 5,
                message:
                    'Ücretsiz planda toplam 5 dakika ses kaydı yapabilirsiniz. '
                    "Premium'a geçerek sınırsız kayıt yapın.",
              ),
              featureIcon: Icons.mic_outlined,
              featureTitle: 'Ses Kaydı Limitine Ulaştınız',
              onUpgrade: () {
                Navigator.pop(sheetCtx);
                GoRouter.of(sheetCtx).push(RouteNames.paywall);
              },
              onDismiss: () => Navigator.pop(sheetCtx),
            ),
          );
        };
      }),
      drawing_ui.exportWatermarkProvider.overrideWith((ref) {
        return ref.watch(currentTierProvider) == SubscriptionTier.free;
      }),
    ];
