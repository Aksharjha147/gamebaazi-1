import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/wallet.dart';
import '../../utils/colors.dart';
import '../../widgets/bet_panel.dart';

class MinesScreen extends StatefulWidget {
  const MinesScreen({super.key});

  @override
  State<MinesScreen> createState() => _MinesScreenState();
}

class _MinesScreenState extends State<MinesScreen> {
  final TextEditingController _betController = TextEditingController(text: '10.00');
  int _mineCount = 3;
  double _currentMultiplier = 1.0;
  bool _isPlaying = false;
  bool _gameOver = false;
  
  List<bool> _isMine = List.filled(25, false);
  List<bool> _revealed = List.filled(25, false);
  int _gemsFound = 0;

  void _startGame() {
    double betAmount = double.tryParse(_betController.text) ?? 0.0;
    if (betAmount <= 0) return;

    final wallet = context.read<WalletProvider>();
    if (!wallet.placeBet(betAmount)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient demo balance!'), backgroundColor: AppColors.danger)
      );
      return;
    }

    _isMine = List.filled(25, false);
    _revealed = List.filled(25, false);
    _gemsFound = 0;
    _currentMultiplier = 1.0;

    int minesPlaced = 0;
    final random = Random();
    while (minesPlaced < _mineCount) {
      int idx = random.nextInt(25);
      if (!_isMine[idx]) {
        _isMine[idx] = true;
        minesPlaced++;
      }
    }

    setState(() {
      _isPlaying = true;
      _gameOver = false;
    });
  }

  void _revealTile(int index) {
    if (!_isPlaying || _gameOver || _revealed[index]) return;

    setState(() {
      _revealed[index] = true;
      if (_isMine[index]) {
        _gameOver = true;
        _isPlaying = false;
        for (int i = 0; i < 25; i++) {
          if (_isMine[i]) _revealed[i] = true;
        }
      } else {
        _gemsFound++;
        _currentMultiplier = _calculateMultiplier(_mineCount, _gemsFound);
      }
    });

    if (_gemsFound == (25 - _mineCount)) {
      _cashOut();
    }
  }

  double _calculateMultiplier(int mines, int gems) {
    double n = 25;
    double k = mines.toDouble();
    double j = gems.toDouble();
    
    double mult = 0.99;
    for (int i = 0; i < j; i++) {
      mult *= (n - i) / (n - k - i);
    }
    return mult;
  }

  void _cashOut() {
    if (!_isPlaying || _gameOver || _gemsFound == 0) return;

    double betAmount = double.tryParse(_betController.text) ?? 0.0;
    final wallet = context.read<WalletProvider>();
    wallet.addWinnings(betAmount * _currentMultiplier);

    setState(() {
      _gameOver = true;
      _isPlaying = false;
      for (int i = 0; i < 25; i++) {
        _revealed[i] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MINES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 800;

          Widget gridArea = Container(
            color: AppColors.background.withOpacity(0.5),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildGrid(),
                  ],
                ),
              ),
            ),
          );

          if (isMobile) {
            return Column(
              children: [
                Expanded(child: gridArea),
                SingleChildScrollView(child: _buildMobileControls()),
              ],
            );
          }

          return Row(
            children: [
              _buildDesktopSidebar(),
              const VerticalDivider(width: 1, color: AppColors.inputBorder),
              Expanded(child: gridArea),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGrid() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: 25,
        itemBuilder: (context, index) {
          bool isRevealed = _revealed[index];
          bool isMine = _isMine[index];
          
          return GestureDetector(
            onTap: () => _revealTile(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isRevealed 
                    ? (isMine ? AppColors.danger.withOpacity(0.2) : AppColors.cardColor) 
                    : AppColors.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isRevealed 
                      ? (isMine ? AppColors.danger : AppColors.primary) 
                      : AppColors.inputBorder,
                  width: 2,
                ),
                boxShadow: isRevealed && !isMine ? AppColors.glowPrimary : null,
              ),
              child: Center(
                child: isRevealed
                    ? Icon(
                        isMine ? Icons.local_fire_department : Icons.diamond,
                        color: isMine ? AppColors.danger : AppColors.primary,
                        size: 32,
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return SizedBox(
      width: 320,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMineSelector(),
            const SizedBox(height: 20),
            if (_isPlaying)
              _buildCashoutButton()
            else
              BetPanel(
                betAmountController: _betController,
                multiplier: _currentMultiplier,
                onBet: _startGame,
                buttonText: 'Bet',
              ),
          ],
        ),
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
          if (!_isPlaying) _buildMineSelector(),
          const SizedBox(height: 12),
          if (_isPlaying)
            _buildCashoutButton()
          else
            BetPanel(
              betAmountController: _betController,
              multiplier: _currentMultiplier,
              onBet: _startGame,
            ),
        ],
      ),
    );
  }

  Widget _buildMineSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mines', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.inputBorder, width: 2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _mineCount,
              isExpanded: true,
              dropdownColor: AppColors.cardColor,
              items: List.generate(24, (i) => i + 1).map((m) {
                return DropdownMenuItem(
                  value: m,
                  child: Text('$m Mines', style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              }).toList(),
              onChanged: _isPlaying ? null : (val) => setState(() => _mineCount = val!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCashoutButton() {
    return InkWell(
      onTap: _gemsFound > 0 ? _cashOut : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(8),
          boxShadow: AppColors.glowPrimary,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'CASH OUT',
                style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.background, letterSpacing: 1.5),
              ),
              Text(
                '${(_currentMultiplier * (double.tryParse(_betController.text) ?? 0)).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.background, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
