import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/account_model.dart';
import 'package:pocketledger/services/account_service.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AccountService accountService = AccountService();
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? 'Not Logged In';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textBlack),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('Accounts', style: GoogleFonts.outfit(color: AppColors.textBlack, fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryGreen, size: 28),
            onPressed: () => Navigator.pushNamed(context, '/add-account'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<AccountModel>>(
              stream: accountService.getAccounts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
                }

                final accounts = snapshot.data ?? [];
                double totalBalance = 0;
                for (var acc in accounts) totalBalance += acc.totalBalance;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildPremiumSummaryHeader(totalBalance),
                    ),
                    if (accounts.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(context),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildPremiumAccountCard(context, accounts[index]),
                            childCount: accounts.length,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          // Debug Info
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[100],
            width: double.infinity,
            child: Text(
              'Debug UID: $currentUid',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSummaryHeader(double total) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.primaryGreen.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: AppColors.primaryGreen.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Text('Total Balance', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 16)),
          const SizedBox(height: 12),
          Text(
            '৳ ${total.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},")}',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Across all your accounts', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.6), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPremiumAccountCard(BuildContext context, AccountModel account) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(16)),
                  child: Icon(
                    account.type == 'Bank' ? Icons.account_balance : Icons.account_balance_wallet,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.name, style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(account.type, style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13)),
                    ],
                  ),
                ),
                Text(
                  '৳${account.totalBalance.toInt()}',
                  style: GoogleFonts.outfit(color: AppColors.primaryGreen, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(color: AppColors.borderLight, height: 1),
            ),
            ...account.breakdown.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.accentGold, shape: BoxShape.circle)),
                          const SizedBox(width: 10),
                          Text(entry.key, style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 15)),
                        ],
                      ),
                      Text('৳${entry.value.toInt()}', style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 100, color: AppColors.surfaceLight),
          const SizedBox(height: 24),
          Text('No accounts found', style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Try adding a new account to see it here', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 14)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/add-account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text('Create First Account', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
