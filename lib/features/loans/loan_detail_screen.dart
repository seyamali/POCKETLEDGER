import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/loan_model.dart';
import 'package:url_launcher/url_launcher.dart';
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
import 'package:pocketledger/services/notification_service.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';

class LoanDetailScreen extends StatefulWidget {
  final LoanModel loan;
  const LoanDetailScreen({super.key, required this.loan});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  final LoanService _loanService = LoanService();
  final AccountService _accountService = AccountService();
  final ScreenshotController _screenshotController = ScreenshotController();

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  AccountModel? _sourceAccount;
  String _sourceOwner = AppConstants.ownerSelf;
  AccountModel? _destAccount;
  String _destOwner = AppConstants.ownerMother;
  bool _trackDestination = false;
  bool _isLoading = false;
  bool _isEarlySettlement = false;

  Map<String, double> getBkashEarlyPayoffDetails() {
    final loan = widget.loan;
    final now = DateTime.now();
    
    const double annualRate = 0.0963; // Set to 9.63% to match user's observed 2.09 TK interest for 3960 BDT on day 0
    double currentPrincipal = loan.amount;
    double accumulatedInterest = 0.0;
    
    final reps = List<RepaymentModel>.from(loan.repayments)
      ..sort((a, b) => a.date.compareTo(b.date));
      
    DateTime currentDate = loan.date;
    int repIndex = 0;
    
    final startDay = DateTime(loan.date.year, loan.date.month, loan.date.day);
    final today = DateTime(now.year, now.month, now.day);
    // bKash counts both the start date and the end date (minimum 2 days)
    final days = today.difference(startDay).inDays + 2;
    
    for (int i = 1; i <= days; i++) {
      final dailyInterest = currentPrincipal * annualRate / 365.0;
      accumulatedInterest += dailyInterest;
      
      final dayDate = startDay.add(Duration(days: i - 1));
      while (repIndex < reps.length) {
        final rDate = reps[repIndex].date;
        if (rDate.year == dayDate.year && rDate.month == dayDate.month && rDate.day == dayDate.day) {
          final pmt = reps[repIndex].amount;
          final interestPaid = pmt < accumulatedInterest ? pmt : accumulatedInterest;
          accumulatedInterest -= interestPaid;
          final principalPaid = pmt - interestPaid;
          currentPrincipal -= principalPaid;
          repIndex++;
        } else {
          break;
        }
      }
    }
    
    if (currentPrincipal < 0) currentPrincipal = 0;
    
    return {
      'principal': currentPrincipal,
      'interest': accumulatedInterest,
      'total': currentPrincipal + accumulatedInterest,
    };
  }

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

    final isBkash = widget.loan.interestRate == 1.098 ||
                    widget.loan.interestRate == 1.611 ||
                    widget.loan.interestRate == 1.619 ||
                    widget.loan.personName.toLowerCase().contains('bkash') ||
                    widget.loan.note.toLowerCase().contains('bkash');
    bool settleFull = _isEarlySettlement;
    if (!settleFull) {
      if (isBkash) {
        final earlyPayoff = getBkashEarlyPayoffDetails()['total'] ?? 0;
        if ((paymentAmount - earlyPayoff).abs() < 2.0 || paymentAmount >= widget.loan.remainingAmount) {
          settleFull = true;
        }
      } else {
        if (paymentAmount >= widget.loan.remainingAmount) {
          settleFull = true;
        }
      }
    }

    if (!settleFull && paymentAmount > widget.loan.remainingAmount) {
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
        settleFull: settleFull,
      );

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.get('error')}: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddPaymentModal() {
    setState(() {
      _isEarlySettlement = false;
      _amountController.clear();
      _noteController.clear();
    });
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
                      isGiven
                          ? AppLocalizations.get('receive_from').replaceFirst('{name}', widget.loan.personName)
                          : AppLocalizations.get('repay_to').replaceFirst('{name}', widget.loan.personName),
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isGiven ? AppLocalizations.get('money_added_to_account') : AppLocalizations.get('record_money_movement'),
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.secondaryText),
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _amountController,
                      hintText: AppLocalizations.get('amount_max').replaceFirst('{amount}', widget.loan.remainingAmount.toInt().toString()),
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
                              AppLocalizations.get('given_by'),
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
                        label: AppLocalizations.get('repay_from_my_pocket'),
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
                            isGiven ? AppLocalizations.get('add_to_my_app_account') : AppLocalizations.get('return_to_app_account'),
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Early Settlement',
                                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryText),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Settle the loan fully with this payment amount',
                                  style: GoogleFonts.outfit(fontSize: 10, color: AppColors.secondaryText),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isEarlySettlement,
                            activeColor: AppColors.brandPrimary,
                            onChanged: (val) => setModalState(() => _isEarlySettlement = val),
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
                        label: isGiven ? AppLocalizations.get('receive_into_my_pocket') : AppLocalizations.get('return_to_their_pocket'),
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
                                AppLocalizations.get('confirm_transaction'),
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
                    hint: Text(AppLocalizations.get('none_outside_app'), style: GoogleFonts.outfit(fontSize: 13, color: AppColors.secondaryText)),
                    items: [
                      DropdownMenuItem<AccountModel>(
                        value: null,
                        child: Text(AppLocalizations.get('none_outside_app'), style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
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
            Text('${AppLocalizations.get('current')}: ৳${account.breakdown[owner]?.toInt() ?? 0}', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.secondaryText)),
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
          AppLocalizations.get('loan_details'),
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
              title: AppLocalizations.get('delete_loan'),
              content: AppLocalizations.get('delete_loan_message'),
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
                const SizedBox(height: 24),
                _buildAttachmentsList(isDark),
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

    final reminderText = AppLocalizations.get('loan_reminder_message')
        .replaceFirst('{name}', widget.loan.personName)
        .replaceFirst('{amount}', widget.loan.remainingAmount.toInt().toString());

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
                    AppLocalizations.get('repayment_reminder_template'),
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
                      content: Text(AppLocalizations.get('reminder_template_copied'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
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
                        AppLocalizations.get('copy_reminder_template'),
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
              if (widget.loan.personPhone != null && widget.loan.personPhone!.isNotEmpty) ...[
                const SizedBox(height: 12),
                ScaleOnTap(
                  onTap: () async {
                    final phone = widget.loan.personPhone!.replaceAll(RegExp(r'\D'), '');
                    final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(reminderText)}');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not launch WhatsApp')),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wechat_rounded, color: Color(0xFF25D366), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Remind via WhatsApp',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF25D366),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (widget.loan.status == LoanStatus.paid || widget.loan.remainingAmount == 0) ...[
                const SizedBox(height: 12),
                ScaleOnTap(
                  onTap: _generateAndShareReceipt,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded, color: AppColors.brandPrimary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Share Receipt',
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
                  AppLocalizations.get('installment_timeline'),
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
                              AppLocalizations.get('installment_number').replaceFirst('{number}', (index + 1).toString()),
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textBlack),
                            ),
                            Text(
                              '${AppLocalizations.get('due')}: ${DateFormat('dd MMM yyyy').format(inst.dueDate)}',
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
      if (widget.loan.installments.isNotEmpty) {
        for (var inst in widget.loan.installments) {
          await NotificationService().cancelLoanReminders('${widget.loan.id}_${inst.id}');
        }
      } else {
        await NotificationService().cancelLoanReminders(widget.loan.id);
      }
      
      await _loanService.deleteLoan(widget.loan);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.get('error')}: $e')));
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.get('error')}: $e')));
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
                    isPaid ? AppLocalizations.get('paid') : AppLocalizations.get('pending'),
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
                isGiven ? AppLocalizations.get('money_you_gave') : AppLocalizations.get('money_you_took'),
                style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13),
              ),
            ),
            if (widget.loan.dueDate != null && widget.loan.installments.isEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: Colors.redAccent, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Due on: ${widget.loan.dueDate!.day}/${widget.loan.dueDate!.month}/${widget.loan.dueDate!.year}',
                      style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            if (widget.loan.interestAmount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statColumn(AppLocalizations.get('principal_amount') ?? 'Principal', widget.loan.amount, AppColors.textBlack),
                  _statColumn(AppLocalizations.get('interest_amount') ?? 'Interest (${widget.loan.interestRate}%)', widget.loan.interestAmount, Colors.orangeAccent),
                  _statColumn(AppLocalizations.get('total_owed') ?? 'Total Owed', widget.loan.amount + widget.loan.interestAmount, AppColors.brandPrimary),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statColumn(AppLocalizations.get('total_amount'), widget.loan.amount + widget.loan.interestAmount, AppColors.textBlack),
                _statColumn(AppLocalizations.get('paid_back'), (widget.loan.amount + widget.loan.interestAmount) - widget.loan.remainingAmount, AppColors.brandPrimary),
                _statColumn(AppLocalizations.get('remaining'), widget.loan.remainingAmount + widget.loan.currentPenalty, widget.loan.remainingAmount > 0 ? Colors.redAccent : AppColors.brandPrimary),
              ],
            ),
            Builder(
              builder: (context) {
                final isBkash = widget.loan.interestRate == 1.098 ||
                                widget.loan.interestRate == 1.611 ||
                                widget.loan.interestRate == 1.619 ||
                                widget.loan.personName.toLowerCase().contains('bkash') ||
                                widget.loan.note.toLowerCase().contains('bkash');
                if (!isBkash || widget.loan.status == LoanStatus.paid) {
                  return const SizedBox.shrink();
                }
                
                final details = getBkashEarlyPayoffDetails();
                final earlyPayoffTotal = details['total'] ?? 0;
                final earlyPayoffInterest = details['interest'] ?? 0;
                final daysElapsed = DateTime.now().difference(widget.loan.date).inDays.clamp(0, 999);
                
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2136E).withValues(alpha: 0.05), // bKash color
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2136E).withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bolt_rounded, color: Color(0xFFE2136E), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'bKash Early Payoff (Today)',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFE2136E),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Days Elapsed: $daysElapsed days',
                                  style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Interest accrued: ৳${earlyPayoffInterest.toStringAsFixed(2)}',
                                  style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '৳${earlyPayoffTotal.toStringAsFixed(2)}',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFFE2136E),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                GestureDetector(
                                  onTap: () {
                                    _amountController.text = earlyPayoffTotal.toStringAsFixed(2);
                                    _showAddPaymentModal();
                                  },
                                  child: Text(
                                    'Pay in Full',
                                    style: GoogleFonts.outfit(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }
            ),
            if (widget.loan.currentPenalty > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Late Penalty Added: ৳${widget.loan.currentPenalty.toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
          child: Text(AppLocalizations.get('no_repayments_yet'), style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13.5)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(AppLocalizations.get('repayment_history'), style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 15, fontWeight: FontWeight.bold)),
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
                            Text(AppLocalizations.get('payment_recieved'), style: GoogleFonts.outfit(color: AppColors.textBlack, fontWeight: FontWeight.w600, fontSize: 14)),
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
                              title: AppLocalizations.get('delete_payment'),
                              content: AppLocalizations.get('delete_payment_message'),
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
        title: Text(AppLocalizations.get('edit_person_name'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: AppLocalizations.get('name'),
            labelStyle: GoogleFonts.outfit(color: AppColors.textGrey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.brandPrimary)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.brandPrimary, width: 2)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.get('cancel'), style: GoogleFonts.outfit(color: AppColors.textGrey))),
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
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.get('error')}: $e')));
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
                  widget.loan.type == LoanType.given ? AppLocalizations.get('receive_payment') : AppLocalizations.get('repay_loan'),
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
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.get('cancel'), style: GoogleFonts.outfit(color: AppColors.textGrey))),
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

  Widget _buildAttachmentsList(bool isDark) {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.attachment_rounded, color: AppColors.brandPrimary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Evidence & Documents',
                      style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                  ],
                ),
                ScaleOnTap(
                  onTap: _pickAndUploadAttachment,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.add_photo_alternate_rounded, color: AppColors.brandPrimary, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.loan.attachmentUrls.isEmpty)
              Text('No attachments uploaded yet.', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 12))
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: widget.loan.attachmentUrls.map((url) => _buildAttachmentThumbnail(url)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentThumbnail(String url) {
    return ScaleOnTap(
      onTap: () async {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 80,
          height: 80,
          color: Colors.grey.withValues(alpha: 0.2),
          child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.description_rounded, color: Colors.grey)),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAttachment() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() => _isLoading = true);
        await _loanService.uploadAttachment(widget.loan.id, File(image.path));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attachment uploaded successfully!')));
        // Note: For real-time updates, ideally listen to a stream, but since we update firestore, let user refresh or we update local model
        setState(() {
          // Just refreshing the screen since we don't have stream builder here directly
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateAndShareReceipt() async {
    setState(() => _isLoading = true);
    try {
      final image = await _screenshotController.captureFromWidget(
        Material(
          color: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.brandPrimary, width: 4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                Text('LOAN SETTLED', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 24),
                Text('Name: ${widget.loan.personName}', style: GoogleFonts.outfit(fontSize: 18, color: Colors.black87)),
                Text('Total Paid: ৳${(widget.loan.amount + widget.loan.interestAmount).toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 18, color: Colors.black87)),
                const SizedBox(height: 24),
                Text('Generated by Pocket Ledger', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final imagePath = await File('${directory.path}/receipt_${widget.loan.id}.png').create();
      await imagePath.writeAsBytes(image);

      await Share.shareXFiles([XFile(imagePath.path)], text: 'Receipt for ${widget.loan.personName}');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating receipt: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
