import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/account_model.dart';
import 'package:pocketledger/services/account_service.dart';
import 'package:pocketledger/features/accounts/account_detail_screen.dart';
import 'package:pocketledger/core/widgets/scale_on_tap.dart';
import 'package:pocketledger/core/widgets/glass_card.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AccountService accountService = AccountService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: ScaleOnTap(
          onTap: () => Navigator.maybePop(context),
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryText, size: 20),
          ),
        ),
        title: Text(
          'Accounts',
          style: GoogleFonts.outfit(
            color: AppColors.primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          ScaleOnTap(
            onTap: () => Navigator.pushNamed(context, '/add-account'),
            child: Icon(Icons.add_circle_rounded, color: AppColors.brandPrimary, size: 28),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: StreamBuilder<List<AccountModel>>(
        stream: accountService.getAccounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
          }

          final accounts = snapshot.data ?? [];
          double totalBalance = accounts.fold(0, (sum, acc) => sum + acc.totalBalance);

          return Stack(
            children: [
              // Liquid glow blobs in background
              Positioned(
                top: 40, left: -50,
                child: Container(
                  width: 240, height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brandPrimary.withValues(alpha: isDark ? 0.08 : 0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: 150, right: -60,
                child: Container(
                  width: 220, height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentGold.withValues(alpha: isDark ? 0.06 : 0.04),
                  ),
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(color: Colors.transparent),
                ),
              ),
              Column(
                children: [
                  _buildSummaryHeader(context, totalBalance),
                  Expanded(
                    child: accounts.isEmpty 
                        ? _buildEmptyState(context)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                            physics: const BouncingScrollPhysics(),
                            itemCount: accounts.length,
                            itemBuilder: (context, index) => _AccountCard(account: accounts[index]),
                          ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context, double total) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: GlassCard(
        blur: 20,
        opacity: isDark ? 0.05 : 0.45,
        color: isDark ? const Color(0xFF16201D) : Colors.white,
        borderRadius: 24,
        border: Border.all(
          color: AppColors.brandPrimary.withValues(alpha: 0.15),
          width: 1.5,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.brandPrimary.withValues(alpha: 0.12),
                AppColors.brandPrimary.withValues(alpha: 0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.wallet_rounded, color: AppColors.brandPrimary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'COMBINED PORTFOLIO BALANCE',
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.white70 : AppColors.brandPrimary.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '৳ ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},")}',
                style: GoogleFonts.outfit(
                  color: AppColors.textBlack,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '“Combined balance of all MFS, Bank & Cash accounts”',
                style: GoogleFonts.outfit(
                  color: AppColors.textGrey,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brandPrimary.withValues(alpha: 0.08),
            ),
            child: Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppColors.brandPrimary.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),
          Text(
            'Where is my money?',
            style: GoogleFonts.outfit(
              color: AppColors.textBlack,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add an account to see your assets here',
            style: GoogleFonts.outfit(
              color: AppColors.textGrey,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final AccountModel account;
  const _AccountCard({required this.account});

  List<Color> _getCardGradient(String type, bool isDark) {
    final t = type.toLowerCase();
    if (t.contains('bank')) {
      return [
        const Color(0xFF0F2027),
        const Color(0xFF203A43),
        const Color(0xFF2C5364),
      ];
    } else if (t.contains('mfs') || t.contains('bkash') || t.contains('nagad')) {
      return [
        const Color(0xFFE2125B),
        const Color(0xFFFF5E62),
      ];
    } else if (t.contains('cash')) {
      return [
        const Color(0xFF005B41),
        const Color(0xFF008967),
      ];
    } else {
      return isDark
          ? [const Color(0xFF16201D), const Color(0xFF283A35)]
          : [const Color(0xFFECE9E6), const Color(0xFFFFFFFF)];
    }
  }

  IconData _getAccountIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('bank')) {
      return Icons.account_balance_rounded;
    } else if (t.contains('mfs') || t.contains('phone') || t.contains('bkash') || t.contains('nagad')) {
      return Icons.phone_android_rounded;
    } else if (t.contains('cash')) {
      return Icons.payments_rounded;
    }
    return Icons.wallet_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = _getCardGradient(account.type, isDark);
    final isSpecialGradient = account.type.toLowerCase().contains('bank') ||
        account.type.toLowerCase().contains('mfs') ||
        account.type.toLowerCase().contains('cash');

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: ScaleOnTap(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AccountDetailScreen(account: account),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withValues(alpha: isDark ? 0.3 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned(
                  right: -15,
                  top: -15,
                  child: Icon(
                    _getAccountIcon(account.type),
                    size: 140,
                    color: Colors.white.withValues(alpha: isSpecialGradient ? 0.05 : (isDark ? 0.03 : 0.05)),
                  ),
                ),
                // Visual simulated smart card chip
                Positioned(
                  left: 24,
                  top: 24,
                  child: Container(
                    width: 36,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB800).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                            ),
                            itemCount: 9,
                            itemBuilder: (context, idx) => Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black12, width: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 70, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              account.name,
                              style: GoogleFonts.outfit(
                                color: isSpecialGradient ? Colors.white : AppColors.textBlack,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: isSpecialGradient ? 0.15 : (isDark ? 0.08 : 0.15)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              account.type.toUpperCase(),
                              style: GoogleFonts.outfit(
                                color: isSpecialGradient ? Colors.white : AppColors.textBlack,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'TOTAL BALANCE',
                        style: GoogleFonts.outfit(
                          color: isSpecialGradient
                              ? Colors.white.withValues(alpha: 0.6)
                              : AppColors.textGrey,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '৳ ${account.totalBalance.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => "${m[1]},")}',
                        style: GoogleFonts.outfit(
                          color: isSpecialGradient ? Colors.white : AppColors.textBlack,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(
                        color: isSpecialGradient
                            ? Colors.white.withValues(alpha: 0.15)
                            : AppColors.secondaryText.withValues(alpha: 0.15),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'OWNER SPLIT',
                        style: GoogleFonts.outfit(
                          color: isSpecialGradient
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppColors.textGrey,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...account.breakdown.entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSpecialGradient
                                              ? Colors.white.withValues(alpha: 0.6)
                                              : AppColors.brandPrimary.withValues(alpha: 0.6),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: GoogleFonts.outfit(
                                            color: isSpecialGradient
                                                ? Colors.white.withValues(alpha: 0.85)
                                                : AppColors.textGrey,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '৳ ${entry.value.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => "${m[1]},")}',
                                  style: GoogleFonts.outfit(
                                    color: isSpecialGradient ? Colors.white : AppColors.textBlack,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
