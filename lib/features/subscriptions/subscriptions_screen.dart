import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/account_model.dart';
import 'package:pocketledger/models/recurring_bill_model.dart';
import 'package:pocketledger/services/account_service.dart';
import 'package:pocketledger/services/recurring_bill_service.dart';
import 'package:pocketledger/core/widgets/scale_on_tap.dart';
import 'package:pocketledger/core/widgets/glass_card.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final RecurringBillService _billService = RecurringBillService();
  final AccountService _accountService = AccountService();

  void _showAddSubscriptionModal(List<AccountModel> accounts) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    String selectedCategory = 'Other';
    String selectedFrequency = 'Monthly';
    DateTime selectedDate = DateTime.now();
    AccountModel? linkedAccount;

    final categories = ['Home', 'Food', 'Wife', 'Myself', 'Other'];
    final frequencies = ['Weekly', 'Monthly', 'Yearly'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          bool isLoading = false;
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 30,
              top: 15,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFF4F6F5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                      ),
                      const SizedBox(height: 15),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            'New Subscription',
                            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textBlack),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ScaleOnTap(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                                child: Icon(Icons.close_rounded, color: AppColors.textGrey, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildModalInput('Subscription Name (e.g. Netflix, Rent)', titleCtrl, Icons.edit_note_rounded, AppColors.brandPrimary, isNumeric: false),
                  const SizedBox(height: 16),
                  _buildModalInput('Amount / Fee', amountCtrl, Icons.payments_outlined, AppColors.brandPrimary, isNumeric: true),
                  const SizedBox(height: 16),

                  Text('Category', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textGrey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return ScaleOnTap(
                        onTap: () => setModalState(() => selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.brandPrimary : AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
                            boxShadow: isSelected
                                ? [BoxShadow(color: AppColors.brandPrimary.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 3))]
                                : [],
                          ),
                          child: Text(
                            cat,
                            style: GoogleFonts.outfit(
                              color: isSelected ? Colors.white : AppColors.textBlack,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  Text('Frequency', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textGrey)),
                  const SizedBox(height: 8),
                  Row(
                    children: frequencies.map((freq) {
                      final isSelected = selectedFrequency == freq;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ScaleOnTap(
                            onTap: () => setModalState(() => selectedFrequency = freq),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.brandPrimary : AppColors.cardWhite,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: AppColors.brandPrimary.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 3))]
                                    : [],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                freq,
                                style: GoogleFonts.outfit(
                                  color: isSelected ? Colors.white : AppColors.textBlack,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  Text('Next Due Date', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textGrey)),
                  const SizedBox(height: 8),
                  ScaleOnTap(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, color: AppColors.brandPrimary, size: 20),
                              const SizedBox(width: 12),
                              Text(DateFormat('MMM dd, yyyy').format(selectedDate), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Icon(Icons.arrow_drop_down_rounded, color: AppColors.textGrey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text('Deduct From Account', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textGrey)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(20)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<AccountModel>(
                        value: linkedAccount,
                        isExpanded: true,
                        hint: Text('Select Account (Optional)', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13)),
                        items: accounts
                            .map((acc) => DropdownMenuItem(
                                  value: acc,
                                  child: Text(acc.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                                ))
                            .toList(),
                        onChanged: (val) => setModalState(() => linkedAccount = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  ScaleOnTap(
                    onTap: isLoading
                        ? () {}
                        : () {
                            if (titleCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;
                            setModalState(() => isLoading = true);

                            final bill = RecurringBillModel(
                              id: '',
                              title: titleCtrl.text.trim(),
                              amount: double.parse(amountCtrl.text),
                              category: selectedCategory,
                              frequency: selectedFrequency,
                              nextDueDate: selectedDate,
                              linkedAccountId: linkedAccount?.id,
                              linkedAccountName: linkedAccount?.name,
                              userId: '',
                            );

                            _billService.createRecurringBill(bill).then((_) {
                              if (mounted) Navigator.pop(context);
                            });
                          },
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.brandPrimary, AppColors.brandPrimary.withValues(alpha: 0.8)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brandPrimary.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      alignment: Alignment.center,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Create Subscription',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModalInput(String label, TextEditingController ctrl, IconData icon, Color color, {bool isNumeric = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(20)),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 12),
          prefixIcon: Icon(icon, color: color, size: 20),
          border: InputBorder.none,
          suffixText: isNumeric ? '৳' : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<AccountModel>>(
        stream: _accountService.getAccounts(),
        builder: (context, accSnapshot) {
          final accounts = accSnapshot.data ?? [];
          return StreamBuilder<List<RecurringBillModel>>(
              stream: _billService.getRecurringBills(),
              builder: (context, billSnapshot) {
                if (billSnapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    backgroundColor: AppColors.primaryBackground,
                    body: Center(child: CircularProgressIndicator(color: AppColors.brandPrimary)),
                  );
                }

                final bills = billSnapshot.data ?? [];
                final monthlyDues = bills.fold(0.0, (sum, bill) {
                  if (bill.frequency == 'Monthly') return sum + bill.amount;
                  if (bill.frequency == 'Weekly') return sum + (bill.amount * 4);
                  return sum + (bill.amount / 12);
                });

                return ThemeBuilder(builder: (context) => Scaffold(
                  backgroundColor: AppColors.primaryBackground,
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: Text(
                      'Subscriptions & Bills',
                      style: GoogleFonts.outfit(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    centerTitle: true,
                    leading: ScaleOnTap(
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryText, size: 18),
                      ),
                    ),
                  ),
                  body: Stack(
                    children: [
                      // Ambient background glow circles
                      Positioned(
                        top: -20,
                        right: -40,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.brandPrimary.withValues(alpha: isDark ? 0.08 : 0.05),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 100,
                        left: -60,
                        child: Container(
                          width: 240,
                          height: 240,
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
                        padding: const EdgeInsets.fromLTRB(24, 10, 24, 80),
                        child: Column(
                          children: [
                            _buildTotalDuesCard(monthlyDues, isDark),
                            const SizedBox(height: 32),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'ACTIVE TIMELINES',
                                style: GoogleFonts.outfit(
                                  color: AppColors.textGrey,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (bills.isEmpty)
                              _buildEmptyState()
                            else
                              ...bills.map((bill) => _buildSubscriptionCard(bill, isDark)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  floatingActionButton: ScaleOnTap(
                    onTap: () => _showAddSubscriptionModal(accounts),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brandPrimary,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brandPrimary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                )); // closes Scaffold + ThemeBuilder
              });
        });
  }

  Widget _buildTotalDuesCard(double total, bool isDark) {
    return GlassCard(
      blur: 20,
      opacity: isDark ? 0.06 : 0.45,
      color: isDark ? const Color(0xFF16201D) : Colors.white,
      borderRadius: 30,
      border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.15)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Estimated Dues',
                  style: GoogleFonts.outfit(
                    color: AppColors.textGrey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.calendar_month_rounded, color: AppColors.brandPrimary, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '৳${total.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => "${m[1]},")}',
              style: GoogleFonts.outfit(
                color: AppColors.textBlack,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'All scheduled subscriptions and recurring logs combined',
              style: GoogleFonts.outfit(
                color: AppColors.textGrey,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BrandConfig _getBrandConfig(String title, String category) {
    final name = title.toLowerCase();
    if (name.contains('netflix')) {
      return BrandConfig(const Color(0xFFE50914), Icons.movie_outlined);
    }
    if (name.contains('spotify')) {
      return BrandConfig(const Color(0xFF1DB954), Icons.music_note_outlined);
    }
    if (name.contains('youtube')) {
      return BrandConfig(const Color(0xFFFF0000), Icons.play_circle_outline_rounded);
    }
    if (name.contains('icloud') || name.contains('apple') || name.contains('app store')) {
      return BrandConfig(const Color(0xFF000000), Icons.cloud_queue_rounded);
    }
    if (name.contains('google') || name.contains('drive') || name.contains('one')) {
      return BrandConfig(const Color(0xFF4285F4), Icons.cloud_outlined);
    }
    if (name.contains('chatgpt') || name.contains('openai') || name.contains('gpt')) {
      return BrandConfig(const Color(0xFF10A37F), Icons.psychology_outlined);
    }
    if (name.contains('amazon') || name.contains('prime')) {
      return BrandConfig(const Color(0xFFFF9900), Icons.shopping_bag_outlined);
    }
    if (name.contains('gym') || name.contains('fitness') || name.contains('workout')) {
      return BrandConfig(const Color(0xFFFF5722), Icons.fitness_center_rounded);
    }
    if (name.contains('electricity') || name.contains('power') || name.contains('desco')) {
      return BrandConfig(const Color(0xFFFFC107), Icons.electric_bolt_rounded);
    }
    if (name.contains('water') || name.contains('wasa')) {
      return BrandConfig(const Color(0xFF2196F3), Icons.water_drop_rounded);
    }
    if (name.contains('internet') || name.contains('wifi') || name.contains('broadband')) {
      return BrandConfig(const Color(0xFF9C27B0), Icons.wifi_rounded);
    }

    IconData fallbackIcon = Icons.wallet_giftcard_rounded;
    if (category == 'Home') {
      fallbackIcon = Icons.home_rounded;
    } else if (category == 'Food') {
      fallbackIcon = Icons.restaurant_rounded;
    } else if (category == 'Wife') {
      fallbackIcon = Icons.favorite_rounded;
    } else if (category == 'Myself') {
      fallbackIcon = Icons.person_rounded;
    }

    return BrandConfig(AppColors.brandPrimary, fallbackIcon);
  }

  Widget _buildSubscriptionCard(RecurringBillModel bill, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(bill.nextDueDate.year, bill.nextDueDate.month, bill.nextDueDate.day);
    final daysLeft = due.difference(today).inDays;

    final brand = _getBrandConfig(bill.title, bill.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        blur: 15,
        opacity: isDark ? 0.04 : 0.45,
        color: isDark ? const Color(0xFF16201D) : Colors.white,
        borderRadius: 25,
        border: Border.all(color: brand.color.withValues(alpha: 0.15)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: brand.color.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(brand.icon, color: brand.color, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill.title,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textBlack),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bill.linkedAccountId != null
                              ? '${bill.frequency} • Deducts ${bill.linkedAccountName}'
                              : '${bill.frequency} • Manual logging',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '৳${bill.amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => "${m[1]},")}',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: brand.color),
                      ),
                      const SizedBox(height: 4),
                      _buildDaysLeftChip(daysLeft),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: AppColors.brandPrimary.withValues(alpha: 0.08), height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Due: ${DateFormat('MMM dd, yyyy').format(bill.nextDueDate)}',
                    style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.textGrey, fontWeight: FontWeight.w500),
                  ),
                  Row(
                    children: [
                      ScaleOnTap(
                        onTap: () => _showDeleteConfirmation(bill.id),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.error.withValues(alpha: 0.08),
                          ),
                          child: Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ScaleOnTap(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          await _billService.payBill(bill);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.brandPrimary,
                                content: Text('${bill.title} paid and logged!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [brand.color, brand.color.withValues(alpha: 0.85)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: brand.color.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Text(
                            'Pay & Log',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
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
      ),
    );
  }

  Widget _buildDaysLeftChip(int daysLeft) {
    Color color = AppColors.brandPrimary;
    String label = '$daysLeft days left';

    if (daysLeft < 0) {
      color = AppColors.error;
      label = '${-daysLeft}d overdue';
    } else if (daysLeft == 0) {
      color = Colors.orangeAccent.shade700;
      label = 'Due today';
    } else if (daysLeft == 1) {
      color = Colors.amber.shade700;
      label = 'Due tomorrow';
    } else if (daysLeft <= 5) {
      color = Colors.amber;
      label = '$daysLeft days left';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: GoogleFonts.outfit(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Subscription?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete this recurring bill? Historical payments logged will not be deleted.',
          style: GoogleFonts.outfit(color: AppColors.textGrey),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textGrey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _billService.deleteRecurringBill(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.brandPrimary.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: Icon(Icons.receipt_long_rounded, color: AppColors.brandPrimary, size: 50),
          ),
          const SizedBox(height: 20),
          Text(
            'No Subscriptions Yet',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textBlack),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your recurring bills, subscriptions, or utility payments and never miss a due date again.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class BrandConfig {
  final Color color;
  final IconData icon;
  BrandConfig(this.color, this.icon);
}
