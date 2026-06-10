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
      engDesc: 'Use Accounts to track where your money is stored. The wallet summary shows your combined balance, and each account updates automatically when you add income, expense, or transfer entries.\n\n'
        '• Add a new account from the Wallet screen with a name, icon, type, and starting balance.\n'
        '• Open an account to edit its details or correct the balance if you missed a transaction.\n'
        '• Delete unused accounts from the account details screen.',
      banDesc: 'আপনার টাকা কোথায় রাখা আছে তা Accounts/Wallet সেকশন থেকে ট্র্যাক করুন। নতুন আয়, ব্যয় বা ট্রান্সফার যোগ করলে ওয়ালেটের মোট ব্যালেন্স এবং প্রতিটি অ্যাকাউন্টের ব্যালেন্স স্বয়ংক্রিয়ভাবে আপডেট হয়।\n\n'
        '• Wallet স্ক্রিন থেকে নাম, আইকন, ধরন এবং শুরুতে ব্যালেন্স দিয়ে নতুন অ্যাকাউন্ট যোগ করুন।\n'
        '• কোনো ট্রানজ্যাকশন মিস হলে অ্যাকাউন্ট ডিটেইলসে গিয়ে তথ্য বা ব্যালেন্স ঠিক করুন।\n'
        '• আর ব্যবহার না করলে অ্যাকাউন্ট ডিটেইলস থেকে সেটি মুছে ফেলতে পারেন।',
      ),
      GuideFeature(
      title: 'Transactions',
        icon: Icons.add_circle_outline_rounded,
      engDesc: 'Transactions are the main place to record your daily money flow. Use the center add button to create income, expense, or transfer entries, then review them in the transaction list.\n\n'
        '• Enter an amount, choose a category, set the date, and pick the account involved.\n'
        '• Use transfers when money moves between your own accounts without changing total wealth.\n'
        '• Search, filter, edit, or delete transactions from the Transactions screen.',
      banDesc: 'দৈনন্দিন আয়-ব্যয়ের হিসাব রাখার মূল জায়গা হলো Transactions। মাঝের Add বাটন থেকে income, expense বা transfer যোগ করতে পারেন, তারপর লিস্টে সব এন্ট্রি দেখতে পারবেন।\n\n'
        '• টাকার পরিমাণ লিখুন, ক্যাটাগরি বেছে নিন, তারিখ সেট করুন এবং সংশ্লিষ্ট অ্যাকাউন্ট নির্বাচন করুন।\n'
        '• আপনার নিজের এক অ্যাকাউন্ট থেকে অন্য অ্যাকাউন্টে টাকা সরালে transfer ব্যবহার করুন।\n'
        '• Transactions স্ক্রিনে সার্চ, ফিল্টার, এডিট এবং ডিলিট করা যায়।',
      ),
      GuideFeature(
        title: 'Monthly Goals',
        icon: Icons.track_changes_rounded,
      engDesc: 'Set a monthly budget to control spending. You can track category limits too, so it is easier to see where money is going.\n\n'
        '• Set an overall budget for the month or add limits for specific categories.\n'
        '• Expenses reduce the remaining budget automatically as you log them.\n'
        '• Warnings appear when spending reaches the alert threshold or goes over the limit.',
      banDesc: 'খরচ নিয়ন্ত্রণে রাখতে মাসিক বাজেট সেট করুন। চাইলে ক্যাটাগরি অনুযায়ীও সীমা নির্ধারণ করতে পারবেন, যাতে কোন খাতে কত খরচ হচ্ছে সহজে বোঝা যায়।\n\n'
        '• পুরো মাসের জন্য বাজেট বা নির্দিষ্ট ক্যাটাগরির জন্য আলাদা লিমিট সেট করুন।\n'
        '• নতুন ব্যয় যোগ করলে অবশিষ্ট বাজেট স্বয়ংক্রিয়ভাবে কমে যাবে।\n'
        '• বাজেটের সীমা ছুঁলে বা ছাড়িয়ে গেলে সতর্কবার্তা দেখাবে।',
      ),
      GuideFeature(
        title: 'Recurring Bills',
        icon: Icons.event_repeat_rounded,
      engDesc: 'Track fixed bills so you do not miss due dates. Subscriptions make it easy to manage rent, internet, streaming services, and other repeating payments.\n\n'
        '• Add a bill with its amount, billing cycle, and next due date.\n'
        '• The app highlights bills that are due soon or overdue.\n'
        '• Mark a bill as paid to move it to the next cycle automatically.',
      banDesc: 'নিয়মিত দিতে হয় এমন বিলগুলো ট্র্যাক করুন, যাতে তারিখ মিস না হয়। সাবস্ক্রিপশন দিয়ে ভাড়া, ইন্টারনেট, স্ট্রিমিং সার্ভিসসহ যেকোনো রিকারিং পেমেন্ট সহজে ম্যানেজ করা যায়।\n\n'
        '• বিলের টাকার পরিমাণ, সাইকেল এবং পরবর্তী তারিখ সেট করুন।\n'
        '• যেসব বিলের তারিখ ঘনিয়ে এসেছে বা পার হয়ে গেছে, সেগুলো অ্যাপে হাইলাইট হবে।\n'
        '• পেমেন্ট হয়ে গেলে Paid হিসেবে মার্ক করুন, তারপর পরের সাইকেল অটো আপডেট হবে।',
      ),
      GuideFeature(
        title: 'Stats & Analytics',
        icon: Icons.analytics_rounded,
      engDesc: 'Use Stats to understand how your money moves. Charts and summaries help you compare income, expense, and category patterns over time.\n\n'
        '• View charts for income, expense, and category trends.\n'
        '• Check which categories take the biggest share of your spending.\n'
        '• Filter by month or custom dates to compare different periods.',
      banDesc: 'আপনার টাকা কীভাবে খরচ হচ্ছে তা বোঝার জন্য Stats ব্যবহার করুন। চার্ট এবং সামারি আয়, ব্যয় ও ক্যাটাগরির ট্রেন্ড সময়ের সাথে তুলনা করতে সাহায্য করবে।\n\n'
        '• আয়, ব্যয় এবং ক্যাটাগরি ট্রেন্ডের চার্ট দেখুন।\n'
        '• কোন ক্যাটাগরিতে সবচেয়ে বেশি খরচ হচ্ছে তা বুঝে নিন।\n'
        '• নির্দিষ্ট মাস বা কাস্টম তারিখ দিয়ে তুলনা করুন।',
      ),
      GuideFeature(
        title: 'Savings',
        icon: Icons.savings_rounded,
      engDesc: 'Set money aside for future goals and watch your progress grow. Savings helps you separate longer-term goals from daily spending.\n\n'
        '• Create a savings goal with a target amount and deadline.\n'
        '• Move money from your main accounts into the savings vault.\n'
        '• Track progress with a visual bar as you get closer to the target.',
      banDesc: 'ভবিষ্যতের লক্ষ্যের জন্য টাকা আলাদা করে রাখুন এবং অগ্রগতি দেখুন। Savings দৈনন্দিন খরচ আর দীর্ঘমেয়াদি লক্ষ্যকে আলাদা রাখতে সাহায্য করে।\n\n'
        '• লক্ষ্যমাত্রা ও সময়সীমা দিয়ে savings goal তৈরি করুন।\n'
        '• মূল অ্যাকাউন্ট থেকে টাকা savings vault-এ স্থানান্তর করুন।\n'
        '• লক্ষ্য পূরণের অগ্রগতি visual progress bar-এ দেখুন।',
      ),
      GuideFeature(
        title: 'Loans & Debts',
        icon: Icons.handshake_rounded,
      engDesc: 'Keep track of money you borrowed or lent to others. The loans section helps you stay organized when there are repayments or due dates to remember.\n\n'
        '• Add a loan or debt with the person name, amount, and due date.\n'
        '• Record repayments as money comes in or goes out.\n'
        '• Mark the loan settled when the full amount has been returned.',
      banDesc: 'অন্যের কাছ থেকে ধার নেওয়া বা কাউকে ধার দেওয়া টাকার হিসাব রাখুন। Repayment বা due date মনে রাখতে Loans সেকশন কাজে লাগে।\n\n'
        '• ব্যক্তির নাম, টাকার পরিমাণ এবং due date দিয়ে loan/debt যোগ করুন।\n'
        '• টাকা ফেরত দেওয়া বা পাওয়ার সময় repayment রেকর্ড করুন।\n'
        '• পুরো টাকা মিটে গেলে loan settled হিসেবে মার্ক করুন।',
      ),
      GuideFeature(
        title: 'Credit Cards',
        icon: Icons.credit_card_rounded,
      engDesc: 'Manage credit card usage, statements, and outstanding balances. This screen keeps your card limits and repayments in one place.\n\n'
        '• Add a card with its limit, billing cycle, and current outstanding amount.\n'
        '• Log card spending so the outstanding balance stays up to date.\n'
        '• Record bill payments to reduce what you still owe.',
      banDesc: 'ক্রেডিট কার্ডের ব্যবহার, স্টেটমেন্ট এবং বকেয়া ব্যালেন্স এক জায়গায় রাখুন। এই স্ক্রিনে কার্ড লিমিট এবং রিপেমেন্ট সহজে ম্যানেজ করা যায়।\n\n'
        '• কার্ডের লিমিট, বিলিং সাইকেল এবং বর্তমান বকেয়া দিয়ে কার্ড যোগ করুন।\n'
        '• কার্ডে খরচ করলে outstanding balance আপডেট হবে।\n'
        '• বিল পেমেন্ট রেকর্ড করলে বকেয়া কমে যাবে।',
      ),
      GuideFeature(
        title: 'Custom Categories',
        icon: Icons.category_rounded,
      engDesc: 'Customize how you classify income and expenses. If the default categories are not enough, you can create your own and give them icons.\n\n'
        '• Add new categories for the way you actually spend.\n'
        '• Rename or update existing categories when your habits change.\n'
        '• Remove categories you no longer use.',
      banDesc: 'আপনার আয়-ব্যয় যেভাবে শ্রেণীবদ্ধ করেন তা নিজের মতো করে সাজান। ডিফল্ট ক্যাটাগরি যথেষ্ট না হলে নিজের ক্যাটাগরি তৈরি করে আইকন দিতে পারবেন।\n\n'
        '• বাস্তব খরচের ধরন অনুযায়ী নতুন ক্যাটাগরি যোগ করুন।\n'
        '• অভ্যাস বদলালে পুরোনো ক্যাটাগরি নাম বা তথ্য আপডেট করুন।\n'
        '• অপ্রয়োজনীয় ক্যাটাগরি মুছে ফেলুন।',
      ),
      GuideFeature(
      title: 'Business Card & Sharing',
        icon: Icons.contact_mail_rounded,
      engDesc: 'Create a simple digital business card from your profile and share it when needed. The card can be customized and exported in a few different ways.\n\n'
        '• Add your name, title, company, contact details, and website.\n'
        '• Share the card through QR code, NFC, vCard, or image export.\n'
        '• Save the finished card to your gallery after customizing it.',
      banDesc: 'প্রোফাইল থেকে সহজেই একটি ডিজিটাল বিজনেস কার্ড তৈরি করুন এবং দরকার হলে শেয়ার করুন। কার্ডটি কাস্টমাইজ করে বিভিন্নভাবে এক্সপোর্ট করা যায়।\n\n'
        '• নাম, পদবি, কোম্পানি, ফোন, ইমেইল এবং ওয়েবসাইট যুক্ত করুন।\n'
        '• QR code, NFC, vCard বা image export দিয়ে শেয়ার করুন।\n'
        '• কাস্টমাইজ করার পর কার্ডটি গ্যালারিতে সেভ করুন।',
      ),
      GuideFeature(
        title: 'Profile & Security',
        icon: Icons.security_rounded,
      engDesc: 'Use the Profile screen to manage account settings, security, reports, and app preferences. This is where your personal tools live.\n\n'
        '• Turn on app lock with a PIN or biometrics for extra protection.\n'
        '• Generate PDF statements for your transactions when you need a report.\n'
        '• Change theme, language, notifications, or update your profile details.',
      banDesc: 'Profile স্ক্রিন থেকে account settings, security, reports এবং app preferences ম্যানেজ করুন। এখানে আপনার ব্যক্তিগত টুলগুলো এক জায়গায় পাওয়া যায়।\n\n'
        '• PIN বা biometrics দিয়ে app lock চালু করুন।\n'
        '• প্রয়োজন হলে transactions-এর PDF statement তৈরি করুন।\n'
        '• Theme, language, notifications বা profile details পরিবর্তন করুন।',
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
