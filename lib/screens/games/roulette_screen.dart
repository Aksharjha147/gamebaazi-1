import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../../models/wallet.dart';
import '../../utils/colors.dart';
import '../../widgets/bet_panel.dart';

class RouletteScreen extends StatefulWidget {
  const RouletteScreen({super.key});

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _betController = TextEditingController(text: '10.00');
  String _selectedColor = 'Red'; 
  double _multiplier = 2.0;
  
  int? _resultRoll;
  String? _resultColor;
  bool _isSpinning = false;
  bool _lastWin = false;
  List<Map<String, dynamic>> _history = [];

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setColor(String color, double multiplier) {
    if (_isSpinning) return;
    setState(() {
      _selectedColor = color;
      _multiplier = multiplier;
    });
  }

  void _spin() async {
    double betAmount = double.tryParse(_betController.text) ?? 0.0;
    if (betAmount <= 0) return;

    final wallet = context.read<WalletProvider>();
    if (!wallet.placeBet(betAmount)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient demo balance!'), backgroundColor: AppColors.danger)
      );
      return;
    }

    setState(() {
      _isSpinning = true;
      _resultRoll = null;
    });

    _animationController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 2000));

    final roll = Random().nextInt(15); 
    String rolledColor;
    if (roll == 0) {
      rolledColor = 'Green';
    } else if (roll <= 7) {
      rolledColor = 'Red';
    } else {
      rolledColor = 'Black';
    }

    bool isWin = rolledColor == _selectedColor;

    if (isWin) {
      wallet.addWinnings(betAmount * _multiplier);
    }

    setState(() {
      _resultRoll = roll;
      _resultColor = rolledColor;
      _lastWin = isWin;
      _isSpinning = false;
      _history.insert(0, {'roll': roll, 'color': rolledColor});
      if (_history.length > 15) _history.removeLast();
    });
  }

  Color _getColorValue(String? color) {
    if (color == 'Red') return AppColors.danger;
    if (color == 'Black') return const Color(0xFF2F4553);
    if (color == 'Green') return AppColors.primary;
    return AppColors.inputBorder;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cardDark,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 24,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.bolt,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'ROULETTE',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 800;

          Widget gameArea = Container(
            color: AppColors.background.withOpacity(0.5),
            child: Column(
              children: [
                _buildHistoryBar(),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildWheel(),
                          if (!_isSpinning && _resultRoll != null) ...[
                            const SizedBox(height: 32),
                            _buildResultMessage(),
                          ],
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
                Expanded(child: gameArea),
                _buildMobileControls(),
              ],
            );
          }

          return Row(
            children: [
              _buildDesktopSidebar(),
              const VerticalDivider(width: 1, color: AppColors.inputBorder),
              Expanded(child: gameArea),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryBar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _history.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _history[index];
          Color color = _getColorValue(item['color']);
          return Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Center(
              child: Text(
                '${item['roll']}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWheel() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animationController.value * 10 * pi,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.inputBorder, width: 8),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 5),
                if (!_isSpinning && _resultRoll != null)
                  BoxShadow(color: _getColorValue(_resultColor).withOpacity(0.4), blurRadius: 40, spreadRadius: 10),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ...List.generate(15, (index) {
                  return Transform.rotate(
                    angle: (index * 2 * pi / 15),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        height: 40,
                        width: 4,
                        color: Colors.white10,
                      ),
                    ),
                  );
                }),
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: _isSpinning ? AppColors.cardColor : _getColorValue(_resultColor),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white10, width: 4),
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: -_animationController.value * 10 * pi,
                      child: _isSpinning
                          ? const Text(
                              'SPINNING',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            )
                          : (_resultRoll != null
                              ? Text(
                                  '$_resultRoll',
                                  style: const TextStyle(
                                    fontSize: 72,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                )
                              : Image.asset(
                                  'assets/images/logo.png',
                                  height: 80,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.bolt,
                                    color: AppColors.primary,
                                    size: 60,
                                  ),
                                )),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: _lastWin ? AppColors.primary.withOpacity(0.1) : AppColors.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _lastWin ? AppColors.primary : AppColors.danger, width: 2),
      ),
      child: Text(
        _lastWin ? 'WINNER!' : 'LOSE',
        style: TextStyle(
          color: _lastWin ? AppColors.primary : AppColors.danger,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildColorSelectors(),
          const SizedBox(height: 20),
          BetPanel(
            betAmountController: _betController,
            multiplier: _multiplier,
            onBet: _spin,
            isBetting: _isSpinning,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildColorSelectors(),
          const SizedBox(height: 12),
          BetPanel(
            betAmountController: _betController,
            multiplier: _multiplier,
            onBet: _spin,
            isBetting: _isSpinning,
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelectors() {
    return Row(
      children: [
        Expanded(child: _buildColorButton('Red', 2.0, AppColors.danger)),
        const SizedBox(width: 8),
        Expanded(child: _buildColorButton('Green', 14.0, AppColors.primary)),
        const SizedBox(width: 8),
        Expanded(child: _buildColorButton('Black', 2.0, const Color(0xFF2F4553))),
      ],
    );
  }

  Widget _buildColorButton(String color, double mult, Color uiColor) {
    bool isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () => _setColor(color, mult),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? uiColor : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.white : AppColors.inputBorder,
            width: 2,
          ),
          boxShadow: isSelected ? [BoxShadow(color: uiColor.withOpacity(0.3), blurRadius: 10)] : [],
        ),
        child: Column(
          children: [
            Text(
              color.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : AppColors.textMuted,
                fontSize: 12,
              ),
            ),
            Text(
              '${mult}x',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white70 : AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
