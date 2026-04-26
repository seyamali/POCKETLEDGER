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
  LoanType _selectedType = LoanType.given;

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
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.brandPrimary, size: 28),
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
            return const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
          }

          final allLoans = snapshot.data ?? [];
          final filteredLoans = allLoans.where((l) => l.type == _selectedType).toList();

          return Column(
            children: [
              _buildSummaryHeader(allLoans),
              const SizedBox(height: 16),
              _buildToggleSwitch(),
              const SizedBox(height: 16),
              Expanded(
                child: filteredLoans.isEmpty 
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
          _toggleButton(LoanType.given, 'Given Loans'),
          _toggleButton(LoanType.taken, 'Taken Loans'),
        ],
      ),
    );
  }

  Widget _toggleButton(LoanType type, String label) {
    bool isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
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
              fontSize: 14,
            )),
        ),
      ),
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
                      child: const Icon(Icons.person_outline, color: AppColors.brandPrimary),
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
