import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/game_store.dart';
import '../models/game_models.dart';

class PowerUpBar extends StatelessWidget {
  const PowerUpBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameStore>(
      builder: (context, store, _) {
        if (store.gameOver || !store.isCurrentPlayerHuman) {
          return const SizedBox.shrink();
        }

        final storedList =
            store.storedPowerUps[store.humanPlayer ?? Player.x] ?? [];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current power-up offered this turn
              if (store.currentPowerUp != null &&
                  store.currentPhase == TurnPhase.powerUpDecision)
                _buildCurrentPowerUp(context, store),

              // Action-mode hint
              if (store.currentPhase == TurnPhase.powerUpAction &&
                  store.currentPowerUp != null)
                _buildActionHint(context, store),

              // Stored power-ups
              if (storedList.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildStoredPowerUps(context, store, storedList),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentPowerUp(BuildContext context, GameStore store) {
    final pu = store.currentPowerUp!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _colorForType(pu.type).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _colorForType(pu.type).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(_iconForType(pu.type),
              color: _colorForType(pu.type), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${pu.type.name.toUpperCase()} — Use or store?',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          TextButton(
            onPressed: () => store.selectPowerUpToUse(pu),
            child: const Text('USE',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => store.storePowerUpAndSkip(),
            child: Text('STORE',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.5))),
          ),
        ],
      ),
    );
  }

  Widget _buildActionHint(BuildContext context, GameStore store) {
    final pu = store.currentPowerUp!;
    String hint;
    switch (pu.type) {
      case PowerUpType.bomb:
        hint = 'Tap an opponent tile to destroy it';
      case PowerUpType.steal:
        hint = 'Tap an opponent tile to steal it';
      case PowerUpType.freeze:
        hint = 'Tap an empty tile to freeze it';
      case PowerUpType.fire:
        hint = 'Tap a frozen tile to melt it';
      case PowerUpType.fortify:
        hint = 'Tap your tile to protect it';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _colorForType(pu.type).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(_iconForType(pu.type),
              color: _colorForType(pu.type), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => store.storePowerUpAndSkip(),
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildStoredPowerUps(
    BuildContext context,
    GameStore store,
    List<PowerUp> storedList,
  ) {
    final canUse = store.currentPhase == TurnPhase.powerUpDecision ||
        store.currentPhase == TurnPhase.tilePlacement;

    return Row(
      children: [
        Text(
          'STORED',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(width: 8),
        ...storedList.map((pu) {
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: canUse ? () => store.selectPowerUpToUse(pu) : null,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _colorForType(pu.type).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _colorForType(pu.type).withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Icon(
                    _iconForType(pu.type),
                    size: 16,
                    color: _colorForType(pu.type),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Color _colorForType(PowerUpType type) {
    switch (type) {
      case PowerUpType.bomb:
        return const Color(0xFFEF4444);
      case PowerUpType.steal:
        return const Color(0xFFA855F7);
      case PowerUpType.freeze:
        return const Color(0xFF38BDF8);
      case PowerUpType.fire:
        return const Color(0xFFF97316);
      case PowerUpType.fortify:
        return const Color(0xFF22D3EE);
    }
  }

  IconData _iconForType(PowerUpType type) {
    switch (type) {
      case PowerUpType.bomb:
        return Icons.rocket_launch;
      case PowerUpType.steal:
        return Icons.pan_tool;
      case PowerUpType.freeze:
        return Icons.ac_unit;
      case PowerUpType.fire:
        return Icons.bolt;
      case PowerUpType.fortify:
        return Icons.shield;
    }
  }
}
