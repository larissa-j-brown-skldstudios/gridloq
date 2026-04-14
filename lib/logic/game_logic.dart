import '../models/game_models.dart';

const int minSequence = 5;

List<CellValue> generateBoard(int boardSize) {
  return List.generate(
    boardSize * boardSize,
    (_) => CellValue.empty(),
  );
}

List<int> getValidMoves(List<CellValue> board) {
  final moves = <int>[];
  for (int i = 0; i < board.length; i++) {
    if (board[i].owner == null && !board[i].isFrozen) {
      moves.add(i);
    }
  }
  return moves;
}

bool isValidMove(List<CellValue> board, int position) {
  if (position < 0 || position >= board.length) return false;
  return board[position].owner == null && !board[position].isFrozen;
}

bool wouldCreateWin(
  List<CellValue> board,
  int position,
  Player player,
  int boardSize,
) {
  final tempBoard = List<CellValue>.from(board);
  tempBoard[position] = tempBoard[position].copyWith(owner: () => player);
  return checkWinCondition(tempBoard, player, boardSize) != null;
}

List<int>? checkWinCondition(
  List<CellValue> board,
  Player player,
  int boardSize,
) {
  for (int pos = 0; pos < board.length; pos++) {
    if (board[pos].owner == player) {
      final sequences = findSequences(board, pos, boardSize);
      for (final sequence in sequences) {
        if (sequence.length >= minSequence) {
          return sequence;
        }
      }
    }
  }
  return null;
}

List<List<int>> findSequences(
  List<CellValue> board,
  int position,
  int boardSize,
) {
  final cell = board[position];
  if (cell.owner == null) return [];

  final row = position ~/ boardSize;
  final col = position % boardSize;
  final player = cell.owner!;
  final sequences = <List<int>>[];

  void addIfValid(List<int> seq) {
    if (seq.length >= minSequence) {
      sequences.add(List.from(seq));
    }
  }

  // Horizontal
  var sequence = [position];
  for (int c = col - 1; c >= 0; c--) {
    final pos = row * boardSize + c;
    if (board[pos].owner == player) {
      sequence.insert(0, pos);
    } else {
      break;
    }
  }
  for (int c = col + 1; c < boardSize; c++) {
    final pos = row * boardSize + c;
    if (board[pos].owner == player) {
      sequence.add(pos);
    } else {
      break;
    }
  }
  addIfValid(sequence);

  // Vertical
  sequence = [position];
  for (int r = row - 1; r >= 0; r--) {
    final pos = r * boardSize + col;
    if (board[pos].owner == player) {
      sequence.insert(0, pos);
    } else {
      break;
    }
  }
  for (int r = row + 1; r < boardSize; r++) {
    final pos = r * boardSize + col;
    if (board[pos].owner == player) {
      sequence.add(pos);
    } else {
      break;
    }
  }
  addIfValid(sequence);

  // Diagonal: top-left to bottom-right
  sequence = [position];
  for (int i = 1; row - i >= 0 && col - i >= 0; i++) {
    final pos = (row - i) * boardSize + (col - i);
    if (board[pos].owner == player) {
      sequence.insert(0, pos);
    } else {
      break;
    }
  }
  for (int i = 1; row + i < boardSize && col + i < boardSize; i++) {
    final pos = (row + i) * boardSize + (col + i);
    if (board[pos].owner == player) {
      sequence.add(pos);
    } else {
      break;
    }
  }
  addIfValid(sequence);

  // Diagonal: top-right to bottom-left
  sequence = [position];
  for (int i = 1; row - i >= 0 && col + i < boardSize; i++) {
    final pos = (row - i) * boardSize + (col + i);
    if (board[pos].owner == player) {
      sequence.insert(0, pos);
    } else {
      break;
    }
  }
  for (int i = 1; row + i < boardSize && col - i >= 0; i++) {
    final pos = (row + i) * boardSize + (col - i);
    if (board[pos].owner == player) {
      sequence.add(pos);
    } else {
      break;
    }
  }
  addIfValid(sequence);

  return sequences;
}

Player? getWinningPlayer(
  List<CellValue> board,
  Player? currentPlayer,
  int gridSize,
) {
  final xWins = checkWinCondition(board, Player.x, gridSize);
  final oWins = checkWinCondition(board, Player.o, gridSize);

  if (xWins != null && oWins != null) {
    return currentPlayer;
  }
  if (xWins != null) return Player.x;
  if (oWins != null) return Player.o;
  return null;
}
