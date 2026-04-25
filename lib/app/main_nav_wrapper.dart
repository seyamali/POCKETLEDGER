import 'package:flutter/material.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/features/dashboard/dashboard_screen.dart';
import 'package:pocketledger/features/accounts/accounts_screen.dart';

class MainNavWrapper extends StatefulWidget {
  const MainNavWrapper({super.key});

  @override
  State<MainNavWrapper> createState() => _MainNavWrapperState();
}

class _MainNavWrapperState extends State<MainNavWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AccountsScreen(),
    const Center(child: Text('Transactions Coming Soon', style: TextStyle(color: AppColors.primaryText))),
    const Center(child: Text('Loans Coming Soon', style: TextStyle(color: AppColors.primaryText))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildPremiumBottomNav(),
    );
  }

  Widget _buildPremiumBottomNav() {
    return Container(
      height: 85,
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.home_filled, 'Home'),
          _navItem(1, Icons.account_balance_wallet_outlined, 'Accounts'),
          _navItem(2, Icons.receipt_long_outlined, 'Records'),
          _navItem(3, Icons.handshake_outlined, 'Loans'),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final bool isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? AppColors.primaryGreen : AppColors.textGrey, size: 24),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11, 
              color: isActive ? AppColors.primaryGreen : AppColors.textGrey, 
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              letterSpacing: 0.2,
            )),
          ],
        ),
      ),
    );
  }
}
