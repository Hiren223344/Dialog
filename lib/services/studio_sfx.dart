import 'package:flutter/services.dart';

/// Named feedback cues for every meaningful action (design doc §5.4
/// "Micro-feedback ... layered SFX").
///
/// This scaffold drives cues through the platform's haptic engine and
/// system sound so every action already has a felt reaction with zero
/// bundled audio assets. Swap [StudioSfx.player] for a real audio-asset
/// backed implementation once sound design lands, without touching call
/// sites.
enum SfxCue {
  tap,
  coinDrop,
  likePop,
  viralBurst,
  rewardStream,
  levelUp,
  buildingComplete,
}

abstract class StudioSfxPlayer {
  Future<void> play(SfxCue cue);
}

class HapticStudioSfxPlayer implements StudioSfxPlayer {
  @override
  Future<void> play(SfxCue cue) async {
    switch (cue) {
      case SfxCue.tap:
        await HapticFeedback.selectionClick();
      case SfxCue.coinDrop:
        await HapticFeedback.lightImpact();
      case SfxCue.likePop:
        await HapticFeedback.selectionClick();
      case SfxCue.viralBurst:
        await HapticFeedback.heavyImpact();
        await SystemSound.play(SystemSoundType.alert);
      case SfxCue.rewardStream:
        await HapticFeedback.lightImpact();
      case SfxCue.levelUp:
      case SfxCue.buildingComplete:
        await HapticFeedback.mediumImpact();
        await SystemSound.play(SystemSoundType.click);
    }
  }
}

class StudioSfx {
  StudioSfx._();

  static StudioSfxPlayer player = HapticStudioSfxPlayer();

  static void play(SfxCue cue) {
    // Fire-and-forget: feedback must never block the interaction it reacts to.
    player.play(cue);
  }
}
