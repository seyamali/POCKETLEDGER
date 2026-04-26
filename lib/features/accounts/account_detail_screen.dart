import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/account_model.dart';
import 'package:pocketledger/models/transaction_model.dart';
import 'package:pocketledger/services/transaction_service.dart';
import 'package:intl/intl.dart';

class AccountDetailScreen extends StatelessWidget {
  final AccountModel account;
  const AccountDetailScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final TransactionService transactionService = TransactionService();

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(account.name, style: GoogleFonts.montserrat(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildBalanceHeader(),
            _buildBreakdownSection(),
            _buildActionButtons(context),
            _buildTransactionSection(transactionService),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Text('Full Balance', style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            '৳ ${account.totalBalance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},")}',
            style: GoogleFonts.montserrat(color: AppColors.primaryText, fontSize: 48, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(account.type, style: GoogleFonts.montserrat(color: AppColors.brandPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Owner Breakdown', style: GoogleFonts.montserrat(color: AppColors.primaryText, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...account.breakdown.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.brandPrimary, shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Text(entry.key, style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 14)),
                  ],
                ),
                Text('৳ ${entry.value.toInt()}', style: GoogleFonts.montserrat(color: AppColors.primaryText, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: _actionButton(
              context, 
              'Add Money', 
              Icons.add_rounded, 
              AppColors.brandPrimary,
              () => Navigator.pushNamed(context, '/add-transaction', arguments: TransactionType.income)
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _actionButton(
              context, 
              'Withdraw', 
              Icons.remove_rounded, 
              Colors.redAccent,
              () => Navigator.pushNamed(context, '/add-transaction', arguments: TransactionType.expense)
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
    );
  }

  Widget _buildTransactionSection(TransactionService service) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transactions', style: GoogleFonts.montserrat(color: AppColors.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          StreamBuilder<List<TransactionModel>>(
            stream: service.getTransactionsByAccount(account.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text('No transactions yet', style: GoogleFonts.montserrat(color: AppColors.secondaryText)),
                  ),
                );
              }

              final transactions = snapshot.data!;
              return Column(
                children: transactions.map((tx) => _transactionItem(tx)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _transactionItem(TransactionModel tx) {
    final bool isIncome = tx.type == TransactionType.income;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isIncome ? AppColors.brandPrimary : Colors.redAccent).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isIncome ? AppColors.brandPrimary : Colors.redAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.category, style: GoogleFonts.montserrat(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(DateFormat('dd MMM yyyy').format(tx.date), style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 11)),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${tx.amount.toInt()}',
            style: GoogleFonts.montserrat(
              color: isIncome ? AppColors.brandPrimary : Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
