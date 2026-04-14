import 'dart:math';

enum Player { x, o }

enum PowerUpType { bomb, steal, freeze, fire, fortify }

enum TurnPhase {
  powerUpDecision,
  powerUpAction,
  tilePlacement,
  turnEnd,
}

class PowerUp {
  final String id;
  final PowerUpType type;
  final int cooldown;
  final bool isAvailable;

  const PowerUp({
    required this.id,
    required this.type,
    this.cooldown = 0,
    this.isAvailable = true,
  });

  PowerUp copyWith({
    String? id,
    PowerUpType? type,
    int? cooldown,
    bool? isAvailable,
  }) {
    return PowerUp(
      id: id ?? this.id,
      type: type ?? this.type,
      cooldown: cooldown ?? this.cooldown,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  static String generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = Random();
    return 'powerup-$now-${rand.nextInt(999999)}';
  }
}

class CellValue {
  final Player? owner;
  final List<PowerUp> powerUps;
  final bool isFrozen;
  final int freezeTurns;
  final bool isProtected;
  final int protectionTurns;
  final bool lastMove;

  const CellValue({
    this.owner,
    this.powerUps = const [],
    this.isFrozen = false,
    this.freezeTurns = 0,
    this.isProtected = false,
    this.protectionTurns = 0,
    this.lastMove = false,
  });

  CellValue copyWith({
    Player? Function()? owner,
    List<PowerUp>? powerUps,
    bool? isFrozen,
    int? freezeTurns,
    bool? isProtected,
    int? protectionTurns,
    bool? lastMove,
  }) {
    return CellValue(
      owner: owner != null ? owner() : this.owner,
      powerUps: powerUps ?? this.powerUps,
      isFrozen: isFrozen ?? this.isFrozen,
      freezeTurns: freezeTurns ?? this.freezeTurns,
      isProtected: isProtected ?? this.isProtected,
      protectionTurns: protectionTurns ?? this.protectionTurns,
      lastMove: lastMove ?? this.lastMove,
    );
  }

  static CellValue empty() => const CellValue();
}

extension PlayerExtension on Player {
  Player get opponent => this == Player.x ? Player.o : Player.x;

  String get symbol => this == Player.x ? 'X' : 'O';
}
