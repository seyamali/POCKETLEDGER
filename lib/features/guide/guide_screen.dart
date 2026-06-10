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
      GuideFeature(
        title: 'Add Transactions',
        icon: Icons.add_circle_outline_rounded,
        engDesc: 'In this section, you record your daily financial activities.\n\n'
            '• Add Income/Expense: Tap the central \'+\' button on the dashboard. Choose Income (money you receive) or Expense (money you spend). Enter the amount, select an appropriate category, add a note (optional), pick the date, and select which account to use.\n'
            '• Add Transfer: Use the Transfer tab to record money moved from one of your accounts to another (e.g., from Cash to Bank) without affecting your total wealth.\n'
            '• Edit/Delete: You can tap on any recent transaction from the Dashboard or Stats screen to edit its details or delete it.',
        banDesc: 'এই সেকশনে আপনি আপনার দৈনন্দিন আর্থিক লেনদেন যুক্ত করতে পারবেন।\n\n'
            '• আয়/ব্যয় যুক্ত করা: ড্যাশবোর্ডের মাঝখানের \'+\' বাটনে চাপ দিন। আয় (Income) বা ব্যয় (Expense) বেছে নিন। টাকার পরিমাণ লিখুন, সঠিক ক্যাটাগরি সিলেক্ট করুন, নোট দিন (ঐচ্ছিক), তারিখ ঠিক করুন এবং কোন অ্যাকাউন্ট থেকে লেনদেন হচ্ছে তা বেছে নিন।\n'
            '• ট্রান্সফার: এক অ্যাকাউন্ট থেকে অন্য অ্যাকাউন্টে (যেমন- ক্যাশ থেকে ব্যাংকে) টাকা সরানোর হিসাব রাখতে ট্রান্সফার (Transfer) ট্যাবটি ব্যবহার করুন। এতে আপনার মোট টাকার কোনো পরিবর্তন হয় না।\n'
            '• এডিট/ডিলিট: ড্যাশবোর্ড বা স্ট্যাটস স্ক্রিন থেকে যেকোনো লেনদেনের উপর চাপ দিয়ে আপনি চাইলে তা পরিবর্তন বা মুছে ফেলতে পারবেন।',
      ),
      GuideFeature(
        title: 'Monthly Goals',
        icon: Icons.track_changes_rounded,
        engDesc: 'Set spending limits to help you stay within your budget.\n\n'
            '• Set a Budget: Go to the Goals section and set an overall monthly limit. You can also assign specific limits to different categories (like Food, Transport).\n'
            '• Automatic Tracking: As you add expenses, the app calculates how much of your budget is used.\n'
            '• Smart Alerts: If your spending reaches 80% or exceeds your set budget, a warning will appear on the Dashboard so you can adjust your spending.',
        banDesc: 'বাজেট অনুযায়ী খরচ করতে মাসিক লক্ষ্য নির্ধারণ করুন।\n\n'
            '• বাজেট সেট করা: গোলস (Goals) সেকশনে গিয়ে মাসের জন্য একটি নির্দিষ্ট লিমিট ঠিক করুন। আপনি চাইলে ক্যাটাগরি অনুযায়ী (যেমন- খাবার, যাতায়াত) আলাদা লিমিটও দিতে পারবেন।\n'
            '• অটোমেটিক ট্র্যাকিং: আপনি যখনই কোনো ব্যয়ের হিসাব যুক্ত করবেন, অ্যাপ নিজে থেকেই হিসাব করবে আপনার বাজেটের কত অংশ খরচ হয়েছে।\n'
            '• স্মার্ট অ্যালার্ট: আপনার খরচ বাজেটের ৮০% এ পৌঁছালে বা বাজেট অতিক্রম করলে ড্যাশবোর্ডে একটি সতর্কবার্তা দেখাবে, যাতে আপনি খরচ নিয়ন্ত্রণে আনতে পারেন।',
      ),
      GuideFeature(
        title: 'Recurring Bills',
        icon: Icons.event_repeat_rounded,
        engDesc: 'Track fixed bills that you need to pay regularly so you never miss a payment.\n\n'
            '• Add a Subscription: Go to the Subscriptions screen and add bills like Rent, Netflix, or Internet. Set the amount, cycle (monthly, yearly), and next due date.\n'
            '• Due Date Alerts: The app tracks the days left and warns you on the Dashboard when a bill is due in 5 days or is overdue.\n'
            '• Manual Marking: Once you pay the bill, you can mark it as paid, and it will automatically schedule the next due date based on your cycle.',
        banDesc: 'যেসব বিল আপনাকে নিয়মিত দিতে হয় তার হিসাব রাখুন, যাতে কোনো বিল মিস না হয়।\n\n'
            '• সাবস্ক্রিপশন যুক্ত করা: সাবস্ক্রিপশন স্ক্রিনে গিয়ে বাড়ি ভাড়া, ইন্টারনেট বা নেটফ্লিক্সের মতো বিলগুলো যুক্ত করুন। টাকার পরিমাণ, কতদিন পর পর দিতে হবে (যেমন- মাসিক, বার্ষিক) এবং পরবর্তী তারিখ সেট করুন।\n'
            '• অ্যালার্ট: কোনো বিল দেওয়ার তারিখের ৫ দিন আগে বা তারিখ পার হয়ে গেলে অ্যাপ আপনাকে ড্যাশবোর্ডে মনে করিয়ে দেবে।\n'
            '• বিল পরিশোধ: বিল দেওয়ার পর আপনি সেটিকে \'Paid\' হিসেবে মার্ক করতে পারবেন, তখন অ্যাপ স্বয়ংক্রিয়ভাবে পরের মাসের তারিখ সেট করে নেবে।',
      ),
      GuideFeature(
        title: 'Stats & Analytics',
        icon: Icons.analytics_rounded,
        engDesc: 'Visualize your spending and income trends over time.\n\n'
            '• View Charts: Go to the Stats screen to see graphical representations of your finances.\n'
            '• Category Breakdown: See exactly what percentage of your money goes into which category (e.g., 40% on Food, 20% on Transport).\n'
            '• Filter by Date: You can filter transactions by current month, past months, or custom date ranges to compare your financial health over time.',
        banDesc: 'আপনার আয় ও ব্যয়ের ধরন চার্টের মাধ্যমে ভিজ্যুয়ালি দেখুন।\n\n'
            '• চার্ট দেখা: স্ট্যাটস স্ক্রিনে গিয়ে আপনার লেনদেনের গ্রাফিকাল চার্ট দেখতে পাবেন।\n'
            '• ক্যাটাগরি ব্রেকডাউন: আপনার টাকার কত শতাংশ কোন খাতে খরচ হচ্ছে (যেমন- খাবারে ৪০%, যাতায়াতে ২০%) তা সহজেই বুঝতে পারবেন।\n'
            '• ফিল্টার: নির্দিষ্ট মাস বা তারিখ অনুযায়ী ফিল্টার করে আপনি আপনার আগের ও বর্তমান সময়ের খরচের তুলনা করতে পারবেন।',
      ),
      GuideFeature(
        title: 'Savings',
        icon: Icons.savings_rounded,
        engDesc: 'Set apart money for your future goals and track your savings progress.\n\n'
            '• Create a Savings Goal: Navigate to the Savings screen and define what you are saving for (e.g., New Laptop, Emergency Fund), the target amount, and the deadline.\n'
            '• Deposit/Withdraw: You can transfer money from your main accounts to your Savings Vault to increase your progress.\n'
            '• Visual Progress: See a progress bar filling up as you get closer to your target amount.',
        banDesc: 'ভবিষ্যতের লক্ষ্যের জন্য টাকা জমানো এবং জমানো টাকার হিসাব রাখা।\n\n'
            '• সেভিংস গোল তৈরি করা: সেভিংস স্ক্রিনে গিয়ে আপনি কিসের জন্য টাকা জমাচ্ছেন (যেমন- ল্যাপটপ, ইমার্জেন্সি ফান্ড), তার লক্ষ্যমাত্রা এবং সময়সীমা সেট করুন।\n'
            '• জমা/উত্তোলন: আপনার মূল অ্যাকাউন্ট থেকে টাকা সেভিংস ভল্টে স্থানান্তর করতে পারবেন, যা আপনার সঞ্চয়ের অগ্রগতি বাড়াবে।\n'
            '• প্রোগ্রেস দেখা: লক্ষ্যমাত্রার কাছাকাছি পৌঁছানোর সাথে সাথে প্রোগ্রেস বার পূর্ণ হতে দেখবেন।',
      ),
      GuideFeature(
        title: 'Loans & Debts',
        icon: Icons.handshake_rounded,
        engDesc: 'Keep track of money you have borrowed or lent to others.\n\n'
            '• Borrowed / Lent: Add a record when you borrow money from someone or lend money to a friend. Specify the person\'s name, amount, and due date.\n'
            '• Repayments: When you pay back a portion or receive money back, add a repayment transaction. The app updates the remaining due amount automatically.\n'
            '• Settle Up: Once the full amount is returned, the loan is marked as settled.',
        banDesc: 'ধার নেওয়া বা ধার দেওয়া টাকার হিসাব রাখুন।\n\n'
            '• ধার নেওয়া / ধার দেওয়া: কারো কাছ থেকে টাকা ধার নিলে বা কাউকে ধার দিলে তার রেকর্ড যুক্ত করুন। ব্যক্তির নাম, টাকার পরিমাণ এবং পরিশোধের তারিখ উল্লেখ করুন।\n'
            '• কিস্তি পরিশোধ: আপনি যখন কিছু টাকা ফেরত দেবেন বা পাবেন, তখন রিপেমেন্ট যুক্ত করুন। অ্যাপ স্বয়ংক্রিয়ভাবে বাকি টাকার হিসাব আপডেট করবে।\n'
            '• সেটেল আপ: সম্পূর্ণ টাকা পরিশোধ হয়ে গেলে লোনটি সেটেলড (Settled) হিসেবে মার্ক হয়ে যাবে।',
      ),
      GuideFeature(
        title: 'Credit Cards',
        icon: Icons.credit_card_rounded,
        engDesc: 'Manage your credit card usages, statements, and outstanding balances.\n\n'
            '• Add a Credit Card: Go to the Credit Cards section and enter your card details including the limit, billing cycle, and current outstanding amount.\n'
            '• Record Spends: Log your credit card expenses directly. The app will increase your outstanding balance and decrease your available limit.\n'
            '• Bill Payments: Record when you pay your credit card bill to reduce the outstanding balance.',
        banDesc: 'ক্রেডিট কার্ডের ব্যবহার, স্টেটমেন্ট এবং বকেয়া ব্যালেন্স পরিচালনা করুন।\n\n'
            '• ক্রেডিট কার্ড যুক্ত করা: ক্রেডিট কার্ড সেকশনে গিয়ে কার্ডের লিমিট, বিলিং সাইকেল এবং বর্তমান বকেয়ার পরিমাণ উল্লেখ করে কার্ড যুক্ত করুন।\n'
            '• খরচ লিপিবদ্ধ করা: ক্রেডিট কার্ডের খরচগুলো সরাসরি যুক্ত করুন। এতে আপনার বকেয়া ব্যালেন্স বাড়বে এবং লিমিট কমে যাবে।\n'
            '• বিল পেমেন্ট: ক্রেডিট কার্ডের বিল পরিশোধ করার পর তা রেকর্ড করলে আপনার বকেয়া ব্যালেন্স স্বয়ংক্রিয়ভাবে কমে যাবে।',
      ),
      GuideFeature(
        title: 'Custom Categories',
        icon: Icons.category_rounded,
        engDesc: 'Personalize the way you classify your income and expenses.\n\n'
            '• Add New Categories: If the default categories don\'t fit your needs, you can create new custom ones (e.g., Pet Care, Gym) and assign icons to them.\n'
            '• Edit/Delete: You can rename existing categories or remove ones you never use.',
        banDesc: 'আপনার আয় ও ব্যয় শ্রেণীবদ্ধ করার পদ্ধতি কাস্টমাইজ করুন।\n\n'
            '• নতুন ক্যাটাগরি তৈরি: যদি ডিফল্ট ক্যাটাগরিগুলো আপনার জন্য যথেষ্ট না হয়, তবে আপনি নিজের মতো নতুন ক্যাটাগরি (যেমন- জিম, পোষা প্রাণী) তৈরি করে আইকন দিতে পারবেন।\n'
            '• এডিট/ডিলিট: চাইলে বর্তমান ক্যাটাগরিগুলোর নাম পরিবর্তন বা অপ্রয়োজনীয় ক্যাটাগরি মুছে ফেলতে পারবেন।',
      ),
      GuideFeature(
        title: 'Digital Business Card',
        icon: Icons.contact_mail_rounded,
        engDesc: 'Create and share your digital identity seamlessly.\n\n'
            '• Setup Your Card: Add your professional details like name, job title, company, phone, email, and website. You can also customize the card design by choosing different color themes.\n'
            '• Easy Sharing: Share your card instantly via QR Code, write it to an NFC tag, or share it as a standard vCard/Image to others.\n'
            '• Save to Gallery: Export your customized business card directly to your phone\'s gallery.',
        banDesc: 'খুব সহজেই আপনার ডিজিটাল পরিচয় তৈরি এবং শেয়ার করুন।\n\n'
            '• কার্ড সেটআপ: আপনার পেশাদার তথ্য যেমন- নাম, পদবি, কোম্পানি, ফোন, ইমেইল এবং ওয়েবসাইট যুক্ত করুন। এছাড়া আপনি বিভিন্ন কালার থিম বেছে নিয়ে কার্ডের ডিজাইন কাস্টমাইজ করতে পারবেন।\n'
            '• সহজে শেয়ার: কিউআর কোড, এনএফসি ট্যাগ অথবা ভিকার্ড/ছবি হিসেবে আপনার কার্ড অন্যদের সাথে শেয়ার করতে পারবেন।\n'
            '• গ্যালারিতে সেভ করুন: আপনার কাস্টমাইজ করা বিজনেস কার্ডটি সরাসরি আপনার ফোনের গ্যালারিতে সংরক্ষণ করুন।',
      ),
      GuideFeature(
        title: 'Profile & Security',
        icon: Icons.security_rounded,
        engDesc: 'Keep your financial data secure and generate reports.\n\n'
            '• App Lock: Enable a 4-digit PIN lock or use Biometrics (Fingerprint/Face ID) to secure your app from unauthorized access.\n'
            '• PDF Statements: Generate and export a complete summary of your transactions as a printable PDF report directly from the Profile section.\n'
            '• Customization: Switch between Light and Dark mode, change language (English/Bangla), and manage notifications.',
        banDesc: 'আপনার আর্থিক তথ্য সুরক্ষিত রাখুন এবং রিপোর্ট তৈরি করুন।\n\n'
            '• অ্যাপ লক: আপনার অ্যাপকে সুরক্ষিত রাখতে ৪-ডিজিটের পিন লক চালু করুন বা বায়োমেট্রিক (ফিঙ্গারপ্রিন্ট/ফেস আইডি) ব্যবহার করুন।\n'
            '• পিডিএফ স্টেটমেন্ট: প্রোফাইল সেকশন থেকে আপনার লেনদেনের সম্পূর্ণ হিসাব প্রিন্ট করার উপযোগী পিডিএফ (PDF) রিপোর্ট হিসেবে তৈরি করুন।\n'
            '• কাস্টমাইজেশন: লাইট এবং ডার্ক মোডের মধ্যে পরিবর্তন করুন, ভাষা (ইংরেজি/বাংলা) পরিবর্তন করুন এবং নোটিফিকেশন নিয়ন্ত্রণ করুন।',
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
