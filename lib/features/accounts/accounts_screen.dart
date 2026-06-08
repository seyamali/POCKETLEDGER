import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/account_model.dart';
import 'package:pocketledger/services/account_service.dart';
import 'package:pocketledger/features/accounts/account_detail_screen.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AccountService accountService = AccountService();

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryText, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('Accounts', style: GoogleFonts.montserrat(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_rounded, color: AppColors.brandPrimary, size: 30),
            onPressed: () => Navigator.pushNamed(context, '/add-account'),
          ),
          const SizedBox(width: 12),
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

          return Column(
            children: [
              _buildSummaryHeader(totalBalance),
              Expanded(
                child: accounts.isEmpty 
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        physics: const BouncingScrollPhysics(),
                        itemCount: accounts.length,
                        itemBuilder: (context, index) => _AccountCard(account: accounts[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(double total) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brandPrimary, AppColors.brandPrimary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.brandPrimary.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💰 Total Across All Accounts', 
            style: GoogleFonts.montserrat(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},")} Tk',
            style: GoogleFonts.montserrat(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('“Combined balance of all accounts”', 
            style: GoogleFonts.montserrat(color: Colors.white.withOpacity(0.8), fontSize: 11, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 80, color: AppColors.secondaryText.withOpacity(0.2)),
          const SizedBox(height: 24),
          Text('Where is my money?', style: GoogleFonts.montserrat(color: AppColors.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Add an account to see it here', style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 13)),
        ],
      ),
    );
  }
}

class _AccountCard extends StatefulWidget {
  final AccountModel account;
  const _AccountCard({required this.account});

  @override
  State<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<_AccountCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: () {
        // Navigate to detail view
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AccountDetailScreen(account: widget.account),
          ),
        );
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.brandPrimary.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(widget.account.name, 
                        style: GoogleFonts.montserrat(color: AppColors.primaryText, fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildTypeTag(widget.account.type),
                  ],
                ),
                const SizedBox(height: 12),
                Text('💰 Total: ${widget.account.totalBalance.toInt()} Tk', 
                  style: GoogleFonts.montserrat(color: AppColors.brandPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Divider(color: AppColors.secondaryText.withOpacity(0.1)),
                const SizedBox(height: 12),
                Text('Breakdown:', style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...widget.account.breakdown.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('• ${entry.key}:', style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 13)),
                      Text('${entry.value.toInt()} ', style: GoogleFonts.montserrat(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTag(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('Type: $type', 
        style: GoogleFonts.montserrat(color: AppColors.brandPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
