import 'package:flutter_test/flutter_test.dart';
import 'package:gridloq/logic/power_up_logic.dart';
import 'package:gridloq/models/game_models.dart';

CellValue _owned(Player owner) => CellValue.empty().copyWith(owner: () => owner);
CellValue _empty() => CellValue.empty();

List<CellValue> _gridlockLikeBoard5x5() {
  // 16 occupied cells in alternating pattern (>= 60% filled) and no obvious one-move win.
  final board = List<CellValue>.filled(25, _empty(), growable: false).toList();
  for (int i = 0; i < 16; i++) {
    final owner = i.isEven ? Player.x : Player.o;
    board[i] = _owned(owner);
  }
  return board;
}

void main() {
  group('detectGridlockRisk', () {
    test('returns true for high-fill late-game deadlock setup', () {
      final board = _gridlockLikeBoard5x5();
      final result = detectGridlockRisk(
        board: board,
        gridSize: 5,
        currentTurn: 8,
        storedPowerUps: const {
          Player.x: <PowerUp>[],
          Player.o: <PowerUp>[],
        },
      );

      expect(result, isTrue);
    });

    test('returns false when a one-move win exists', () {
      final board = _gridlockLikeBoard5x5();
      // Set up XXXX_ on top row for X.
      board[0] = _owned(Player.x);
      board[1] = _owned(Player.x);
      board[2] = _owned(Player.x);
      board[3] = _owned(Player.x);
      board[4] = _empty();

      final result = detectGridlockRisk(
        board: board,
        gridSize: 5,
        currentTurn: 8,
        storedPowerUps: const {
          Player.x: <PowerUp>[],
          Player.o: <PowerUp>[],
        },
      );

      expect(result, isFalse);
    });

    test('returns false when offensive power-ups are already available', () {
      final board = _gridlockLikeBoard5x5();
      final result = detectGridlockRisk(
        board: board,
        gridSize: 5,
        currentTurn: 8,
        storedPowerUps: {
          Player.x: const [PowerUp(id: 'x-bomb', type: PowerUpType.bomb)],
          Player.o: const [PowerUp(id: 'o-steal', type: PowerUpType.steal)],
        },
      );

      expect(result, isFalse);
    });
  });

  group('generateSmartPowerUp', () {
    test('returns only bomb or steal when gridlock risk is true', () {
      final board = _gridlockLikeBoard5x5();
      final powerUp = generateSmartPowerUp(
        board: board,
        currentPlayer: Player.x,
        gridSize: 5,
        storedPowerUps: const {
          Player.x: <PowerUp>[],
          Player.o: <PowerUp>[],
        },
        currentTurn: 8,
      );

      expect(
        powerUp.type == PowerUpType.bomb || powerUp.type == PowerUpType.steal,
        isTrue,
      );
    });
  });
}
