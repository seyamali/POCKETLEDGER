import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/account_model.dart';
import 'package:pocketledger/models/transaction_model.dart';
import 'package:pocketledger/services/account_service.dart';
import 'package:pocketledger/services/transaction_service.dart';
import 'package:pocketledger/features/auth/widgets/custom_text_field.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final AccountService _accountService = AccountService();
  final TransactionService _transactionService = TransactionService();

  void _showAddOpeningSavingsModal() {
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 32, left: 24, right: 24,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primaryBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Add Opening Savings', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                const SizedBox(height: 8),
                Text('E.g. A fixed deposit or piggy bank you already have', style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.secondaryText), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                
                CustomTextField(
                  controller: nameCtrl,
                  hintText: 'Savings Name (e.g. My bKash Savings)',
                  icon: Icons.edit_note_rounded,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: balanceCtrl,
                  hintText: 'Initial Amount (৳)',
                  icon: Icons.savings_outlined,
                  keyboardType: TextInputType.number,
                ),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      if (nameCtrl.text.isEmpty || balanceCtrl.text.isEmpty) return;
                      setModalState(() => isLoading = true);
                      
                      await _accountService.createAccount(
                        name: nameCtrl.text,
                        type: 'Savings',
                        breakdown: {'Self': double.parse(balanceCtrl.text)},
                      );
                      
                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Save Opening Balance', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showAddSavingsTransferModal(List<AccountModel> allAccounts) {
    final amountCtrl = TextEditingController();
    AccountModel? fromAccount;
    AccountModel? toSavingsAccount;
    bool isLoading = false;
    DateTime selectedMonth = DateTime.now();

    final standardAccounts = allAccounts.where((a) => a.type != 'Savings').toList();
    final savingsAccounts = allAccounts.where((a) => a.type == 'Savings').toList();

    if (savingsAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add an Opening Savings account first!')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 32, left: 24, right: 24,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primaryBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Add to Savings', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                const SizedBox(height: 4),
                Text('Move money from your wallet to a savings account', style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.secondaryText), textAlign: TextAlign.center),
                const SizedBox(height: 20),

                // Month selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.brandPrimary.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded, size: 16, color: AppColors.brandPrimary),
                        onPressed: () => setModalState(() => selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1)),
                      ),
                      Text('${monthNames[selectedMonth.month - 1]} ${selectedMonth.year}',
                        style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AppColors.primaryText, fontSize: 15)),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.brandPrimary),
                        onPressed: () => setModalState(() => selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: amountCtrl,
                  hintText: 'Amount (৳)',
                  icon: Icons.arrow_downward_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                
                _buildModalDropdown(standardAccounts, 'From Account (e.g. Bank/Cash)', fromAccount, (val) => setModalState(() => fromAccount = val)),
                const SizedBox(height: 16),
                _buildModalDropdown(savingsAccounts, 'To Savings Account', toSavingsAccount, (val) => setModalState(() => toSavingsAccount = val)),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      if (amountCtrl.text.isEmpty || fromAccount == null || toSavingsAccount == null) return;
                      setModalState(() => isLoading = true);
                      
                      // Use the 15th of the selected month as the transaction date
                      final txDate = DateTime(selectedMonth.year, selectedMonth.month, 15);

                      await _transactionService.addTransferWithDate(
                        fromAccountId: fromAccount!.id,
                        fromAccountName: fromAccount!.name,
                        fromOwner: 'Self',
                        toAccountId: toSavingsAccount!.id,
                        toAccountName: toSavingsAccount!.name,
                        toOwner: 'Self',
                        amount: double.parse(amountCtrl.text),
                        note: 'Monthly savings contribution',
                        category: 'Savings Transfer',
                        date: txDate,
                      );
                      
                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Complete Transfer', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildModalDropdown(List<AccountModel> accounts, String hint, AccountModel? value, Function(AccountModel?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AccountModel>(
          value: value != null && accounts.any((a) => a.id == value.id) 
              ? accounts.firstWhere((a) => a.id == value.id) 
              : null,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          hint: Text(hint, style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 13)),
          items: accounts.map((acc) => DropdownMenuItem(value: acc, child: Text(acc.name, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 15)))).toList(),
          onChanged: onChanged,
        ),
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
        title: Text('Savings', style: GoogleFonts.montserrat(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryText, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: StreamBuilder<List<AccountModel>>(
        stream: _accountService.getAccounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
          }

          final allAccounts = snapshot.data ?? [];
          final savingsAccounts = allAccounts.where((a) => a.type == 'Savings').toList();
          double totalSavings = savingsAccounts.fold(0, (sum, acc) => sum + acc.totalBalance);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              children: [
                _buildTotalSavingsCard(totalSavings),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildActionBtn(
                        'Opening Savings', 
                        Icons.add_card_rounded, 
                        _showAddOpeningSavingsModal,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionBtn(
                        'Add to Savings', 
                        Icons.move_up_rounded, 
                        () => _showAddSavingsTransferModal(allAccounts),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('YOUR SAVINGS ACCOUNTS', style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
                const SizedBox(height: 16),
                
                if (savingsAccounts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('No savings accounts yet. Add an Opening Saving to start!', textAlign: TextAlign.center, style: GoogleFonts.montserrat(color: AppColors.secondaryText)),
                  )
                else
                  ...savingsAccounts.map((acc) => _buildSavingsCard(acc)),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildTotalSavingsCard(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade600, Colors.amber.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.savings_rounded, color: Colors.white.withOpacity(0.9), size: 48),
          const SizedBox(height: 16),
          Text('Total Savings', style: GoogleFonts.montserrat(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('৳ ${total.toInt()}', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.brandPrimary.withOpacity(0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.brandPrimary, size: 28),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.montserrat(color: AppColors.primaryText, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsCard(AccountModel acc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance_wallet_rounded, color: Colors.amber.shade600),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(acc.name, style: GoogleFonts.montserrat(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Savings Vault', style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 12)),
              ],
            ),
          ),
          Text('৳ ${acc.totalBalance.toInt()}', style: GoogleFonts.montserrat(color: AppColors.brandPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
