import 'dart:async';

import 'package:flame_audio/bgm.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';

/// Owns Seville's low-volume, looping interface music.
///
/// Music assets are optional while the soundtrack is being selected. Missing
/// track slots are ignored, so adding a licensed file is enough to enable it.
class BackgroundMusicController {
  BackgroundMusicController({
    Bgm? bgm,
    this.targetVolume = 0.12,
    this.fadeInDuration = const Duration(seconds: 10),
  }) : _bgm = bgm ?? Bgm(audioCache: FlameAudio.audioCache);

  static const trackFileNames = <String>[
    'menu-lounge-vaporwave-01.m4a',
    'menu-lounge-vaporwave-02.m4a',
    'menu-lounge-vaporwave-03.m4a',
  ];

  final Bgm _bgm;
  final double targetVolume;
  final Duration fadeInDuration;

  bool _initialized = false;
  bool _disposed = false;
  int _fadeGeneration = 0;
  Set<String>? _bundledAssets;

  int? activeTrackIndex;

  Future<List<int>> availableTrackIndexes() async {
    final assets = await _loadBundledAssets();
    return [
      for (var index = 0; index < trackFileNames.length; index++)
        if (assets.contains('assets/audio/${trackFileNames[index]}')) index,
    ];
  }

  /// Starts the preferred slot, or the first installed slot when it is absent.
  Future<bool> start({int preferredTrackIndex = 0}) async {
    final available = await availableTrackIndexes();
    if (available.isEmpty) return false;
    final selectedIndex = available.contains(preferredTrackIndex)
        ? preferredTrackIndex
        : available.first;
    return playTrack(selectedIndex);
  }

  /// Selects one of the three soundtrack slots and fades it up from silence.
  Future<bool> playTrack(int trackIndex) async {
    if (trackIndex < 0 || trackIndex >= trackFileNames.length) {
      throw RangeError.index(trackIndex, trackFileNames, 'trackIndex');
    }
    if (_disposed) return false;
    final available = await availableTrackIndexes();
    if (_disposed) return false;
    if (!available.contains(trackIndex)) return false;

    if (!_initialized) {
      await _bgm.initialize();
      _initialized = true;
    }
    if (_disposed) return false;

    final generation = ++_fadeGeneration;
    await _bgm.play(trackFileNames[trackIndex], volume: 0);
    activeTrackIndex = trackIndex;
    unawaited(_fadeIn(generation));
    return true;
  }

  Future<void> _fadeIn(int generation) async {
    const interval = Duration(milliseconds: 100);
    final stepCount = fadeInDuration.inMilliseconds ~/ interval.inMilliseconds;
    if (stepCount <= 0) {
      if (_disposed || generation != _fadeGeneration) return;
      await _bgm.audioPlayer.setVolume(targetVolume);
      return;
    }
    for (var step = 1; step <= stepCount; step++) {
      await Future<void>.delayed(interval);
      if (_disposed || generation != _fadeGeneration) return;
      await _bgm.audioPlayer.setVolume(targetVolume * step / stepCount);
    }
  }

  Future<Set<String>> _loadBundledAssets() async {
    final cached = _bundledAssets;
    if (cached != null) return cached;
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return _bundledAssets = manifest.listAssets().toSet();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _fadeGeneration++;
    activeTrackIndex = null;
    await _bgm.dispose();
  }
}
