import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../models/wallet.dart';
import '../utils/colors.dart';
import 'games/crash_screen.dart';
import 'games/dice_screen.dart';
import 'games/mines_screen.dart';
import 'games/coin_flip_screen.dart';
import 'games/roulette_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  int _selectedCategory = 0;
  final List<String> _categories = ['All', 'Originals', 'Slots', 'Live', 'New'];
  
  final ScrollController _tickerController = ScrollController();
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTicker());
  }

  void _startTicker() {
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_tickerController.hasClients) {
        double maxScroll = _tickerController.position.maxScrollExtent;
        double currentScroll = _tickerController.offset;
        if (currentScroll >= maxScroll) {
          _tickerController.jumpTo(0);
        } else {
          _tickerController.animateTo(
            currentScroll + 1,
            duration: const Duration(milliseconds: 50),
            curve: Curves.linear,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _tickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _buildBottomNavBar(),
      appBar: _selectedTab == 0 ? AppBar(
        backgroundColor: AppColors.cardDark,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 15,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
                boxShadow: AppColors.neonGlow(AppColors.primary),
              ),
              child: const Icon(Icons.bolt, color: AppColors.background, size: 18),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: ShaderMask(
                shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                child: const Text(
                  'GAMEBAAZI',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        actions: [
          _buildBalanceIndicator(wallet.balance),
          const SizedBox(width: 8),
          _buildWalletIcon(context),
          const SizedBox(width: 15),
        ],
      ) : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_selectedTab == 3) {
      return const ProfileScreen();
    }
    
    // Default Home Body
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.03),
              shape: BoxShape.circle,
            ),
          ),
        ),
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPremiumHero(),
              _buildCategoryTabs(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    _buildSectionHeader('POPULAR GAMES', Icons.star_rounded),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.8,
                      children: [
                        _buildSharpGameCard(context, 'Dice', Icons.casino, AppColors.primary, const DiceScreen(), 'Multiplayer'),
                        _buildSharpGameCard(context, 'Crash', Icons.rocket_launch, AppColors.danger, const CrashScreen(), 'High Stakes'),
                        _buildSharpGameCard(context, 'Mines', Icons.grid_view_rounded, AppColors.warning, const MinesScreen(), 'Classic'),
                        _buildSharpGameCard(context, 'Coin Flip', Icons.monetization_on, AppColors.secondary, const CoinFlipScreen(), 'Fast 50/50'),
                        _buildSharpGameCard(context, 'Roulette', Icons.refresh_rounded, AppColors.info, const RouletteScreen(), 'The Wheel'),
                        _buildComingSoonCard(),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 46,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedCategory == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.cardDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.inputBorder.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  _categories[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textMuted,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.textMuted.withOpacity(0.5)),
      ],
    );
  }

  Widget _buildBalanceIndicator(double balance) {
    return Center(
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.inputBorder, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              balance.toStringAsFixed(2),
              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.toll_rounded, color: AppColors.primary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletIcon(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => context.read<WalletProvider>().resetDemoMoney(),
        child: Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.inputBorder, width: 1.5),
          ),
          child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 18),
        ),
      ),
    );
  }

  Widget _buildPremiumHero() {
    return Container(
      height: 140,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF2FAAF4), Color(0xFF1D323F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -40,
            bottom: -40,
            child: Icon(Icons.rocket_launch, size: 180, color: Colors.white.withOpacity(0.05)),
          ),
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'GRAND OPENING',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2),
                ),
                SizedBox(height: 6),
                FittedBox(
                  child: Text(
                    'GET \$10,000 FREE CREDITS',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharpGameCard(BuildContext context, String title, IconData icon, Color color, Widget screen, String tag) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.inputBorder.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.15), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Icon(icon, size: 48, color: color, shadows: [Shadow(color: color.withOpacity(0.4), blurRadius: 20)]),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(color: AppColors.cardDark),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tag,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.inputBorder.withOpacity(0.1), width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_clock_rounded, color: AppColors.textMuted.withOpacity(0.2), size: 36),
            const SizedBox(height: 6),
            Text('COMING SOON', style: TextStyle(color: AppColors.textMuted.withOpacity(0.2), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 75,
      decoration: const BoxDecoration(
        color: AppColors.cardDark,
        border: Border(top: BorderSide(color: AppColors.inputBorder, width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavIcon(Icons.home_filled, 'Home', 0),
          _buildNavIcon(Icons.search_rounded, 'Search', 1),
          _buildNavIcon(Icons.account_balance_rounded, 'Vault', 2),
          _buildNavIcon(Icons.person_rounded, 'Profile', 3),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, String label, int index) {
    bool active = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? AppColors.primary : AppColors.textMuted, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: active ? AppColors.primary : AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
