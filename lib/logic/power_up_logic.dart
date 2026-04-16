import 'dart:math';
import '../models/game_models.dart';
import 'game_logic.dart';

List<CellValue> updateFreezeTimers(List<CellValue> board) {
  return board.map((cell) {
    if (cell.isFrozen && cell.freezeTurns > 0) {
      final newTurns = cell.freezeTurns - 1;
      return cell.copyWith(
        freezeTurns: newTurns,
        isFrozen: newTurns > 0,
      );
    }
    return cell;
  }).toList();
}

List<CellValue> updateProtectionTimers(List<CellValue> board) {
  return board.map((cell) {
    if (cell.isProtected && cell.protectionTurns > 0) {
      final newTurns = cell.protectionTurns - 1;
      return cell.copyWith(
        protectionTurns: newTurns,
        isProtected: newTurns > 0,
      );
    }
    return cell;
  }).toList();
}

bool canFreezeTile(CellValue cell) => cell.owner == null && !cell.isFrozen;

bool canBombOrStealTile(CellValue cell) => cell.owner != null;

bool canMeltTile(CellValue cell) => cell.isFrozen;

bool detectGridlockRisk({
  required List<CellValue> board,
  required int gridSize,
  required int currentTurn,
  required Map<Player, List<PowerUp>> storedPowerUps,
  PowerUp? currentPowerUp,
}) {
  final totalTiles = gridSize * gridSize;
  final occupiedTiles = board.where((cell) => cell.owner != null).length;
  final fillRatio = occupiedTiles / totalTiles;

  // 1) Board fill threshold
  final fillThreshold = gridSize <= 5 ? 0.60 : (gridSize <= 7 ? 0.65 : 0.70);
  if (fillRatio < fillThreshold) return false;

  // 2) Minimum turns to avoid triggering too early
  final minTurns = gridSize <= 5 ? 6 : (gridSize <= 7 ? 10 : 15);
  if (currentTurn < minTurns) return false;

  // 3) If either player has an immediate winning move, don't force gridlock mode
  for (int pos = 0; pos < board.length; pos++) {
    if (board[pos].owner != null || board[pos].isFrozen) continue;
    if (wouldCreateWin(board, pos, Player.x, gridSize) ||
        wouldCreateWin(board, pos, Player.o, gridSize)) {
      return false;
    }
  }

  // 4) Only trigger if offensive power-ups are scarce across both players
  int countOffensive(List<PowerUp> powerUps) {
    return powerUps
        .where(
          (powerUp) =>
              powerUp.isAvailable &&
              (powerUp.type == PowerUpType.bomb ||
                  powerUp.type == PowerUpType.steal),
        )
        .length;
  }

  var totalOffensive =
      countOffensive(storedPowerUps[Player.x] ?? []) +
          countOffensive(storedPowerUps[Player.o] ?? []);

  if (currentPowerUp != null &&
      (currentPowerUp.type == PowerUpType.bomb ||
          currentPowerUp.type == PowerUpType.steal) &&
      currentPowerUp.isAvailable) {
    totalOffensive += 1;
  }

  if (totalOffensive >= 2) return false;

  return true;
}

PowerUp generatePowerUp() {
  final weightedPowerUps = [
    (type: PowerUpType.fortify, weight: 4),
    (type: PowerUpType.freeze, weight: 3),
    (type: PowerUpType.steal, weight: 3),
    (type: PowerUpType.fire, weight: 2),
    (type: PowerUpType.bomb, weight: 1),
  ];

  final totalWeight =
      weightedPowerUps.fold<int>(0, (sum, p) => sum + p.weight);
  var random = Random().nextDouble() * totalWeight;

  for (final powerup in weightedPowerUps) {
    random -= powerup.weight;
    if (random <= 0) {
      return PowerUp(
        id: PowerUp.generateId(),
        type: powerup.type,
      );
    }
  }

  return PowerUp(id: PowerUp.generateId(), type: PowerUpType.freeze);
}

PowerUp generateSmartPowerUp({
  required List<CellValue> board,
  required Player? currentPlayer,
  required int gridSize,
  required Map<Player, List<PowerUp>> storedPowerUps,
  PowerUp? currentPowerUp,
  int currentTurn = 0,
}) {
  if (detectGridlockRisk(
    board: board,
    gridSize: gridSize,
    currentTurn: currentTurn,
    storedPowerUps: storedPowerUps,
    currentPowerUp: currentPowerUp,
  )) {
    final type = Random().nextBool() ? PowerUpType.bomb : PowerUpType.steal;
    return PowerUp(id: PowerUp.generateId(), type: type);
  }

  final opponentTiles =
      board.where((c) => c.owner != null && c.owner != currentPlayer).length;
  final emptyTiles =
      board.where((c) => c.owner == null && !c.isFrozen).length;
  final frozenTiles = board.where((c) => c.isFrozen).length;
  final playerTiles =
      board.where((c) => c.owner == currentPlayer).length;
  final unprotectedPlayerTiles =
      board.where((c) => c.owner == currentPlayer && !c.isProtected).length;

  var weights = <PowerUpType, double>{
    PowerUpType.freeze: 5,
    PowerUpType.steal: 3,
    PowerUpType.fire: 2,
    PowerUpType.fortify: 2,
    PowerUpType.bomb: 1,
  };

  if (opponentTiles > 0) {
    weights[PowerUpType.bomb] = weights[PowerUpType.bomb]! * 2;
    weights[PowerUpType.steal] = weights[PowerUpType.steal]! * 2;
  }
  if (emptyTiles > 0) {
    weights[PowerUpType.freeze] = weights[PowerUpType.freeze]! * 1.5;
  }
  if (frozenTiles > 0) {
    weights[PowerUpType.fire] = weights[PowerUpType.fire]! * 3;
  }
  if (playerTiles > 0 && unprotectedPlayerTiles > 3) {
    weights[PowerUpType.fortify] = weights[PowerUpType.fortify]! * 2;
  }

  final totalWeight = weights.values.fold<double>(0, (a, b) => a + b);
  var random = Random().nextDouble() * totalWeight;

  for (final entry in weights.entries) {
    random -= entry.value;
    if (random <= 0) {
      return PowerUp(id: PowerUp.generateId(), type: entry.key);
    }
  }

  return PowerUp(id: PowerUp.generateId(), type: PowerUpType.freeze);
}
