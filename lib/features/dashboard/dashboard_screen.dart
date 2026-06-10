import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/core/localization/app_localizations.dart';
import 'package:pocketledger/services/account_service.dart';
import 'package:pocketledger/services/auth_service.dart';
import 'package:pocketledger/models/account_model.dart';
import 'package:pocketledger/features/goals/monthly_goal_screen.dart';
import 'package:pocketledger/features/savings/savings_screen.dart';
import 'package:pocketledger/features/loans/loans_screen.dart';
import 'package:pocketledger/features/accounts/accounts_screen.dart';
import 'package:pocketledger/features/transactions/transactions_screen.dart';
import 'package:pocketledger/models/transaction_model.dart';
import 'package:pocketledger/core/constants/app_constants.dart';
import 'package:pocketledger/core/utils/image_utils.dart';
import 'package:pocketledger/services/transaction_service.dart';
import 'package:pocketledger/services/loan_service.dart';
import 'package:pocketledger/models/loan_model.dart';
import 'package:pocketledger/features/profile/profile_screen.dart';
import 'package:pocketledger/features/categories/category_manager_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pocketledger/services/goal_service.dart';
import 'package:pocketledger/models/goal_model.dart';
import 'package:pocketledger/features/subscriptions/subscriptions_screen.dart';
import 'package:pocketledger/models/recurring_bill_model.dart';
import 'package:pocketledger/services/recurring_bill_service.dart';
import 'package:pocketledger/features/credit_cards/credit_cards_screen.dart';
import 'package:pocketledger/services/credit_card_service.dart';
import 'package:pocketledger/features/dashboard/widgets/notifications_sheet.dart';
import 'package:pocketledger/core/widgets/scale_on_tap.dart';
import 'package:pocketledger/core/widgets/glass_card.dart';
import 'package:pocketledger/features/guide/guide_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pocketledger/features/business_card/business_card_screen.dart';
import 'package:pocketledger/features/analytics/analytics_screen.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AccountService _accountService = AccountService();
  final LoanService _loanService = LoanService();
  final CreditCardService _creditCardService = CreditCardService();

  int _dueCount = 0;
  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

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
    _initConnectivity();
  }

  void _initConnectivity() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    _updateConnectionStatus(result);
    _connectivitySubscription = connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    if (mounted) {
      setState(() {
        _isOffline = result.contains(ConnectivityResult.none) || result.isEmpty;
      });
    }
  }

  @override
  void dispose() {
    _cardSub.cancel();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  String _fmt(double v) => AppLocalizations.convertDigits(
        v.toInt().toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},',
            ),
      );

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppLocalizations.get('good_morning');
    if (hour < 17) return AppLocalizations.get('good_afternoon');
    return AppLocalizations.get('good_evening');
  }

  void _go(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return ThemeBuilder(builder: (context) => Scaffold(
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

              return Stack(
                children: [
                  // ── Premium glowing liquid background blobs ──
                  Positioned(
                    top: 100, left: -60,
                    child: Container(
                      width: 280, height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryGreen.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 450, right: -80,
                    child: Container(
                      width: 260, height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentGold.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 220, left: -50,
                    child: Container(
                      width: 220, height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                      child: Container(color: Colors.transparent),
                    ),
                  ),

                  // ── Scrolling content ──
                  CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                  // ── Sticky Header ──
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyHeaderDelegate(
                      dueCount: _dueCount,
                      statusBarHeight: MediaQuery.of(context).padding.top,
                    ),
                  ),

                  // ── Offline Banner ──
                  SliverToBoxAdapter(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: _isOffline ? 40 : 0,
                      color: AppColors.error,
                      child: SingleChildScrollView(
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                "No internet connection. You're offline.",
                                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
                      child: _buildSectionRow(AppLocalizations.get('recent_transactions'), onTap: () => _go(const TransactionsScreen())),
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
              ),
            ],
          );
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    )); // closes Scaffold + ThemeBuilder
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
              color: AppColors.primaryGreen.withValues(alpha: 0.3),
              blurRadius: 30, offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              // Abstract Geometric Shapes for AppLocalizations.get('smart') look
              Positioned(
                top: -50, right: -30,
                child: Transform.rotate(
                  angle: 0.4,
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withValues(alpha: 0.1), Colors.transparent],
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
                    color: AppColors.accentGold.withValues(alpha: 0.05),
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
                            Text(AppLocalizations.get('total_assets'), 
                              style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
                            color: Colors.white.withValues(alpha: 0.1),
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
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.analytics_outlined, color: AppColors.accentGold, size: 16),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.get('member_breakdown'), 
                                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: ownerTotals.entries.map((e) {
                                final label = e.key == AppConstants.ownerSelf ? AppLocalizations.get('me') : e.key;
                                final accs = ownerAccounts[e.key] ?? [];
                                return GestureDetector(
                                  onTap: () => _showOwnerBreakdown(label, e.value, accs),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
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
      {'label': AppLocalizations.get('accounts'),   'icon': Icons.account_balance_wallet_outlined, 'screen': const AccountsScreen()},
      {'label': AppLocalizations.get('records'),    'icon': Icons.receipt_long_outlined,            'screen': const TransactionsScreen()},
      {'label': AppLocalizations.get('loans'),      'icon': Icons.handshake_outlined,               'screen': const LoansScreen()},
      {'label': AppLocalizations.get('savings'),    'icon': Icons.savings_outlined,                 'screen': const SavingsScreen()},
      {'label': AppLocalizations.get('credit'),     'icon': Icons.credit_card_outlined,             'screen': const CreditCardsScreen()},
      {'label': AppLocalizations.get('goals'),      'icon': Icons.track_changes_rounded,            'screen': const MonthlyGoalScreen()},
      {'label': AppLocalizations.get('bills'),      'icon': Icons.event_repeat_rounded,             'screen': const SubscriptionsScreen()},
      {'label': 'Biz Card',                         'icon': Icons.contact_mail_outlined,            'screen': const BusinessCardScreen()},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(AppLocalizations.get('quick_actions')),
        const SizedBox(height: 16),
        Wrap(
          spacing: (MediaQuery.of(context).size.width - 40 - (58 * 4)) / 3 > 0 
            ? (MediaQuery.of(context).size.width - 40 - (58 * 4)) / 3 
            : 16,
          runSpacing: 16,
          children: actions.map((a) => ScaleOnTap(
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
                      boxShadow: [BoxShadow(color: AppColors.primaryGreen.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))],
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
        _sectionTitle(AppLocalizations.get('savings_and_loans')),
        const SizedBox(height: 14),
        // Savings — gold card
        ScaleOnTap(
          onTap: () => _go(const SavingsScreen()),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accentGold, AppColors.accentGold.withValues(alpha: 0.75)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppColors.accentGold.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), shape: BoxShape.circle),
                  child: const Icon(Icons.savings_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.get('my_savings'), style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w600)),
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
            Expanded(child: ScaleOnTap(
              onTap: () => _go(const LoansScreen()),
              child: _loanCard(AppLocalizations.get('loan_given'), given, AppColors.primaryGreen, Icons.arrow_upward_rounded),
            )),
            const SizedBox(width: 12),
            Expanded(child: ScaleOnTap(
              onTap: () => _go(const LoansScreen()),
              child: _loanCard(AppLocalizations.get('loan_taken'), taken, const Color(0xFFE67E22), Icons.arrow_downward_rounded),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
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
            _buildSectionRow(AppLocalizations.get('credit_cards'), onTap: () => _go(const CreditCardsScreen())),
            const SizedBox(height: 14),
            ScaleOnTap(
              onTap: () => _go(const CreditCardsScreen()),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.get('total_balance'), style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13)),
                            Text('৳ ${_fmt(summary['totalBalance'] ?? 0)}', style: GoogleFonts.outfit(color: AppColors.error, fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(AppLocalizations.get('available_limit'), style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13)),
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
        _buildSectionRow(AppLocalizations.get('accounts'), onTap: () => _go(const AccountsScreen())),
        const SizedBox(height: 14),
        ...regular.map((acc) => ScaleOnTap(
          onTap: () => _go(const AccountsScreen()),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(color: AppColors.primaryGreen.withValues(alpha: 0.08), shape: BoxShape.circle),
                  child: Icon(Icons.account_balance_outlined, color: AppColors.primaryGreen, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(acc.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textBlack))),
                Text('৳ ${_fmt(acc.totalBalance)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryGreen)),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: AppColors.textGrey.withValues(alpha: 0.5), size: 18),
              ],
            ),
          ),
        )),
      ],
    );
  }

  // ─────────────────── GOALS BANNER ───────────────────
  Widget _buildGoalsBanner() {
    return ScaleOnTap(
      onTap: () => _go(const MonthlyGoalScreen()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.primaryGreen.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.track_changes_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.get('monthly_goals'), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(AppLocalizations.get('track_your_income_and_expense_targets'), style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
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
                color: AppColors.primaryGreen.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primaryGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
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
              Text(AppLocalizations.get('see_all'), style: GoogleFonts.outfit(fontSize: 13, color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
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
            child: Text(AppLocalizations.get('no_recent_transactions'), style: GoogleFonts.outfit(color: AppColors.textGrey)),
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
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
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
    final isDark = AppColors.isDark;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      color: Colors.transparent,
      child: GlassCard(
        blur: 24,
        opacity: isDark ? 0.9 : 0.88,
        color: isDark ? const Color(0xFF13201A) : Colors.white,
        borderRadius: 30,
        border: Border.all(
          color: isDark
              ? AppColors.primaryGreen.withValues(alpha: 0.16)
              : Colors.black.withValues(alpha: 0.05),
          width: 1.2,
        ),
        child: SizedBox(
          height: 82,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _navItem(
                  icon: Icons.home_rounded,
                  label: AppLocalizations.get('home'),
                  isActive: true,
                ),
              ),
              Expanded(
                child: _navItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: AppLocalizations.get('wallet'),
                  isActive: false,
                  onTap: () => _go(const AccountsScreen()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ScaleOnTap(
                  onTap: () => Navigator.pushNamed(context, '/add-transaction'),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryGreen, isDark ? const Color(0xFF1A3A2A) : const Color(0xFF003829)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withValues(alpha: isDark ? 0.25 : 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                  ),
                ),
              ),
              Expanded(
                child: _navItem(
                  icon: Icons.analytics_rounded,
                  label: AppLocalizations.get('stats'),
                  isActive: false,
                  onTap: () => _go(const AnalyticsScreen()),
                ),
              ),
              Expanded(
                child: _navItem(
                  icon: Icons.grid_view_rounded,
                  label: 'More',
                  isActive: false,
                  onTap: _showQuickActionsSheet,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return ScaleOnTap(
      onTap: onTap ?? () {},
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primaryGreen.withValues(alpha: 0.12) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? AppColors.primaryGreen : AppColors.secondaryText,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              color: isActive ? AppColors.primaryGreen : AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickActionsSheet() {
    final isDark = AppColors.isDark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16201D) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Quick Access',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Open the most useful sections in one tap.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 18),
              _quickActionTile(
                icon: Icons.security_rounded,
                title: 'Profile & Security',
                subtitle: 'PIN, biometrics, themes, language',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _go(const ProfileScreen());
                },
              ),
              _quickActionTile(
                icon: Icons.credit_card_rounded,
                title: 'Credit Cards',
                subtitle: 'Limits, billing cycles, payments',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _go(const CreditCardsScreen());
                },
              ),
              _quickActionTile(
                icon: Icons.event_repeat_rounded,
                title: 'Recurring Bills',
                subtitle: 'Rent, internet, subscriptions',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _go(const SubscriptionsScreen());
                },
              ),
              _quickActionTile(
                icon: Icons.savings_rounded,
                title: 'Savings',
                subtitle: 'Goals and savings progress',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _go(const SavingsScreen());
                },
              ),
              _quickActionTile(
                icon: Icons.handshake_rounded,
                title: 'Loans & Debts',
                subtitle: 'Track money you gave or borrowed',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _go(const LoansScreen());
                },
              ),
              _quickActionTile(
                icon: Icons.category_rounded,
                title: 'Categories',
                subtitle: 'Customize your income and expense tags',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _go(const CategoryManagerScreen());
                },
              ),
              _quickActionTile(
                icon: Icons.menu_book_rounded,
                title: 'App Guide',
                subtitle: 'Learn how to use PocketLedger',
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GuideScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ScaleOnTap(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primaryGreen, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textGrey.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int dueCount;
  final double statusBarHeight;
  const _StickyHeaderDelegate({required this.dueCount, required this.statusBarHeight});
  @override
  double get minExtent => 65.0 + statusBarHeight;
  @override
  double get maxExtent => 65.0 + statusBarHeight;

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
              ? const Color(0xFF003829).withValues(alpha: 0.85) 
              : (AppColors.isDark
                  ? const Color(0xFF0F1715).withValues(alpha: 0.92)
                  : const Color(0xFFF4F6F5).withValues(alpha: 0.7)),
            border: Border(
              bottom: BorderSide(
                color: isScrolled
                    ? Colors.white.withValues(alpha: 0.05)
                    : (AppColors.isDark
                        ? AppColors.primaryGreen.withValues(alpha: 0.08)
                        : Colors.transparent),
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
                  StreamBuilder<DocumentSnapshot>(
                    stream: AuthService().getUserProfile(),
                    builder: (context, snapshot) {
                      String? profilePic;
                      String userName = 'User';
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        profilePic = data['profilePic'];
                        userName = data['name'] ?? 'User';
                      }
                      return Row(
                        children: [
                          ScaleOnTap(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                            child: Container(
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
                              Text(userName, 
                                style: GoogleFonts.outfit(
                                  color: isScrolled ? Colors.white : AppColors.textBlack, 
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold,
                                )),
                            ],
                          ),
                        ],
                      );
                    }
                  ),
                  ScaleOnTap(
                    onTap: () => NotificationsSheet.show(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isScrolled
                            ? Colors.white.withValues(alpha: 0.15)
                            : (AppColors.isDark
                                ? AppColors.primaryGreen.withValues(alpha: 0.12)
                                : Colors.white),
                        shape: BoxShape.circle,
                        border: !isScrolled && AppColors.isDark
                            ? Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2), width: 1)
                            : null,
                        boxShadow: isScrolled || AppColors.isDark ? [] : [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
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
            final Color borderColor = isOverLimit ? Colors.redAccent.withValues(alpha: 0.2) : Colors.orangeAccent.withValues(alpha: 0.2);
            final Color textColor = isOverLimit ? Colors.red.shade900 : Colors.orange.shade900;
            final IconData icon = isOverLimit ? Icons.error_outline_rounded : Icons.warning_amber_rounded;
            final String title = isOverLimit ? AppLocalizations.get('budget_exceeded') : AppLocalizations.get('budget_warning');
            final String message = isOverLimit 
                ? 'You have spent ৳${actualExpense.toInt()} which is $utilizationPercent% of your monthly limit (৳${limit.toInt()}).'
                : 'You have utilized $utilizationPercent% of your monthly budget limit (৳${actualExpense.toInt()} spent of ৳${limit.toInt()}).';

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: GlassCard(
                opacity: 0.1,
                color: cardColor,
                borderRadius: 20,
                border: Border.all(color: borderColor, width: 1.5),
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                                color: textColor.withValues(alpha: 0.8),
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

        String title = AppLocalizations.get('upcoming_bill_due');
        String subtitle = '';
        Color bannerColor = AppColors.accentGold;
        Color textColor = AppColors.textBlack;

        if (daysLeft < 0) {
          title = AppLocalizations.get('overdue_bills_alert');
          subtitle = '${firstBill.title} is overdue by ${-daysLeft} days.';
          bannerColor = Colors.red.shade50;
          textColor = Colors.red.shade900;
        } else if (daysLeft == 0) {
          title = AppLocalizations.get('bill_due_today');
          subtitle = '${firstBill.title} (৳${firstBill.amount.toInt()}) is due today.';
          bannerColor = Colors.orange.shade50;
          textColor = Colors.orange.shade900;
        } else {
          subtitle = '${firstBill.title} (৳${firstBill.amount.toInt()}) due in $daysLeft days.';
          bannerColor = AppColors.primaryGreen.withValues(alpha: 0.05);
          textColor = AppColors.primaryGreen;
        }

        if (count > 1) {
          subtitle += ' (and ${count - 1} other bills)';
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: ScaleOnTap(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubscriptionsScreen()),
            ),
            child: GlassCard(
              opacity: 0.08,
              color: bannerColor,
              borderRadius: 24,
              border: Border.all(
                color: textColor.withValues(alpha: 0.15),
                width: 1.5,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.1),
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
                              color: textColor.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: textColor.withValues(alpha: 0.5),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// 🧠 Smart Financial Tips & AI Budget Advisor
enum AdvisorTipType {
  info,
  danger,
  warning,
  warningAlt,
  purple,
  success,
}

class _AdvisorTip {
  final String title;
  final String content;
  final IconData icon;
  final String buttonText;
  final Widget targetScreen;
  final AdvisorTipType type;

  const _AdvisorTip({
    required this.title,
    required this.content,
    required this.icon,
    required this.buttonText,
    required this.targetScreen,
    required this.type,
  });
}

class _AdvisorTipColors {
  final List<Color> gradientColors;
  final Color borderColor;
  final Color textColor;
  final Color bulbColor;

  const _AdvisorTipColors({
    required this.gradientColors,
    required this.borderColor,
    required this.textColor,
    required this.bulbColor,
  });
}

class SmartAdvisorCard extends StatelessWidget {
  const SmartAdvisorCard({super.key});

  _AdvisorTipColors _getTipColors(AdvisorTipType type, bool isDark) {
    switch (type) {
      case AdvisorTipType.info:
        return isDark
            ? _AdvisorTipColors(
                gradientColors: [const Color(0xFF082F49).withValues(alpha: 0.35), const Color(0xFF0C4A6E).withValues(alpha: 0.25)],
                borderColor: const Color(0xFF0284C7).withValues(alpha: 0.3),
                textColor: const Color(0xFF38BDF8),
                bulbColor: const Color(0xFF0EA5E9),
              )
            : _AdvisorTipColors(
                gradientColors: [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)],
                borderColor: const Color(0xFFB9E6FE),
                textColor: const Color(0xFF0369A1),
                bulbColor: const Color(0xFF0EA5E9),
              );
      case AdvisorTipType.danger:
        return isDark
            ? _AdvisorTipColors(
                gradientColors: [const Color(0xFF450A0A).withValues(alpha: 0.35), const Color(0xFF7F1D1D).withValues(alpha: 0.25)],
                borderColor: const Color(0xFFDC2626).withValues(alpha: 0.3),
                textColor: const Color(0xFFFCA5A5),
                bulbColor: const Color(0xFFEF4444),
              )
            : _AdvisorTipColors(
                gradientColors: [const Color(0xFFFEF2F2), const Color(0xFFFEE2E2)],
                borderColor: const Color(0xFFFCA5A5),
                textColor: const Color(0xFFB91C1C),
                bulbColor: const Color(0xFFEF4444),
              );
      case AdvisorTipType.warning:
        return isDark
            ? _AdvisorTipColors(
                gradientColors: [const Color(0xFF431407).withValues(alpha: 0.35), const Color(0xFF7C2D12).withValues(alpha: 0.25)],
                borderColor: const Color(0xFFEA580C).withValues(alpha: 0.3),
                textColor: const Color(0xFFFDBA74),
                bulbColor: const Color(0xFFF97316),
              )
            : _AdvisorTipColors(
                gradientColors: [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)],
                borderColor: const Color(0xFFFED7AA),
                textColor: const Color(0xFFC2410C),
                bulbColor: const Color(0xFFF97316),
              );
      case AdvisorTipType.warningAlt:
        return isDark
            ? _AdvisorTipColors(
                gradientColors: [const Color(0xFF422006).withValues(alpha: 0.35), const Color(0xFF713F12).withValues(alpha: 0.25)],
                borderColor: const Color(0xFFCA8A04).withValues(alpha: 0.3),
                textColor: const Color(0xFFFDE047),
                bulbColor: const Color(0xFFEAB308),
              )
            : _AdvisorTipColors(
                gradientColors: [const Color(0xFFFEFCE8), const Color(0xFFFEF9C3)],
                borderColor: const Color(0xFFFEF08A),
                textColor: const Color(0xFFA16207),
                bulbColor: const Color(0xFFEAB308),
              );
      case AdvisorTipType.purple:
        return isDark
            ? _AdvisorTipColors(
                gradientColors: [const Color(0xFF3B0764).withValues(alpha: 0.35), const Color(0xFF581C87).withValues(alpha: 0.25)],
                borderColor: const Color(0xFF9333EA).withValues(alpha: 0.3),
                textColor: const Color(0xFFE9D5FF),
                bulbColor: const Color(0xFFA855F7),
              )
            : _AdvisorTipColors(
                gradientColors: [const Color(0xFFFAF5FF), const Color(0xFFF3E8FF)],
                borderColor: const Color(0xFFE9D5FF),
                textColor: const Color(0xFF6B21A8),
                bulbColor: const Color(0xFFA855F7),
              );
      case AdvisorTipType.success:
        return isDark
            ? _AdvisorTipColors(
                gradientColors: [const Color(0xFF022C22).withValues(alpha: 0.35), const Color(0xFF064E3B).withValues(alpha: 0.25)],
                borderColor: const Color(0xFF16A34A).withValues(alpha: 0.3),
                textColor: const Color(0xFF86EFAC),
                bulbColor: const Color(0xFF22C55E),
              )
            : _AdvisorTipColors(
                gradientColors: [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
                borderColor: const Color(0xFFBBF7D0),
                textColor: const Color(0xFF15803D),
                bulbColor: const Color(0xFF22C55E),
              );
    }
  }

  Widget _buildRichTextContent(String content, Color baseColor, Color highlightColor) {
    final regex = RegExp(r'(৳\d+(?:,\d+)*|\d+%)');
    final matches = regex.allMatches(content);
    if (matches.isEmpty) {
      return Text(
        content,
        style: GoogleFonts.outfit(
          fontSize: 13.5,
          height: 1.45,
          fontWeight: FontWeight.w500,
          color: baseColor,
        ),
      );
    }

    final spans = <TextSpan>[];
    int start = 0;
    for (final match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: content.substring(start, match.start),
          style: TextStyle(color: baseColor, fontWeight: FontWeight.w500),
        ));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: TextStyle(
          color: highlightColor,
          fontWeight: FontWeight.w800,
          shadows: [
            Shadow(
              color: highlightColor.withValues(alpha: 0.35),
              blurRadius: 6,
            ),
          ],
        ),
      ));
      start = match.end;
    }
    if (start < content.length) {
      spans.add(TextSpan(
        text: content.substring(start),
        style: TextStyle(color: baseColor, fontWeight: FontWeight.w500),
      ));
    }

    return RichText(
      text: TextSpan(
        children: spans,
        style: GoogleFonts.outfit(
          fontSize: 13.5,
          height: 1.45,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, _AdvisorTip tip) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _getTipColors(tip.type, isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GlassCard(
        blur: 24,
        opacity: isDark ? 0.03 : 0.45,
        color: isDark ? const Color(0xFF16201D) : Colors.white,
        borderRadius: 24,
        border: Border.all(
          color: colors.borderColor,
          width: 1.5,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.gradientColors[0].withValues(alpha: isDark ? 0.15 : 0.55),
                colors.gradientColors[1].withValues(alpha: isDark ? 0.05 : 0.35),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Ambient Light Bulb Glow Circle
              Positioned(
                right: -25,
                top: -25,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colors.bulbColor.withValues(alpha: isDark ? 0.22 : 0.15),
                        colors.bulbColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row with Pulse Indicator and Type Label
                    Row(
                      children: [
                        GlowingPulseIcon(
                          icon: tip.icon,
                          color: colors.bulbColor,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Pulsing active dot
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colors.bulbColor,
                                      boxShadow: [
                                        BoxShadow(
                                          color: colors.bulbColor.withValues(alpha: 0.6),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppLocalizations.get('ai_wealth_copilot'),
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                      color: colors.textColor.withValues(alpha: isDark ? 0.75 : 0.65),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tip.title,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.5,
                                  color: isDark ? Colors.white : colors.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildRichTextContent(
                        tip.content,
                        isDark ? Colors.white.withValues(alpha: 0.88) : colors.textColor.withValues(alpha: 0.88),
                        colors.textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ScaleOnTap(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => tip.targetScreen),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colors.bulbColor,
                                colors.bulbColor.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: colors.bulbColor.withValues(alpha: isDark ? 0.45 : 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                tip.buttonText,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ],
                          ),
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
                  title: AppLocalizations.get('set_your_goals'),
                  content: "Set your targets! Setting monthly budgets helps users save up to 20% more. Set a goal.",
                  icon: Icons.lightbulb_outline_rounded,
                  buttonText: AppLocalizations.get('set_goal'),
                  targetScreen: const MonthlyGoalScreen(),
                  type: AdvisorTipType.info,
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
                  title: AppLocalizations.get('budget_exceeded'),
                  content: "Budget Exceeded! You spent ৳${overSpent.toInt()} over your monthly limit. Hold non-essential purchases.",
                  icon: Icons.error_outline_rounded,
                  buttonText: AppLocalizations.get('adjust_goals'),
                  targetScreen: const MonthlyGoalScreen(),
                  type: AdvisorTipType.danger,
                ),
              );
            }

            // Priority 2: Nearing Limit (>= 80%)
            if (expenseLimit > 0 && actualExpense >= expenseLimit * 0.8) {
              final utilization = ((actualExpense / expenseLimit) * 100).toInt();
              return _buildCard(
                context,
                _AdvisorTip(
                  title: AppLocalizations.get('budget_warning'),
                  content: "Nearing Limit! You have used $utilization% of your budget. Cut down discretionary spending.",
                  icon: Icons.warning_amber_rounded,
                  buttonText: AppLocalizations.get('adjust_goals'),
                  targetScreen: const MonthlyGoalScreen(),
                  type: AdvisorTipType.warning,
                ),
              );
            }

            // Priority 3: Savings Alert (< 50% of Goal)
            if (savingsTarget > 0 && actualSaved < savingsTarget * 0.5) {
              final savingsPercent = savingsTarget > 0 ? ((actualSaved / savingsTarget) * 100).toInt() : 0;
              return _buildCard(
                context,
                _AdvisorTip(
                  title: AppLocalizations.get('savings_alert'),
                  content: "Savings Alert: You met only $savingsPercent% of your savings target. Log savings early to stay safe.",
                  icon: Icons.savings_rounded,
                  buttonText: AppLocalizations.get('log_savings'),
                  targetScreen: const SavingsScreen(),
                  type: AdvisorTipType.warningAlt,
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
                  title: AppLocalizations.get('category_spike'),
                  content: "Category Check: Spending on '$highestCategory' is $categoryPercent% of your total. Try cooking at home or deferring.",
                  icon: Icons.pie_chart_outline_rounded,
                  buttonText: AppLocalizations.get('view_trends'),
                  targetScreen: const MonthlyGoalScreen(),
                  type: AdvisorTipType.purple,
                ),
              );
            }

            // Priority 5: Savings met or exceeded
            if (savingsTarget > 0 && actualSaved >= savingsTarget) {
              return _buildCard(
                context,
                _AdvisorTip(
                  title: AppLocalizations.get('excellent_cashflow'),
                  content: "Excellent Cashflow! You met your savings target. Put surplus cash into Savings Vaults.",
                  icon: Icons.stars_rounded,
                  buttonText: AppLocalizations.get('log_savings'),
                  targetScreen: const SavingsScreen(),
                  type: AdvisorTipType.success,
                ),
              );
            }

            // Fallback: On Track
            return _buildCard(
              context,
              _AdvisorTip(
                title: AppLocalizations.get('advisor_update'),
                content: "On Track! Your expenses and savings are healthy. Keep tracking and maintain the streak!",
                icon: Icons.insights_rounded,
                buttonText: AppLocalizations.get('view_analytics'),
                targetScreen: const MonthlyGoalScreen(),
                type: AdvisorTipType.info,
              ),
            );
          },
        );
      },
    );
  }
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
                color: widget.color.withValues(alpha: _opacityAnimation.value * 0.3),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: _opacityAnimation.value),
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
            color: widget.color.withValues(alpha: 0.15),
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
