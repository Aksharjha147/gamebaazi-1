import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/wallet.dart';
import '../../utils/colors.dart';
import '../../widgets/bet_panel.dart';

class CrashScreen extends StatefulWidget {
  const CrashScreen({super.key});

  @override
  State<CrashScreen> createState() => _CrashScreenState();
}

class _CrashScreenState extends State<CrashScreen> {
  final TextEditingController _betController = TextEditingController(text: '10.00');
  double _currentMultiplier = 1.0;
  double _crashPoint = 0.0;
  bool _isPlaying = false;
  bool _crashed = false;
  bool _cashedOut = false;
  Timer? _timer;
  List<double> _history = [];
  final List<Offset> _points = [];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _generateCrashPoint() {
    double random = Random().nextDouble();
    // 1% instant crash at 1.00x, otherwise exponential-ish distribution
    if (random < 0.01) {
      _crashPoint = 1.00;
    } else {
      _crashPoint = 0.99 / (1.0 - random);
    }
  }

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

    _generateCrashPoint();
    _points.clear();
    _points.add(const Offset(0, 0));
    
    setState(() {
      _currentMultiplier = 1.0;
      _isPlaying = true;
      _crashed = false;
      _cashedOut = false;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        if (_currentMultiplier < _crashPoint) {
          // Faster growth as it gets higher
          double increment = 0.005 * _currentMultiplier;
          _currentMultiplier += increment;
          
          // Add point for graph
          double x = _points.length.toDouble();
          double y = (_currentMultiplier - 1.0) * 100; // scaling for graph
          _points.add(Offset(x, y));
        } else {
          _currentMultiplier = _crashPoint;
          _crashed = true;
          _isPlaying = false;
          _history.insert(0, _crashPoint);
          if (_history.length > 15) _history.removeLast();
          timer.cancel();
        }
      });
    });
  }

  void _cashOut() {
    if (!_isPlaying || _cashedOut || _crashed) return;

    double betAmount = double.tryParse(_betController.text) ?? 0.0;
    final wallet = context.read<WalletProvider>();
    wallet.addWinnings(betAmount * _currentMultiplier);

    setState(() {
      _cashedOut = true;
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRASH', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: _buildGraphArea(),
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
          double val = _history[index];
          Color color = val >= 2.0 ? AppColors.primary : AppColors.danger;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Center(
              child: Text(
                '${val.toStringAsFixed(2)}x',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGraphArea() {
    return AspectRatio(
      aspectRatio: 1.5,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.inputBorder, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Simple grid lines
            CustomPaint(
              size: Size.infinite,
              painter: GridPainter(),
            ),
            // The Curve
            if (_points.isNotEmpty)
              CustomPaint(
                size: Size.infinite,
                painter: CurvePainter(points: _points, isCrashed: _crashed),
              ),
            // Multiplier Text
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 100, // Constrain height to help scaleDown
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${_currentMultiplier.toStringAsFixed(2)}x',
                        style: TextStyle(
                          fontSize: 84,
                          fontWeight: FontWeight.w900,
                          color: _crashed ? AppColors.danger : (_cashedOut ? AppColors.primary : Colors.white),
                          shadows: [
                            Shadow(
                              color: (_crashed ? AppColors.danger : (_cashedOut ? AppColors.primary : Colors.white)).withOpacity(0.3),
                              blurRadius: 20,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_crashed)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: const Text(
                        'CRASHED',
                        style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 4),
                      ),
                    ),
                  if (_cashedOut && !_crashed)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'CASHED OUT',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 4),
                      ),
                    ),
                ],
              ),
            ),
          ],
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
          if (_isPlaying && !_cashedOut)
            _buildCashoutButton()
          else
            BetPanel(
              betAmountController: _betController,
              multiplier: 0, // Not used for crash in BetPanel display
              onBet: _startGame,
              isBetting: _isPlaying,
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
      child: _isPlaying && !_cashedOut 
          ? _buildCashoutButton() 
          : BetPanel(
              betAmountController: _betController,
              multiplier: 0,
              onBet: _startGame,
              isBetting: _isPlaying,
            ),
    );
  }

  Widget _buildCashoutButton() {
    return InkWell(
      onTap: _cashOut,
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

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.inputBorder.withOpacity(0.2)
      ..strokeWidth = 1;

    for (double i = 0; i <= size.width; i += size.width / 10) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i <= size.height; i += size.height / 10) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CurvePainter extends CustomPainter {
  final List<Offset> points;
  final bool isCrashed;

  CurvePainter({required this.points, required this.isCrashed});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = isCrashed ? AppColors.danger : AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Scale points to fit canvas
    double maxX = points.length.toDouble();
    if (maxX < 100) maxX = 100; // Minimum width view
    
    double maxY = 200; // Base scaling
    for (var p in points) {
      if (p.dy > maxY) maxY = p.dy;
    }
    maxY *= 1.2; // Add some padding

    path.moveTo(0, size.height);
    
    for (int i = 0; i < points.length; i++) {
      double x = (points[i].dx / maxX) * size.width;
      double y = size.height - (points[i].dy / maxY) * size.height;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
    
    // Gradient fill under the curve
    final fillPath = Path.from(path)
      ..lineTo((points.last.dx / maxX) * size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          (isCrashed ? AppColors.danger : AppColors.primary).withOpacity(0.3),
          (isCrashed ? AppColors.danger : AppColors.primary).withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CurvePainter oldDelegate) => true;
}
