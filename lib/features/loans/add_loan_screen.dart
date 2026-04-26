import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/loan_model.dart';
import 'package:pocketledger/services/loan_service.dart';
import 'package:pocketledger/features/auth/widgets/custom_text_field.dart';
import 'package:pocketledger/models/account_model.dart';
import 'package:pocketledger/services/account_service.dart';

class AddLoanScreen extends StatefulWidget {
  const AddLoanScreen({super.key});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final LoanService _loanService = LoanService();
  final AccountService _accountService = AccountService();

  LoanType _selectedType = LoanType.given;
  AccountModel? _selectedAccount;

  final _personNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isLoading = false;
  bool _adjustBalance = false; // OFF by default — for existing loans, balance is already correct

  void _handleSave() async {
    if (_personNameController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter name and amount')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _loanService.addLoan(
        personName: _personNameController.text,
        amount: double.parse(_amountController.text),
        type: _selectedType,
        linkedAccountId: _adjustBalance ? _selectedAccount?.id : null,
        linkedAccountName: _adjustBalance ? _selectedAccount?.name : null,
        note: _noteController.text,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.primaryText, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('New Loan', style: GoogleFonts.montserrat(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<AccountModel>>(
        stream: _accountService.getAccounts(),
        builder: (context, snapshot) {
          final accounts = snapshot.data ?? [];

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildTypeSelector(),
                const SizedBox(height: 40),

                Text('AMOUNT', style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                _buildAmountInput(),

                const SizedBox(height: 48),
                _buildSectionLabel('PERSON NAME'),
                const SizedBox(height: 12),
                _buildDetailsInputs(),

                const SizedBox(height: 24),
                _buildSectionLabel('LINK ACCOUNT (OPTIONAL)'),
                const SizedBox(height: 12),
                _buildAccountDropdown(accounts),

                const SizedBox(height: 24),
                _buildAdjustBalanceToggle(),

                const SizedBox(height: 48),
                _buildSaveButton(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label, 
        style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          _typeButton(LoanType.given, 'Given Loan'),
          _typeButton(LoanType.taken, 'Taken Loan'),
        ],
      ),
    );
  }

  Widget _typeButton(LoanType type, String label) {
    bool isSelected = _selectedType == type;
    Color activeColor = AppColors.brandPrimary;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected ? [BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
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

  Widget _buildAmountInput() {
    return IntrinsicWidth(
      child: TextField(
        controller: _amountController,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: GoogleFonts.montserrat(fontSize: 54, fontWeight: FontWeight.bold, color: AppColors.primaryText),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: '0',
          hintStyle: TextStyle(color: AppColors.secondaryText.withOpacity(0.3)),
          prefixText: '৳ ',
          prefixStyle: const TextStyle(color: AppColors.brandPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDetailsInputs() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          CustomTextField(
            controller: _personNameController,
            hintText: 'Person Name (e.g. Rahim)',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 24),
          CustomTextField(
            controller: _noteController,
            hintText: 'Note (optional)',
            icon: Icons.notes_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustBalanceToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Adjust Account Balance', style: GoogleFonts.montserrat(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  _adjustBalance 
                    ? 'ON — Balance will be updated now'
                    : 'OFF — Only records the loan (balance already correct)',
                  style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: _adjustBalance,
            activeColor: AppColors.brandPrimary,
            onChanged: (val) => setState(() => _adjustBalance = val),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDropdown(List<AccountModel> accounts) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AccountModel>(
          value: _selectedAccount != null && accounts.any((a) => a.id == _selectedAccount!.id) 
              ? accounts.firstWhere((a) => a.id == _selectedAccount!.id) 
              : null,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.secondaryText),
          hint: Text('Select Account', style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 15)),
          items: accounts.map((acc) => DropdownMenuItem(
            value: acc,
            child: Text(acc.name, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 16)),
          )).toList(),
          onChanged: (val) => setState(() => _selectedAccount = val),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.brandPrimary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : Text('Save Loan', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5)),
      ),
    );
  }
}
