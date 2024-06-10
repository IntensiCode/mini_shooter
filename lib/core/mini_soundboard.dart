import 'package:audioplayers/audioplayers.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame_audio/flame_audio.dart';

import 'mini_common.dart';

enum MiniSound {
  asteroid_clash,
  block,
  death,
  drop,
  explosion,
  game_on,
  game_over,
  hit,
  incoming,
  laser,
  strangeness,
}

final soundboard = MiniSoundboard();

double get musicVolume => soundboard.music * soundboard.master;

class MiniSoundboard {
  double master = 0.3;
  double music = 0.5;
  double voice = 0.8;
  double sound = 0.8;

  bool muted = false;

  toggleMute() {
    muted = !muted;
    if (muted) {
      if (_bgm?.state == PlayerState.playing) _bgm?.pause();
    } else {
      if (_bgm?.state == PlayerState.paused) _bgm?.resume();
    }
  }

  preload() async {
    for (final it in MiniSound.values) {
      logInfo('cache $it');
      await FlameAudio.audioCache.load('effect/${it.name}.ogg');
    }
  }

  int _activeSounds = 0;

  play(MiniSound sound, {double? volume}) {
    if (muted) return;

    volume ??= soundboard.sound;

    if (_activeSounds >= _maxActive) {
      logWarn('sound overload');
      return;
    }

    _playPooled(sound, volume);
  }

  _playPooled(MiniSound sound, double volume) async {
    final reuse = _pooledPlayers.indexWhere((it) {
      if (it.$1 != sound) return false;
      if (it.$2.state == PlayerState.playing) return false;
      return true;
    });

    if (reuse == -1) {
      while (_pooledPlayers.length >= _maxPooled) {
        logInfo('disposing pooled player');
        final (_, player) = _pooledPlayers.removeAt(0);
        player.dispose();
      }

      final it = await FlameAudio.play('effect/${sound.name}.ogg', volume: volume * master);
      it.setPlayerMode(PlayerMode.lowLatency);
      it.setReleaseMode(ReleaseMode.stop);
      it.onPlayerStateChanged.listen((it) {
        if (it == PlayerState.playing) {
          _activeSounds++;
        } else {
          _activeSounds--;
        }
      });

      _activeSounds++;
      _pooledPlayers.add((sound, it));
      logInfo('pooled: ${_pooledPlayers.length}');
    } else {
      final it = _pooledPlayers.removeAt(reuse);
      _pooledPlayers.add(it);
      final player = it.$2;
      player.setVolume(volume * master);
      player.resume();
    }
  }

  final _pooledPlayers = <(MiniSound, AudioPlayer)>[];

  static const _maxActive = 10;
  static const _maxPooled = 50;

  AudioPlayer? _bgm;

  Future<AudioPlayer> playBackgroundMusic(String filename) async {
    _bgm?.stop();

    final volume = music * master;
    if (dev) {
      _bgm = await FlameAudio.playLongAudio(filename, volume: volume);

      // only in dev: stop music after 10 seconds, to avoid playing multiple times on hot restart.
      // final afterTenSeconds = player.onPositionChanged.where((it) => it.inSeconds >= 10).take(1);
      // autoDispose('afterTenSeconds', afterTenSeconds.listen((it) => player.stop()));
    } else {
      await FlameAudio.bgm.play(filename, volume: volume);
      _bgm = FlameAudio.bgm.audioPlayer;
    }

    if (muted) _bgm!.pause();

    return _bgm!;
  }

  Future<AudioPlayer> playAudio(String filename, {double? volume}) async {
    volume ??= sound;
    final player = await FlameAudio.play(filename, volume: volume * master);
    if (muted) player.setVolume(0);
    return player;
  }
}

// TODO Replace AudioPlayer result type with AudioHandle to change stop into fade out etc
