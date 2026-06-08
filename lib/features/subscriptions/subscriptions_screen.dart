import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/account_model.dart';
import 'package:pocketledger/models/recurring_bill_model.dart';
import 'package:pocketledger/services/account_service.dart';
import 'package:pocketledger/services/recurring_bill_service.dart';

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
              top: 15, left: 24, right: 24,
            ),
            decoration: BoxDecoration(
              color: Color(0xFFF4F6F5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modal drag handle & close
                  Column(
                    children: [
                      Container(
                        width: 45, height: 5,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                      ),
                      const SizedBox(height: 15),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Text('New Subscription', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Container(
                                padding: const EdgeInsets.all(4),
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
                  
                  _buildModalInput('Subscription Name (e.g. Netflix, Rent)', titleCtrl, Icons.edit_note_rounded, AppColors.primaryGreen, isNumeric: false),
                  const SizedBox(height: 16),
                  _buildModalInput('Amount / Fee', amountCtrl, Icons.payments_outlined, AppColors.primaryGreen, isNumeric: true),
                  const SizedBox(height: 16),
                  
                  // Category selector
                  Text('Category', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textGrey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat, style: GoogleFonts.outfit(color: isSelected ? Colors.white : AppColors.textBlack, fontWeight: FontWeight.bold, fontSize: 13)),
                        selected: isSelected,
                        selectedColor: AppColors.primaryGreen,
                        backgroundColor: AppColors.cardWhite,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade200)),
                        onSelected: (val) {
                          if (val) setModalState(() => selectedCategory = cat);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Frequency Selector
                  Text('Frequency', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textGrey)),
                  const SizedBox(height: 8),
                  Row(
                    children: frequencies.map((freq) {
                      final isSelected = selectedFrequency == freq;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => selectedFrequency = freq),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryGreen : AppColors.cardWhite,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
                            ),
                            alignment: Alignment.center,
                            child: Text(freq, style: GoogleFonts.outfit(color: isSelected ? Colors.white : AppColors.textBlack, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Next Due Date DatePicker
                  Text('Next Due Date', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textGrey)),
                  const SizedBox(height: 8),
                  GestureDetector(
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
                              Icon(Icons.calendar_today_rounded, color: AppColors.primaryGreen, size: 20),
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

                  // Linked Account
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
                        items: accounts.map((acc) => DropdownMenuItem(value: acc, child: Text(acc.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)))).toList(),
                        onChanged: (val) => setModalState(() => linkedAccount = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  Container(
                    width: double.infinity, height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.primaryGreen, AppColors.primaryGreen.withOpacity(0.8)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: AppColors.primaryGreen.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () async {
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
                        
                        await _billService.createRecurringBill(bill);
                        if (mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text('Create Subscription', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
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
    return StreamBuilder<List<AccountModel>>(
      stream: _accountService.getAccounts(),
      builder: (context, accSnapshot) {
        final accounts = accSnapshot.data ?? [];
        return StreamBuilder<List<RecurringBillModel>>(
          stream: _billService.getRecurringBills(),
          builder: (context, billSnapshot) {
            if (billSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: AppColors.surfaceLight,
                body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
              );
            }

            final bills = billSnapshot.data ?? [];
            final monthlyDues = bills.fold(0.0, (sum, bill) {
              if (bill.frequency == 'Monthly') return sum + bill.amount;
              if (bill.frequency == 'Weekly') return sum + (bill.amount * 4); // rough estimate
              return sum + (bill.amount / 12); // yearly division
            });

            return Scaffold(
              backgroundColor: AppColors.surfaceLight,
              appBar: AppBar(
                backgroundColor: AppColors.cardWhite,
                elevation: 0,
                title: Text('Subscriptions & Bills', style: GoogleFonts.outfit(color: AppColors.textBlack, fontWeight: FontWeight.bold, fontSize: 18)),
                centerTitle: true,
                leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textBlack, size: 18), onPressed: () => Navigator.pop(context)),
              ),
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
                child: Column(
                  children: [
                    _buildTotalDuesCard(monthlyDues),
                    const SizedBox(height: 32),
                    Align(alignment: Alignment.centerLeft, child: Text('ACTIVE TIMELINES', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5))),
                    const SizedBox(height: 16),
                    if (bills.isEmpty) _buildEmptyState() else ...bills.map((bill) => _buildSubscriptionCard(bill)),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => _showAddSubscriptionModal(accounts),
                backgroundColor: AppColors.primaryGreen,
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildTotalDuesCard(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen, Color(0xFF2D6A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: AppColors.primaryGreen.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Estimated Dues', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(Icons.calendar_month_rounded, color: AppColors.accentGold, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('৳${total.toInt()}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('All scheduled subscriptions and recurring logs combined', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(RecurringBillModel bill) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(bill.nextDueDate.year, bill.nextDueDate.month, bill.nextDueDate.day);
    final daysLeft = due.difference(today).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.08), shape: BoxShape.circle),
                child: Icon(
                  bill.category == 'Home'
                      ? Icons.home_rounded
                      : bill.category == 'Food'
                          ? Icons.restaurant_rounded
                          : bill.category == 'Wife'
                              ? Icons.favorite_rounded
                              : bill.category == 'Myself'
                                  ? Icons.person_rounded
                                  : Icons.wallet_giftcard_rounded,
                  color: AppColors.primaryGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bill.title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textBlack)),
                    Text(
                      bill.linkedAccountId != null 
                          ? '${bill.frequency} • Deducts ${bill.linkedAccountName}'
                          : '${bill.frequency} • Manual logging', 
                      style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('৳${bill.amount.toInt()}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryGreen)),
                  const SizedBox(height: 4),
                  _buildDaysLeftChip(daysLeft),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade100, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Due: ${DateFormat('MMM dd, yyyy').format(bill.nextDueDate)}', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _showDeleteConfirmation(bill.id),
                    icon: Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      await _billService.payBill(bill);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.success,
                            content: Text('${bill.title} paid and logged!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text('Pay & Log', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaysLeftChip(int daysLeft) {
    Color color = AppColors.success;
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
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: GoogleFonts.outfit(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Subscription?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this recurring bill? Historical payments logged will not be deleted.', style: GoogleFonts.outfit(color: AppColors.textGrey)),
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
            decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(Icons.receipt_long_rounded, color: AppColors.primaryGreen, size: 50),
          ),
          const SizedBox(height: 20),
          Text('No Subscriptions Yet', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
          const SizedBox(height: 8),
          Text('Add your recurring bills, subscriptions, or utility payments and never miss a due date again.', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 12)),
        ],
      ),
    );
  }
}
