import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/services/account_service.dart';
import 'package:pocketledger/services/auth_service.dart';
import 'package:pocketledger/models/account_model.dart';
import 'package:pocketledger/features/goals/monthly_goal_screen.dart';
import 'package:pocketledger/features/savings/savings_screen.dart';
import 'package:pocketledger/features/loans/loans_screen.dart';
import 'package:pocketledger/features/accounts/accounts_screen.dart';
import 'package:pocketledger/features/transactions/transactions_screen.dart';
import 'package:pocketledger/models/transaction_model.dart';
import 'package:pocketledger/features/auth/widgets/custom_text_field.dart';
import 'package:pocketledger/core/constants/app_constants.dart';
import 'package:pocketledger/core/utils/image_utils.dart';
import 'package:pocketledger/services/transaction_service.dart';
import 'package:pocketledger/services/loan_service.dart';
import 'package:pocketledger/models/loan_model.dart';
import 'package:pocketledger/features/profile/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AccountService _accountService = AccountService();
  final AuthService _authService = AuthService();
  final LoanService _loanService = LoanService();

  String _fmt(double v) => v.toInt().toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _go(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF4F6F5),
      body: StreamBuilder<List<AccountModel>>(
        stream: _accountService.getAccounts(),
        builder: (context, accSnapshot) {
          return StreamBuilder<List<LoanModel>>(
            stream: _loanService.getLoans(),
            builder: (context, loanSnapshot) {
              final accounts = accSnapshot.data ?? [];
              final loans = loanSnapshot.data ?? [];

              double grandTotal = 0;
              double savingsTotal = 0;
              Map<String, double> ownerTotals = {};
              // Per owner: list of (accountName, amount)
              Map<String, List<Map<String, dynamic>>> ownerAccounts = {};

              for (var acc in accounts) {
                if (acc.type == 'Savings') {
                  savingsTotal += acc.totalBalance;
                } else {
                  grandTotal += acc.totalBalance;
                  acc.breakdown.forEach((owner, amt) {
                    if (amt > 0) {
                      ownerTotals[owner] = (ownerTotals[owner] ?? 0) + amt;
                      ownerAccounts[owner] = (ownerAccounts[owner] ?? [])..add({'name': acc.name, 'amount': amt});
                    }
                  });
                }
              }

              double loanGiven = loans.where((l) => l.type == LoanType.given).fold(0, (s, l) => s + l.remainingAmount);
              double loanTaken = loans.where((l) => l.type == LoanType.taken).fold(0, (s, l) => s + l.remainingAmount);

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Sticky Header ──
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyHeaderDelegate(),
                  ),

                  // ── Premium Balance & Owners ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 0), // Removed extra top padding
                      child: _buildBalancePanel(grandTotal, ownerTotals, ownerAccounts),
                    ),
                  ),

                  // ── Quick Actions ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                      child: _buildQuickActions(),
                    ),
                  ),

                  // ── Savings & Loans ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                      child: _buildSavingsLoansSection(savingsTotal, loanGiven, loanTaken),
                    ),
                  ),

                  // ── Accounts Preview ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                      child: _buildAccountsSection(accounts),
                    ),
                  ),

                  // ── Goals Banner ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                      child: _buildGoalsBanner(),
                    ),
                  ),

                  // ── Recent Transactions ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                      child: _buildSectionRow('Recent Transactions', onTap: () => _go(const TransactionsScreen())),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                      child: _buildTransactionList(),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ─────────────────── FINANCIAL PANEL ───────────────────
  Widget _buildBalancePanel(double grandTotal, Map<String, double> ownerTotals, Map<String, List<Map<String, dynamic>>> ownerAccounts) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            colors: [Color(0xFF005F41), Color(0xFF008967)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.3),
              blurRadius: 30, offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              // Abstract Geometric Shapes for "Smart" look
              Positioned(
                top: -50, right: -30,
                child: Transform.rotate(
                  angle: 0.4,
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withOpacity(0.1), Colors.transparent],
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -80, left: -40,
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TOTAL ASSETS', 
                              style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('৳', style: GoogleFonts.outfit(color: AppColors.accentGold, fontSize: 24, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                Text(_fmt(grandTotal),
                                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold, letterSpacing: -1)),
                              ],
                            ),
                          ],
                        ),
                        // NFC/Chip Icon for Card Feel
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.nfc_rounded, color: AppColors.accentGold, size: 24),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Glassmorphic Member Breakdown
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.analytics_outlined, color: AppColors.accentGold, size: 16),
                              const SizedBox(width: 8),
                              Text('MEMBER BREAKDOWN', 
                                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: ownerTotals.entries.map((e) {
                                final label = e.key == AppConstants.ownerSelf ? 'Me' : e.key;
                                final accs = ownerAccounts[e.key] ?? [];
                                return GestureDetector(
                                  onTap: () => _showOwnerBreakdown(label, e.value, accs),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 4),
                                        Text('৳${_fmt(e.value)}', style: GoogleFonts.outfit(color: AppColors.accentGold, fontSize: 13, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────── QUICK ACTIONS ───────────────────
  Widget _buildQuickActions() {
    final actions = [
      {'label': 'Accounts',   'icon': Icons.account_balance_wallet_outlined, 'screen': const AccountsScreen()},
      {'label': 'Records',    'icon': Icons.receipt_long_outlined,            'screen': const TransactionsScreen()},
      {'label': 'Loans',      'icon': Icons.handshake_outlined,               'screen': const LoansScreen()},
      {'label': 'Savings',    'icon': Icons.savings_outlined,                 'screen': const SavingsScreen()},
      {'label': 'Goals',      'icon': Icons.track_changes_rounded,            'screen': const MonthlyGoalScreen()},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Quick Actions'),
        const SizedBox(height: 16),
        Wrap(
          spacing: (MediaQuery.of(context).size.width - 40 - (58 * 5)) / 4 > 0 
            ? (MediaQuery.of(context).size.width - 40 - (58 * 5)) / 4 
            : 16,
          runSpacing: 16,
          alignment: WrapAlignment.spaceBetween,
          children: actions.map((a) => GestureDetector(
            onTap: () => _go(a['screen'] as Widget),
            child: SizedBox(
              width: 58,
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.primaryGreen.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Icon(a['icon'] as IconData, color: AppColors.primaryGreen, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(a['label'] as String,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textBlack)),
                ],
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  // ─────────────────── SAVINGS & LOANS ───────────────────
  Widget _buildSavingsLoansSection(double savings, double given, double taken) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Savings & Loans'),
        const SizedBox(height: 14),
        // Savings — gold card
        GestureDetector(
          onTap: () => _go(const SavingsScreen()),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accentGold, AppColors.accentGold.withOpacity(0.75)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppColors.accentGold.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle),
                  child: const Icon(Icons.savings_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Savings', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('৳ ${_fmt(savings)}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Loans row
        Row(
          children: [
            Expanded(child: GestureDetector(
              onTap: () => _go(const LoansScreen()),
              child: _loanCard('Loan Given', given, AppColors.primaryGreen, Icons.arrow_upward_rounded),
            )),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () => _go(const LoansScreen()),
              child: _loanCard('Loan Taken', taken, const Color(0xFFE67E22), Icons.arrow_downward_rounded),
            )),
          ],
        ),
      ],
    );
  }

  Widget _loanCard(String label, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11, fontWeight: FontWeight.w600)),
                Text('৳ ${_fmt(value)}', style: GoogleFonts.outfit(color: color, fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── ACCOUNTS ───────────────────
  Widget _buildAccountsSection(List<AccountModel> accounts) {
    final regular = accounts.where((a) => a.type != 'Savings').take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionRow('Accounts', onTap: () => _go(const AccountsScreen())),
        const SizedBox(height: 14),
        ...regular.map((acc) => GestureDetector(
          onTap: () => _go(const AccountsScreen()),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.08), shape: BoxShape.circle),
                  child: Icon(Icons.account_balance_outlined, color: AppColors.primaryGreen, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(acc.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textBlack))),
                Text('৳ ${_fmt(acc.totalBalance)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryGreen)),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: AppColors.textGrey.withOpacity(0.5), size: 18),
              ],
            ),
          ),
        )),
      ],
    );
  }

  // ─────────────────── GOALS BANNER ───────────────────
  Widget _buildGoalsBanner() {
    return GestureDetector(
      onTap: () => _go(const MonthlyGoalScreen()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.primaryGreen.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.track_changes_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Monthly Goals', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Track your income & expense targets', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  void _showOwnerBreakdown(String label, double total, List<Map<String, dynamic>> accounts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$label\'s Balance', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                Text('৳ ${_fmt(total)}', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Account-wise distribution', style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textGrey)),
            const SizedBox(height: 24),
            ...accounts.map((acc) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.account_balance_outlined, color: AppColors.primaryGreen, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(acc['name'] as String, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textBlack))),
                  Text('৳ ${_fmt(acc['amount'] as double)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryGreen)),
                ],
              ),
            )).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─────────────────── HELPERS ───────────────────
  Widget _sectionTitle(String title) =>
    Text(title, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textBlack));

  Widget _buildSectionRow(String title, {required VoidCallback onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
        GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Text('See all', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primaryGreen),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────── TRANSACTIONS ───────────────────
  Widget _buildTransactionList() {
    final TransactionService txService = TransactionService();
    return StreamBuilder<List<TransactionModel>>(
      stream: txService.getRecentTransactions(limit: 4),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('No recent transactions', style: GoogleFonts.outfit(color: AppColors.textGrey)),
          ));
        }

        return Column(
          children: snapshot.data!.map((tx) {
            final isIncome = tx.type == TransactionType.income;
            final isTransfer = tx.type == TransactionType.transfer;
            final isOthers = tx.type == TransactionType.others;
            
            final Color color;
            if (isIncome) color = AppColors.primaryGreen;
            else if (isTransfer) color = Colors.blue;
            else if (isOthers) color = Colors.purpleAccent;
            else color = Colors.redAccent;

            final IconData icon;
            if (isIncome) icon = Icons.arrow_downward_rounded;
            else if (isTransfer) icon = Icons.swap_horiz_rounded;
            else if (isOthers) icon = Icons.change_circle_rounded;
            else icon = Icons.arrow_upward_rounded;

            String prefix = '';
            if (isIncome) {
              prefix = '+';
            } else if (isOthers) {
              if (tx.category.contains('Taken') || tx.category.contains('Received')) {
                prefix = '+';
              } else {
                prefix = '-';
              }
            } else if (!isTransfer) {
              prefix = '-';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx.category, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textBlack), overflow: TextOverflow.ellipsis),
                        Text(isTransfer ? '${tx.accountName} → ${tx.toAccountName}' : tx.accountName,
                          style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 12), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${tx.date.day}/${tx.date.month}', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11)),
                      Text('$prefix${_fmt(tx.amount)}', style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ─────────────────── BOTTOM NAV BAR ───────────────────
  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      color: Colors.transparent,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(Icons.home_filled, 'Home', true),
            _navItem(Icons.account_balance_wallet_rounded, 'Wallet', false, onTap: () => _go(const AccountsScreen())),
            
            // Central Add Button (Inline inside the pill)
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/add-transaction'),
              child: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryGreen, Color(0xFF003829)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.35),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
              ),
            ),
            
            _navItem(Icons.analytics_rounded, 'Stats', false, onTap: () => _go(const TransactionsScreen())),
            _navItem(Icons.person_rounded, 'Profile', false, onTap: () => _go(const ProfileScreen())),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, 
            color: isActive ? AppColors.primaryGreen : Colors.grey.shade400, 
            size: 26),
          const SizedBox(height: 4),
          if (isActive)
            Container(
              width: 4, height: 4,
              decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 65.0 + 32.0; // Icon height + Status bar approx
  @override
  double get maxExtent => 65.0 + 32.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isScrolled = shrinkOffset > 0;
    
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isScrolled 
              ? const Color(0xFF003829).withOpacity(0.85) 
              : const Color(0xFFF4F6F5).withOpacity(0.7),
            border: Border(
              bottom: BorderSide(
                color: isScrolled ? Colors.white.withOpacity(0.05) : Colors.transparent,
                width: 1,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                        child: StreamBuilder<DocumentSnapshot>(
                          stream: AuthService().getUserProfile(),
                          builder: (context, snapshot) {
                            String? profilePic;
                            if (snapshot.hasData && snapshot.data!.exists) {
                              profilePic = (snapshot.data!.data() as Map<String, dynamic>)['profilePic'];
                            }
                            return Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: isScrolled ? [Colors.white30, Colors.white10] : [AppColors.primaryGreen, AppColors.accentGold],
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white,
                                backgroundImage: ImageUtils.buildProfileImage(profilePic),
                                child: (profilePic == null || profilePic.isEmpty)
                                    ? Icon(Icons.person_rounded, color: AppColors.primaryGreen, size: 20)
                                    : null,
                              ),
                            );
                          }
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_DashboardScreenState.getGreeting(), 
                            style: GoogleFonts.outfit(
                              color: isScrolled ? Colors.white70 : AppColors.textGrey, 
                              fontSize: 11, 
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            )),
                          Text('Seyam Ali', 
                            style: GoogleFonts.outfit(
                              color: isScrolled ? Colors.white : AppColors.textBlack, 
                              fontSize: 16, 
                              fontWeight: FontWeight.bold,
                            )),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isScrolled ? Colors.white.withOpacity(0.15) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: isScrolled ? [] : [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Icon(Icons.notifications_none_rounded, 
                          color: isScrolled ? Colors.white : AppColors.primaryGreen, size: 24),
                        Positioned(
                          right: 2, top: 2,
                          child: Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}
