import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/loan_model.dart';
import 'package:pocketledger/services/loan_service.dart';
import 'package:pocketledger/features/loans/add_loan_screen.dart';
import 'package:pocketledger/features/loans/loan_detail_screen.dart';
import 'package:pocketledger/core/widgets/scale_on_tap.dart';
import 'package:pocketledger/core/widgets/glass_card.dart';
import 'package:pocketledger/core/localization/app_localizations.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  final LoanService _loanService = LoanService();
  int _selectedTabIndex = 0; // 0: Given, 1: Taken, 2: By Person
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ThemeBuilder(builder: (context) => Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Loans',
          style: GoogleFonts.outfit(
            color: AppColors.primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
        actions: [
          ScaleOnTap(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddLoanScreen()));
            },
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandPrimary.withValues(alpha: 0.1),
              ),
              child: Icon(Icons.add_rounded, color: AppColors.brandPrimary, size: 24),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<LoanModel>>(
        stream: _loanService.getLoans(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.w500),
                ),
              ),
            );
          }

          final allLoans = snapshot.data ?? [];
          var filteredLoans = allLoans.where((l) =>
              _selectedTabIndex == 0 ? l.type == LoanType.given : l.type == LoanType.taken
          ).toList();

          if (_searchQuery.isNotEmpty) {
            filteredLoans = filteredLoans.where((l) {
              final nameMatch = l.personName.toLowerCase().contains(_searchQuery);
              final noteMatch = l.note.toLowerCase().contains(_searchQuery);
              return nameMatch || noteMatch;
            }).toList();
          }

          return Stack(
            children: [
              // Ambient backgrounds
              Positioned(
                top: -20, right: -40,
                child: Container(
                  width: 220, height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brandPrimary.withValues(alpha: isDark ? 0.08 : 0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: 120, left: -60,
                child: Container(
                  width: 240, height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blueAccent.withValues(alpha: isDark ? 0.06 : 0.04),
                  ),
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(color: Colors.transparent),
                ),
              ),
              Column(
                children: [
                  _buildSummaryHeader(allLoans, isDark),
                  const SizedBox(height: 16),
                  _buildToggleSwitch(isDark),
                  _buildSearchBar(isDark),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _selectedTabIndex == 2
                        ? _buildByPersonList(allLoans, isDark)
                        : filteredLoans.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 80),
                                physics: const BouncingScrollPhysics(),
                                itemCount: filteredLoans.length,
                                itemBuilder: (context, index) => _LoanCard(loan: filteredLoans[index]),
                              ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    )); // closes Scaffold + ThemeBuilder
  }

  Widget _buildSummaryHeader(List<LoanModel> allLoans, bool isDark) {
    double totalGiven = 0;
    double totalTaken = 0;
    double totalGivenPending = 0;
    double totalTakenPending = 0;

    for (var loan in allLoans) {
      if (loan.type == LoanType.given) {
        totalGiven += loan.amount;
        totalGivenPending += loan.remainingAmount;
      } else {
        totalTaken += loan.amount;
        totalTakenPending += loan.remainingAmount;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GlassCard(
        blur: 20,
        opacity: isDark ? 0.06 : 0.45,
        color: isDark ? const Color(0xFF16201D) : Colors.white,
        borderRadius: 24,
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.15)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(child: _summaryStat('GIVEN TOTAL', totalGiven, 'Pending: ৳${totalGivenPending.toInt()}', AppColors.brandPrimary)),
              Container(width: 1, height: 44, color: AppColors.brandPrimary.withValues(alpha: 0.08)),
              Expanded(child: _summaryStat('TAKEN TOTAL', totalTaken, 'Pending: ৳${totalTakenPending.toInt()}', Colors.redAccent)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryStat(String title, double amount, String subtitle, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 6),
        Text(
          '৳${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => "${m[1]},")}',
          style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildToggleSwitch(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16201D).withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _toggleButton(0, 'Given'),
          _toggleButton(1, 'Taken'),
          _toggleButton(2, 'By Person'),
        ],
      ),
    );
  }

  Widget _toggleButton(int index, String label) {
    bool isSelected = _selectedTabIndex == index;
    Color activeColor = AppColors.brandPrimary;
    if (index == 1) activeColor = Colors.redAccent;
    else if (index == 2) activeColor = Colors.blueAccent;

    return Expanded(
      child: ScaleOnTap(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: isSelected ? Colors.white : AppColors.secondaryText,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    final isFocused = _searchFocusNode.hasFocus;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: GlassCard(
        blur: 10,
        opacity: isDark ? 0.03 : 0.45,
        color: isDark ? const Color(0xFF16201D) : Colors.white,
        borderRadius: 16,
        border: Border.all(
          color: isFocused
              ? AppColors.brandPrimary.withValues(alpha: 0.4)
              : AppColors.brandPrimary.withValues(alpha: 0.08),
          width: isFocused ? 1.5 : 1.0,
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
          decoration: InputDecoration(
            hintText: AppLocalizations.get('search_by_person_name'),
            hintStyle: GoogleFonts.outfit(color: AppColors.secondaryText, fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded, color: isFocused ? AppColors.brandPrimary : AppColors.secondaryText, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? ScaleOnTap(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Icon(Icons.clear_rounded, color: AppColors.secondaryText, size: 18),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primaryText),
        ),
      ),
    );
  }

  Widget _buildByPersonList(List<LoanModel> allLoans, bool isDark) {
    if (allLoans.isEmpty) return _buildEmptyState();

    Map<String, Map<String, dynamic>> personSummary = {};
    for (var loan in allLoans) {
      String rawName = loan.personName.trim();
      String key = rawName.toLowerCase();

      if (_searchQuery.isNotEmpty && !key.contains(_searchQuery)) {
        continue;
      }

      if (!personSummary.containsKey(key)) {
        personSummary[key] = {'name': rawName, 'given': 0.0, 'taken': 0.0, 'net': 0.0, 'count': 0};
      }

      personSummary[key]!['count'] = (personSummary[key]!['count'] as int) + 1;

      if (loan.type == LoanType.given) {
        personSummary[key]!['given'] = (personSummary[key]!['given'] as double) + loan.remainingAmount;
        personSummary[key]!['net'] = (personSummary[key]!['net'] as double) + loan.remainingAmount;
      } else {
        personSummary[key]!['taken'] = (personSummary[key]!['taken'] as double) + loan.remainingAmount;
        personSummary[key]!['net'] = (personSummary[key]!['net'] as double) - loan.remainingAmount;
      }
    }

    final personsKeys = personSummary.keys.toList()..sort();
    if (personsKeys.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 80),
      physics: const BouncingScrollPhysics(),
      itemCount: personsKeys.length,
      itemBuilder: (context, index) {
        final key = personsKeys[index];
        final summary = personSummary[key]!;

        final name = summary['name'] as String;
        final count = summary['count'] as int;
        final given = summary['given'] as double;
        final taken = summary['taken'] as double;
        final net = summary['net'] as double;

        bool theyOwe = net > 0;
        bool settled = net == 0;

        Color netColor = settled
            ? AppColors.brandPrimary
            : (theyOwe ? AppColors.brandPrimary : Colors.redAccent);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassCard(
            blur: 15,
            opacity: isDark ? 0.04 : 0.45,
            color: isDark ? const Color(0xFF16201D) : Colors.white,
            borderRadius: 24,
            border: Border.all(color: netColor.withValues(alpha: 0.15)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: netColor.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person_rounded, color: netColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: GoogleFonts.outfit(color: AppColors.textBlack, fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('$count loan${count > 1 ? "s" : ""}', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11.5, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: settled ? AppColors.brandPrimary.withValues(alpha: 0.1) : (theyOwe ? AppColors.brandPrimary.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          settled ? 'SETTLED' : (theyOwe ? 'THEY OWE' : 'YOU OWE'),
                          style: GoogleFonts.outfit(
                            color: settled ? AppColors.brandPrimary : (theyOwe ? AppColors.brandPrimary : Colors.redAccent),
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _detailStat('Given (Pending)', given, AppColors.textGrey),
                      _detailStat('Taken (Pending)', taken, AppColors.textGrey),
                      _detailStat('Net Balance', net.abs(), netColor),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brandPrimary.withValues(alpha: 0.05),
            ),
            child: Icon(Icons.handshake_outlined, size: 54, color: AppColors.brandPrimary.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 20),
          Text(
            'No loans found',
            style: GoogleFonts.outfit(color: AppColors.secondaryText, fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _detailStat(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          '৳${value.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => "${m[1]},")}',
          style: GoogleFonts.outfit(color: color, fontSize: 14.5, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _LoanCard extends StatelessWidget {
  final LoanModel loan;

  const _LoanCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    final isPaid = loan.status == LoanStatus.paid;
    final isGiven = loan.type == LoanType.given;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color loanColor = isGiven ? AppColors.brandPrimary : Colors.redAccent;
    IconData loanIcon = isGiven ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ScaleOnTap(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => LoanDetailScreen(loan: loan)));
        },
        child: GlassCard(
          blur: 15,
          opacity: isDark ? 0.04 : 0.45,
          color: isDark ? const Color(0xFF16201D) : Colors.white,
          borderRadius: 24,
          border: Border.all(color: loanColor.withValues(alpha: 0.15)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: loanColor.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(loanIcon, color: loanColor, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loan.personName, style: GoogleFonts.outfit(color: AppColors.textBlack, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 2),
                            Text(DateFormat('dd MMM yyyy').format(loan.date), style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11.5)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isPaid ? AppColors.brandPrimary.withValues(alpha: 0.1) : Colors.orangeAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPaid ? 'PAID' : 'PENDING',
                        style: GoogleFonts.outfit(
                          color: isPaid ? AppColors.brandPrimary : Colors.orangeAccent,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _detailStat('Total ${isGiven ? "Given" : "Taken"}', loan.amount, AppColors.textGrey),
                    _detailStat('Paid Back', loan.amount - loan.remainingAmount, AppColors.brandPrimary),
                    _detailStat('Remaining', loan.remainingAmount, loan.remainingAmount > 0 ? Colors.redAccent : AppColors.brandPrimary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailStat(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          "৳${value.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}",
          style: GoogleFonts.outfit(color: color, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
