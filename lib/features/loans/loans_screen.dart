import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/loan_model.dart';
import 'package:pocketledger/services/loan_service.dart';
import 'package:pocketledger/features/loans/add_loan_screen.dart';
import 'package:pocketledger/features/loans/loan_detail_screen.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  final LoanService _loanService = LoanService();
  int _selectedTabIndex = 0; // 0: Given, 1: Taken, 2: By Person
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Loans', style: GoogleFonts.montserrat(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: AppColors.brandPrimary, size: 28),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddLoanScreen()));
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<List<LoanModel>>(
        stream: _loanService.getLoans(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
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

          return Column(
            children: [
              _buildSummaryHeader(allLoans),
              const SizedBox(height: 16),
              _buildToggleSwitch(),
              _buildSearchBar(),
              const SizedBox(height: 8),
              Expanded(
                child: _selectedTabIndex == 2 
                    ? _buildByPersonList(allLoans)
                    : filteredLoans.isEmpty 
                        ? _buildEmptyState() 
                        : ListView.builder(
                            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredLoans.length,
                            itemBuilder: (context, index) => _LoanCard(loan: filteredLoans[index]),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(List<LoanModel> allLoans) {
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))],
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(child: _summaryStat('Given Total', totalGiven, 'Pending: $totalGivenPending')),
          Container(width: 1, height: 40, color: AppColors.brandPrimary.withOpacity(0.1)),
          Expanded(child: _summaryStat('Taken Total', totalTaken, 'Pending: $totalTakenPending')),
        ],
      ),
    );
  }

  Widget _summaryStat(String title, double amount, String subtitle) {
    return Column(
      children: [
        Text(title, style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('৳ ${amount.toInt()}', style: GoogleFonts.montserrat(color: AppColors.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitle, style: GoogleFonts.montserrat(color: AppColors.brandPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildToggleSwitch() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
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
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected ? [BoxShadow(color: AppColors.brandPrimary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
          ),
          child: Text(label, 
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: isSelected ? Colors.white : AppColors.secondaryText,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            )),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: AppColors.brandPrimary.withOpacity(0.05)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search by person name or note...',
            hintStyle: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded, color: AppColors.secondaryText, size: 20),
            suffixIcon: _searchQuery.isNotEmpty 
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: AppColors.secondaryText, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primaryText),
        ),
      ),
    );
  }

  Widget _buildByPersonList(List<LoanModel> allLoans) {
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
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
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
        
        bool youOwe = net < 0;
        bool theyOwe = net > 0;
        bool settled = net == 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
            border: Border.all(color: AppColors.brandPrimary.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person, color: AppColors.brandPrimary),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: GoogleFonts.montserrat(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('$count loan${count > 1 ? 's' : ''}', style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 11, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: settled ? AppColors.brandPrimary.withOpacity(0.1) : (theyOwe ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(settled ? 'SETTLED' : (theyOwe ? 'THEY OWE' : 'YOU OWE'), 
                      style: GoogleFonts.montserrat(
                        color: settled ? AppColors.brandPrimary : (theyOwe ? Colors.green : Colors.red), 
                        fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1,
                      )
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _detailStat('Given (Pending)', given, AppColors.secondaryText),
                  _detailStat('Taken (Pending)', taken, AppColors.secondaryText),
                  _detailStat('Net Balance', net.abs(), settled ? AppColors.brandPrimary : (theyOwe ? Colors.green : Colors.red)),
                ],
              ),
            ],
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
          Icon(Icons.handshake_outlined, size: 80, color: AppColors.brandPrimary.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('No loans found', style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _detailStat(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('৳ ${value.toInt()}', style: GoogleFonts.montserrat(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
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

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => LoanDetailScreen(loan: loan)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
          border: Border.all(color: AppColors.brandPrimary.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person_outline, color: AppColors.brandPrimary),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loan.personName, style: GoogleFonts.montserrat(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${loan.date.day}/${loan.date.month}/${loan.date.year}', style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPaid ? AppColors.brandPrimary.withOpacity(0.1) : Colors.orangeAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(isPaid ? 'PAID' : 'PENDING', 
                    style: GoogleFonts.montserrat(
                      color: isPaid ? AppColors.brandPrimary : Colors.orangeAccent, 
                      fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1,
                    )
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _detailStat('Total ${loan.type == LoanType.given ? "Given" : "Taken"}', loan.amount, AppColors.secondaryText),
                _detailStat('Paid Back', loan.amount - loan.remainingAmount, AppColors.brandPrimary),
                _detailStat('Remaining', loan.remainingAmount, loan.remainingAmount > 0 ? Colors.redAccent : AppColors.brandPrimary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailStat(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('৳ ${value.toInt()}', style: GoogleFonts.montserrat(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
