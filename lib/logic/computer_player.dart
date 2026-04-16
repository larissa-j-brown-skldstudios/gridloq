import 'dart:math';
import '../models/game_models.dart';
import 'game_logic.dart';

class MoveEvaluation {
  final int position;
  final double winPotential;
  final double blockPotential;
  final double strategicValue;

  MoveEvaluation({
    required this.position,
    required this.winPotential,
    required this.blockPotential,
    required this.strategicValue,
  });
}

class ComputerMoveResult {
  final String type; // 'powerup' or 'tile'
  final int position;
  final PowerUpType? powerUpType;

  ComputerMoveResult({
    required this.type,
    required this.position,
    this.powerUpType,
  });
}

// ---------- Threat analysis ----------

class HumanThreatProfile {
  final int totalPowerups;
  final int offensivePowerups;
  final int bombCount;
  final int stealCount;
  final int freezeCount;
  final int fireCount;
  final int fortifyCount;
  final String threatLevel; // low, medium, high, critical

  HumanThreatProfile({
    required this.totalPowerups,
    required this.offensivePowerups,
    required this.bombCount,
    required this.stealCount,
    required this.freezeCount,
    required this.fireCount,
    required this.fortifyCount,
    required this.threatLevel,
  });
}

// ---------- Core helpers ----------

int countNearbyTiles(
  List<CellValue> board,
  int position,
  Player player,
  int boardSize,
) {
  final row = position ~/ boardSize;
  final col = position % boardSize;
  int count = 0;

  for (int dr = -1; dr <= 1; dr++) {
    for (int dc = -1; dc <= 1; dc++) {
      if (dr == 0 && dc == 0) continue;
      final nr = row + dr;
      final nc = col + dc;
      if (nr >= 0 && nr < boardSize && nc >= 0 && nc < boardSize) {
        final pos = nr * boardSize + nc;
        if (board[pos].owner == player) count++;
      }
    }
  }
  return count;
}

double checkNearWinSequences(
  List<CellValue> board,
  int position,
  Player? player,
  int boardSize,
) {
  if (player == null) return 0;

  final row = position ~/ boardSize;
  final col = position % boardSize;
  double maxValue = 0;

  const directions = [
    (dr: 0, dc: 1),
    (dr: 1, dc: 0),
    (dr: 1, dc: 1),
    (dr: 1, dc: -1),
  ];

  for (final d in directions) {
    int seqLen = 1;
    int openEnds = 0;

    for (int i = 1; i < 5; i++) {
      final nr = row + d.dr * i;
      final nc = col + d.dc * i;
      if (nr < 0 || nr >= boardSize || nc < 0 || nc >= boardSize) break;
      final pos = nr * boardSize + nc;
      if (board[pos].owner == player) {
        seqLen++;
      } else if (board[pos].owner == null && !board[pos].isFrozen) {
        openEnds++;
        break;
      } else {
        break;
      }
    }

    for (int i = 1; i < 5; i++) {
      final nr = row - d.dr * i;
      final nc = col - d.dc * i;
      if (nr < 0 || nr >= boardSize || nc < 0 || nc >= boardSize) break;
      final pos = nr * boardSize + nc;
      if (board[pos].owner == player) {
        seqLen++;
      } else if (board[pos].owner == null && !board[pos].isFrozen) {
        openEnds++;
        break;
      } else {
        break;
      }
    }

    double value = 0;
    if (seqLen >= 4 && openEnds >= 1) {
      value = 100;
    } else if (seqLen == 4 && openEnds == 0) {
      value = 50;
    } else if (seqLen == 3 && openEnds >= 2) {
      value = 40;
    } else if (seqLen == 3 && openEnds >= 1) {
      value = 20;
    } else if (seqLen == 2 && openEnds >= 2) {
      value = 8;
    } else if (seqLen == 2 && openEnds >= 1) {
      value = 3;
    }
    if (value > maxValue) maxValue = value;
  }
  return maxValue;
}

double calculateStrategicValue(
  List<CellValue> board,
  int position,
  Player player,
  int boardSize,
) {
  final row = position ~/ boardSize;
  final col = position % boardSize;
  double value = 0;

  for (int dr = -2; dr <= 2; dr++) {
    for (int dc = -2; dc <= 2; dc++) {
      if (dr == 0 && dc == 0) continue;
      final nr = row + dr;
      final nc = col + dc;
      if (nr >= 0 && nr < boardSize && nc >= 0 && nc < boardSize) {
        final pos = nr * boardSize + nc;
        if (board[pos].owner == player) {
          value += 10;
        } else if (board[pos].owner == null && !board[pos].isFrozen) {
          value += 5;
        }
      }
    }
  }

  final centerRow = boardSize ~/ 2;
  final centerCol = boardSize ~/ 2;
  final dist = (row - centerRow).abs() + (col - centerCol).abs();
  value += (20 - dist).clamp(0, 20).toDouble();

  return value;
}

List<({int position, double threatLevel, String direction})> scanAllThreats(
  List<CellValue> board,
  Player player,
  int boardSize,
) {
  final threats = <({int position, double threatLevel, String direction})>[];

  const directions = [
    (dr: 0, dc: 1, name: 'horizontal'),
    (dr: 1, dc: 0, name: 'vertical'),
    (dr: 1, dc: 1, name: 'diagonal-dr'),
    (dr: 1, dc: -1, name: 'diagonal-dl'),
  ];

  for (int pos = 0; pos < board.length; pos++) {
    if (board[pos].owner != player) continue;
    final row = pos ~/ boardSize;
    final col = pos % boardSize;

    for (final d in directions) {
      int seqLen = 1;
      final emptySpots = <int>[];
      bool blocked = false;

      for (int i = 1; i < 5 && !blocked; i++) {
        final nr = row + d.dr * i;
        final nc = col + d.dc * i;
        if (nr < 0 || nr >= boardSize || nc < 0 || nc >= boardSize) {
          blocked = true;
          break;
        }
        final npos = nr * boardSize + nc;
        if (board[npos].owner == player) {
          seqLen++;
        } else if (board[npos].owner == null && !board[npos].isFrozen) {
          emptySpots.add(npos);
        } else {
          blocked = true;
        }
      }

      if (seqLen >= 3 && emptySpots.isNotEmpty) {
        final level = seqLen == 4 ? 100.0 : (seqLen == 3 ? 40.0 : 10.0);
        for (final ep in emptySpots) {
          threats.add((position: ep, threatLevel: level, direction: d.name));
        }
      }
    }
  }
  return threats;
}

List<int> detectForkOpportunities(
  List<CellValue> board,
  Player player,
  int boardSize,
) {
  final forks = <int>[];
  final emptyPositions = <int>[];
  for (int i = 0; i < board.length; i++) {
    if (board[i].owner == null && !board[i].isFrozen) emptyPositions.add(i);
  }

  for (final pos in emptyPositions) {
    final sim = List<CellValue>.from(board);
    sim[pos] = sim[pos].copyWith(owner: () => player);
    final threats = scanAllThreats(sim, player, boardSize);
    final highThreats = threats.where((t) => t.threatLevel >= 40).length;
    if (highThreats >= 2) forks.add(pos);
  }
  return forks;
}

List<int> getAdjacentPositions(int position, int boardSize) {
  final row = position ~/ boardSize;
  final col = position % boardSize;
  final adjacent = <int>[];
  for (int dr = -1; dr <= 1; dr++) {
    for (int dc = -1; dc <= 1; dc++) {
      if (dr == 0 && dc == 0) continue;
      final nr = row + dr;
      final nc = col + dc;
      if (nr >= 0 && nr < boardSize && nc >= 0 && nc < boardSize) {
        adjacent.add(nr * boardSize + nc);
      }
    }
  }
  return adjacent;
}

bool _opponentHasOffensivePowerUps(
  Map<Player, List<PowerUp>> storedPowerUps,
  Player opponent,
) {
  return (storedPowerUps[opponent] ?? []).any(
    (p) =>
        p.isAvailable &&
        (p.type == PowerUpType.bomb ||
            p.type == PowerUpType.steal ||
            p.type == PowerUpType.fire),
  );
}

List<int> _findCriticalBlockingTiles(
  List<CellValue> board,
  Player computer,
  Player opponent,
  int gridSize,
) {
  final critical = <int>[];
  for (int i = 0; i < board.length; i++) {
    if (board[i].owner != computer || board[i].isProtected) continue;

    final simulated = List<CellValue>.from(board);
    simulated[i] = simulated[i].copyWith(owner: () => null);
    final adjacent = getAdjacentPositions(i, gridSize);

    var isCritical = false;
    for (final pos in adjacent) {
      if (simulated[pos].owner != opponent) continue;
      final threat = checkNearWinSequences(simulated, pos, opponent, gridSize);
      if (threat >= 5) {
        isCritical = true;
        break;
      }
    }

    if (isCritical) {
      critical.add(i);
    }
  }

  return critical;
}

bool _wouldBlockOpponentWin(
  List<CellValue> board,
  int position,
  Player opponent,
  int gridSize,
) {
  if (position < 0 || position >= board.length) return false;
  if (board[position].owner != opponent || board[position].isProtected) return false;

  final before = checkWinCondition(board, opponent, gridSize) != null;

  final simulated = List<CellValue>.from(board);
  simulated[position] = simulated[position].copyWith(
    owner: () => null,
    isProtected: false,
  );
  final after = checkWinCondition(simulated, opponent, gridSize) != null;

  if (before && !after) return true;

  final nearWinBefore = checkNearWinSequences(board, position, opponent, gridSize);
  final nearWinAfter =
      checkNearWinSequences(simulated, position, opponent, gridSize);

  return nearWinBefore >= 10 && nearWinAfter < nearWinBefore;
}

Set<int> _simulateStealComboThreats({
  required List<CellValue> board,
  required Player computer,
  required Player opponent,
  required int gridSize,
  required Map<Player, List<PowerUp>> storedPowerUps,
}) {
  final hasSteal = (storedPowerUps[opponent] ?? [])
      .any((p) => p.isAvailable && p.type == PowerUpType.steal);
  if (!hasSteal) return <int>{};

  final threats = <int>{};

  for (int stealTarget = 0; stealTarget < board.length; stealTarget++) {
    final cell = board[stealTarget];
    if (cell.owner != computer || cell.isProtected) continue;

    final afterSteal = List<CellValue>.from(board);
    afterSteal[stealTarget] = afterSteal[stealTarget].copyWith(
      owner: () => opponent,
      isProtected: false,
    );

    if (checkWinCondition(afterSteal, opponent, gridSize) != null) {
      threats.add(stealTarget);
      continue;
    }

    for (int placePos = 0; placePos < afterSteal.length; placePos++) {
      final placeCell = afterSteal[placePos];
      if (placeCell.owner != null || placeCell.isFrozen) continue;
      final afterPlace = List<CellValue>.from(afterSteal);
      afterPlace[placePos] = afterPlace[placePos].copyWith(owner: () => opponent);
      if (checkWinCondition(afterPlace, opponent, gridSize) != null) {
        threats.add(stealTarget);
        threats.add(placePos);
      }
    }
  }

  return threats;
}

Set<int> _simulateBombComboThreats({
  required List<CellValue> board,
  required Player computer,
  required Player opponent,
  required int gridSize,
  required Map<Player, List<PowerUp>> storedPowerUps,
}) {
  final hasBomb = (storedPowerUps[opponent] ?? [])
      .any((p) => p.isAvailable && p.type == PowerUpType.bomb);
  if (!hasBomb) return <int>{};

  final threats = <int>{};

  for (int bombTarget = 0; bombTarget < board.length; bombTarget++) {
    final cell = board[bombTarget];
    if (cell.owner != computer || cell.isProtected) continue;

    final afterBomb = List<CellValue>.from(board);
    afterBomb[bombTarget] = CellValue.empty();

    for (int placePos = 0; placePos < afterBomb.length; placePos++) {
      final placeCell = afterBomb[placePos];
      if (placeCell.owner != null || placeCell.isFrozen) continue;
      final afterPlace = List<CellValue>.from(afterBomb);
      afterPlace[placePos] = afterPlace[placePos].copyWith(owner: () => opponent);
      if (checkWinCondition(afterPlace, opponent, gridSize) != null) {
        threats.add(bombTarget);
        threats.add(placePos);
      }
    }
  }

  return threats;
}

Set<int> _simulateFireComboThreats({
  required List<CellValue> board,
  required Player opponent,
  required int gridSize,
  required Map<Player, List<PowerUp>> storedPowerUps,
}) {
  final hasFire = (storedPowerUps[opponent] ?? [])
      .any((p) => p.isAvailable && p.type == PowerUpType.fire);
  if (!hasFire) return <int>{};

  final threats = <int>{};
  for (int i = 0; i < board.length; i++) {
    final cell = board[i];
    if (!cell.isFrozen || cell.owner != null) continue;
    final afterFire = List<CellValue>.from(board);
    afterFire[i] = afterFire[i].copyWith(
      isFrozen: false,
      freezeTurns: 0,
      owner: () => opponent,
    );
    if (checkWinCondition(afterFire, opponent, gridSize) != null) {
      threats.add(i);
    }
  }

  return threats;
}

// ---------- Vulnerability / threat helpers ----------

HumanThreatProfile analyzeHumanThreat({
  required Player? currentPlayer,
  required Player? humanPlayer,
  required Map<Player, List<PowerUp>> storedPowerUps,
  required PowerUp? currentPowerUp,
}) {
  final human = humanPlayer ?? (currentPlayer == Player.x ? Player.o : Player.x);
  final humanPowerups = storedPowerUps[human] ?? [];
  final all = currentPlayer != human && currentPowerUp != null
      ? [...humanPowerups, currentPowerUp]
      : humanPowerups;

  int bombCount = 0, stealCount = 0, freezeCount = 0;
  int fireCount = 0, fortifyCount = 0;

  for (final p in all) {
    if (!p.isAvailable) continue;
    switch (p.type) {
      case PowerUpType.bomb:
        bombCount++;
      case PowerUpType.steal:
        stealCount++;
      case PowerUpType.freeze:
        freezeCount++;
      case PowerUpType.fire:
        fireCount++;
      case PowerUpType.fortify:
        fortifyCount++;
    }
  }

  final offensive = bombCount + stealCount;
  final total = all.where((p) => p.isAvailable).length;
  String threat;
  if (offensive == 0) {
    threat = 'low';
  } else if (offensive == 1) {
    threat = 'medium';
  } else if (offensive == 2) {
    threat = 'high';
  } else {
    threat = 'critical';
  }

  return HumanThreatProfile(
    totalPowerups: total,
    offensivePowerups: offensive,
    bombCount: bombCount,
    stealCount: stealCount,
    freezeCount: freezeCount,
    fireCount: fireCount,
    fortifyCount: fortifyCount,
    threatLevel: threat,
  );
}

double _calculateStealValueForOpponent(
  List<CellValue> board,
  int position,
  Player humanPlayer,
  int gridSize,
) {
  final simBoard = List<CellValue>.from(board);
  simBoard[position] = simBoard[position].copyWith(owner: () => humanPlayer);

  double value = 0;
  final row = position ~/ gridSize;
  final col = position % gridSize;

  const directions = [
    (dr: 0, dc: 1),
    (dr: 1, dc: 0),
    (dr: 1, dc: 1),
    (dr: 1, dc: -1),
  ];

  for (final d in directions) {
    int humanCount = 1;
    int emptyCount = 0;

    for (int i = 1; i < 5; i++) {
      final nr = row + d.dr * i;
      final nc = col + d.dc * i;
      if (nr < 0 || nr >= gridSize || nc < 0 || nc >= gridSize) break;
      final pos = nr * gridSize + nc;
      if (simBoard[pos].owner == humanPlayer) {
        humanCount++;
      } else if (simBoard[pos].owner == null && !simBoard[pos].isFrozen) {
        emptyCount++;
      } else {
        break;
      }
    }
    for (int i = 1; i < 5; i++) {
      final nr = row - d.dr * i;
      final nc = col - d.dc * i;
      if (nr < 0 || nr >= gridSize || nc < 0 || nc >= gridSize) break;
      final pos = nr * gridSize + nc;
      if (simBoard[pos].owner == humanPlayer) {
        humanCount++;
      } else if (simBoard[pos].owner == null && !simBoard[pos].isFrozen) {
        emptyCount++;
      } else {
        break;
      }
    }

    if (humanCount >= 4 && emptyCount >= 1) {
      value += 200;
    } else if (humanCount >= 4) {
      value += 150;
    } else if (humanCount == 3 && emptyCount >= 2) {
      value += 80;
    }
  }
  return value;
}

// ---------- Main evaluation ----------

MoveEvaluation evaluateMove({
  required List<CellValue> board,
  required int position,
  required Player? currentPlayer,
  required int gridSize,
  required Map<Player, List<PowerUp>> storedPowerUps,
  required PowerUp? currentPowerUp,
  required Player? humanPlayer,
}) {
  if (board[position].owner != null || board[position].isFrozen) {
    return MoveEvaluation(
      position: position,
      winPotential: -1,
      blockPotential: -1,
      strategicValue: -1,
    );
  }

  final simBoard = List<CellValue>.from(board);
  simBoard[position] = simBoard[position].copyWith(owner: () => currentPlayer);

  final wouldWin = currentPlayer != null
      ? checkWinCondition(simBoard, currentPlayer, gridSize) != null
      : false;

  final opponent = currentPlayer == Player.x ? Player.o : Player.x;
  final wouldBlock = wouldCreateWin(board, position, opponent, gridSize);

  final totalTiles = board.length;
  final occupiedTiles = board.where((c) => c.owner != null).length;
  final gameProgress = occupiedTiles / totalTiles;

  final isLargeBoard = gridSize >= 10;
  final endgameThreshold = isLargeBoard ? 0.2 : 0.5;
  final midgameThreshold = isLargeBoard ? 0.1 : 0.3;

  double strategicValue = currentPlayer != null
      ? calculateStrategicValue(simBoard, position, currentPlayer, gridSize)
      : 0;

  final nearWinValue =
      checkNearWinSequences(simBoard, position, currentPlayer, gridSize);
  final nearBlockValue =
      checkNearWinSequences(board, position, opponent, gridSize);

  if (gameProgress > endgameThreshold) {
    final beyond = gameProgress - endgameThreshold;
    final maxP = 1 - endgameThreshold;
    final mult = 1 + (beyond / maxP) * 2;
    strategicValue += nearWinValue * mult;
    strategicValue += nearBlockValue * 0.9 * mult;
  } else if (gameProgress > midgameThreshold) {
    final mult = isLargeBoard ? 0.8 : 0.5;
    strategicValue += nearWinValue * mult;
    strategicValue += nearBlockValue * mult * 0.9;
  }

  if (isLargeBoard && nearWinValue >= 20) {
    strategicValue += 30;
  }

  // Vulnerability assessment
  if (currentPlayer != null) {
    final humanThreat = analyzeHumanThreat(
      currentPlayer: currentPlayer,
      humanPlayer: humanPlayer,
      storedPowerUps: storedPowerUps,
      currentPowerUp: currentPowerUp,
    );

    if (humanThreat.bombCount > 0 || humanThreat.stealCount > 0) {
      double riskScore = humanThreat.bombCount * 30.0 +
          humanThreat.stealCount * 35.0;

      final human =
          humanPlayer ?? (currentPlayer == Player.x ? Player.o : Player.x);
      final stealVal =
          _calculateStealValueForOpponent(board, position, human, gridSize);
      if (stealVal >= 150) {
        riskScore += 200;
      } else if (stealVal >= 80) {
        riskScore += 100;
      }

      final canProtect = (storedPowerUps[currentPlayer] ?? [])
          .any((p) => p.type == PowerUpType.fortify && p.isAvailable);
      if (canProtect) riskScore *= 0.5;

      final penalty = riskScore.clamp(0, 100) * 0.5;
      strategicValue -= penalty;
      if (gameProgress > 0.6) strategicValue -= penalty * 0.5;
      if (canProtect) strategicValue += 15;
    }

    final opponentTiles = board.where((c) => c.owner == opponent).length;
    final playerHasProtection = (storedPowerUps[currentPlayer] ?? [])
        .any((p) => p.type == PowerUpType.fortify && p.isAvailable);
    if (opponentTiles > 5 && !playerHasProtection) {
      final near = countNearbyTiles(board, position, opponent, gridSize);
      strategicValue -= near * 15;
    }
  }

  final endgameBoost =
      gameProgress > 0.6 ? 1 + (gameProgress - 0.6) * 2.5 : 1.0;

  return MoveEvaluation(
    position: position,
    winPotential: wouldWin ? 1000 * endgameBoost : 0,
    blockPotential: wouldBlock ? 500 * endgameBoost : 0,
    strategicValue: strategicValue,
  );
}

// ---------- Public API ----------

int findBestMove({
  required List<CellValue> board,
  required Player? currentPlayer,
  required int gridSize,
  required Map<Player, List<PowerUp>> storedPowerUps,
  required PowerUp? currentPowerUp,
  required Player? humanPlayer,
}) {
  final available = getValidMoves(board);
  if (available.isEmpty) return -1;

  final evals = available.map((pos) {
    return evaluateMove(
      board: board,
      position: pos,
      currentPlayer: currentPlayer,
      gridSize: gridSize,
      storedPowerUps: storedPowerUps,
      currentPowerUp: currentPowerUp,
      humanPlayer: humanPlayer,
    );
  }).toList();

  evals.sort((a, b) {
    final wCmp = b.winPotential.compareTo(a.winPotential);
    if (wCmp != 0) return wCmp;
    final bCmp = b.blockPotential.compareTo(a.blockPotential);
    if (bCmp != 0) return bCmp;
    return b.strategicValue.compareTo(a.strategicValue);
  });

  return evals.first.position;
}

double _calculateStealValue(
  List<CellValue> board,
  int targetPosition,
  Player computer,
  Player opponent,
  int gridSize,
) {
  double value = 0;
  final row = targetPosition ~/ gridSize;
  final col = targetPosition % gridSize;

  const directions = [
    (dr: 0, dc: 1),
    (dr: 1, dc: 0),
    (dr: 1, dc: 1),
    (dr: 1, dc: -1),
  ];

  for (final d in directions) {
    int opponentCount = 1;
    int emptyCount = 0;

    for (int i = 1; i < 5; i++) {
      final nr = row + d.dr * i;
      final nc = col + d.dc * i;
      if (nr < 0 || nr >= gridSize || nc < 0 || nc >= gridSize) break;
      final pos = nr * gridSize + nc;
      if (board[pos].owner == opponent) {
        opponentCount++;
      } else if (board[pos].owner == null && !board[pos].isFrozen) {
        emptyCount++;
      } else {
        break;
      }
    }
    for (int i = 1; i < 5; i++) {
      final nr = row - d.dr * i;
      final nc = col - d.dc * i;
      if (nr < 0 || nr >= gridSize || nc < 0 || nc >= gridSize) break;
      final pos = nr * gridSize + nc;
      if (board[pos].owner == opponent) {
        opponentCount++;
      } else if (board[pos].owner == null && !board[pos].isFrozen) {
        emptyCount++;
      } else {
        break;
      }
    }

    if (opponentCount >= 4) {
      value += 200;
    } else if (opponentCount == 3 && emptyCount >= 1) {
      value += 100;
    } else if (opponentCount == 2 && emptyCount >= 2) {
      value += 30;
    }
  }
  return value;
}

List<int> _findOpponentTilesInWinningSequence(
  List<CellValue> board,
  int mustBlockPosition,
  Player opponent,
  int boardSize,
) {
  final row = mustBlockPosition ~/ boardSize;
  final col = mustBlockPosition % boardSize;
  final tiles = <int>{};

  const directions = [
    (dr: 0, dc: 1),
    (dr: 1, dc: 0),
    (dr: 1, dc: 1),
    (dr: 1, dc: -1),
  ];

  for (final d in directions) {
    final inDir = <int>[];
    for (int i = 1; i <= 4; i++) {
      final nr = row + d.dr * i;
      final nc = col + d.dc * i;
      if (nr < 0 || nr >= boardSize || nc < 0 || nc >= boardSize) break;
      final pos = nr * boardSize + nc;
      if (board[pos].owner == opponent && !board[pos].isProtected) {
        inDir.add(pos);
      } else if (board[pos].owner != opponent) {
        break;
      }
    }
    for (int i = 1; i <= 4; i++) {
      final nr = row - d.dr * i;
      final nc = col - d.dc * i;
      if (nr < 0 || nr >= boardSize || nc < 0 || nc >= boardSize) break;
      final pos = nr * boardSize + nc;
      if (board[pos].owner == opponent && !board[pos].isProtected) {
        inDir.add(pos);
      } else if (board[pos].owner != opponent) {
        break;
      }
    }
    if (inDir.length >= 4) tiles.addAll(inDir);
  }
  return tiles.toList();
}

/// Full advanced move selection: power-up orchestration + tile placement.
ComputerMoveResult advancedFindBestMove({
  required List<CellValue> board,
  required Player? currentPlayer,
  required int gridSize,
  required Map<Player, List<PowerUp>> storedPowerUps,
  required PowerUp? currentPowerUp,
  required Player? humanPlayer,
}) {
  final opponent =
      currentPlayer == Player.x ? Player.o : Player.x;
  final computer = currentPlayer;
  final available = getValidMoves(board);
  final opponentHasOffense =
      _opponentHasOffensivePowerUps(storedPowerUps, opponent);

  // 1. Can we win immediately?
  for (final pos in available) {
    if (wouldCreateWin(board, pos, computer!, gridSize)) {
      return ComputerMoveResult(type: 'tile', position: pos);
    }
  }

  // 2. Must-block detection
  int mustBlock = -1;
  int criticalThreatPos = -1;
  double maxThreat = 0;

  for (final pos in available) {
    if (wouldCreateWin(board, pos, opponent, gridSize)) {
      mustBlock = pos;
      break;
    }
    final sim = List<CellValue>.from(board);
    sim[pos] = sim[pos].copyWith(owner: () => opponent);
    final threat = checkNearWinSequences(sim, pos, opponent, gridSize);
    if (threat >= 10 && threat > maxThreat) {
      maxThreat = threat;
      criticalThreatPos = pos;
    }
  }

  if (mustBlock != -1) {
    // Try power-ups to block
    final myPowerUps = storedPowerUps[computer!] ?? [];
    final hasFreeze = (currentPowerUp?.type == PowerUpType.freeze) ||
        myPowerUps.any((p) => p.isAvailable && p.type == PowerUpType.freeze);
    if (hasFreeze) {
      return ComputerMoveResult(
          type: 'powerup', position: mustBlock, powerUpType: PowerUpType.freeze);
    }

    final hasSteal = (currentPowerUp?.type == PowerUpType.steal) ||
        myPowerUps.any((p) => p.isAvailable && p.type == PowerUpType.steal);
    if (hasSteal) {
      final seqTiles =
          _findOpponentTilesInWinningSequence(board, mustBlock, opponent, gridSize);
      if (seqTiles.isNotEmpty) {
        return ComputerMoveResult(
            type: 'powerup',
            position: seqTiles.first,
            powerUpType: PowerUpType.steal);
      }
    }

    final hasBomb = (currentPowerUp?.type == PowerUpType.bomb) ||
        myPowerUps.any((p) => p.isAvailable && p.type == PowerUpType.bomb);
    if (hasBomb) {
      final seqTiles =
          _findOpponentTilesInWinningSequence(board, mustBlock, opponent, gridSize);
      if (seqTiles.isNotEmpty) {
        return ComputerMoveResult(
            type: 'powerup',
            position: seqTiles.first,
            powerUpType: PowerUpType.bomb);
      }
    }

    return ComputerMoveResult(type: 'tile', position: mustBlock);
  }

  // Critical threat (4-in-a-row with open end)
  if (maxThreat >= 100 && criticalThreatPos != -1) {
    return ComputerMoveResult(type: 'tile', position: criticalThreatPos);
  }

  // 2.5 Combo threat defense (opponent power-up + placement immediate wins)
  if (computer != null && opponentHasOffense) {
    final comboThreats = <int>{
      ..._simulateStealComboThreats(
        board: board,
        computer: computer,
        opponent: opponent,
        gridSize: gridSize,
        storedPowerUps: storedPowerUps,
      ),
      ..._simulateBombComboThreats(
        board: board,
        computer: computer,
        opponent: opponent,
        gridSize: gridSize,
        storedPowerUps: storedPowerUps,
      ),
      ..._simulateFireComboThreats(
        board: board,
        opponent: opponent,
        gridSize: gridSize,
        storedPowerUps: storedPowerUps,
      ),
    };

    if (comboThreats.isNotEmpty) {
      final myPowerUps = storedPowerUps[computer] ?? [];
      final hasFortify = (currentPowerUp?.type == PowerUpType.fortify) ||
          myPowerUps.any((p) => p.isAvailable && p.type == PowerUpType.fortify);
      if (hasFortify) {
        final protectableTargets = comboThreats.where((pos) {
          final cell = board[pos];
          return cell.owner == computer && !cell.isProtected;
        }).toList();

        if (protectableTargets.isNotEmpty) {
          protectableTargets.sort((a, b) => checkNearWinSequences(
                board,
                b,
                computer,
                gridSize,
              ).compareTo(checkNearWinSequences(board, a, computer, gridSize)));
          return ComputerMoveResult(
            type: 'powerup',
            position: protectableTargets.first,
            powerUpType: PowerUpType.fortify,
          );
        }
      }

      final hasFreeze = (currentPowerUp?.type == PowerUpType.freeze) ||
          myPowerUps.any((p) => p.isAvailable && p.type == PowerUpType.freeze);
      if (hasFreeze) {
        final freezableTargets = comboThreats.where((pos) {
          final cell = board[pos];
          return cell.owner == null && !cell.isFrozen;
        }).toList();

        if (freezableTargets.isNotEmpty) {
          freezableTargets.sort((a, b) => checkNearWinSequences(
                board,
                b,
                opponent,
                gridSize,
              ).compareTo(checkNearWinSequences(board, a, opponent, gridSize)));
          return ComputerMoveResult(
            type: 'powerup',
            position: freezableTargets.first,
            powerUpType: PowerUpType.freeze,
          );
        }
      }

      final blockByTile = comboThreats.firstWhere(
        available.contains,
        orElse: () => -1,
      );
      if (blockByTile != -1) {
        return ComputerMoveResult(type: 'tile', position: blockByTile);
      }
    }
  }

  // 3. Aggressive power-up usage
  final totalTiles = board.length;
  final occupied = board.where((c) => c.owner != null).length;
  final gameProgress = occupied / totalTiles;

  final myPowerUps = storedPowerUps[computer!] ?? [];
  final hasSteal = (currentPowerUp?.type == PowerUpType.steal) ||
      myPowerUps.any((p) => p.isAvailable && p.type == PowerUpType.steal);
  final hasBomb = (currentPowerUp?.type == PowerUpType.bomb) ||
      myPowerUps.any((p) => p.isAvailable && p.type == PowerUpType.bomb);
  final hasFreeze = (currentPowerUp?.type == PowerUpType.freeze) ||
      myPowerUps.any((p) => p.isAvailable && p.type == PowerUpType.freeze);
  final hasFortify = (currentPowerUp?.type == PowerUpType.fortify) ||
      myPowerUps.any((p) => p.isAvailable && p.type == PowerUpType.fortify);

  if (hasSteal) {
    final targets = <int>[];
    for (int i = 0; i < board.length; i++) {
      if (board[i].owner == opponent && !board[i].isProtected) targets.add(i);
    }
    if (targets.isNotEmpty) {
      final scored = targets.map((idx) {
        final defVal = _calculateStealValue(board, idx, computer, opponent, gridSize);
        final blocksWin = _wouldBlockOpponentWin(board, idx, opponent, gridSize);
        final sim = List<CellValue>.from(board);
        sim[idx] = sim[idx].copyWith(owner: () => computer);
        final offVal = checkNearWinSequences(sim, idx, computer, gridSize);
        return (
          position: idx,
          blocksWin: blocksWin,
          total: defVal + offVal + (blocksWin ? 120 : 0)
        );
      }).toList()
        ..sort((a, b) {
          if (a.blocksWin != b.blocksWin) return b.blocksWin ? 1 : -1;
          return b.total.compareTo(a.total);
        });

      final threshold = gameProgress < 0.2 ? 8.0 : 5.0;
      if (scored.first.total >= threshold) {
        return ComputerMoveResult(
            type: 'powerup',
            position: scored.first.position,
            powerUpType: PowerUpType.steal);
      }
    }
  }

  if (hasBomb) {
    final targets = <int>[];
    for (int i = 0; i < board.length; i++) {
      if (board[i].owner == opponent && !board[i].isProtected) targets.add(i);
    }
    if (targets.isNotEmpty) {
      final scored = targets
          .map((idx) => (
                position: idx,
                blocksWin: _wouldBlockOpponentWin(board, idx, opponent, gridSize),
                value: _calculateStealValue(board, idx, computer, opponent, gridSize),
              ))
          .toList()
        ..sort((a, b) {
          if (a.blocksWin != b.blocksWin) return b.blocksWin ? 1 : -1;
          return b.value.compareTo(a.value);
        });

      final threshold = gameProgress < 0.2 ? 15.0 : 10.0;
      if (scored.first.value >= threshold) {
        return ComputerMoveResult(
            type: 'powerup',
            position: scored.first.position,
            powerUpType: PowerUpType.bomb);
      }
    }
  }

  if (hasFreeze) {
    final empties = <int>[];
    for (int i = 0; i < board.length; i++) {
      if (board[i].owner == null && !board[i].isFrozen) empties.add(i);
    }
    if (empties.isNotEmpty) {
      final scored = empties.map((idx) {
        final sim = List<CellValue>.from(board);
        sim[idx] = sim[idx].copyWith(owner: () => opponent);
        final val = checkNearWinSequences(sim, idx, opponent, gridSize);
        return (position: idx, value: val);
      }).toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (scored.first.value >= 15) {
        return ComputerMoveResult(
            type: 'powerup',
            position: scored.first.position,
            powerUpType: PowerUpType.freeze);
      }
    }
  }

  if (hasFortify) {
    final ours = <int>[];
    for (int i = 0; i < board.length; i++) {
      if (board[i].owner == computer && !board[i].isProtected) ours.add(i);
    }
    if (ours.isNotEmpty) {
      final criticalBlockingTiles = _findCriticalBlockingTiles(
        board,
        computer,
        opponent,
        gridSize,
      );
      if (criticalBlockingTiles.isNotEmpty) {
        criticalBlockingTiles.sort((a, b) => checkNearWinSequences(
              board,
              b,
              computer,
              gridSize,
            ).compareTo(checkNearWinSequences(board, a, computer, gridSize)));
        return ComputerMoveResult(
          type: 'powerup',
          position: criticalBlockingTiles.first,
          powerUpType: PowerUpType.fortify,
        );
      }

      final scored = ours
          .map((idx) => (
                position: idx,
                value: checkNearWinSequences(board, idx, computer, gridSize),
              ))
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final threshold = opponentHasOffense ? 5.0 : 20.0;
      if (scored.first.value >= threshold) {
        return ComputerMoveResult(
            type: 'powerup',
            position: scored.first.position,
            powerUpType: PowerUpType.fortify);
      }
    }
  }

  // 4. Offensive tile play — forks
  final forks = detectForkOpportunities(board, computer, gridSize);
  if (forks.isNotEmpty) {
    return ComputerMoveResult(type: 'tile', position: forks.first);
  }

  // 5. Best offensive move
  final offensiveMoves = available.map((pos) {
    final sim = List<CellValue>.from(board);
    sim[pos] = sim[pos].copyWith(owner: () => computer);
    final threat = checkNearWinSequences(sim, pos, computer, gridSize);
    final adj = countNearbyTiles(board, pos, computer, gridSize);
    return (position: pos, value: threat + adj * 5);
  }).toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  if (offensiveMoves.isNotEmpty && offensiveMoves.first.value >= 15) {
    final best = offensiveMoves.first.value;
    final topTier = offensiveMoves.where((m) => m.value == best).toList();
    final chosen = topTier[Random().nextInt(topTier.length)];
    return ComputerMoveResult(type: 'tile', position: chosen.position);
  }

  // 6. Defensive blocking
  final opponentForks = detectForkOpportunities(board, opponent, gridSize);
  if (opponentForks.isNotEmpty) {
    return ComputerMoveResult(type: 'tile', position: opponentForks.first);
  }

  if (maxThreat >= 40 && criticalThreatPos != -1) {
    return ComputerMoveResult(type: 'tile', position: criticalThreatPos);
  }

  // 7. Fallback
  if (offensiveMoves.isNotEmpty) {
    final best = offensiveMoves.first.value;
    final topTier = offensiveMoves.where((m) => m.value == best).toList();
    final chosen = topTier[Random().nextInt(topTier.length)];
    return ComputerMoveResult(type: 'tile', position: chosen.position);
  }

  final idx = Random().nextInt(available.length);
  return ComputerMoveResult(type: 'tile', position: available[idx]);
}
