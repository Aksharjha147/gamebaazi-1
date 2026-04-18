import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../../models/wallet.dart';
import '../../utils/colors.dart';
import '../../widgets/bet_panel.dart';

class DiceScreen extends StatefulWidget {
  const DiceScreen({super.key});

  @override
  State<DiceScreen> createState() => _DiceScreenState();
}

class _DiceScreenState extends State<DiceScreen> {
  final TextEditingController _betController = TextEditingController(text: '10.00');
  double _targetValue = 50.0; // The number to roll under
  double _rollResult = 50.0;
  bool _isRolling = false;
  bool _lastWin = false;
  List<Map<String, dynamic>> _history = [];

  double get _winChance => _targetValue;
  double get _multiplier => 99.0 / _targetValue;

  void _rollDice() async {
    double betAmount = double.tryParse(_betController.text) ?? 0.0;
    if (betAmount <= 0) return;

    final wallet = context.read<WalletProvider>();
    if (!wallet.placeBet(betAmount, game: 'Dice')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance!'), backgroundColor: AppColors.danger)
      );
      return;
    }

    setState(() {
      _isRolling = true;
    });

    // Simulate rolling animation delay
    await Future.delayed(const Duration(milliseconds: 500));

    final roll = Random().nextDouble() * 100;
    bool isWin = roll < _targetValue;

    if (isWin) {
      wallet.addWinnings(betAmount * _multiplier, game: 'Dice');
    }

    if (mounted) {
      setState(() {
        _rollResult = roll;
        _lastWin = isWin;
        _isRolling = false;
        _history.insert(0, {'val': roll, 'win': isWin});
        if (_history.length > 10) _history.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DICE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.textMuted),
            onPressed: () => setState(() => _history.clear()),
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 800;
          
          Widget gameContent = Container(
            color: AppColors.background.withOpacity(0.5),
            child: Column(
              children: [
                // History pills
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _history.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      double val = item['val'];
                      bool win = item['win'];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: win ? AppColors.primary.withOpacity(0.2) : AppColors.danger.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: win ? AppColors.primary : AppColors.danger, width: 1),
                        ),
                        child: Center(
                          child: Text(
                            val.toStringAsFixed(2),
                            style: TextStyle(
                              color: win ? AppColors.primary : AppColors.danger,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDiceDisplay(),
                          const SizedBox(height: 60),
                          _buildSliderArea(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );

          if (isMobile) {
            return Column(
              children: [
                Expanded(child: gameContent),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BetPanel(
                    betAmountController: _betController,
                    multiplier: _multiplier,
                    onBet: _rollDice,
                    isBetting: _isRolling,
                  ),
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: BetPanel(
                    betAmountController: _betController,
                    multiplier: _multiplier,
                    onBet: _rollDice,
                    isBetting: _isRolling,
                  ),
                ),
              ),
              const VerticalDivider(width: 1, color: AppColors.inputBorder),
              Expanded(child: gameContent),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDiceDisplay() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: _isRolling ? AppColors.inputBorder : (_lastWin ? AppColors.primary : AppColors.danger),
          width: 4,
        ),
        boxShadow: _isRolling ? [] : (_lastWin ? AppColors.glowPrimary : AppColors.glowDanger),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 120,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _rollResult.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 96,
                  fontWeight: FontWeight.w900,
                  color: _lastWin ? AppColors.primary : AppColors.danger,
                  letterSpacing: -2,
                  shadows: [
                    Shadow(color: (_lastWin ? AppColors.primary : AppColors.danger).withOpacity(0.5), blurRadius: 30)
                  ],
                ),
              ),
            ),
          ),
          Text(
            _isRolling ? 'ROLLING...' : (_lastWin ? 'WIN' : 'LOSS'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: _isRolling ? AppColors.textMuted : (_lastWin ? AppColors.primary : AppColors.danger).withOpacity(0.7),
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderArea() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.inputBorder, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatTile('Multiplier', '${_multiplier.toStringAsFixed(4)}x'),
              _buildStatTile('Win Chance', '${_winChance.toStringAsFixed(2)}%', isPrimary: true),
            ],
          ),
          const SizedBox(height: 32),
          Column(
            children: [
              const Text(
                'ROLL UNDER',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              Stack(
                alignment: Alignment.center,
                children: [
                  // Custom track background
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: const [
                          AppColors.primary,
                          AppColors.danger,
                        ],
                        stops: [_targetValue / 100, _targetValue / 100],
                      ),
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.transparent,
                      inactiveTrackColor: Colors.transparent,
                      thumbColor: Colors.white,
                      overlayColor: AppColors.primary.withOpacity(0.2),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14, elevation: 6),
                      trackHeight: 16,
                    ),
                    child: Slider(
                      value: _targetValue,
                      min: 2.0,
                      max: 98.0,
                      onChanged: (val) {
                        setState(() {
                          _targetValue = val;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLabel('0'),
              _buildLabel('25'),
              _buildLabel('50'),
              _buildLabel('75'),
              _buildLabel('100'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w900, fontSize: 12),
    );
  }

  Widget _buildStatTile(String label, String value, {bool isPrimary = false}) {
    return Column(
      crossAxisAlignment: isPrimary ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isPrimary ? AppColors.primary : AppColors.textLight,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
