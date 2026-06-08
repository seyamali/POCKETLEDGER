import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/loan_model.dart';
import 'package:pocketledger/services/loan_service.dart';
import 'package:pocketledger/features/auth/widgets/custom_text_field.dart';
import 'package:pocketledger/models/account_model.dart';
import 'package:pocketledger/services/account_service.dart';
import 'package:pocketledger/core/constants/app_constants.dart';
import 'package:pocketledger/core/widgets/scale_on_tap.dart';
import 'package:pocketledger/core/widgets/glass_card.dart';

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

  String _selectedOwner = AppConstants.ownerSelf;
  bool _isLoading = false;
  bool _adjustBalance = false;

  bool _isInstallmentEnabled = false;
  int _installmentCount = 5;
  String _installmentFrequency = 'Monthly';

  List<String> _existingNames = [];
  TextEditingController? _autoCompleteController;

  @override
  void initState() {
    super.initState();
    _loadExistingNames();
  }

  void _loadExistingNames() async {
    final loansStream = _loanService.getLoans();
    final loans = await loansStream.first;
    final names = loans.map((l) => l.personName).toSet().toList();
    if (mounted) {
      setState(() {
        _existingNames = names;
      });
    }
  }

  void _handleSave() async {
    final personName = _autoCompleteController?.text ?? _personNameController.text;
    if (personName.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter name and amount')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.tryParse(_amountController.text) ?? 0;

      List<InstallmentModel> installments = [];
      if (_isInstallmentEnabled) {
        final double instAmt = amount / _installmentCount;
        final now = DateTime.now();
        for (int i = 1; i <= _installmentCount; i++) {
          DateTime dueDate;
          if (_installmentFrequency.toLowerCase() == 'weekly') {
            dueDate = now.add(Duration(days: 7 * i));
          } else {
            dueDate = DateTime(now.year, now.month + i, now.day);
          }
          installments.add(InstallmentModel(
            id: 'inst_${i}_${now.millisecondsSinceEpoch}',
            amount: instAmt,
            dueDate: dueDate,
            isPaid: false,
          ));
        }
      }

      final loan = LoanModel(
        id: '',
        personName: personName,
        amount: amount,
        remainingAmount: amount,
        type: _selectedType,
        status: LoanStatus.pending,
        linkedAccountId: _adjustBalance ? _selectedAccount?.id : null,
        linkedAccountName: _adjustBalance ? _selectedAccount?.name : null,
        owner: _selectedOwner,
        date: DateTime.now(),
        note: _noteController.text,
        userId: '',
        installments: installments,
      );

      await _loanService.addLoan(loan);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: ScaleOnTap(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(Icons.close_rounded, color: AppColors.primaryText, size: 24),
          ),
        ),
        title: Text('New Loan', style: GoogleFonts.outfit(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<AccountModel>>(
        stream: _accountService.getAccounts(),
        builder: (context, snapshot) {
          final accounts = snapshot.data ?? [];

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
                bottom: 100, left: -60,
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
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildTypeSelector(),
                    const SizedBox(height: 40),

                    Text('AMOUNT', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    _buildAmountInput(),

                    const SizedBox(height: 40),
                    _buildSectionLabel('PERSON NAME'),
                    const SizedBox(height: 12),
                    _buildDetailsInputs(isDark),

                    const SizedBox(height: 24),
                    _buildSectionLabel('LOAN OWNER / PORTION'),
                    const SizedBox(height: 12),
                    _buildOwnerDropdown(isDark),

                    const SizedBox(height: 24),
                    _buildSectionLabel('LINK ACCOUNT (OPTIONAL)'),
                    const SizedBox(height: 12),
                    _buildAccountDropdown(accounts, isDark),

                    const SizedBox(height: 24),
                    _buildAdjustBalanceToggle(isDark),

                    const SizedBox(height: 24),
                    _buildInstallmentSection(isDark),

                    const SizedBox(height: 40),
                    _buildSaveButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label,
          style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
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
    if (type == LoanType.taken) activeColor = Colors.redAccent;

    return Expanded(
      child: ScaleOnTap(
        onTap: () => setState(() => _selectedType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected ? [BoxShadow(color: activeColor.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 4))] : [],
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.white : AppColors.secondaryText,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              )),
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    Color outlineColor = _selectedType == LoanType.given ? AppColors.brandPrimary : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      decoration: BoxDecoration(
        color: outlineColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: outlineColor.withValues(alpha: 0.2), width: 1.5),
      ),
      child: IntrinsicWidth(
        child: TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 52, fontWeight: FontWeight.bold, color: AppColors.primaryText),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: '0',
            hintStyle: TextStyle(color: AppColors.secondaryText.withValues(alpha: 0.3)),
            prefixText: '৳ ',
            prefixStyle: TextStyle(color: outlineColor, fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsInputs(bool isDark) {
    return GlassCard(
      blur: 15,
      opacity: isDark ? 0.04 : 0.45,
      color: isDark ? const Color(0xFF16201D) : Colors.white,
      borderRadius: 24,
      border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.08)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return _existingNames.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                _personNameController.text = selection;
              },
              fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                _autoCompleteController = fieldTextEditingController;
                return CustomTextField(
                  controller: fieldTextEditingController,
                  focusNode: fieldFocusNode,
                  hintText: 'Person Name (e.g. Rahim)',
                  icon: Icons.person_outline_rounded,
                );
              },
              optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 8.0,
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.surfaceLight,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 200, maxWidth: MediaQuery.of(context).size.width - 96),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(option, style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 15, fontWeight: FontWeight.w500)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _noteController,
              hintText: 'Note (optional)',
              icon: Icons.notes_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustBalanceToggle(bool isDark) {
    return GlassCard(
      blur: 15,
      opacity: isDark ? 0.04 : 0.45,
      color: isDark ? const Color(0xFF16201D) : Colors.white,
      borderRadius: 20,
      border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.08)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Adjust Account Balance', style: GoogleFonts.outfit(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    _adjustBalance
                        ? 'ON — Balance will be updated now'
                        : 'OFF — Only records the loan (balance already correct)',
                    style: GoogleFonts.outfit(color: AppColors.secondaryText, fontSize: 11),
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
      ),
    );
  }

  Widget _buildOwnerDropdown(bool isDark) {
    return GlassCard(
      blur: 15,
      opacity: isDark ? 0.04 : 0.45,
      color: isDark ? const Color(0xFF16201D) : Colors.white,
      borderRadius: 20,
      border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.05)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedOwner,
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.secondaryText),
            items: AppConstants.allowedOwners
                .map((o) => DropdownMenuItem(
                      value: o,
                      child: Text(o, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
                    ))
                .toList(),
            onChanged: (val) => setState(() => _selectedOwner = val ?? AppConstants.ownerSelf),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountDropdown(List<AccountModel> accounts, bool isDark) {
    return GlassCard(
      blur: 15,
      opacity: isDark ? 0.04 : 0.45,
      color: isDark ? const Color(0xFF16201D) : Colors.white,
      borderRadius: 20,
      border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.05)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<AccountModel>(
            value: _selectedAccount != null && accounts.any((a) => a.id == _selectedAccount!.id)
                ? accounts.firstWhere((a) => a.id == _selectedAccount!.id)
                : null,
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.secondaryText),
            hint: Text('Select Account', style: GoogleFonts.outfit(color: AppColors.secondaryText, fontSize: 14)),
            items: accounts
                .map((acc) => DropdownMenuItem(
                      value: acc,
                      child: Text(acc.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
                    ))
                .toList(),
            onChanged: (val) => setState(() => _selectedAccount = val),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ScaleOnTap(
      onTap: () {
        if (_isLoading) return;
        _handleSave();
      },
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.brandPrimary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.brandPrimary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        alignment: Alignment.center,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text('Save Loan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildInstallmentSection(bool isDark) {
    return GlassCard(
      blur: 15,
      opacity: isDark ? 0.04 : 0.45,
      color: isDark ? const Color(0xFF16201D) : Colors.white,
      borderRadius: 24,
      border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.08)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Divide into Installments', style: GoogleFonts.outfit(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Split this loan into smaller payments', style: GoogleFonts.outfit(color: AppColors.secondaryText, fontSize: 11)),
                    ],
                  ),
                ),
                Switch(
                  value: _isInstallmentEnabled,
                  activeColor: AppColors.brandPrimary,
                  onChanged: (val) => setState(() => _isInstallmentEnabled = val),
                ),
              ],
            ),
            if (_isInstallmentEnabled) ...[
              const SizedBox(height: 20),
              Divider(color: AppColors.brandPrimary.withValues(alpha: 0.08), height: 1),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('INSTALLMENTS', style: GoogleFonts.outfit(color: AppColors.secondaryText, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _installmentCount,
                              isExpanded: true,
                              items: List.generate(23, (index) => index + 2)
                                  .map((count) => DropdownMenuItem(
                                        value: count,
                                        child: Text('$count times', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                                      ))
                                  .toList(),
                              onChanged: (val) => setState(() => _installmentCount = val ?? 5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FREQUENCY', style: GoogleFonts.outfit(color: AppColors.secondaryText, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _installmentFrequency,
                              isExpanded: true,
                              items: ['Weekly', 'Monthly']
                                  .map((freq) => DropdownMenuItem(
                                        value: freq,
                                        child: Text(freq, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                                      ))
                                  .toList(),
                              onChanged: (val) => setState(() => _installmentFrequency = val ?? 'Monthly'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Builder(builder: (context) {
                final amt = double.tryParse(_amountController.text) ?? 0;
                final perInst = amt > 0 ? (amt / _installmentCount).toInt() : 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.brandPrimary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Splits this loan into $_installmentCount installments of ৳$perInst paid ${_installmentFrequency.toLowerCase()}.',
                          style: GoogleFonts.outfit(color: AppColors.brandPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
