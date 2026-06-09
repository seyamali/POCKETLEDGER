import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/loan_model.dart';
import 'package:pocketledger/services/loan_service.dart';
import 'package:pocketledger/models/account_model.dart';
import 'package:pocketledger/services/account_service.dart';
import 'package:pocketledger/features/auth/widgets/custom_text_field.dart';
import 'package:pocketledger/core/constants/app_constants.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:pocketledger/core/widgets/scale_on_tap.dart';
import 'package:pocketledger/core/widgets/glass_card.dart';
import 'package:pocketledger/core/localization/app_localizations.dart';

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

  AccountModel? _sourceAccount;
  String _sourceOwner = AppConstants.ownerSelf;
  AccountModel? _destAccount;
  String _destOwner = AppConstants.ownerMother;
  bool _trackDestination = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final allowedOwners = AppConstants.allowedOwners;

    if (widget.loan.type == LoanType.taken) {
      if (allowedOwners.contains(widget.loan.personName)) {
        _destOwner = widget.loan.personName;
      } else {
        _destOwner = AppConstants.ownerOther;
      }
      _sourceOwner = AppConstants.ownerSelf;
      _trackDestination = false;
    } else {
      _destOwner = AppConstants.ownerSelf;
      if (allowedOwners.contains(widget.loan.personName)) {
        _sourceOwner = widget.loan.personName;
      } else {
        _sourceOwner = AppConstants.ownerOther;
      }
      _trackDestination = true;
    }

    _initializeAccounts();
  }

  void _initializeAccounts() async {
    if (widget.loan.linkedAccountId == null) return;

    final accounts = await _accountService.getAccounts().first;
    if (mounted) {
      setState(() {
        final linked = accounts.firstWhere((a) => a.id == widget.loan.linkedAccountId, orElse: () => accounts.first);
        if (widget.loan.type == LoanType.taken) {
          _sourceAccount = linked;
          _sourceOwner = widget.loan.owner;
        } else {
          _destAccount = linked;
          _destOwner = widget.loan.owner;
        }
      });
    }
  }

  void _handleAddPayment() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.get('please_enter_an_amount'))));
      return;
    }

    final paymentAmount = double.tryParse(_amountController.text) ?? 0;
    if (paymentAmount <= 0) return;

    if (paymentAmount > widget.loan.remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.get('payment_cannot_exceed_remaining'))));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _loanService.addRepayment(
        loanId: widget.loan.id,
        paymentAmount: paymentAmount,
        sourceAccountId: _sourceAccount?.id,
        sourceAccountName: _sourceAccount?.name,
        sourceOwner: _sourceOwner,
        destAccountId: _trackDestination ? _destAccount?.id : null,
        destAccountName: _trackDestination ? _destAccount?.name : null,
        destOwner: _trackDestination ? _destOwner : null,
        note: _noteController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
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
        top: 32,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: StreamBuilder<List<AccountModel>>(
        stream: _accountService.getAccounts(),
        builder: (context, snapshot) {
          final accounts = snapshot.data ?? [];
          final isGiven = widget.loan.type == LoanType.given;

          return StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isGiven ? 'Receive from ${widget.loan.personName}' : 'Repay to ${widget.loan.personName}',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isGiven ? 'Money will be added to your account' : 'Record where the money is moving',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.secondaryText),
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _amountController,
                      hintText: 'Amount (Max: ${widget.loan.remainingAmount.toInt()})',
                      icon: Icons.attach_money_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    if (isGiven)
                      Container(
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GIVEN BY',
                              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondaryText, letterSpacing: 1),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.loan.personName,
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryText),
                            ),
                          ],
                        ),
                      )
                    else
                      _buildFlowSection(
                        label: 'REPAY FROM (MY POCKET)',
                        account: _sourceAccount,
                        owner: _sourceOwner,
                        accounts: accounts,
                        onAccountChanged: (val) => setModalState(() => _sourceAccount = val),
                        onOwnerChanged: (val) => setModalState(() => _sourceOwner = val ?? AppConstants.ownerSelf),
                      ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isGiven ? 'Add to my App Account?' : 'Return to an App Account?',
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryText),
                          ),
                          Switch(
                            value: _trackDestination,
                            activeColor: AppColors.brandPrimary,
                            onChanged: (val) => setModalState(() => _trackDestination = val),
                          ),
                        ],
                      ),
                    ),
                    if (_trackDestination) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Icon(Icons.arrow_downward_rounded, color: AppColors.brandPrimary),
                      ),
                      _buildFlowSection(
                        label: isGiven ? 'RECEIVE INTO (MY POCKET)' : 'RETURN TO (THEIR POCKET)',
                        account: _destAccount,
                        owner: _destOwner,
                        accounts: accounts,
                        onAccountChanged: (val) => setModalState(() => _destAccount = val),
                        onOwnerChanged: (val) => setModalState(() => _destOwner = val ?? AppConstants.ownerSelf),
                      ),
                    ],
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _noteController,
                      hintText: AppLocalizations.get('note_optional'),
                      icon: Icons.notes_rounded,
                    ),
                    const SizedBox(height: 32),
                    ScaleOnTap(
                      onTap: () {
                        if (_isLoading) return;
                        _handleAddPayment();
                      },
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandPrimary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        alignment: Alignment.center,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Confirm Transaction',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFlowSection({
    required String label,
    required AccountModel? account,
    required String owner,
    required List<AccountModel> accounts,
    required Function(AccountModel?) onAccountChanged,
    required Function(String?) onOwnerChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondaryText, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AccountModel>(
                    value: account != null && accounts.any((a) => a.id == account.id)
                        ? accounts.firstWhere((a) => a.id == account.id)
                        : null,
                    isExpanded: true,
                    hint: Text('None (Outside App)', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.secondaryText)),
                    items: [
                      DropdownMenuItem<AccountModel>(
                        value: null,
                        child: Text('None (Outside App)', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                      ),
                      ...accounts.map((acc) => DropdownMenuItem(
                            value: acc,
                            child: Text(acc.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: onAccountChanged,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: owner,
                    isExpanded: true,
                    items: AppConstants.allowedOwners
                        .map((o) => DropdownMenuItem(
                              value: o,
                              child: Text(o, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.brandPrimary)),
                            ))
                        .toList(),
                    onChanged: onOwnerChanged,
                  ),
                ),
              ),
            ],
          ),
          if (account != null) ...[
            const SizedBox(height: 8),
            Text('Current: ৳${account.breakdown[owner]?.toInt() ?? 0}', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.secondaryText)),
          ]
        ],
      ),
    );
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
            child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryText, size: 18),
          ),
        ),
        title: Text(
          'Loan Details',
          style: GoogleFonts.outfit(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          ScaleOnTap(
            onTap: _showEditNameDialog,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.edit_rounded, color: AppColors.brandPrimary, size: 20),
            ),
          ),
          ScaleOnTap(
            onTap: () => _showDeleteConfirmation(
              title: 'Delete Loan?',
              content: 'This will revert all balances and delete this loan forever.',
              onConfirm: _handleDeleteLoan,
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background blobs
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
            bottom: 200, left: -60,
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
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
            child: Column(
              children: [
                _buildMainCard(isDark),
                _buildReminderTemplateCard(isDark),
                if (widget.loan.installments.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildInstallmentsTimeline(isDark),
                ],
                const SizedBox(height: 24),
                _buildRepaymentsList(isDark),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.loan.status == LoanStatus.pending ? _buildBottomBar() : null,
    )); // closes Scaffold + ThemeBuilder
  }

  Widget _buildReminderTemplateCard(bool isDark) {
    if (widget.loan.type != LoanType.given || widget.loan.status == LoanStatus.paid) {
      return const SizedBox.shrink();
    }

    final reminderText = "Hey ${widget.loan.personName}! Just a gentle reminder regarding the loan balance of ৳${widget.loan.remainingAmount.toInt()} when you get a moment. Thank you! 🙏";

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: GlassCard(
        blur: 15,
        opacity: isDark ? 0.04 : 0.45,
        color: isDark ? const Color(0xFF16201D) : Colors.white,
        borderRadius: 20,
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, color: AppColors.brandPrimary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'REPAYMENT REMINDER TEMPLATE',
                    style: GoogleFonts.outfit(
                      color: AppColors.textGrey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  reminderText,
                  style: GoogleFonts.outfit(
                    color: AppColors.textBlack,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ScaleOnTap(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: reminderText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.brandPrimary,
                      content: Text('Reminder template copied!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.15)),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.copy_rounded, color: AppColors.brandPrimary, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Copy Reminder Template',
                        style: GoogleFonts.outfit(
                          color: AppColors.brandPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstallmentsTimeline(bool isDark) {
    final installments = widget.loan.installments;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

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
                Icon(Icons.timeline_rounded, color: AppColors.brandPrimary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'INSTALLMENT TIMELINE',
                  style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: installments.length,
              itemBuilder: (context, index) {
                final inst = installments[index];
                final isPaid = inst.isPaid;
                final instDate = DateTime(inst.dueDate.year, inst.dueDate.month, inst.dueDate.day);
                final isOverdue = !isPaid && instDate.isBefore(today);

                Color statusColor = isPaid
                    ? AppColors.brandPrimary
                    : (isOverdue ? Colors.redAccent : Colors.orangeAccent);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Icon(isPaid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: statusColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Installment #${index + 1}',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textBlack),
                            ),
                            Text(
                              'Due: ${DateFormat('dd MMM yyyy').format(inst.dueDate)}',
                              style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '৳${inst.amount.toInt()}',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: isPaid ? AppColors.textGrey : AppColors.textBlack),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleDeleteLoan() async {
    setState(() => _isLoading = true);
    try {
      await _loanService.deleteLoan(widget.loan);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleDeleteRepayment(RepaymentModel repayment) async {
    setState(() => _isLoading = true);
    try {
      await _loanService.deleteRepayment(widget.loan.id, repayment);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildMainCard(bool isDark) {
    final isPaid = widget.loan.status == LoanStatus.paid;
    final isGiven = widget.loan.type == LoanType.given;

    Color stateColor = isGiven ? AppColors.brandPrimary : Colors.redAccent;

    return GlassCard(
      blur: 20,
      opacity: isDark ? 0.05 : 0.45,
      color: isDark ? const Color(0xFF16201D) : Colors.white,
      borderRadius: 24,
      border: Border.all(color: stateColor.withValues(alpha: 0.15)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.loan.personName,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPaid ? AppColors.brandPrimary.withValues(alpha: 0.1) : Colors.orangeAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPaid ? 'PAID' : 'PENDING',
                    style: GoogleFonts.outfit(
                      color: isPaid ? AppColors.brandPrimary : Colors.orangeAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                isGiven ? 'Money you gave' : 'Money you took',
                style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statColumn('Total Amount', widget.loan.amount, AppColors.textBlack),
                _statColumn('Paid Back', widget.loan.amount - widget.loan.remainingAmount, AppColors.brandPrimary),
                _statColumn('Remaining', widget.loan.remainingAmount, widget.loan.remainingAmount > 0 ? Colors.redAccent : AppColors.brandPrimary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
          '৳${value.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => "${m[1]},")}',
          style: GoogleFonts.outfit(color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRepaymentsList(bool isDark) {
    if (widget.loan.repayments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text('No repayments yet.', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13.5)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text('Repayment History', style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 15, fontWeight: FontWeight.bold)),
        ),
        ...widget.loan.repayments.map((rep) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                blur: 15,
                opacity: isDark ? 0.04 : 0.45,
                color: isDark ? const Color(0xFF16201D) : Colors.white,
                borderRadius: 18,
                border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.08)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Payment Recieved', style: GoogleFonts.outfit(color: AppColors.textBlack, fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(DateFormat('dd MMM yyyy').format(rep.date), style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11.5)),
                            if (rep.note.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(rep.note, style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11)),
                            ]
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '৳${rep.amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => "${m[1]},")}',
                            style: GoogleFonts.outfit(color: AppColors.brandPrimary, fontWeight: FontWeight.bold, fontSize: 15.5),
                          ),
                          const SizedBox(width: 12),
                          ScaleOnTap(
                            onTap: () => _showDeleteConfirmation(
                              title: 'Delete Payment?',
                              content: 'This will restore the loan balance and revert account changes.',
                              onConfirm: () => _handleDeleteRepayment(rep),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.error.withValues(alpha: 0.08),
                              ),
                              child: Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }

  void _showEditNameDialog() {
    final ctrl = TextEditingController(text: widget.loan.personName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Person Name', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: 'Name',
            labelStyle: GoogleFonts.outfit(color: AppColors.textGrey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.brandPrimary)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.brandPrimary, width: 2)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textGrey))),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await _loanService.updateLoanPersonName(widget.loan.id, ctrl.text.trim());
                // Redraw
                setState(() {});
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary, foregroundColor: Colors.white),
            child: Text(AppLocalizations.get('save')),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: ScaleOnTap(
          onTap: _showAddPaymentModal,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPrimary.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.payment_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.loan.type == LoanType.given ? 'Receive Payment' : 'Repay Loan',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(content, style: GoogleFonts.outfit(color: AppColors.textGrey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textGrey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: Text(AppLocalizations.get('confirm')),
          ),
        ],
      ),
    );
  }
}
