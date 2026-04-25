import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/services/account_service.dart';
import 'package:pocketledger/services/auth_service.dart';
import 'package:pocketledger/models/account_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AccountService _accountService = AccountService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            _buildBalanceHeader(),
            const SizedBox(height: 40),
            _buildQuickActionsGrid(),
            const SizedBox(height: 32),
            _buildSectionHeader('Accounts', onAdd: () {}),
            const SizedBox(height: 16),
            _buildAccountsCarousel(),
            const SizedBox(height: 32),
            _buildSectionHeader('Recent Transection', onAdd: null, actionLabel: 'See all'),
            const SizedBox(height: 16),
            _buildTransactionList(),
            const SizedBox(height: 120), // Space for floating nav
          ],
        ),
      ),
      extendBody: true,
      bottomNavigationBar: null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: const Icon(Icons.menu, color: AppColors.textBlack, size: 28),
      title: Image.asset('assets/images/logo.png', height: 32),
      centerTitle: true,
      actions: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            const Icon(Icons.notifications_none_outlined, color: AppColors.textBlack, size: 28),
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildBalanceHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Total Balance', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 16, fontWeight: FontWeight.w400)),
            const SizedBox(width: 8),
            const Icon(Icons.visibility_outlined, size: 20, color: AppColors.textGrey),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<AccountModel>>(
          stream: _accountService.getAccounts(),
          builder: (context, snapshot) {
            double total = 0;
            if (snapshot.hasData) for (var acc in snapshot.data!) total += acc.totalBalance;
            return Text(
              total.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},"),
              style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: -1),
            );
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_graph_rounded, size: 18, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              Text('View stats', style: GoogleFonts.outfit(color: AppColors.primaryGreen, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _actionItem('Add\nMoney', Icons.account_balance_wallet_outlined),
            _actionItem('Found\nTransfer', Icons.swap_horiz_outlined),
            _actionItem('Mobile\nTop Up', Icons.smartphone_outlined),
            _actionItem('Buy\nTicket', Icons.confirmation_number_outlined),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('See more', style: GoogleFonts.outfit(color: AppColors.textBlack, fontWeight: FontWeight.w500, fontSize: 14)),
            const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.textBlack),
          ],
        ),
      ],
    );
  }

  Widget _actionItem(String label, IconData icon) {
    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 28),
          const SizedBox(height: 10),
          Text(label, 
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textBlack, height: 1.2)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onAdd, String? actionLabel}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 20, fontWeight: FontWeight.bold)),
        if (onAdd != null) 
          GestureDetector(
            onTap: onAdd,
            child: Row(
              children: [
                const Icon(Icons.add, size: 16, color: AppColors.textGrey),
                const SizedBox(width: 4),
                Text('Add', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          )
        else if (actionLabel != null)
          Text(actionLabel, style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildAccountsCarousel() {
    return StreamBuilder<List<AccountModel>>(
      stream: _accountService.getAccounts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox();
        return SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final acc = snapshot.data![index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.surfaceLight, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryGreen.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('***** BDT', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textBlack)),
                        Icon(Icons.credit_card, size: 18, color: AppColors.primaryGreen.withOpacity(0.7)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Current - ${acc.name}', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 12)),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Open', style: GoogleFonts.outfit(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                        const Icon(Icons.call_made, size: 14, color: AppColors.textBlack),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTransactionList() {
    return Column(
      children: List.generate(3, (index) => Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.swap_horiz_rounded, color: AppColors.primaryGreen),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transfer', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textBlack)),
                  Text('Cr by FRSD @****5876', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('07/08/2023', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 12)),
                const SizedBox(height: 4),
                Text('+40,345.00', style: GoogleFonts.outfit(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      )),
    );
  }
}
