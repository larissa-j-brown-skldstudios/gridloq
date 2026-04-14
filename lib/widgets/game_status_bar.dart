import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/game_store.dart';
import '../models/game_models.dart';

class GameStatusBar extends StatelessWidget {
  const GameStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameStore>(
      builder: (context, store, _) {
        String statusText;
        Color statusColor;

        if (store.gameOver) {
          if (store.winner != null) {
            final isHumanWin = store.winner == store.humanPlayer;
            statusText = isHumanWin ? 'You win!' : 'Computer wins!';
            statusColor = isHumanWin
                ? const Color(0xFF4ADE80)
                : const Color(0xFFFF6584);
          } else {
            statusText = 'Draw — no moves left';
            statusColor = Colors.amber;
          }
        } else {
          final isHumanTurn = store.isCurrentPlayerHuman;
          statusText = isHumanTurn ? 'Your turn (${store.currentPlayer!.symbol})'
              : 'Computer thinking...';
          statusColor = store.currentPlayer == Player.x
              ? const Color(0xFF6C63FF)
              : const Color(0xFFFF6584);
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              Text(
                'Turn ${store.currentTurn}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
