import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class BetPanel extends StatefulWidget {
  final TextEditingController betAmountController;
  final double multiplier;
  final VoidCallback onBet;
  final bool isBetting;
  final String buttonText;

  const BetPanel({
    super.key,
    required this.betAmountController,
    required this.multiplier,
    required this.onBet,
    this.isBetting = false,
    this.buttonText = 'Bet',
  });

  @override
  State<BetPanel> createState() => _BetPanelState();
}

class _BetPanelState extends State<BetPanel> {
  @override
  void initState() {
    super.initState();
    widget.betAmountController.addListener(_updateState);
  }

  @override
  void dispose() {
    widget.betAmountController.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double betAmount = double.tryParse(widget.betAmountController.text) ?? 0.0;
    double possibleWin = betAmount * widget.multiplier;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Bet Amount'),
                const SizedBox(height: 8),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.inputBorder, width: 2),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.attach_money, color: AppColors.textMuted, size: 18),
                      ),
                      Expanded(
                        child: TextField(
                          controller: widget.betAmountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '0.00',
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintStyle: TextStyle(color: AppColors.textMuted),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                      ),
                      _buildQuickBetButton('½', () {
                        double current = double.tryParse(widget.betAmountController.text) ?? 0;
                        widget.betAmountController.text = (current / 2).toStringAsFixed(2);
                      }),
                      const VerticalDivider(width: 1, color: AppColors.inputBorder, indent: 8, endIndent: 8),
                      _buildQuickBetButton('2x', () {
                        double current = double.tryParse(widget.betAmountController.text) ?? 0;
                        widget.betAmountController.text = (current * 2).toStringAsFixed(2);
                      }),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildLabel('Profit on Win'),
                const SizedBox(height: 8),
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.inputBorder, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '\$${possibleWin.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.trending_up, color: AppColors.primary, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isBetting ? null : widget.onBet,
                borderRadius: BorderRadius.circular(8),
                child: Ink(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: widget.isBetting ? null : AppColors.primaryGradient,
                    color: widget.isBetting ? AppColors.inputBorder : null,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: widget.isBetting ? [] : AppColors.glowPrimary,
                  ),
                  child: Center(
                    child: widget.isBetting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textMuted),
                            ),
                          )
                        : Text(
                            widget.buttonText.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.background,
                              letterSpacing: 1.5,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildQuickBetButton(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            color: AppColors.textLight,
          ),
        ),
      ),
    );
  }
}
