import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/account_model.dart';
import 'package:pocketledger/models/transaction_model.dart';
import 'package:pocketledger/services/account_service.dart';
import 'package:pocketledger/services/transaction_service.dart';
import 'package:pocketledger/features/auth/widgets/custom_text_field.dart';
import 'package:pocketledger/core/constants/app_constants.dart';

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
              bottom: MediaQuery.of(context).viewInsets.bottom + 30,
              top: 15, left: 24, right: 24,
            ),
            decoration: BoxDecoration(
              color: Color(0xFFF4F6F5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _modalHeader(context, 'New Savings Account'),
                const SizedBox(height: 24),
                _buildModalInput('Account Name (e.g. DPS, bKash)', nameCtrl, Icons.edit_note_rounded, Colors.amber.shade600, isNumeric: false),
                const SizedBox(height: 16),
                _buildModalInput('Opening Balance', balanceCtrl, Icons.savings_rounded, Colors.amber.shade600, isNumeric: true),
                const SizedBox(height: 32),
                _primaryBtn('Create Account', isLoading, () async {
                  if (nameCtrl.text.isEmpty || balanceCtrl.text.isEmpty) return;
                  setModalState(() => isLoading = true);
                  await _accountService.createAccount(
                    name: nameCtrl.text,
                    type: 'Savings',
                    breakdown: {AppConstants.ownerSelf: double.parse(balanceCtrl.text)},
                  );
                  if (mounted) Navigator.pop(context);
                }),
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
    bool alreadyPaid = false;
    DateTime selectedMonth = DateTime.now();

    final standardAccounts = allAccounts.where((a) => a.type != 'Savings').toList();
    final savingsAccounts = allAccounts.where((a) => a.type == 'Savings').toList();

    if (savingsAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a savings account first!')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 30,
              top: 15, left: 24, right: 24,
            ),
            decoration: BoxDecoration(
              color: Color(0xFFF4F6F5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _modalHeader(context, 'Add to Savings'),
                  const SizedBox(height: 24),
                  
                  // Month Picker
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(15)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: () => setModalState(() => selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1))),
                        Text('${_getMonthName(selectedMonth.month)} ${selectedMonth.year}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: () => setModalState(() => selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildModalInput('Amount to Save', amountCtrl, Icons.add_circle_rounded, AppColors.primaryGreen, isNumeric: true),
                  const SizedBox(height: 16),
                  
                  // Toggle for "Already Paid"
                  GestureDetector(
                    onTap: () => setModalState(() => alreadyPaid = !alreadyPaid),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: alreadyPaid ? AppColors.primaryGreen.withOpacity(0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: alreadyPaid ? AppColors.primaryGreen : Colors.transparent),
                      ),
                      child: Row(
                        children: [
                          Icon(alreadyPaid ? Icons.check_circle_rounded : Icons.info_outline_rounded, color: alreadyPaid ? AppColors.primaryGreen : AppColors.textGrey, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Already paid/deducted?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Won\'t cut from your wallet/cash balance', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textGrey)),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: alreadyPaid,
                            onChanged: (v) => setModalState(() => alreadyPaid = v),
                            activeColor: AppColors.primaryGreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (!alreadyPaid) ...[
                    _buildModalDropdown(standardAccounts, 'Deduct From', fromAccount, (val) => setModalState(() => fromAccount = val)),
                    const SizedBox(height: 16),
                  ],
                  
                  _buildModalDropdown(savingsAccounts, 'Save Into', toSavingsAccount, (val) => setModalState(() => toSavingsAccount = val)),
                  
                  const SizedBox(height: 32),
                  _primaryBtn('Complete Saving', isLoading, () async {
                    if (amountCtrl.text.isEmpty || toSavingsAccount == null || (!alreadyPaid && fromAccount == null)) return;
                    setModalState(() => isLoading = true);
                    
                    final now = DateTime.now();
                    final isCurrentMonth = selectedMonth.year == now.year && selectedMonth.month == now.month;
                    
                    // Use exact 'now' for current month entries so they show at the top
                    // Use 15th of the month for past/future entries
                    final txDate = isCurrentMonth 
                        ? now 
                        : DateTime(selectedMonth.year, selectedMonth.month, 15);
                        
                    final amount = double.parse(amountCtrl.text);

                    if (alreadyPaid) {
                      // Manual log: Increase Savings account balance without deducting from others
                      // We log it as an "Adjustment/Manual" transaction
                      await _transactionService.addManualBalanceAdjustment(
                        accountId: toSavingsAccount!.id,
                        accountName: toSavingsAccount!.name,
                        amount: amount,
                        category: 'Savings (Already Paid)',
                        date: txDate,
                        isAddition: true,
                      );
                    } else {
                      await _transactionService.addTransferWithDate(
                        fromAccountId: fromAccount!.id,
                        fromAccountName: fromAccount!.name,
                        fromOwner: AppConstants.ownerSelf,
                        toAccountId: toSavingsAccount!.id,
                        toAccountName: toSavingsAccount!.name,
                        toOwner: AppConstants.ownerSelf,
                        amount: amount,
                        note: 'Monthly savings contribution',
                        category: 'Savings Transfer',
                        date: txDate,
                      );
                    }
                    if (mounted) Navigator.pop(context);
                  }),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _modalHeader(BuildContext context, String title) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: AppColors.textGrey)),
        ),
        Positioned(top: 25, child: Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildModalInput(String label, TextEditingController ctrl, IconData icon, Color color, {bool isNumeric = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(20)),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 12),
          prefixIcon: Icon(icon, color: color, size: 20),
          border: InputBorder.none,
          suffixText: isNumeric ? '৳' : null,
        ),
      ),
    );
  }

  Widget _buildModalDropdown(List<AccountModel> accounts, String hint, AccountModel? value, Function(AccountModel?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(20)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AccountModel>(
          value: value != null && accounts.any((a) => a.id == value.id) ? accounts.firstWhere((a) => a.id == value.id) : null,
          isExpanded: true,
          hint: Text(hint, style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13)),
          items: accounts.map((acc) => DropdownMenuItem(value: acc, child: Text(acc.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _primaryBtn(String label, bool isLoading, VoidCallback onTap) {
    return Container(
      width: double.infinity, height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primaryGreen, AppColors.primaryGreen.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primaryGreen.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        child: isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        elevation: 0,
        title: Text('Savings Dashboard', style: GoogleFonts.outfit(color: AppColors.textBlack, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textBlack, size: 18), onPressed: () => Navigator.pop(context)),
      ),
      body: StreamBuilder<List<AccountModel>>(
        stream: _accountService.getAccounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
          final allAccounts = snapshot.data ?? [];
          final savingsAccounts = allAccounts.where((a) => a.type == 'Savings').toList();
          double totalSavings = savingsAccounts.fold(0, (sum, acc) => sum + acc.totalBalance);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
            child: Column(
              children: [
                _buildTotalSavingsCard(totalSavings),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildActionBtn('Add Account', Icons.add_business_rounded, Colors.blueAccent, _showAddOpeningSavingsModal)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildActionBtn('Log Savings', Icons.auto_graph_rounded, AppColors.primaryGreen, () => _showAddSavingsTransferModal(allAccounts))),
                  ],
                ),
                const SizedBox(height: 32),
                Align(alignment: Alignment.centerLeft, child: Text('YOUR SAVINGS VAULTS', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5))),
                const SizedBox(height: 16),
                if (savingsAccounts.isEmpty) _buildEmptyState() else ...savingsAccounts.map((acc) => _buildSavingsCard(acc)),
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
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.amber.shade600, Colors.amber.shade400], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 12))],
      ),
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.savings_rounded, color: Colors.white, size: 30)),
          const SizedBox(height: 20),
          Text('Total Net Savings', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('৳${total.toInt()}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: -1)),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsCard(AccountModel acc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.account_balance_wallet_rounded, color: Colors.amber.shade600, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(acc.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Secure Savings Vault', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11)),
              ],
            ),
          ),
          Text('৳${acc.totalBalance.toInt()}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.primaryGreen)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(padding: const EdgeInsets.all(40), child: Text('No vaults found. Tap Add Account to create your first savings vault.', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13)));
  }

  String _getMonthName(int month) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[month - 1];
  }
}
