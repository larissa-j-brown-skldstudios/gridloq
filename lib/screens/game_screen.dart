import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/game_store.dart';
import '../models/game_models.dart';
import '../widgets/game_board.dart';
import '../widgets/game_status_bar.dart';
import '../widgets/power_up_bar.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GRIDLOQ',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            context.read<GameStore>().resetGame();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Consumer<GameStore>(
        builder: (context, store, _) {
          return SafeArea(
            child: Column(
              children: [
                const GameStatusBar(),
                const SizedBox(height: 8),
                const PowerUpBar(),
                const SizedBox(height: 8),
                Expanded(child: const GameBoard()),
                if (store.gameOver) _buildGameOverBar(context, store),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameOverBar(BuildContext context, GameStore store) {
    final message = store.winner != null
        ? '${store.winner!.symbol} wins!'
        : 'Draw!';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => store.playAgain(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Play Again',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
