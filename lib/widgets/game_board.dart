import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/game_store.dart';
import '../models/game_models.dart';
import 'game_cell.dart';

class GameBoard extends StatelessWidget {
  const GameBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameStore>(
      builder: (context, store, _) {
        final size = store.gridSize;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: size,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                ),
                itemCount: size * size,
                itemBuilder: (context, index) {
                  return GameCell(
                    index: index,
                    cell: store.board[index],
                    isLastMove: store.lastMove == index,
                    isWinningCell:
                        store.winningLine?.contains(index) ?? false,
                    gridSize: size,
                    onTap: () => _handleCellTap(context, store, index),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleCellTap(BuildContext context, GameStore store, int index) {
    if (store.gameOver) return;
    if (!store.isCurrentPlayerHuman) return;

    if (store.currentPhase == TurnPhase.powerUpAction) {
      store.applyPowerUp(index);
      return;
    }

    if (store.currentPhase == TurnPhase.tilePlacement ||
        store.currentPhase == TurnPhase.powerUpDecision) {
      // If still in decision phase, auto-store the power-up first
      if (store.currentPhase == TurnPhase.powerUpDecision) {
        store.storePowerUpAndSkip();
      }
      store.makeMove(index);
    }
  }
}
