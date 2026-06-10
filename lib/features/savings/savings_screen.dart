import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/account_model.dart';
import 'package:pocketledger/models/transaction_model.dart';
import 'package:pocketledger/services/account_service.dart';
import 'package:pocketledger/services/transaction_service.dart';
import 'package:pocketledger/features/auth/widgets/custom_text_field.dart';
import 'package:pocketledger/core/constants/app_constants.dart';
import 'package:pocketledger/core/localization/app_localizations.dart';
import 'package:pocketledger/services/notification_service.dart';
import 'package:pocketledger/core/widgets/glass_card.dart';
import 'package:pocketledger/core/widgets/scale_on_tap.dart';

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
    final balanceCtrl = TextEditingController(text: '0');
    bool isLoading = false;
    
    bool isInstallmentEnabled = false;
    final installmentAmtCtrl = TextEditingController();
    final installmentDurationCtrl = TextEditingController();
    String installmentFrequency = 'Monthly';

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
                _modalHeader(context, AppLocalizations.get('new_savings_account')),
                const SizedBox(height: 24),
                _buildModalInput(AppLocalizations.get('account_name_eg_savings'), nameCtrl, Icons.edit_note_rounded, Colors.amber.shade600, isNumeric: false),
                const SizedBox(height: 16),
                _buildModalInput(AppLocalizations.get('opening_balance'), balanceCtrl, Icons.savings_rounded, Colors.amber.shade600, isNumeric: true, isCurrency: true),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Enable DPS/Installment Plan', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                      Switch(
                        value: isInstallmentEnabled,
                        activeColor: AppColors.primaryGreen,
                        onChanged: (val) => setModalState(() => isInstallmentEnabled = val),
                      ),
                    ],
                  ),
                ),
                if (isInstallmentEnabled) ...[
                  const SizedBox(height: 16),
                  _buildModalInput('Installment Amount', installmentAmtCtrl, Icons.payments_rounded, AppColors.primaryGreen, isNumeric: true, isCurrency: true),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModalInput('Total Months (e.g. 6)', installmentDurationCtrl, Icons.calendar_month_rounded, AppColors.primaryGreen, isNumeric: true, isCurrency: false),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(20)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: installmentFrequency,
                              isExpanded: true,
                              items: ['Monthly', 'Weekly'].map((f) => DropdownMenuItem(value: f, child: Text(f, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)))).toList(),
                              onChanged: (val) => setModalState(() => installmentFrequency = val ?? 'Monthly'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
                _primaryBtn(AppLocalizations.get('create_account'), isLoading, () async {
                  if (nameCtrl.text.isEmpty || balanceCtrl.text.isEmpty) return;
                  if (isInstallmentEnabled && (installmentAmtCtrl.text.isEmpty || installmentDurationCtrl.text.isEmpty)) return;
                  
                  setModalState(() => isLoading = true);
                  
                  DateTime? nextDueDate;
                  if (isInstallmentEnabled) {
                    final now = DateTime.now();
                    nextDueDate = installmentFrequency == 'Monthly' 
                        ? DateTime(now.year, now.month + 1, now.day)
                        : now.add(const Duration(days: 7));
                  }
                  
                  int inputMonths = int.tryParse(installmentDurationCtrl.text) ?? 0;
                  int calculatedInstallmentDuration = installmentFrequency == 'Monthly' ? inputMonths : (inputMonths * 52 / 12).round();

                  final accountId = await _accountService.createAccount(
                    name: nameCtrl.text,
                    type: 'Savings',
                    breakdown: {AppConstants.ownerSelf: double.parse(balanceCtrl.text)},
                    isInstallmentEnabled: isInstallmentEnabled,
                    installmentAmount: double.tryParse(installmentAmtCtrl.text) ?? 0,
                    installmentFrequency: installmentFrequency,
                    installmentDuration: calculatedInstallmentDuration,
                    installmentsPaid: 0,
                    nextDueDate: nextDueDate,
                  );
                  
                  if (accountId != null && isInstallmentEnabled && nextDueDate != null) {
                    await NotificationService().scheduleSavingsInstallmentReminder(
                      accountId: accountId,
                      accountName: nameCtrl.text,
                      dueDate: nextDueDate,
                      installmentAmount: double.tryParse(installmentAmtCtrl.text) ?? 0,
                    );
                  }
                  
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
    DateTime _selectedDate = DateTime.now();

    final standardAccounts = allAccounts.where((a) => a.type != 'Savings').toList();
    final savingsAccounts = allAccounts.where((a) => a.type == 'Savings').toList();

    if (savingsAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.get('add_a_savings_account'))));
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
                  _modalHeader(context, AppLocalizations.get('add_to_savings')),
                  const SizedBox(height: 24),
                  
                  // Date Picker
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(primary: AppColors.primaryGreen),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null && mounted) {
                        setModalState(() => _selectedDate = date);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(15)),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, color: AppColors.primaryGreen, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildModalInput(AppLocalizations.get('amount_to_save'), amountCtrl, Icons.add_circle_rounded, AppColors.primaryGreen, isNumeric: true, isCurrency: true),
                  const SizedBox(height: 16),
                  
                  // Toggle for "Already Paid"
                  GestureDetector(
                    onTap: () => setModalState(() => alreadyPaid = !alreadyPaid),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: alreadyPaid ? AppColors.primaryGreen.withValues(alpha: 0.05) : Colors.white,
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
                                Text(AppLocalizations.get('already_paiddeducted'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(AppLocalizations.get('wont_cut_balance'), style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textGrey)),
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
                    _buildModalDropdown(standardAccounts, AppLocalizations.get('deduct_from'), fromAccount, (val) => setModalState(() => fromAccount = val)),
                    const SizedBox(height: 16),
                  ],
                  
                  _buildModalDropdown(savingsAccounts, AppLocalizations.get('save_into'), toSavingsAccount, (val) => setModalState(() => toSavingsAccount = val)),
                  
                  const SizedBox(height: 32),
                  _primaryBtn(AppLocalizations.get('complete_saving'), isLoading, () async {
                    if (amountCtrl.text.isEmpty || toSavingsAccount == null || (!alreadyPaid && fromAccount == null)) return;
                    setModalState(() => isLoading = true);
                    
                    final txDate = _selectedDate;
                        
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
                    
                    // Update DPS logic
                    if (toSavingsAccount!.isInstallmentEnabled && toSavingsAccount!.installmentAmount > 0) {
                      int currentPaid = toSavingsAccount!.installmentsPaid;
                      DateTime? nextDue = toSavingsAccount!.nextDueDate;
                      
                      int numPaid = (amount / toSavingsAccount!.installmentAmount).floor();
                      if (numPaid < 1) numPaid = 1; // if they paid something, assume at least 1 installment
                      
                      currentPaid += numPaid;
                      
                      if (nextDue != null) {
                        for (int i=0; i<numPaid; i++) {
                          if (toSavingsAccount!.installmentFrequency == 'Monthly') {
                            nextDue = DateTime(nextDue!.year, nextDue!.month + 1, nextDue!.day);
                          } else {
                            nextDue = nextDue!.add(const Duration(days: 7));
                          }
                        }
                      }
                      
                      await _accountService.updateSavingsInstallmentProgress(toSavingsAccount!.id, currentPaid, nextDue);
                      
                      if (nextDue != null) {
                        await NotificationService().scheduleSavingsInstallmentReminder(
                          accountId: toSavingsAccount!.id,
                          accountName: toSavingsAccount!.name,
                          dueDate: nextDue,
                          installmentAmount: toSavingsAccount!.installmentAmount,
                        );
                      }
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

  Widget _buildModalInput(String label, TextEditingController ctrl, IconData icon, Color color, {bool isNumeric = false, bool isCurrency = false}) {
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
          suffixText: isCurrency ? '৳' : null,
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
        gradient: LinearGradient(colors: [AppColors.primaryGreen, AppColors.primaryGreen.withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primaryGreen.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
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
    return ThemeBuilder(builder: (context) => Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        elevation: 0,
        title: Text(AppLocalizations.get('savings_dashboard'), style: GoogleFonts.outfit(color: AppColors.textBlack, fontWeight: FontWeight.bold, fontSize: 18)),
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
                    Expanded(child: _buildActionBtn(AppLocalizations.get('add_account'), Icons.add_business_rounded, Colors.blueAccent, _showAddOpeningSavingsModal)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildActionBtn(AppLocalizations.get('log_savings'), Icons.auto_graph_rounded, AppColors.primaryGreen, () => _showAddSavingsTransferModal(allAccounts))),
                  ],
                ),
                const SizedBox(height: 32),
                Align(alignment: Alignment.centerLeft, child: Text(AppLocalizations.get('your_savings_vaults'), style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5))),
                const SizedBox(height: 16),
                if (savingsAccounts.isEmpty) _buildEmptyState() else ...savingsAccounts.map((acc) => _buildSavingsCard(acc)),
              ],
            ),
          );
        }
      ),
    )); // closes Scaffold + ThemeBuilder
  }

  Widget _buildTotalSavingsCard(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.amber.shade600, Colors.amber.shade400], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 25, offset: const Offset(0, 12))],
      ),
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(Icons.savings_rounded, color: Colors.white, size: 30)),
          const SizedBox(height: 20),
          Text(AppLocalizations.get('total_net_savings'), style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Text('৳${total.toInt()}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: -1)),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String title, IconData icon, Color color, VoidCallback onTap) {
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.cardWhite, 
          borderRadius: BorderRadius.circular(25), 
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))],
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textBlack), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsCard(AccountModel acc) {
    bool showDps = acc.isInstallmentEnabled;
    bool isOverdue = false;
    double progress = 0;
    if (showDps) {
      if (acc.nextDueDate != null) {
        final now = DateTime.now();
        isOverdue = DateTime(now.year, now.month, now.day).isAfter(acc.nextDueDate!);
      }
      if (acc.installmentDuration > 0) {
        progress = (acc.installmentsPaid / acc.installmentDuration).clamp(0.0, 1.0);
      }
    }
    
    return ScaleOnTap(
      onTap: () {
        // Maybe open a detail page later, for now just simple scale effect
      },
      child: GlassCard(
        blur: 20,
        opacity: 0.8,
        color: AppColors.cardWhite,
        borderRadius: 25,
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.05)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12), 
                    decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), shape: BoxShape.circle), 
                    child: Icon(Icons.account_balance_wallet_rounded, color: Colors.amber.shade600, size: 22)
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(acc.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textBlack)),
                        Text(AppLocalizations.get('secure_savings_vault'), style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text('৳${acc.totalBalance.toInt()}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primaryGreen, letterSpacing: -0.5)),
                ],
              ),
              if (showDps) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isOverdue ? Colors.redAccent.withValues(alpha: 0.05) : AppColors.brandPrimary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: isOverdue ? Colors.redAccent.withValues(alpha: 0.2) : AppColors.brandPrimary.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.track_changes_rounded, size: 16, color: AppColors.brandPrimary),
                              const SizedBox(width: 6),
                              Text('DPS Plan (${acc.installmentFrequency})', style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Text('৳${acc.installmentAmount.toInt()} / per', style: GoogleFonts.outfit(color: AppColors.primaryGreen, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          color: AppColors.brandPrimary,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${acc.installmentsPaid} of ${acc.installmentDuration} Paid', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.w600)),
                          if (acc.nextDueDate != null)
                            Row(
                              children: [
                                if (isOverdue) const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  isOverdue ? 'Overdue!' : 'Next: ${acc.nextDueDate!.day}/${acc.nextDueDate!.month}/${acc.nextDueDate!.year}',
                                  style: GoogleFonts.outfit(color: isOverdue ? Colors.redAccent : AppColors.brandPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40), 
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.savings_rounded, size: 50, color: Colors.amber.shade600),
          ),
          const SizedBox(height: 20),
          Text(AppLocalizations.get('no_vaults_found_tap') ?? 'No savings accounts yet. Tap Add Account to get started!', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 14, height: 1.5)),
        ],
      )
    );
  }

  String _getMonthName(int month) {
    final key = 'month_short_$month';
    return AppLocalizations.get(key);
  }
}
