import 'package:collection/collection.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/extensions.dart';

import '../core/mini_common.dart';
import '../core/mini_messaging.dart';
import '../scripting/mini_script.dart';
import '../util/random.dart';
import 'mini_balls.dart';
import 'mini_enemy.dart';
import 'mini_enemy_kind.dart';

class MiniEnemies extends MiniScriptComponent {
  MiniEnemies({required this.level, required this.formation});

  final int level;

  final Iterable<MiniEnemy> formation;

  bool get hasActiveEnemies => _active && _attackers.isNotEmpty;

  Iterable<MiniEnemy> get _attackers => _enemies.where((it) => it.isActive);

  @override
  void onLoad() async {
    logInfo('load level $level');
    for (final it in formation) {
      it.onDefeated = _onDefeated;
      at(0.1, () => add(it));
    }
    at(0.5, () => messaging.send(FormationComplete()));
    at(0.5, () => reactivate());
  }

  void _onDefeated() {
    logInfo('enemy defeated ${children.length}');
    if (children.length <= 1) sendMessage(EnemiesDefeated());
  }

  void reactivate() => _active = true;

  bool _active = false;
  double _fireAtWillCoolDown = 0;
  late double _sendAttackerCoolDown = _attackerCoolDown();
  late double _sendFormationCoolDown = _formationCoolDown();

  @override
  void onMount() {
    super.onMount();
    onMessage<PlayerDestroyed>((_) => _active = false);
    onMessage<GetClosestEnemyPosition>((it) => _pickClosest(it.position, it.onResult));
  }

  void _pickClosest(Vector2 pos, Function(Vector2) onPick) {
    final it = _enemies
        .where((it) => it.position.y < pos.y)
        .map((it) => (it, it.position.distanceToSquared(pos)))
        .toList()
        .sorted((a, b) => (a.$2 - b.$2).sign.toInt())
        .firstOrNull;

    if (it != null) onPick(it.$1.position);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_active) _onFireAtWill(dt);
    if (_active) _sendAttacker(dt);
    if (_active) _sendFormation(dt);
  }

  Iterable<MiniEnemy> get _enemies => children.whereType<MiniEnemy>();

  void _onFireAtWill(double dt) {
    if (_fireAtWillCoolDown <= 0) {
      final it = _enemies.toList();
      if (it.isNotEmpty) {
        spawnBall(it.random(random).position);
        _fireAtWillCoolDown = (2 - level / 10).clamp(0.2, 2);
      }
    } else if (_fireAtWillCoolDown > 0) {
      _fireAtWillCoolDown -= dt;
    }
  }

  void _sendAttacker(double dt) {
    final attackers = _attackers;
    if (_sendAttackerCoolDown <= 0 && attackers.length < _maxAttackers) {
      final it = _waiting.where(_notSmiley).toList();
      if (it.isNotEmpty) {
        it.random(random).startAttackRun();
        _sendAttackerCoolDown = _attackerCoolDown();
      }
    } else if (_sendAttackerCoolDown > 0) {
      _sendAttackerCoolDown -= dt;
    }
  }

  void _sendFormation(double dt) {
    final attackers = _attackers;
    if (_sendFormationCoolDown <= 0 && attackers.length < _maxAttackers) {
      final candidates = _waiting.where(_smiley).toList();
      if (candidates.isNotEmpty) {
        final leader = candidates.random(random);
        leader.startAttackRun();
        final followers = _twoClosestTo(leader, _enemies.where(_notSmiley)).toList();
        if (followers.length == 2) {
          followers.sort((a, b) => (a.position.x - b.position.x).sign.toInt());
          followers.first.startFollowing(leader, -1);
          followers.last.startFollowing(leader, 1);
        } else if (followers.length == 1) {
          final it = followers.single;
          it.startFollowing(leader, it.x < leader.x ? -1 : 1);
        }
        _sendFormationCoolDown = _formationCoolDown();
      }
    } else if (_sendFormationCoolDown > 0) {
      _sendFormationCoolDown -= dt;
    }
  }

  Iterable<MiniEnemy> _twoClosestTo(MiniEnemy leader, Iterable<MiniEnemy> others) {
    final result = <(double, MiniEnemy)>[];
    // put distance to leader plus other into result:
    for (final it in others) {
      final distance = leader.position.distanceTo(it.position);
      if (distance > 32) continue;
      logInfo('distance to ${it.kind}: $distance');
      result.add((distance, it));
    }
    result.sort((a, b) => (a.$1 - b.$1).sign.toInt());
    return result.take(2).map((it) => it.$2);
  }

  bool _smiley(MiniEnemy it) => it.kind == MiniEnemyKind.smiley;

  bool _notSmiley(MiniEnemy it) => it.kind != MiniEnemyKind.smiley;

  Iterable<MiniEnemy> get _waiting => _enemies.where((it) => it.isWaiting);

  double _attackerCoolDown() => (8 - level / 4).clamp(2, 8);

  double _formationCoolDown() => (19 - level / 6).clamp(2, 19);

  int get _maxAttackers => (level / 3).clamp(1, 4).toInt();
}
