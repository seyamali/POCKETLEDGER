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
import 'package:pocketledger/services/goal_service.dart';
import 'package:pocketledger/models/goal_model.dart';
import 'package:pocketledger/features/subscriptions/subscriptions_screen.dart';
import 'package:pocketledger/models/recurring_bill_model.dart';
import 'package:pocketledger/services/recurring_bill_service.dart';
import 'package:pocketledger/features/credit_cards/credit_cards_screen.dart';
import 'package:pocketledger/services/credit_card_service.dart';
import 'package:pocketledger/models/credit_card_model.dart';
import 'package:pocketledger/features/dashboard/widgets/notifications_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AccountService _accountService = AccountService();
  final AuthService _authService = AuthService();
  final LoanService _loanService = LoanService();
  final CreditCardService _creditCardService = CreditCardService();

  int _dueCount = 0;
  late final _cardSub = CreditCardService().getCards().listen((cards) {
    if (mounted) {
      setState(() {
        _dueCount = cards.where((c) => c.daysUntilDue <= 7 && c.outstandingBalance > 0).length;
      });
    }
  });

  @override
  void initState() {
    super.initState();
    _cardSub; // initialise the late field
  }

  @override
  void dispose() {
    _cardSub.cancel();
    super.dispose();
  }

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
      backgroundColor: AppColors.pageBackground,
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
                    delegate: _StickyHeaderDelegate(dueCount: _dueCount),
                  ),

                  // ── Premium Balance & Owners ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 0), // Removed extra top padding
                      child: _buildBalancePanel(grandTotal, ownerTotals, ownerAccounts),
                    ),
                  ),

                  // ── Budget Warning Banner ──
                  const SliverToBoxAdapter(
                    child: BudgetAlertBanner(),
                  ),

                  // ── Recurring Bills Alert ──
                  const SliverToBoxAdapter(
                    child: RecurringBillsAlert(),
                  ),

                  // ── Smart Financial Tips & AI Budget Advisor ──
                  const SliverToBoxAdapter(
                    child: SmartAdvisorCard(),
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

                  // ── Credit Overview ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                      child: _buildCreditOverview(),
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
          gradient: LinearGradient(
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
                          child: Icon(Icons.nfc_rounded, color: AppColors.accentGold, size: 24),
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
                              Icon(Icons.analytics_outlined, color: AppColors.accentGold, size: 16),
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
      {'label': 'Credit',     'icon': Icons.credit_card_outlined,             'screen': const CreditCardsScreen()},
      {'label': 'Goals',      'icon': Icons.track_changes_rounded,            'screen': const MonthlyGoalScreen()},
      {'label': 'Bills',      'icon': Icons.event_repeat_rounded,             'screen': const SubscriptionsScreen()},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Quick Actions'),
        const SizedBox(height: 16),
        Wrap(
          spacing: (MediaQuery.of(context).size.width - 40 - (58 * 4)) / 3 > 0 
            ? (MediaQuery.of(context).size.width - 40 - (58 * 4)) / 3 
            : 16,
          runSpacing: 16,
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
                      color: AppColors.cardWhite,
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
        color: AppColors.cardWhite,
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

  // ─────────────────── CREDIT CARDS ───────────────────
  Widget _buildCreditOverview() {
    return StreamBuilder<Map<String, double>>(
      stream: _creditCardService.getCreditSummary(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final summary = snapshot.data!;
        if (summary['totalLimit'] == 0) return const SizedBox.shrink(); // Hide if no cards

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionRow('Credit Cards', onTap: () => _go(const CreditCardsScreen())),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => _go(const CreditCardsScreen()),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Balance', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13)),
                            Text('৳ ${_fmt(summary['totalBalance'] ?? 0)}', style: GoogleFonts.outfit(color: AppColors.error, fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Available Limit', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13)),
                            Text('৳ ${_fmt((summary['totalLimit'] ?? 0) - (summary['totalBalance'] ?? 0))}', style: GoogleFonts.outfit(color: AppColors.primaryGreen, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: summary['utilization'],
                        backgroundColor: AppColors.pageBackground,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          (summary['utilization'] ?? 0) > 0.8 ? AppColors.error : AppColors.primaryGreen,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
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
              color: AppColors.cardWhite,
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
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
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
                    child: Icon(Icons.account_balance_outlined, color: AppColors.primaryGreen, size: 18),
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
          return Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
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
                color: AppColors.cardWhite,
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
          color: AppColors.cardWhite,
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
                  gradient: LinearGradient(
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
              decoration: BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int dueCount;
  const _StickyHeaderDelegate({required this.dueCount});
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
                                backgroundColor: AppColors.cardWhite,
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
                  GestureDetector(
                    onTap: () => NotificationsSheet.show(context),
                    child: Container(
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
                          if (dueCount > 0)
                            Positioned(
                              right: 0, top: 0,
                              child: Container(
                                width: 10, height: 10,
                                decoration: BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                                child: Center(
                                  child: Text(
                                    dueCount < 10 ? '$dueCount' : '',
                                    style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
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
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) => oldDelegate.dueCount != dueCount;
}

// ⏳ Budget Utilization Warning Alert
class BudgetAlertBanner extends StatelessWidget {
  const BudgetAlertBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final GoalService goalService = GoalService();
    final now = DateTime.now();
    final monthYearKey = "${now.month.toString().padLeft(2, '0')}-${now.year}";

    return StreamBuilder<GoalModel?>(
      stream: goalService.getGoal(monthYearKey),
      builder: (context, goalSnapshot) {
        if (!goalSnapshot.hasData || goalSnapshot.data == null) {
          return const SizedBox.shrink(); // No goal set
        }
        final goal = goalSnapshot.data!;

        return StreamBuilder<List<TransactionModel>>(
          stream: goalService.getTransactionsForMonth(now.month, now.year),
          builder: (context, txSnapshot) {
            if (!txSnapshot.hasData || txSnapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            final transactions = txSnapshot.data!;
            final filtered = transactions.where((tx) {
              if (tx.owner != AppConstants.ownerSelf) return false;
              final cat = tx.category.toLowerCase();
              final note = tx.note.toLowerCase();
              if (cat.contains('opening') || cat.contains('initial') || 
                  note.contains('opening') || note.contains('initial')) {
                return false;
              }
              return true;
            }).toList();

            double actualExpense = goal.initialProgressExpense;
            for (var tx in filtered) {
              final cat = tx.category.toLowerCase();
              bool isSavings = cat.contains('sav') || 
                               tx.toAccountName?.toLowerCase().contains('sav') == true;
              if (!isSavings && tx.type == TransactionType.expense) {
                actualExpense += tx.amount;
              }
            }

            double limit = goal.expenseLimit;
            if (limit <= 0) {
              limit = goal.categoryLimits.values.fold(0.0, (a, b) => a + b);
            }

            if (limit <= 0) return const SizedBox.shrink();

            final ratio = actualExpense / limit;
            if (ratio < 0.8) return const SizedBox.shrink(); // Show alert only when utilization >= 80%

            final isOverLimit = ratio >= 1.0;
            final utilizationPercent = (ratio * 100).toInt();

            final Color cardColor = isOverLimit ? const Color(0xFFFFECEB) : const Color(0xFFFFF6E6);
            final Color borderColor = isOverLimit ? Colors.redAccent.withOpacity(0.2) : Colors.orangeAccent.withOpacity(0.2);
            final Color textColor = isOverLimit ? Colors.red.shade900 : Colors.orange.shade900;
            final IconData icon = isOverLimit ? Icons.error_outline_rounded : Icons.warning_amber_rounded;
            final String title = isOverLimit ? 'Budget Exceeded!' : 'Budget Warning!';
            final String message = isOverLimit 
                ? 'You have spent ৳${actualExpense.toInt()} which is $utilizationPercent% of your monthly limit (৳${limit.toInt()}).'
                : 'You have utilized $utilizationPercent% of your monthly budget limit (৳${actualExpense.toInt()} spent of ৳${limit.toInt()}).';

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: (isOverLimit ? Colors.redAccent : Colors.orangeAccent).withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: isOverLimit ? Colors.redAccent : Colors.orangeAccent, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: textColor.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class RecurringBillsAlert extends StatelessWidget {
  const RecurringBillsAlert({super.key});

  @override
  Widget build(BuildContext context) {
    final billService = RecurringBillService();

    return StreamBuilder<List<RecurringBillModel>>(
      stream: billService.getRecurringBills(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final bills = snapshot.data!;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Find bills that are overdue or due in the next 5 days
        final dueSoonBills = bills.where((bill) {
          final due = DateTime(bill.nextDueDate.year, bill.nextDueDate.month, bill.nextDueDate.day);
          final diff = due.difference(today).inDays;
          return diff <= 5;
        }).toList();

        if (dueSoonBills.isEmpty) {
          return const SizedBox.shrink();
        }

        // Sort by due date ascending (overdue first)
        dueSoonBills.sort((a, b) {
          final dueA = DateTime(a.nextDueDate.year, a.nextDueDate.month, a.nextDueDate.day);
          final dueB = DateTime(b.nextDueDate.year, b.nextDueDate.month, b.nextDueDate.day);
          return dueA.compareTo(dueB);
        });

        final count = dueSoonBills.length;
        final firstBill = dueSoonBills.first;
        final firstDue = DateTime(firstBill.nextDueDate.year, firstBill.nextDueDate.month, firstBill.nextDueDate.day);
        final daysLeft = firstDue.difference(today).inDays;

        String title = 'Upcoming Bill Due';
        String subtitle = '';
        Color bannerColor = AppColors.accentGold;
        Color textColor = AppColors.textBlack;

        if (daysLeft < 0) {
          title = 'Overdue Bills Alert';
          subtitle = '${firstBill.title} is overdue by ${-daysLeft} days.';
          bannerColor = Colors.red.shade50;
          textColor = Colors.red.shade900;
        } else if (daysLeft == 0) {
          title = 'Bill Due Today';
          subtitle = '${firstBill.title} (৳${firstBill.amount.toInt()}) is due today.';
          bannerColor = Colors.orange.shade50;
          textColor = Colors.orange.shade900;
        } else {
          subtitle = '${firstBill.title} (৳${firstBill.amount.toInt()}) due in $daysLeft days.';
          bannerColor = AppColors.primaryGreen.withOpacity(0.05);
          textColor = AppColors.primaryGreen;
        }

        if (count > 1) {
          subtitle += ' (and ${count - 1} other bills)';
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubscriptionsScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: bannerColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: textColor.withOpacity(0.15),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: textColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.event_repeat_rounded,
                      color: textColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: textColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: textColor.withOpacity(0.5),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// 🧠 Smart Financial Tips & AI Budget Advisor
class SmartAdvisorCard extends StatelessWidget {
  const SmartAdvisorCard({super.key});

  Widget _buildCard(BuildContext context, _AdvisorTip tip) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: tip.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: tip.borderColor.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: tip.textColor.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tip.bulbColor.withOpacity(0.04),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GlowingPulseIcon(
                          icon: tip.icon,
                          color: tip.bulbColor,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "SMART ADVISOR",
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  color: tip.textColor.withOpacity(0.6),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tip.title,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: tip.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        tip.content,
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: tip.textColor.withOpacity(0.85),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => tip.targetScreen),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: tip.textColor.withOpacity(0.1),
                          foregroundColor: tip.textColor,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: tip.textColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tip.buttonText,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: tip.textColor,
                            ),
                          ],
                        ),
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthYearKey = "${now.month.toString().padLeft(2, '0')}-${now.year}";
    final goalService = GoalService();

    return StreamBuilder<GoalModel?>(
      stream: goalService.getGoal(monthYearKey),
      builder: (context, goalSnapshot) {
        return StreamBuilder<List<TransactionModel>>(
          stream: goalService.getTransactionsForMonth(now.month, now.year),
          builder: (context, txSnapshot) {
            if (goalSnapshot.connectionState == ConnectionState.waiting ||
                txSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }

            final goal = goalSnapshot.data;
            final transactions = txSnapshot.data ?? [];

            // 1. If no active goal
            if (goal == null) {
              return _buildCard(
                context,
                _AdvisorTip(
                  title: "Set Your Goals",
                  content: "Set your targets! Setting monthly budgets helps users save up to 20% more. Set a goal.",
                  gradientColors: [const Color(0xFFF0F9FF), const Color(0xFFD2EFFF)],
                  borderColor: const Color(0xFFA5D8FF),
                  textColor: const Color(0xFF005A9C),
                  icon: Icons.lightbulb_outline_rounded,
                  bulbColor: const Color(0xFF0288D1),
                  buttonText: "Set Goal",
                  targetScreen: const MonthlyGoalScreen(),
                ),
              );
            }

            // Calculations
            final filtered = transactions.where((tx) {
              if (tx.owner != AppConstants.ownerSelf) return false;
              final cat = tx.category.toLowerCase();
              final note = tx.note.toLowerCase();
              if (cat.contains('opening') || cat.contains('initial') || 
                  note.contains('opening') || note.contains('initial')) {
                return false;
              }
              return true;
            }).toList();

            double actualExpense = goal.initialProgressExpense;
            double actualSaved = goal.initialProgressSavings;
            Map<String, double> expenseByCategory = {};

            for (var tx in filtered) {
              final cat = tx.category.toLowerCase();
              bool isSavings = cat.contains('sav') || 
                               tx.toAccountName?.toLowerCase().contains('sav') == true;

              if (isSavings) {
                actualSaved += tx.amount;
              } else {
                if (tx.type == TransactionType.expense) {
                  actualExpense += tx.amount;
                  expenseByCategory[tx.category] = (expenseByCategory[tx.category] ?? 0) + tx.amount;
                }
              }
            }

            double expenseLimit = goal.expenseLimit;
            if (expenseLimit <= 0) {
              expenseLimit = goal.categoryLimits.values.fold(0.0, (a, b) => a + b);
            }

            double savingsTarget = goal.savingsTarget;

            // Priority 1: Budget Exceeded
            if (expenseLimit > 0 && actualExpense >= expenseLimit) {
              final overSpent = actualExpense - expenseLimit;
              return _buildCard(
                context,
                _AdvisorTip(
                  title: "Budget Exceeded!",
                  content: "Budget Exceeded! You spent ৳${overSpent.toInt()} over your monthly limit. Hold non-essential purchases.",
                  gradientColors: [const Color(0xFFFFECEB), const Color(0xFFFFDCDA)],
                  borderColor: const Color(0xFFFFC0BD),
                  textColor: const Color(0xFFC62828),
                  icon: Icons.error_outline_rounded,
                  bulbColor: const Color(0xFFE53935),
                  buttonText: "Adjust Goals",
                  targetScreen: const MonthlyGoalScreen(),
                ),
              );
            }

            // Priority 2: Nearing Limit (>= 80%)
            if (expenseLimit > 0 && actualExpense >= expenseLimit * 0.8) {
              final utilization = ((actualExpense / expenseLimit) * 100).toInt();
              return _buildCard(
                context,
                _AdvisorTip(
                  title: "Budget Warning!",
                  content: "Nearing Limit! You have used $utilization% of your budget. Cut down discretionary spending.",
                  gradientColors: [const Color(0xFFFFF6E6), const Color(0xFFFFECD0)],
                  borderColor: const Color(0xFFFFD49E),
                  textColor: const Color(0xFFD84315),
                  icon: Icons.warning_amber_rounded,
                  bulbColor: const Color(0xFFFB8C00),
                  buttonText: "Adjust Goals",
                  targetScreen: const MonthlyGoalScreen(),
                ),
              );
            }

            // Priority 3: Savings Alert (< 50% of Goal)
            if (savingsTarget > 0 && actualSaved < savingsTarget * 0.5) {
              final savingsPercent = savingsTarget > 0 ? ((actualSaved / savingsTarget) * 100).toInt() : 0;
              return _buildCard(
                context,
                _AdvisorTip(
                  title: "Savings Alert",
                  content: "Savings Alert: You met only $savingsPercent% of your savings target. Log savings early to stay safe.",
                  gradientColors: [const Color(0xFFFFFDF0), const Color(0xFFFFF7C2)],
                  borderColor: const Color(0xFFFFE082),
                  textColor: const Color(0xFFF57F17),
                  icon: Icons.savings_rounded,
                  bulbColor: const Color(0xFFFBC02D),
                  buttonText: "Log Savings",
                  targetScreen: const SavingsScreen(),
                ),
              );
            }

            // Priority 4: Category Spike (> 40% of total)
            String highestCategory = '';
            double highestAmount = 0;
            expenseByCategory.forEach((cat, amt) {
              if (amt > highestAmount) {
                highestAmount = amt;
                highestCategory = cat;
              }
            });

            if (actualExpense > 0 && highestAmount > 0 && (highestAmount / actualExpense) > 0.4) {
              final categoryPercent = ((highestAmount / actualExpense) * 100).toInt();
              return _buildCard(
                context,
                _AdvisorTip(
                  title: "Category Spike!",
                  content: "Category Check: Spending on '$highestCategory' is $categoryPercent% of your total. Try cooking at home or deferring.",
                  gradientColors: [const Color(0xFFF5F0FF), const Color(0xFFE5D5FF)],
                  borderColor: const Color(0xFFD1B3FF),
                  textColor: const Color(0xFF6A1B9A),
                  icon: Icons.pie_chart_outline_rounded,
                  bulbColor: const Color(0xFF7E57C2),
                  buttonText: "View Trends",
                  targetScreen: const MonthlyGoalScreen(),
                ),
              );
            }

            // Priority 5: Savings met or exceeded
            if (savingsTarget > 0 && actualSaved >= savingsTarget) {
              return _buildCard(
                context,
                _AdvisorTip(
                  title: "Excellent Cashflow!",
                  content: "Excellent Cashflow! You met your savings target. Put surplus cash into Savings Vaults.",
                  gradientColors: [const Color(0xFFEDFBF4), const Color(0xFFD0F5E2)],
                  borderColor: const Color(0xFFA3EBBF),
                  textColor: const Color(0xFF2E7D32),
                  icon: Icons.stars_rounded,
                  bulbColor: const Color(0xFF43A047),
                  buttonText: "Log Savings",
                  targetScreen: const SavingsScreen(),
                ),
              );
            }

            // Fallback: On Track
            return _buildCard(
              context,
              _AdvisorTip(
                title: "Advisor Update",
                content: "On Track! Your expenses and savings are healthy. Keep tracking and maintain the streak!",
                gradientColors: [const Color(0xFFF0F9FF), const Color(0xFFD2EFFF)],
                borderColor: const Color(0xFFA5D8FF),
                textColor: const Color(0xFF005A9C),
                icon: Icons.insights_rounded,
                bulbColor: const Color(0xFF0288D1),
                buttonText: "View Analytics",
                targetScreen: const MonthlyGoalScreen(),
              ),
            );
          },
        );
      },
    );
  }
}

class _AdvisorTip {
  final String title;
  final String content;
  final List<Color> gradientColors;
  final Color borderColor;
  final Color textColor;
  final IconData icon;
  final Color bulbColor;
  final String buttonText;
  final Widget targetScreen;

  _AdvisorTip({
    required this.title,
    required this.content,
    required this.gradientColors,
    required this.borderColor,
    required this.textColor,
    required this.icon,
    required this.bulbColor,
    required this.buttonText,
    required this.targetScreen,
  });
}

class GlowingPulseIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const GlowingPulseIcon({super.key, required this.icon, required this.color});

  @override
  State<GlowingPulseIcon> createState() => _GlowingPulseIconState();
}

class _GlowingPulseIconState extends State<GlowingPulseIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(_opacityAnimation.value * 0.3),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(_opacityAnimation.value),
                    blurRadius: 10 * _scaleAnimation.value,
                    spreadRadius: 2 * _scaleAnimation.value,
                  ),
                ],
              ),
            );
          },
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            color: widget.color,
            size: 20,
          ),
        ),
      ],
    );
  }
}
