import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/loan_model.dart';
import 'package:pocketledger/services/loan_service.dart';
import 'package:pocketledger/models/account_model.dart';
import 'package:pocketledger/services/account_service.dart';
import 'package:pocketledger/features/auth/widgets/custom_text_field.dart';

class LoanDetailScreen extends StatefulWidget {
  final LoanModel loan;
  const LoanDetailScreen({super.key, required this.loan});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  final LoanService _loanService = LoanService();
  final AccountService _accountService = AccountService();
  
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  AccountModel? _selectedAccount;
  bool _isLoading = false;

  void _handleAddPayment() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an amount')));
      return;
    }

    final paymentAmount = double.tryParse(_amountController.text) ?? 0;
    if (paymentAmount <= 0) return;

    if (paymentAmount > widget.loan.remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment cannot exceed remaining balance')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _loanService.addRepayment(
        loanId: widget.loan.id,
        paymentAmount: paymentAmount,
        linkedAccountId: _selectedAccount?.id,
        linkedAccountName: _selectedAccount?.name,
        note: _noteController.text,
      );

      if (mounted) {
        Navigator.pop(context); // Close modal
        Navigator.pop(context); // Close detail screen so it refreshes from stream on parent
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddPaymentModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPaymentModal(),
    );
  }

  Widget _buildPaymentModal() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 32, left: 24, right: 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: StreamBuilder<List<AccountModel>>(
        stream: _accountService.getAccounts(),
        builder: (context, snapshot) {
          final accounts = snapshot.data ?? [];
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add Repayment', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
              const SizedBox(height: 24),
              
              CustomTextField(
                controller: _amountController,
                hintText: 'Amount (Max: ${widget.loan.remainingAmount.toInt()})',
                icon: Icons.attach_money_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.brandPrimary.withOpacity(0.05)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AccountModel>(
                    value: _selectedAccount,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.secondaryText),
                    hint: Text('Linked Account (Optional)', style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 15)),
                    items: accounts.map((acc) => DropdownMenuItem(
                      value: acc,
                      child: Text(acc.name, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 16)),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedAccount = val),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _noteController,
                hintText: 'Note (Optional)',
                icon: Icons.notes_rounded,
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAddPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Save Payment', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Loan Details', style: GoogleFonts.montserrat(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          children: [
            _buildMainCard(),
            const SizedBox(height: 32),
            _buildRepaymentsList(),
          ],
        ),
      ),
      bottomNavigationBar: widget.loan.status == LoanStatus.pending ? _buildBottomBar() : null,
    );
  }

  Widget _buildMainCard() {
    final isPaid = widget.loan.status == LoanStatus.paid;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))],
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.loan.personName, style: GoogleFonts.montserrat(color: AppColors.primaryText, fontSize: 24, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isPaid ? AppColors.brandPrimary.withOpacity(0.1) : Colors.orangeAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(isPaid ? 'PAID' : 'PENDING', 
                  style: GoogleFonts.montserrat(
                    color: isPaid ? AppColors.brandPrimary : Colors.orangeAccent, 
                    fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1,
                  )
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(widget.loan.type == LoanType.given ? 'Money you gave' : 'Money you took', 
              style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 13)),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statColumn('Total Amount', widget.loan.amount, AppColors.primaryText),
              _statColumn('Paid Back', widget.loan.amount - widget.loan.remainingAmount, AppColors.brandPrimary),
              _statColumn('Remaining', widget.loan.remainingAmount, widget.loan.remainingAmount > 0 ? Colors.redAccent : AppColors.brandPrimary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('৳ ${value.toInt()}', style: GoogleFonts.montserrat(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRepaymentsList() {
    if (widget.loan.repayments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text('No repayments yet.', style: GoogleFonts.montserrat(color: AppColors.secondaryText)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Repayment History', style: GoogleFonts.montserrat(color: AppColors.primaryText, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...widget.loan.repayments.map((rep) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.brandPrimary.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment', style: GoogleFonts.montserrat(color: AppColors.primaryText, fontWeight: FontWeight.w600)),
                  Text('${rep.date.day}/${rep.date.month}/${rep.date.year}', style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 12)),
                  if (rep.note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(rep.note, style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 11)),
                  ]
                ],
              ),
              Text('৳ ${rep.amount.toInt()}', style: GoogleFonts.montserrat(color: AppColors.brandPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: _showAddPaymentModal,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text('Add Payment', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        ),
      ),
    );
  }
}
