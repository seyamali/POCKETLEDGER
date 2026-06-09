import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/scale_on_tap.dart';
import '../../core/localization/app_localizations.dart';

class GuideFeature {
  final String title;
  final IconData icon;
  final String engDesc;
  final String banDesc;

  GuideFeature({required this.title, required this.icon, required this.engDesc, required this.banDesc});
}

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  List<GuideFeature> _getFeatures() {
    return [
      GuideFeature(
        title: 'Accounts & Wallet Management',
        icon: Icons.account_balance_wallet_rounded,
        engDesc: 'Welcome to the core of your financial tracking: The Accounts/Wallet section. Here you can manage every source of your money with absolute precision.\n\n'
            '1. View Total Assets: At the very top of your dashboard, you will see your "Total Assets" or "Total Balance". This is the sum of all your accounts (excluding savings vaults) calculated automatically.\n\n'
            '2. Add a New Account: To add a new source of funds (like a Bank Account, bKash, Cash, or Credit Card), tap on the Wallet icon at the bottom, then tap the "Add Account" or "+" button. You will be asked to choose an icon, name your account (e.g., "City Bank Salary"), select the account type, and enter the starting balance. Once saved, it will immediately appear in your wallet.\n\n'
            '3. Real-time Balance Tracking: You never have to manually calculate how much is left in your account. Every time you add an "Income" transaction, the chosen account\'s balance goes up. Every time you add an "Expense", it goes down. If you perform a "Transfer" from Cash to bKash, the cash balance decreases and bKash increases instantly.\n\n'
            '4. Edit or Correct Balances: Sometimes you might forget to log a transaction and your physical money does not match the app. No worries! Tap on any account from the Wallet screen, and tap "Edit". You can manually correct the balance, change the account name, or update its icon.\n\n'
            '5. Delete an Account: If you no longer use an account, you can delete it from the Edit screen. Note: Deleting an account may affect your overall transaction history.\n\n'
            'Mastering this section ensures your digital ledger perfectly mirrors your real-life wallet!',
        banDesc: 'অ্যাকাউন্ট এবং ওয়ালেট ম্যানেজমেন্ট সেকশনে স্বাগতম! এখান থেকে আপনি আপনার সমস্ত টাকার উৎস অত্যন্ত নিখুঁতভাবে পরিচালনা করতে পারবেন।\n\n'
            '১. মোট সম্পদ দেখা: ড্যাশবোর্ডের একদম উপরে আপনি আপনার "মোট সম্পদ" বা "Total Balance" দেখতে পাবেন। এটি আপনার সমস্ত অ্যাকাউন্টের (সেভিংস ভল্ট বাদে) টাকার যোগফল, যা স্বয়ংক্রিয়ভাবে হিসাব করা হয়।\n\n'
            '২. নতুন অ্যাকাউন্ট যুক্ত করা: আয়ের নতুন কোনো উৎস (যেমন- ব্যাংক অ্যাকাউন্ট, বিকাশ, নগদ বা ক্যাশ) যোগ করতে নিচের ওয়ালেট আইকনে চাপ দিন এবং এরপর "Add Account" বা "+" বাটনে চাপ দিন। অ্যাকাউন্টের একটি সুন্দর আইকন বেছে নিন, নাম লিখুন (যেমন- "City Bank Salary"), ধরন নির্বাচন করুন এবং বর্তমান ব্যালেন্স লিখে সেভ করুন। এটি সাথে সাথে আপনার ওয়ালেটে যুক্ত হয়ে যাবে।\n\n'
            '৩. রিয়েল-টাইম ব্যালেন্স ট্র্যাকিং: আপনাকে আর নিজে হিসাব করতে হবে না। যখনই আপনি কোনো "Income" (আয়) যুক্ত করবেন, ঐ অ্যাকাউন্টের ব্যালেন্স বেড়ে যাবে। "Expense" (ব্যয়) যুক্ত করলে ব্যালেন্স কমে যাবে। আবার, ক্যাশ থেকে বিকাশে "Transfer" করলে ক্যাশ কমবে এবং বিকাশে সাথে সাথে টাকা বেড়ে যাবে।\n\n'
            '৪. ব্যালেন্স এডিট বা সংশোধন করা: মাঝে মাঝে আমরা হিসাব রাখতে ভুলে যাই এবং আসল টাকার সাথে অ্যাপের হিসাব মেলে না। চিন্তার কিছু নেই! ওয়ালেট স্ক্রিন থেকে যেকোনো অ্যাকাউন্টের ওপর চাপ দিন এবং "Edit" বাটনে ক্লিক করুন। এখান থেকে আপনি খুব সহজেই টাকার পরিমাণ ঠিক করতে পারবেন বা অ্যাকাউন্টের নাম ও আইকন পরিবর্তন করতে পারবেন।\n\n'
            '৫. অ্যাকাউন্ট মুছে ফেলা: কোনো অ্যাকাউন্ট আর ব্যবহার না করলে আপনি সেটি এডিট স্ক্রিন থেকে মুছে ফেলতে পারেন।\n\n'
            'এই সেকশনটি সঠিকভাবে ব্যবহার করলে আপনার ডিজিটাল হিসাব আর বাস্তবের মানিব্যাগের মধ্যে কোনো পার্থক্য থাকবে না!',
      ),
    ];
  }

  void _showFeatureDetails(BuildContext context, GuideFeature feature) {
    final isDark = AppColors.isDark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16201D) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(feature.icon, color: AppColors.primaryGreen, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    feature.title,
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textBlack),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('English', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
            const SizedBox(height: 8),
            Text(
              feature.engDesc,
              style: GoogleFonts.outfit(fontSize: 15, color: isDark ? Colors.white70 : AppColors.textGrey, height: 1.5),
            ),
            const SizedBox(height: 24),
            Text('বাংলা (Bangla)', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
            const SizedBox(height: 8),
            Text(
              feature.banDesc,
              style: GoogleFonts.outfit(fontSize: 15, color: isDark ? Colors.white70 : AppColors.textGrey, height: 1.5),
            ),
            const SizedBox(height: 32),
          ],
        ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    final features = _getFeatures();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'App Guide',
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white : AppColors.textBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.textBlack),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: features.length,
        itemBuilder: (context, index) {
          final feature = features[index];
          return ScaleOnTap(
            onTap: () => _showFeatureDetails(context, feature),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: GlassCard(
                opacity: isDark ? 0.8 : 0.9,
                color: isDark ? const Color(0xFF1A2623) : Colors.white,
                borderRadius: 20,
                border: Border.all(
                  color: isDark
                      ? AppColors.primaryGreen.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(feature.icon, color: AppColors.primaryGreen, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feature.title,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textBlack,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to see details',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: AppColors.textGrey.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
