import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/wallet.dart';
import '../utils/colors.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String month = months[date.month - 1];
    String day = date.day.toString().padLeft(2, '0');
    String year = date.year.toString();
    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');
    return '$month $day, $year • $hour:$minute';
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('LIVE SUPPORT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('For assistance, please reach out to us:', style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 20),
            _buildContactRow(Icons.email_rounded, 'aksharjha65@gmail.com', true),
            const SizedBox(height: 12),
            _buildContactRow(Icons.phone_rounded, '+91 456789123', false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text, bool isSelectable) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: isSelectable 
            ? SelectableText(
                text, 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)
              )
            : Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _showDepositDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('DEPOSIT FUNDS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter amount to deposit via UPI / Card', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Enter Amount',
                hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.toll_rounded, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () {
              double? amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                context.read<WalletProvider>().deposit(amount);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Successfully deposited \$${amount.toStringAsFixed(2)}'), backgroundColor: AppColors.primary),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.background),
            child: const Text('DEPOSIT NOW'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'PROFILE',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildUserHeader(user),
            const SizedBox(height: 24),
            _buildWalletCard(context, wallet.balance),
            const SizedBox(height: 24),
            _buildStatsGrid(wallet),
            const SizedBox(height: 24),
            _buildMenuSection(context, wallet),
            const SizedBox(height: 40),
            _buildLogoutButton(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(User? user) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: AppColors.neonGlow(AppColors.primary),
              ),
              child: CircleAvatar(
                radius: 45,
                backgroundColor: AppColors.cardDark,
                backgroundImage: (user?.photoURL != null) ? NetworkImage(user!.photoURL!) : null,
                child: (user?.photoURL == null) 
                  ? const Icon(Icons.person_rounded, size: 50, color: AppColors.textMuted)
                  : null,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, size: 14, color: AppColors.background),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user?.displayName ?? user?.phoneNumber ?? 'Guest User',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildWalletCard(BuildContext context, double balance) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.inputBorder.withOpacity(0.5)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Balance', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
              Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary.withOpacity(0.5), size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.toll_rounded, color: AppColors.primary, size: 28),
              const SizedBox(width: 10),
              Text(
                balance.toStringAsFixed(2),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton('DEPOSIT', Icons.add_rounded, AppColors.primary, onTap: () => _showDepositDialog(context)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton('WITHDRAW', Icons.remove_rounded, AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, {VoidCallback? onTap}) {
    bool isPrimary = color == AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary ? null : Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isPrimary ? AppColors.background : Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? AppColors.background : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(WalletProvider wallet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: [
          _buildStatCard('Total Wagered', '\$${wallet.totalWagered.toStringAsFixed(0)}', Icons.bar_chart_rounded, AppColors.secondary),
          _buildStatCard('Total Wins', wallet.totalWins.toString(), Icons.emoji_events_rounded, AppColors.warning),
          _buildStatCard('Biggest Win', '\$${wallet.biggestWin.toStringAsFixed(0)}', Icons.trending_up_rounded, AppColors.primary),
          _buildStatCard('Games Played', wallet.gamesPlayed.toString(), Icons.sports_esports_rounded, AppColors.info),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 18, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, WalletProvider wallet) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.inputBorder.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            Icons.history_rounded, 
            'Transaction History', 
            'View your deposits and withdrawals',
            onTap: () => _showTransactionHistory(context, wallet),
          ),
          _buildDivider(),
          _buildMenuItem(Icons.security_rounded, 'Security & Privacy', 'Password, 2FA, and sessions'),
          _buildDivider(),
          _buildMenuItem(Icons.notifications_none_rounded, 'Notifications', 'Manage your alerts'),
          _buildDivider(),
          _buildMenuItem(
            Icons.support_agent_rounded, 
            'Live Support', 
            'Get help from our team',
            onTap: () => _showSupportDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: AppColors.inputBorder.withOpacity(0.3), indent: 16, endIndent: 16);
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextButton(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          try {
            await GoogleSignIn().signOut();
          } catch (e) {
            debugPrint("Error signing out from Google: $e");
          }
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        },
        style: TextButton.styleFrom(
          foregroundColor: AppColors.danger,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.danger.withOpacity(0.3)),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 20),
            SizedBox(width: 8),
            Text('LOG OUT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }

  void _showTransactionHistory(BuildContext context, WalletProvider wallet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            final transactions = wallet.transactions;
            
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.inputBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'TRANSACTION HISTORY',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: transactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_rounded, size: 64, color: AppColors.textMuted.withOpacity(0.2)),
                              const SizedBox(height: 16),
                              Text('No transactions yet', style: TextStyle(color: AppColors.textMuted.withOpacity(0.5))),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            final isPositive = tx.amount > 0;
                            
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (isPositive ? AppColors.primary : AppColors.danger).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isPositive ? Icons.add_rounded : Icons.remove_rounded,
                                  color: isPositive ? AppColors.primary : AppColors.danger,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                tx.description,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                _formatDate(tx.date),
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                              trailing: Text(
                                '${isPositive ? "+" : ""}${tx.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: isPositive ? AppColors.primary : Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
