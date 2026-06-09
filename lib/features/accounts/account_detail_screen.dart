import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/account_model.dart';
import 'package:pocketledger/models/transaction_model.dart';
import 'package:pocketledger/services/account_service.dart';
import 'package:pocketledger/services/transaction_service.dart';
import 'package:intl/intl.dart';
import 'package:pocketledger/core/widgets/scale_on_tap.dart';
import 'package:pocketledger/core/widgets/glass_card.dart';
import 'package:pocketledger/core/constants/app_constants.dart';
import 'package:pocketledger/features/auth/widgets/custom_text_field.dart';
import 'package:pocketledger/core/localization/app_localizations.dart';

class AccountDetailScreen extends StatefulWidget {
  final AccountModel account;
  const AccountDetailScreen({super.key, required this.account});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  late String _currentName;
  String? _currentAccountNumber;
  String? _currentCardNumber;
  String? _currentBranchName;
  String? _currentRoutingNumber;
  String? _currentMobileNumber;
  final AccountService _accountService = AccountService();

  @override
  void initState() {
    super.initState();
    _currentName = widget.account.name;
    _currentAccountNumber = widget.account.accountNumber;
    _currentCardNumber = widget.account.cardNumber;
    _currentBranchName = widget.account.branchName;
    _currentRoutingNumber = widget.account.routingNumber;
    _currentMobileNumber = widget.account.mobileNumber;
  }

  void _copyToClipboard(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.get('copied_to_clipboard').replaceFirst('{label}', label),
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.brandPrimary,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _copyAllBankDetails() {
    final buffer = StringBuffer();
    buffer.writeln(AppLocalizations.get('bank_account_details'));
    buffer.writeln('${AppLocalizations.get('bank')}: $_currentName');
    if (_currentAccountNumber != null && _currentAccountNumber!.isNotEmpty) {
      buffer.writeln('${AppLocalizations.get('account_number')}: $_currentAccountNumber');
    }
    if (_currentCardNumber != null && _currentCardNumber!.isNotEmpty) {
      buffer.writeln('${AppLocalizations.get('card_number')}: $_currentCardNumber');
    }
    if (_currentBranchName != null && _currentBranchName!.isNotEmpty) {
      buffer.writeln('${AppLocalizations.get('branch_name')}: $_currentBranchName');
    }
    if (_currentRoutingNumber != null && _currentRoutingNumber!.isNotEmpty) {
      buffer.writeln('${AppLocalizations.get('routing_number')}: $_currentRoutingNumber');
    }
    _copyToClipboard(AppLocalizations.get('all_bank_details'), buffer.toString().trim());
  }

  void _copyAllMfsDetails() {
    final buffer = StringBuffer();
    buffer.writeln(AppLocalizations.get('mobile_wallet_details'));
    buffer.writeln('${AppLocalizations.get('wallet_name')}: $_currentName');
    if (_currentMobileNumber != null && _currentMobileNumber!.isNotEmpty) {
      buffer.writeln('${AppLocalizations.get('mobile_number')}: $_currentMobileNumber');
    }
    _copyToClipboard(AppLocalizations.get('wallet_details'), buffer.toString().trim());
  }

  String _maskCardNumber(String cardNumber) {
    if (cardNumber.length <= 4) return cardNumber;
    final last4 = cardNumber.substring(cardNumber.length - 4);
    return '•••• •••• •••• $last4';
  }

  Widget? _buildMfsBrandBadge(String name) {
    final n = name.toLowerCase();
    String brand = '';
    Color brandColor = Colors.transparent;

    if (n.contains('bkash')) {
      brand = 'bKash Wallet';
      brandColor = const Color(0xFFE2125B);
    } else if (n.contains('nagad')) {
      brand = 'Nagad Wallet';
      brandColor = const Color(0xFFFF5E62);
    } else if (n.contains('rocket')) {
      brand = 'Rocket Wallet';
      brandColor = const Color(0xFF8C3494);
    } else {
      return null;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: brandColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: brandColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        brand,
        style: GoogleFonts.outfit(
          color: brandColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  void _showEditAccountSheet() {
    final nameCtrl = TextEditingController(text: _currentName);
    final accNumCtrl = TextEditingController(text: _currentAccountNumber ?? '');
    final cardNumCtrl = TextEditingController(text: _currentCardNumber ?? '');
    final branchCtrl = TextEditingController(text: _currentBranchName ?? '');
    final routingCtrl = TextEditingController(text: _currentRoutingNumber ?? '');
    final mobileCtrl = TextEditingController(text: _currentMobileNumber ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF16201D) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.get('edit_account_info'),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppColors.textBlack,
                    ),
                  ),
                  ScaleOnTap(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close_rounded, color: AppColors.textGrey, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.get('account_name'),
                style: GoogleFonts.outfit(
                  color: AppColors.textGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: nameCtrl,
                hintText: AppLocalizations.get('account_name_1'),
                icon: Icons.edit_note_outlined,
              ),
              if (widget.account.type.toLowerCase().contains('bank')) ...[
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.get('bank_account_details'),
                  style: GoogleFonts.outfit(
                    color: AppColors.textGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.security_rounded, color: Colors.redAccent, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        AppLocalizations.get('for_security_do_not'),
                        style: GoogleFonts.outfit(
                          color: Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: accNumCtrl,
                  hintText: AppLocalizations.get('account_number'),
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: cardNumCtrl,
                  hintText: AppLocalizations.get('card_number_last_4'),
                  icon: Icons.credit_card_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: branchCtrl,
                  hintText: AppLocalizations.get('branch_name'),
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: routingCtrl,
                  hintText: AppLocalizations.get('routing_number'),
                  icon: Icons.tag_rounded,
                  keyboardType: TextInputType.number,
                ),
              ] else if (widget.account.type.toLowerCase().contains('mfs') || widget.account.type.toLowerCase().contains('phone')) ...[
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.get('mobile_wallet_details'),
                  style: GoogleFonts.outfit(
                    color: AppColors.textGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: mobileCtrl,
                  hintText: AppLocalizations.get('wallet_mobile_number'),
                  icon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ScaleOnTap(
                  onTap: () async {
                    if (nameCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.get('please_enter_account_name'))),
                      );
                      return;
                    }

                    final name = nameCtrl.text;
                    final accNum = accNumCtrl.text.isNotEmpty ? accNumCtrl.text : null;
                    final cardNum = cardNumCtrl.text.isNotEmpty ? cardNumCtrl.text : null;
                    final branch = branchCtrl.text.isNotEmpty ? branchCtrl.text : null;
                    final routing = routingCtrl.text.isNotEmpty ? routingCtrl.text : null;
                    final mobile = mobileCtrl.text.isNotEmpty ? mobileCtrl.text : null;

                    await _accountService.updateAccountDetails(
                      accountId: widget.account.id,
                      name: name,
                      accountNumber: accNum,
                      cardNumber: cardNum,
                      branchName: branch,
                      routingNumber: routing,
                      mobileNumber: mobile,
                    );

                    setState(() {
                      _currentName = name;
                      _currentAccountNumber = accNum;
                      _currentCardNumber = cardNum;
                      _currentBranchName = branch;
                      _currentRoutingNumber = routing;
                      _currentMobileNumber = mobile;
                    });

                    if (mounted) Navigator.pop(context);
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandPrimary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      AppLocalizations.get('save_changes'),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TransactionService transactionService = TransactionService();
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
            child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryText, size: 20),
          ),
        ),
        title: Text(
          _currentName,
          style: GoogleFonts.outfit(
            color: AppColors.primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          ScaleOnTap(
            onTap: _showEditAccountSheet,
            child: Icon(Icons.edit_rounded, color: AppColors.brandPrimary, size: 20),
          ),
          const SizedBox(width: 20),
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
            child: Column(
              children: [
                _buildBalanceHeader(context),
                _buildDetailsSection(context),
                _buildBreakdownSection(context),
                _buildActionButtons(context),
                _buildTransactionSection(context, transactionService),
              ],
            ),
          ),
        ],
      ),
    )); // closes Scaffold + ThemeBuilder
  }

  Widget _buildBalanceHeader(BuildContext context) {
    final mfsBadge = _buildMfsBrandBadge(_currentName);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Text(
            AppLocalizations.get('full_balance'),
            style: GoogleFonts.outfit(
              color: AppColors.textGrey,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '৳ ${widget.account.totalBalance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},")}',
            style: GoogleFonts.outfit(
              color: AppColors.textBlack,
              fontSize: 44,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.15)),
            ),
            child: Text(
              widget.account.type.toUpperCase(),
              style: GoogleFonts.outfit(
                color: AppColors.brandPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
          if (mfsBadge != null) mfsBadge,
        ],
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    final acc = widget.account;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasBankDetails = acc.type.toLowerCase().contains('bank') && (
      (_currentAccountNumber != null && _currentAccountNumber!.isNotEmpty) ||
      (_currentCardNumber != null && _currentCardNumber!.isNotEmpty) ||
      (_currentBranchName != null && _currentBranchName!.isNotEmpty) ||
      (_currentRoutingNumber != null && _currentRoutingNumber!.isNotEmpty)
    );

    final hasMfsDetails = (acc.type.toLowerCase().contains('mfs') || acc.type.toLowerCase().contains('phone')) &&
      _currentMobileNumber != null && _currentMobileNumber!.isNotEmpty;

    if (!hasBankDetails && !hasMfsDetails) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: GlassCard(
        blur: 20,
        opacity: isDark ? 0.05 : 0.45,
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
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.brandPrimary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.get('account_information'),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.outfit(
                              color: AppColors.textBlack,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ScaleOnTap(
                    onTap: hasBankDetails ? _copyAllBankDetails : _copyAllMfsDetails,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.copy_all_rounded, color: AppColors.brandPrimary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.get('copy_all'),
                            style: GoogleFonts.outfit(
                              color: AppColors.brandPrimary,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (hasBankDetails) ...[
                if (_currentAccountNumber != null && _currentAccountNumber!.isNotEmpty)
                  _buildDetailRow(AppLocalizations.get('account_number'), _currentAccountNumber!, Icons.badge_outlined),
                if (_currentCardNumber != null && _currentCardNumber!.isNotEmpty)
                  _buildDetailRow(AppLocalizations.get('card_number'), _maskCardNumber(_currentCardNumber!), Icons.credit_card_rounded, rawValue: _currentCardNumber),
                if (_currentBranchName != null && _currentBranchName!.isNotEmpty)
                  _buildDetailRow(AppLocalizations.get('branch_name'), _currentBranchName!, Icons.location_on_outlined),
                if (_currentRoutingNumber != null && _currentRoutingNumber!.isNotEmpty)
                  _buildDetailRow(AppLocalizations.get('routing_number'), _currentRoutingNumber!, Icons.tag_rounded),
              ] else if (hasMfsDetails) ...[
                _buildDetailRow(AppLocalizations.get('mobile_number'), _currentMobileNumber!, Icons.phone_android_rounded),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String displayValue, IconData icon, {String? rawValue}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, color: AppColors.textGrey, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.outfit(
                          color: AppColors.textGrey,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayValue,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: GoogleFonts.outfit(
                          color: AppColors.textBlack,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ScaleOnTap(
            onTap: () => _copyToClipboard(label, rawValue ?? displayValue),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandPrimary.withValues(alpha: 0.08),
              ),
              child: Icon(Icons.copy_rounded, color: AppColors.brandPrimary, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = widget.account.totalBalance > 0 ? widget.account.totalBalance : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassCard(
        blur: 20,
        opacity: isDark ? 0.05 : 0.45,
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
                  Icon(Icons.pie_chart_outline_rounded, color: AppColors.brandPrimary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.get('owner_share_distribution'),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.outfit(
                        color: AppColors.textBlack,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...widget.account.breakdown.entries.map((entry) {
                final double sharePercentage = (entry.value / total) * 100;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(color: AppColors.brandPrimary, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: GoogleFonts.outfit(
                                      color: AppColors.textBlack,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '৳ ${entry.value.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => "${m[1]},")}',
                                style: GoogleFonts.outfit(
                                  color: AppColors.textBlack,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${sharePercentage.toStringAsFixed(1)}%',
                                style: GoogleFonts.outfit(
                                  color: AppColors.textGrey,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: entry.value / total,
                          backgroundColor: isDark ? const Color(0xFF283A35) : const Color(0xFFEEEEEE),
                          color: AppColors.brandPrimary,
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
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
              AppLocalizations.get('add_money'), 
              Icons.add_rounded, 
              AppColors.brandPrimary,
              () => Navigator.pushNamed(
                context, 
                '/add-transaction', 
                arguments: {
                  'type': TransactionType.income,
                  'account': widget.account,
                },
              )
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _actionButton(
              context, 
              AppLocalizations.get('withdraw'), 
              Icons.remove_rounded, 
              Colors.redAccent,
              () => Navigator.pushNamed(
                context, 
                '/add-transaction', 
                arguments: {
                  'type': TransactionType.expense,
                  'account': widget.account,
                },
              )
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.08 : 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionSection(BuildContext context, TransactionService service) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, color: AppColors.brandPrimary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.get('transaction_history'),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.outfit(
                    color: AppColors.primaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          StreamBuilder<List<TransactionModel>>(
            stream: service.getTransactionsByAccount(widget.account.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      AppLocalizations.get('no_transactions_recorded_yet'),
                      style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13.5),
                    ),
                  ),
                );
              }

              final transactions = snapshot.data!;
              return Column(
                children: transactions.map((tx) => _transactionItem(context, tx)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _transactionItem(BuildContext context, TransactionModel tx) {
    final bool isIncome = tx.type == TransactionType.income;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        blur: 15,
        opacity: isDark ? 0.03 : 0.45,
        color: isDark ? const Color(0xFF16201D) : Colors.white,
        borderRadius: 20,
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.05)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isIncome ? AppColors.brandPrimary : Colors.redAccent).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: isIncome ? AppColors.brandPrimary : Colors.redAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.category,
                      style: GoogleFonts.outfit(
                        color: AppColors.textBlack,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMM yyyy').format(tx.date),
                      style: GoogleFonts.outfit(
                        color: AppColors.textGrey,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}${tx.amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => "${m[1]},")}',
                    style: GoogleFonts.outfit(
                      color: isIncome ? AppColors.brandPrimary : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.5,
                    ),
                  ),
                  if (tx.owner != AppConstants.ownerSelf)
                    Text(
                      tx.owner.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: AppColors.textGrey,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
