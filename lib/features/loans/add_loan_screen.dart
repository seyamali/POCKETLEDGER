import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/loan_model.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:pocketledger/services/loan_service.dart';
import 'package:pocketledger/features/auth/widgets/custom_text_field.dart';
import 'package:pocketledger/models/account_model.dart';
import 'package:pocketledger/services/account_service.dart';
import 'package:pocketledger/core/constants/app_constants.dart';
import 'package:pocketledger/core/widgets/scale_on_tap.dart';
import 'package:pocketledger/core/widgets/glass_card.dart';
import 'package:pocketledger/core/localization/app_localizations.dart';
import 'package:pocketledger/services/notification_service.dart';

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
  int _installmentCount = 3;
  String _installmentFrequency = 'Monthly';

  bool _isInterestEnabled = false;
  bool _isBkashLoan = false;
  final _interestRateController = TextEditingController();

  List<String> _existingNames = [];
  TextEditingController? _autoCompleteController;
  DateTime _selectedDate = DateTime.now();
  DateTime? _dueDate;
  String? _personPhone;

  @override
  void initState() {
    super.initState();
    _loadExistingNames();
    _amountController.addListener(_onInputChanged);
    _interestRateController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    if (_isInterestEnabled) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_onInputChanged);
    _interestRateController.removeListener(_onInputChanged);
    _amountController.dispose();
    _interestRateController.dispose();
    _personNameController.dispose();
    _noteController.dispose();
    super.dispose();
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

  Future<void> _pickContact() async {
    if (await FlutterContacts.requestPermission()) {
      final contact = await FlutterContacts.openExternalPick();
      if (contact != null) {
        setState(() {
          _personNameController.text = contact.displayName;
          _personPhone = contact.phones.isNotEmpty ? contact.phones.first.number : null;
        });
      }
    }
  }

  void _handleSave() async {
    final personName = _autoCompleteController?.text ?? _personNameController.text;
    if (personName.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.get('please_enter_name_and'))));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.tryParse(_amountController.text) ?? 0;
      double interestRate = 0;
      double interestAmount = 0;
      double totalOwed = amount;
      double instAmt = 0;

      if (_isInterestEnabled) {
        if (_isBkashLoan) {
          // bKash Effective Monthly Rate (approximates the 9% daily + 0.575% fee exactly)
          interestRate = 1.619;
        } else {
          interestRate = double.tryParse(_interestRateController.text) ?? 0;
        }
        double r = interestRate / 100;
        if (_isInstallmentEnabled && _installmentCount > 0 && r > 0) {
          int n = _installmentCount;
          double emi = (amount * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
          totalOwed = emi * n;
          interestAmount = totalOwed - amount;
          instAmt = emi;
        } else {
          interestAmount = amount * r;
          totalOwed = amount + interestAmount;
          if (_isInstallmentEnabled && _installmentCount > 0) {
            instAmt = totalOwed / _installmentCount;
          }
        }
      } else {
        if (_isInstallmentEnabled && _installmentCount > 0) {
          instAmt = totalOwed / _installmentCount;
        }
      }

      List<InstallmentModel> installments = [];
      if (_isInstallmentEnabled) {
        final now = _selectedDate;
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
        personName: _personNameController.text.trim(),
        personPhone: _personPhone,
        amount: amount,
        remainingAmount: totalOwed,
        type: _selectedType,
        status: LoanStatus.pending,
        linkedAccountId: _adjustBalance ? _selectedAccount?.id : null,
        linkedAccountName: _adjustBalance ? _selectedAccount?.name : null,
        owner: _selectedOwner,
        date: _selectedDate,
        dueDate: _isInstallmentEnabled ? null : _dueDate,
        note: _noteController.text,
        userId: '',
        installments: installments,
        interestAmount: interestAmount,
        interestRate: interestRate,
      );

      final loanId = await _loanService.addLoan(loan);

      if (loanId != null) {
        if (_isInstallmentEnabled) {
          for (var inst in installments) {
            await NotificationService().scheduleLoanReminders(
              loanId: '${loanId}_${inst.id}',
              personName: personName,
              dueDate: inst.dueDate,
              amount: inst.amount,
              isGiven: _selectedType == LoanType.given,
            );
          }
        } else if (_dueDate != null) {
          await NotificationService().scheduleLoanReminders(
            loanId: loanId,
            personName: personName,
            dueDate: _dueDate!,
            amount: totalOwed,
            isGiven: _selectedType == LoanType.given,
          );
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.get('error')}: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ThemeBuilder(builder: (context) => Scaffold(
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
        title: Text(AppLocalizations.get('new_loan'), style: GoogleFonts.outfit(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 20)),
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

                    Text(AppLocalizations.get('amount'), style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    _buildAmountInput(),

                    const SizedBox(height: 40),

                    _buildCardGroup(
                      title: AppLocalizations.get('loan_details') ?? 'Loan Details',
                      icon: Icons.info_outline_rounded,
                      isDark: isDark,
                      children: [
                        _buildSectionLabel(AppLocalizations.get('when_was_it') ?? 'When did this happen?'),
                        const SizedBox(height: 12),
                        _buildDatePickerRow(isDark),
                        const SizedBox(height: 24),
                        _buildSectionLabel(AppLocalizations.get('who_is_it_with') ?? 'Who is this loan with?'),
                        const SizedBox(height: 12),
                        _buildDetailsInputs(isDark),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildCardGroup(
                      title: AppLocalizations.get('how_to_return') ?? 'How will it be returned?',
                      icon: Icons.handshake_rounded,
                      isDark: isDark,
                      children: [
                        _buildInterestSection(isDark),
                        const SizedBox(height: 24),
                        _buildInstallmentSection(isDark),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildCardGroup(
                      title: AppLocalizations.get('where_money_goes') ?? 'Where is the money going?',
                      icon: Icons.account_balance_wallet_rounded,
                      isDark: isDark,
                      children: [
                        _buildSectionLabel(AppLocalizations.get('whose_money') ?? 'Whose money is this?'),
                        const SizedBox(height: 12),
                        _buildOwnerDropdown(isDark),
                        const SizedBox(height: 24),
                        _buildSectionLabel(AppLocalizations.get('link_app_account') ?? 'Link with App Account (Optional)'),
                        const SizedBox(height: 12),
                        _buildAccountDropdown(accounts, isDark),
                        const SizedBox(height: 24),
                        _buildAdjustBalanceToggle(isDark),
                      ],
                    ),

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
    )); // closes Scaffold + ThemeBuilder
  }

  Widget _buildCardGroup({required String title, required IconData icon, required bool isDark, required List<Widget> children}) {
    return GlassCard(
      blur: 20,
      opacity: isDark ? 0.04 : 0.45,
      color: isDark ? const Color(0xFF16201D) : Colors.white,
      borderRadius: 24,
      border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.1)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.brandPrimary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerRow(bool isDark) {
    return ScaleOnTap(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(primary: AppColors.brandPrimary),
              ),
              child: child!,
            );
          },
        );
        if (date != null && mounted) {
          setState(() => _selectedDate = date);
        }
      },
      child: GlassCard(
        blur: 15,
        opacity: isDark ? 0.04 : 0.45,
        color: isDark ? const Color(0xFF16201D) : Colors.white,
        borderRadius: 20,
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.08)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: AppColors.brandPrimary, size: 20),
              const SizedBox(width: 12),
              Text(
                "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                style: GoogleFonts.outfit(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ),
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
          _typeButton(LoanType.given, AppLocalizations.get('given_loan')),
          _typeButton(LoanType.taken, AppLocalizations.get('taken_loan')),
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
                return Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: fieldTextEditingController,
                        focusNode: fieldFocusNode,
                        hintText: AppLocalizations.get('hint_person_name') ?? 'Name of the person (e.g. Rahim)',
                        icon: Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.contacts_rounded, color: AppColors.brandPrimary),
                        onPressed: () async {
                          if (await FlutterContacts.requestPermission()) {
                            final contact = await FlutterContacts.openExternalPick();
                            if (contact != null) {
                              final fullContact = await FlutterContacts.getContact(contact.id);
                              if (fullContact != null) {
                                setState(() {
                                  _personNameController.text = fullContact.displayName;
                                  _autoCompleteController?.text = fullContact.displayName;
                                  if (fullContact.phones.isNotEmpty) {
                                    _personPhone = fullContact.phones.first.number;
                                  }
                                });
                              }
                            }
                          }
                        },
                      ),
                    ),
                  ],
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
              hintText: AppLocalizations.get('hint_note_optional') ?? 'Any notes? (Optional)',
              icon: Icons.notes_rounded,
            ),
            if (!_isInstallmentEnabled) ...[
              const SizedBox(height: 16),
              ScaleOnTap(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: AppColors.brandPrimary,
                            onPrimary: Colors.white,
                            onSurface: AppColors.textBlack,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      _dueDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, color: AppColors.brandPrimary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _dueDate == null ? (AppLocalizations.get('hint_due_date') ?? 'When will it be due? (Optional)') : 'Due on: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                          style: GoogleFonts.outfit(
                            color: _dueDate == null ? AppColors.secondaryText : AppColors.brandPrimary,
                            fontSize: 14,
                            fontWeight: _dueDate == null ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_dueDate != null)
                        InkWell(
                          onTap: () => setState(() => _dueDate = null),
                          child: Icon(Icons.close_rounded, color: AppColors.secondaryText, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
            ],
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
                  Text(AppLocalizations.get('adjust_account_balance'), style: GoogleFonts.outfit(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    _adjustBalance
                        ? AppLocalizations.get('balance_update_on')
                        : AppLocalizations.get('balance_update_off'),
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
            hint: Text(AppLocalizations.get('select_account'), style: GoogleFonts.outfit(color: AppColors.secondaryText, fontSize: 14)),
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
            : Text(AppLocalizations.get('save_loan'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, letterSpacing: 0.5)),
      ),
    );
  }

  String _frequencyLabel(String frequency) {
    switch (frequency) {
      case 'Weekly':
        return AppLocalizations.get('weekly');
      case 'Monthly':
        return AppLocalizations.get('monthly');
      default:
        return frequency;
    }
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
                      Text(AppLocalizations.get('divide_into_installments'), style: GoogleFonts.outfit(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(AppLocalizations.get('split_this_loan_into'), style: GoogleFonts.outfit(color: AppColors.secondaryText, fontSize: 11)),
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
                        Text(AppLocalizations.get('installments'), style: GoogleFonts.outfit(color: AppColors.secondaryText, fontSize: 10, fontWeight: FontWeight.bold)),
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
                                        child: Text(AppLocalizations.get('installment_times').replaceFirst('{count}', count.toString()), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
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
                        Text(AppLocalizations.get('frequency'), style: GoogleFonts.outfit(color: AppColors.secondaryText, fontSize: 10, fontWeight: FontWeight.bold)),
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
                                        child: Text(_frequencyLabel(freq), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
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
                double rate = 0;
                double totalOwed = amt;
                double instAmt = 0;
                
                if (_isInterestEnabled) {
                  if (_isBkashLoan) {
                    rate = 1.619;
                  } else {
                    rate = double.tryParse(_interestRateController.text) ?? 0;
                  }
                  double r = rate / 100;
                  if (_installmentCount > 0 && r > 0) {
                    double emi = (amt * r * pow(1 + r, _installmentCount)) / (pow(1 + r, _installmentCount) - 1);
                    totalOwed = emi * _installmentCount;
                    instAmt = emi;
                  } else {
                    totalOwed = amt + (amt * r);
                    instAmt = _installmentCount > 0 ? totalOwed / _installmentCount : 0;
                  }
                } else {
                  instAmt = _installmentCount > 0 ? amt / _installmentCount : 0;
                }
                
                final perInst = instAmt > 0 ? instAmt.toStringAsFixed(2) : '0';
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
                          AppLocalizations.get('installment_summary')
                              .replaceFirst('{count}', _installmentCount.toString())
                              .replaceFirst('{amount}', perInst.toString())
                              .replaceFirst('{frequency}', _frequencyLabel(_installmentFrequency).toLowerCase()),
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

  Widget _buildInterestSection(bool isDark) {
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
                      Text(AppLocalizations.get('add_interest') ?? 'Add Interest', style: GoogleFonts.outfit(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(AppLocalizations.get('add_interest_subtitle') ?? 'Include an interest rate (percentage) to this loan', style: GoogleFonts.outfit(color: AppColors.secondaryText, fontSize: 11)),
                    ],
                  ),
                ),
                Switch(
                  value: _isInterestEnabled,
                  activeColor: AppColors.brandPrimary,
                  onChanged: (val) => setState(() => _isInterestEnabled = val),
                ),
              ],
            ),
            if (_isInterestEnabled) ...[
              const SizedBox(height: 20),
              Divider(color: AppColors.brandPrimary.withValues(alpha: 0.08), height: 1),
              const SizedBox(height: 20),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2136E).withValues(alpha: 0.05), // bKash brand color
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2136E).withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('bKash Loan Mode', style: GoogleFonts.outfit(color: const Color(0xFFE2136E), fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text('Automatically calculates 9% daily interest + 0.575% fee', style: GoogleFonts.outfit(color: AppColors.secondaryText, fontSize: 10)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isBkashLoan,
                      activeColor: const Color(0xFFE2136E),
                      onChanged: (val) => setState(() => _isBkashLoan = val),
                    ),
                  ],
                ),
              ),
              
              if (!_isBkashLoan) ...[
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _interestRateController,
                  hintText: AppLocalizations.get('interest_rate_hint') ?? 'Interest Rate (%)',
                  icon: Icons.percent_rounded,
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final amt = double.tryParse(_amountController.text) ?? 0;
                  double rate = _isBkashLoan ? 1.619 : (double.tryParse(_interestRateController.text) ?? 0);
                  double r = rate / 100;
                  double totalOwed = amt;

                  if (_isInstallmentEnabled && _installmentCount > 0 && r > 0) {
                    double emi = (amt * r * pow(1 + r, _installmentCount)) / (pow(1 + r, _installmentCount) - 1);
                    totalOwed = emi * _installmentCount;
                  } else {
                    totalOwed = amt + (amt * r);
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.brandPrimary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${AppLocalizations.get('total_payable') ?? 'Total Payable'}: ৳${totalOwed.toStringAsFixed(2)}',
                            style: GoogleFonts.outfit(color: AppColors.brandPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              ),
            ],
          ],
        ),
      ),
    );
  }
}
