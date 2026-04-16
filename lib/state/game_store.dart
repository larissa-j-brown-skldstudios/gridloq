import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/game_models.dart';
import '../logic/game_logic.dart';
import '../logic/power_up_logic.dart';
import '../logic/computer_player.dart';

class GameStore extends ChangeNotifier {
  // ----- State -----
  int _gridSize = 10;
  late List<CellValue> _board;
  Player? _currentPlayer = Player.x;
  Player? _winner;
  bool _gameOver = false;
  int _currentTurn = 1;
  TurnPhase _currentPhase = TurnPhase.powerUpDecision;
  int? _lastMove;
  List<int>? _winningLine;
  bool _isComputerPlayer = true;
  Player? _humanPlayer;
  PowerUp? _currentPowerUp;
  Map<Player, List<PowerUp>> _storedPowerUps = {Player.x: [], Player.o: []};
  bool _computerPowerupUsed = false;
  String? _errorMessage;
  bool _gameStarted = false;

  // ----- Getters -----
  int get gridSize => _gridSize;
  List<CellValue> get board => _board;
  Player? get currentPlayer => _currentPlayer;
  Player? get winner => _winner;
  bool get gameOver => _gameOver;
  int get currentTurn => _currentTurn;
  TurnPhase get currentPhase => _currentPhase;
  int? get lastMove => _lastMove;
  List<int>? get winningLine => _winningLine;
  bool get isComputerPlayer => _isComputerPlayer;
  Player? get humanPlayer => _humanPlayer;
  PowerUp? get currentPowerUp => _currentPowerUp;
  Map<Player, List<PowerUp>> get storedPowerUps => _storedPowerUps;
  String? get errorMessage => _errorMessage;
  bool get gameStarted => _gameStarted;

  bool get isCurrentPlayerHuman {
    return _humanPlayer == _currentPlayer;
  }

  GameStore() {
    _board = generateBoard(_gridSize);
  }

  // ----- Actions -----

  void setGridSize(int size) {
    _gridSize = size;
    _board = generateBoard(size);
    _currentPlayer = Player.x;
    _winner = null;
    _gameOver = false;
    _currentTurn = 1;
    _storedPowerUps = {Player.x: [], Player.o: []};
    _currentPowerUp = null;
    _currentPhase = TurnPhase.tilePlacement;
    _gameStarted = false;
    notifyListeners();
  }

  void startGame({required Player humanChoice}) {
    _board = generateBoard(_gridSize);
    _currentPlayer = Player.x;
    _winner = null;
    _gameOver = false;
    _currentTurn = 1;
    _humanPlayer = humanChoice;
    _isComputerPlayer = true;
    _storedPowerUps = {Player.x: [], Player.o: []};
    _computerPowerupUsed = false;
    _lastMove = null;
    _winningLine = null;
    _errorMessage = null;
    _gameStarted = true;

    _currentPowerUp = generateSmartPowerUp(
      board: _board,
      currentPlayer: _currentPlayer,
      gridSize: _gridSize,
      storedPowerUps: _storedPowerUps,
    );
    _currentPhase = TurnPhase.powerUpDecision;

    notifyListeners();

    // If computer goes first, trigger its move
    if (_humanPlayer != Player.x) {
      _scheduleComputerMove();
    }
  }

  void playAgain() {
    final hp = _humanPlayer;
    if (hp != null) {
      startGame(humanChoice: hp);
    }
  }

  void resetGame() {
    _board = generateBoard(_gridSize);
    _currentPlayer = Player.x;
    _winner = null;
    _gameOver = false;
    _currentTurn = 1;
    _storedPowerUps = {Player.x: [], Player.o: []};
    _currentPowerUp = null;
    _currentPhase = TurnPhase.tilePlacement;
    _humanPlayer = null;
    _isComputerPlayer = true;
    _gameStarted = false;
    _lastMove = null;
    _winningLine = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Player decides to store current power-up (skip using it)
  void storePowerUpAndSkip() {
    if (_currentPhase != TurnPhase.powerUpDecision) return;
    if (_currentPowerUp == null || _currentPlayer == null) return;

    final playerPowerUps = _storedPowerUps[_currentPlayer!] ?? [];
    final alreadyStored =
        playerPowerUps.any((powerUp) => powerUp.id == _currentPowerUp!.id);
    if (!alreadyStored && playerPowerUps.length < 5) {
      _storedPowerUps[_currentPlayer!] = [...playerPowerUps, _currentPowerUp!];
    }
    _currentPowerUp = null;
    _currentPhase = TurnPhase.tilePlacement;
    notifyListeners();
  }

  // Player chooses to use the current (or a stored) power-up
  void selectPowerUpToUse(PowerUp powerUp) {
    if (_gameOver) return;
    if (_currentPlayer == null) return;

    if (!canUsePowerUpNow(powerUp)) {
      // If this is the current offered power-up, auto-store it and continue.
      if (_currentPhase == TurnPhase.powerUpDecision &&
          _currentPowerUp?.id == powerUp.id) {
        final playerPowerUps = _storedPowerUps[_currentPlayer!] ?? [];
        final alreadyStored = playerPowerUps.any((p) => p.id == powerUp.id);
        if (!alreadyStored && playerPowerUps.length < 5) {
          _storedPowerUps[_currentPlayer!] = [...playerPowerUps, powerUp];
        }
        _currentPowerUp = null;
      } else {
        // For stored power-ups with no valid targets, just cancel usage attempt.
        _currentPowerUp = null;
      }
      _currentPhase = TurnPhase.tilePlacement;
      _errorMessage = 'No valid targets for ${powerUp.type.name.toUpperCase()} right now.';
      notifyListeners();
      return;
    }

    _errorMessage = null;
    _currentPowerUp = powerUp;
    _currentPhase = TurnPhase.powerUpAction;
    notifyListeners();
  }

  // Exit action mode and continue the turn without consuming the selected power-up.
  void cancelPowerUpAction() {
    if (_currentPhase != TurnPhase.powerUpAction) return;
    _currentPhase = TurnPhase.tilePlacement;
    notifyListeners();
  }

  void applyPowerUp(int position) {
    if (_currentPowerUp == null || _currentPlayer == null) return;
    if (position < 0 || position >= _board.length) return;
    final pu = _currentPowerUp!;
    final cell = _board[position];

    if (!_isValidPowerUpTarget(pu, cell, _currentPlayer!)) {
      _errorMessage = 'That tile is not a valid target for ${pu.type.name.toUpperCase()}.';
      notifyListeners();
      return;
    }

    switch (pu.type) {
      case PowerUpType.bomb:
        _board[position] = CellValue.empty();
        break;

      case PowerUpType.steal:
        _board[position] = cell.copyWith(owner: () => _currentPlayer, lastMove: true);
        break;

      case PowerUpType.freeze:
        _board[position] = cell.copyWith(isFrozen: true, freezeTurns: 6);
        break;

      case PowerUpType.fire:
        _board[position] = cell.copyWith(isFrozen: false, freezeTurns: 0);
        break;

      case PowerUpType.fortify:
        _board[position] = cell.copyWith(isProtected: true, protectionTurns: 6);
        break;
    }

    // Remove from stored if it came from there
    final playerPowerUps = _storedPowerUps[_currentPlayer!] ?? [];
    _storedPowerUps[_currentPlayer!] =
        playerPowerUps.where((p) => p.id != pu.id).toList();

    _currentPowerUp = null;
    _currentPhase = TurnPhase.tilePlacement;
    _errorMessage = null;

    // Check win after steal
    if (pu.type == PowerUpType.steal) {
      _checkWinner();
      if (_gameOver) {
        notifyListeners();
        return;
      }
    }

    notifyListeners();
  }

  void makeMove(int position) {
    if (_gameOver) return;
    if (_currentPlayer == null) return;
    if (position < 0 || position >= _board.length) return;
    if (_board[position].owner != null) return;
    if (_board[position].isFrozen) return;

    // Place tile
    for (int i = 0; i < _board.length; i++) {
      if (_board[i].lastMove) {
        _board[i] = _board[i].copyWith(lastMove: false);
      }
    }
    _board[position] = _board[position].copyWith(
      owner: () => _currentPlayer,
      lastMove: true,
    );
    _lastMove = position;

    // Update timers
    _board = updateProtectionTimers(updateFreezeTimers(_board));

    // Check winner
    _checkWinner();
    if (_gameOver) {
      notifyListeners();
      return;
    }

    // Store unused power-up
    if (_currentPowerUp != null && _currentPlayer != null) {
      final pups = _storedPowerUps[_currentPlayer!] ?? [];
      final alreadyStored = pups.any((powerUp) => powerUp.id == _currentPowerUp!.id);
      if (!alreadyStored && pups.length < 5) {
        _storedPowerUps[_currentPlayer!] = [...pups, _currentPowerUp!];
      }
    }

    // Switch turn
    final next = _currentPlayer == Player.x ? Player.o : Player.x;
    _currentPlayer = next;
    _currentTurn++;
    _computerPowerupUsed = false;

    // Generate power-up for next player
    _currentPowerUp = generateSmartPowerUp(
      board: _board,
      currentPlayer: _currentPlayer,
      gridSize: _gridSize,
      storedPowerUps: _storedPowerUps,
      currentTurn: _currentTurn,
    );
    _currentPhase = TurnPhase.powerUpDecision;

    // Stalemate check
    if (!_canPlayerMakeMove()) {
      _gameOver = true;
      _winner = null;
      _currentPhase = TurnPhase.turnEnd;
      notifyListeners();
      return;
    }

    notifyListeners();

    // Trigger computer move if needed
    if (_humanPlayer != _currentPlayer && _isComputerPlayer) {
      _scheduleComputerMove();
    }
  }

  // ----- Internal helpers -----

  void _checkWinner() {
    final w = getWinningPlayer(_board, _currentPlayer, _gridSize);
    if (w != null) {
      _winner = w;
      _gameOver = true;
      _winningLine = checkWinCondition(_board, w, _gridSize);
      _currentPhase = TurnPhase.turnEnd;
    }
  }

  bool _canPlayerMakeMove() {
    if (_board.any((c) => c.owner == null && !c.isFrozen)) return true;
    if (_currentPlayer == null) return false;
    final opponent = _currentPlayer!.opponent;

    final hasBomb = (_currentPowerUp?.type == PowerUpType.bomb) ||
        (_storedPowerUps[_currentPlayer!] ?? [])
            .any((p) => p.type == PowerUpType.bomb && p.isAvailable);
    if (hasBomb && _board.any((c) => c.owner == opponent && !c.isProtected)) {
      return true;
    }

    final hasSteal = (_currentPowerUp?.type == PowerUpType.steal) ||
        (_storedPowerUps[_currentPlayer!] ?? [])
            .any((p) => p.type == PowerUpType.steal && p.isAvailable);
    if (hasSteal && _board.any((c) => c.owner == opponent && !c.isProtected)) {
      return true;
    }

    final hasFire = (_currentPowerUp?.type == PowerUpType.fire) ||
        (_storedPowerUps[_currentPlayer!] ?? [])
            .any((p) => p.type == PowerUpType.fire && p.isAvailable);
    if (hasFire && _board.any((c) => c.isFrozen)) return true;

    return false;
  }

  bool canUsePowerUpNow(PowerUp powerUp) {
    if (_currentPlayer == null) return false;
    return _board.any((cell) => _isValidPowerUpTarget(powerUp, cell, _currentPlayer!));
  }

  bool _isValidPowerUpTarget(PowerUp powerUp, CellValue cell, Player actingPlayer) {
    switch (powerUp.type) {
      case PowerUpType.bomb:
      case PowerUpType.steal:
        return cell.owner != null &&
            cell.owner != actingPlayer &&
            !cell.isProtected;
      case PowerUpType.freeze:
        return cell.owner == null && !cell.isFrozen;
      case PowerUpType.fire:
        return cell.isFrozen;
      case PowerUpType.fortify:
        return cell.owner == actingPlayer && !cell.isProtected;
    }
  }

  void _scheduleComputerMove() {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (_gameOver || _currentPlayer == _humanPlayer) return;

      final result = advancedFindBestMove(
        board: _board,
        currentPlayer: _currentPlayer,
        gridSize: _gridSize,
        storedPowerUps: _storedPowerUps,
        currentPowerUp: _currentPowerUp,
        humanPlayer: _humanPlayer,
      );

      if (result.position == -1) return;

      if (result.type == 'powerup' &&
          result.powerUpType != null &&
          !_computerPowerupUsed) {
        // Find the power-up to use
        PowerUp? puToUse;
        if (_currentPowerUp?.type == result.powerUpType) {
          puToUse = _currentPowerUp;
        } else {
          final computerPlayer =
              _humanPlayer == Player.x ? Player.o : Player.x;
          puToUse = (_storedPowerUps[computerPlayer] ?? []).cast<PowerUp?>().firstWhere(
            (p) => p!.type == result.powerUpType && p.isAvailable,
            orElse: () => null,
          );
        }

        if (puToUse != null) {
          _computerPowerupUsed = true;
          _currentPowerUp = puToUse;
          applyPowerUp(result.position);

          // Then place a tile
          Future.delayed(const Duration(milliseconds: 400), () {
            if (_gameOver || _currentPlayer == _humanPlayer) return;
            final tilePos = findBestMove(
              board: _board,
              currentPlayer: _currentPlayer,
              gridSize: _gridSize,
              storedPowerUps: _storedPowerUps,
              currentPowerUp: _currentPowerUp,
              humanPlayer: _humanPlayer,
            );
            if (tilePos != -1) {
              makeMove(tilePos);
            }
          });
        } else {
          // Fallback to tile
          final tilePos = findBestMove(
            board: _board,
            currentPlayer: _currentPlayer,
            gridSize: _gridSize,
            storedPowerUps: _storedPowerUps,
            currentPowerUp: _currentPowerUp,
            humanPlayer: _humanPlayer,
          );
          if (tilePos != -1) {
            makeMove(tilePos);
          }
        }
      } else {
        makeMove(result.position);
      }
    });
  }
}
