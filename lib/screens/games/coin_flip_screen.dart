import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../../models/wallet.dart';
import '../../utils/colors.dart';
import '../../widgets/bet_panel.dart';

class CoinFlipScreen extends StatefulWidget {
  const CoinFlipScreen({super.key});

  @override
  State<CoinFlipScreen> createState() => _CoinFlipScreenState();
}

class _CoinFlipScreenState extends State<CoinFlipScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _betController = TextEditingController(text: '10.00');
  String _selectedSide = 'Heads'; 
  String? _result;
  bool _isFlipping = false;
  bool _lastWin = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _flipCoin() async {
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
      _isFlipping = true;
      _result = null;
    });

    _animationController.repeat();
    await Future.delayed(const Duration(seconds: 1)); 

    final flip = Random().nextBool(); 
    String flippedSide = flip ? 'Heads' : 'Tails';
    bool isWin = flippedSide == _selectedSide;

    if (isWin) {
      wallet.addWinnings(betAmount * 1.98);
    }

    _animationController.stop();
    _animationController.reset();

    setState(() {
      _result = flippedSide;
      _lastWin = isWin;
      _isFlipping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('COIN FLIP', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 800;

          Widget gameArea = Container(
            color: AppColors.background.withOpacity(0.5),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCoinDisplay(),
                    if (_result != null && !_isFlipping) ...[
                      const SizedBox(height: 32),
                      _buildResultMessage(),
                    ],
                  ],
                ),
              ),
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

  Widget _buildCoinDisplay() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        double rotation = _isFlipping ? _animation.value * pi : (_result == 'Tails' ? pi : 0);
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(rotation),
          alignment: Alignment.center,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardDark,
              border: Border.all(color: AppColors.primary, width: 8),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 30, spreadRadius: 5),
              ],
              gradient: const LinearGradient(
                colors: [Color(0xFF2FAAF4), Color(0xFF1A2C38)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: rotation % (2 * pi) > pi / 2 && rotation % (2 * pi) < 3 * pi / 2
                ? Transform(
                    transform: Matrix4.identity()..rotateX(pi),
                    alignment: Alignment.center,
                    child: const Icon(Icons.monetization_on, size: 100, color: Colors.amber),
                  )
                : const Icon(Icons.face, size: 100, color: Colors.amber),
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
        _lastWin ? 'YOU WON!' : 'TRY AGAIN',
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
          _buildSideSelector(),
          const SizedBox(height: 20),
          BetPanel(
            betAmountController: _betController,
            multiplier: 1.98,
            onBet: _flipCoin,
            isBetting: _isFlipping,
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
          _buildSideSelector(),
          const SizedBox(height: 12),
          BetPanel(
            betAmountController: _betController,
            multiplier: 1.98,
            onBet: _flipCoin,
            isBetting: _isFlipping,
          ),
        ],
      ),
    );
  }

  Widget _buildSideSelector() {
    return Row(
      children: [
        Expanded(child: _buildSideButton('Heads')),
        const SizedBox(width: 8),
        Expanded(child: _buildSideButton('Tails')),
      ],
    );
  }

  Widget _buildSideButton(String side) {
    bool isSelected = _selectedSide == side;
    return GestureDetector(
      onTap: _isFlipping ? null : () => setState(() => _selectedSide = side),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.inputBorder,
            width: 2,
          ),
        ),
        child: Text(
          side.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isSelected ? AppColors.primary : AppColors.textMuted,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
