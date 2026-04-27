import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/goal_model.dart';
import 'package:pocketledger/models/transaction_model.dart';
import 'package:pocketledger/services/goal_service.dart';
import 'package:pocketledger/features/auth/widgets/custom_text_field.dart';
import 'package:pocketledger/models/account_model.dart';
import 'package:pocketledger/services/account_service.dart';
import 'package:pocketledger/services/transaction_service.dart';

class MonthlyGoalScreen extends StatefulWidget {
  const MonthlyGoalScreen({super.key});

  @override
  State<MonthlyGoalScreen> createState() => _MonthlyGoalScreenState();
}

class _MonthlyGoalScreenState extends State<MonthlyGoalScreen> {
  final GoalService _goalService = GoalService();
  final AccountService _accountService = AccountService();
  final TransactionService _transactionService = TransactionService();
  
  DateTime _currentMonth = DateTime.now();

  String get _monthYearKey => "${_currentMonth.month.toString().padLeft(2, '0')}-${_currentMonth.year}";
  String get _monthName => _getMonthName(_currentMonth.month);

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset);
    });
  }

  void _showSetGoalModal(GoalModel? currentGoal) {
    final incomeCtrl = TextEditingController(text: currentGoal?.incomeTarget.toInt().toString() ?? '');
    final expenseCtrl = TextEditingController(text: currentGoal?.expenseLimit.toInt().toString() ?? '');
    final savingsCtrl = TextEditingController(text: currentGoal?.savingsTarget.toInt().toString() ?? '');
    
    final categoryCtrls = {
      'Home': TextEditingController(text: currentGoal?.categoryLimits['Home']?.toInt().toString() ?? ''),
      'Food': TextEditingController(text: currentGoal?.categoryLimits['Food']?.toInt().toString() ?? ''),
      'Wife': TextEditingController(text: currentGoal?.categoryLimits['Wife']?.toInt().toString() ?? ''),
      'Myself': TextEditingController(text: currentGoal?.categoryLimits['Myself']?.toInt().toString() ?? ''),
      'Other': TextEditingController(text: currentGoal?.categoryLimits['Other']?.toInt().toString() ?? ''),
    };

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
            decoration: const BoxDecoration(
              color: Color(0xFFF4F6F5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Modal Header with Close Button
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: AppColors.textGrey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Target Settings', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Set your targets for $_monthName ${_currentMonth.year}', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13)),
                  const SizedBox(height: 32),
                  
                  _buildModalInput('Monthly Income Target', incomeCtrl, Icons.payments_rounded, AppColors.primaryGreen),
                  const SizedBox(height: 16),
                  _buildModalInput('Monthly Savings Target', savingsCtrl, Icons.savings_rounded, Colors.amber.shade600),
                  const SizedBox(height: 16),
                  _buildModalInput('Overall Expense Limit', expenseCtrl, Icons.money_off_rounded, Colors.redAccent),
                  
                  const SizedBox(height: 32),
                  Align(alignment: Alignment.centerLeft, child: Text('CATEGORY LIMITS', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5))),
                  const SizedBox(height: 16),
                  
                  ...categoryCtrls.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildModalInput('${entry.key} Limit', entry.value, Icons.pie_chart_rounded, Colors.orangeAccent, isSmall: true),
                  )).toList(),
                  
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.primaryGreen, AppColors.primaryGreen.withOpacity(0.8)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: AppColors.primaryGreen.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        if (incomeCtrl.text.isEmpty) return;
                        setModalState(() => isLoading = true);

                        Map<String, double> categoryLimits = {};
                        for (var entry in categoryCtrls.entries) {
                          categoryLimits[entry.key] = double.tryParse(entry.value.text) ?? 0;
                        }
                        
                        await _goalService.setGoal(
                          monthYear: _monthYearKey,
                          incomeTarget: double.tryParse(incomeCtrl.text) ?? 0,
                          expenseLimit: double.tryParse(expenseCtrl.text) ?? 0,
                          savingsTarget: double.tryParse(savingsCtrl.text) ?? 0,
                          categoryLimits: categoryLimits,
                        );
                        
                        if (mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text('Update Targets', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
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

  Widget _buildModalInput(String label, TextEditingController ctrl, IconData icon, Color color, {bool isSmall = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: GoogleFonts.outfit(fontSize: isSmall ? 15 : 18, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: color, size: 20),
          border: InputBorder.none,
          suffixText: '৳',
          suffixStyle: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: StreamBuilder<List<TransactionModel>>(
        stream: _goalService.getTransactionsForMonth(_currentMonth.month, _currentMonth.year),
        builder: (context, txSnapshot) {
          return StreamBuilder<GoalModel?>(
            stream: _goalService.getGoal(_monthYearKey),
            builder: (context, goalSnapshot) {
              if (txSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
              }

              final transactions = txSnapshot.data ?? [];
              final goal = goalSnapshot.data;

              double actualIncome = 0;
              double actualExpense = 0;
              double actualSaved = 0;
              Map<String, double> expenseByCategory = {};

              for (var tx in transactions) {
                if (tx.category == 'Opening Balance') continue;

                // Detect if this is a savings-related transaction
                bool isSavings = tx.category.toLowerCase().contains('sav') || 
                                 tx.toAccountName?.toLowerCase().contains('sav') == true;

                if (isSavings) {
                  actualSaved += tx.amount;
                } else {
                  if (tx.type == TransactionType.income) actualIncome += tx.amount;
                  if (tx.type == TransactionType.expense) {
                    actualExpense += tx.amount;
                    expenseByCategory[tx.category] = (expenseByCategory[tx.category] ?? 0) + tx.amount;
                  }
                }
              }

              final passiveRemaining = actualIncome - actualExpense - actualSaved;

              return Column(
                children: [
                  _buildPremiumHeader(goal, actualIncome, actualExpense, actualSaved),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Financial Health', 'Live status for this month'),
                          const SizedBox(height: 16),
                          _buildHealthMeter(goal, actualExpense, actualIncome),
                          
                          const SizedBox(height: 32),
                          _buildSectionHeader('Category Targets', 'Limits vs Actual spending'),
                          const SizedBox(height: 16),
                          _buildCategoryTargetGrid(goal, expenseByCategory),

                          const SizedBox(height: 32),
                          _buildSectionHeader('Month Summary', 'Key figures at a glance'),
                          const SizedBox(height: 16),
                          _buildSummaryStats(actualIncome, actualExpense, actualSaved, passiveRemaining),
                          
                          const SizedBox(height: 32),
                          _buildSectionHeader('Recent Activity', 'Top movements this month'),
                          const SizedBox(height: 16),
                          _buildRecentActivity(transactions),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSetGoalModal(null),
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.track_changes_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildPremiumHeader(GoalModel? goal, double income, double expense, double saved) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 5, 24, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              Text('Monthly Analytics', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => _showSetGoalModal(goal),
                icon: const Icon(Icons.tune_rounded, size: 20, color: AppColors.primaryGreen),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildHorizontalMonthSelector(),
          const SizedBox(height: 20),
          _buildMainCircleStats(goal, income, expense, saved),
        ],
      ),
    );
  }

  Widget _buildHorizontalMonthSelector() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 12,
        itemBuilder: (context, index) {
          final monthDate = DateTime(_currentMonth.year, index + 1);
          final isSelected = monthDate.month == _currentMonth.month;
          return GestureDetector(
            onTap: () => setState(() => _currentMonth = monthDate),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryGreen : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(15),
              ),
              alignment: Alignment.center,
              child: Text(_getMonthName(index + 1), 
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.white : AppColors.textGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainCircleStats(GoalModel? goal, double income, double expense, double saved) {
    double progressIncome = goal != null && goal.incomeTarget > 0 ? (income / goal.incomeTarget) : 0;
    double progressExpense = goal != null && goal.expenseLimit > 0 ? (expense / goal.expenseLimit) : 0;
    double savingsRatio = goal != null && goal.savingsTarget > 0 
        ? (saved / goal.savingsTarget) 
        : (income > 0 ? (saved / income) : 0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _circleIndicator('Income', income, progressIncome.clamp(0, 1), AppColors.primaryGreen),
        _circleIndicator('Savings', saved, savingsRatio.clamp(0, 1), Colors.amber.shade600),
        _circleIndicator('Spent', expense, progressExpense.clamp(0, 1), Colors.redAccent),
      ],
    );
  }

  Widget _circleIndicator(String label, double value, double progress, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 55, height: 55,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeCap: StrokeCap.round,
              ),
            ),
            Text('${(progress * 100).toInt()}%', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
        Text('৳${value.toInt()}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
      ],
    );
  }

  Widget _buildHealthMeter(GoalModel? goal, double expense, double income) {
    if (goal == null) return _buildNoGoalPrompt();
    
    double ratio = expense / goal.expenseLimit;
    String status = 'Excellent';
    Color color = AppColors.primaryGreen;

    if (ratio > 1.0) { status = 'Critical'; color = Colors.redAccent; }
    else if (ratio > 0.8) { status = 'Warning'; color = Colors.orangeAccent; }
    else if (ratio > 0.5) { status = 'Good'; color = Colors.blueAccent; }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 15)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Budget Health', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(status, style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio.clamp(0, 1),
              minHeight: 10,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 12),
          Text('You have utilized ${(ratio * 100).toInt()}% of your budget.', 
            style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCategoryTargetGrid(GoalModel? goal, Map<String, double> actuals) {
    if (goal == null || goal.categoryLimits.isEmpty) return const SizedBox();
    
    final limits = goal.categoryLimits.entries.where((e) => e.value > 0).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
      ),
      itemCount: limits.length,
      itemBuilder: (context, i) {
        final entry = limits[i];
        final actual = actuals[entry.key] ?? 0;
        final progress = (actual / entry.value).clamp(0.0, 1.0);
        final isOver = actual > entry.value;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isOver ? Colors.redAccent.withOpacity(0.1) : Colors.transparent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(entry.key, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textBlack), overflow: TextOverflow.ellipsis),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('৳${actual.toInt()} / ৳${entry.value.toInt()}', style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textGrey)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 3,
                      backgroundColor: Colors.grey.shade50,
                      valueColor: AlwaysStoppedAnimation<Color>(isOver ? Colors.redAccent : AppColors.primaryGreen),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryStats(double income, double expense, double saved, double remaining) {
    return Row(
      children: [
        _statTile('Net Saved', saved, Colors.amber.shade600, Icons.savings_rounded),
        const SizedBox(width: 12),
        _statTile('Pass. Rem.', remaining, AppColors.primaryGreen, Icons.account_balance_wallet_rounded),
      ],
    );
  }

  Widget _statTile(String label, double val, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 12),
            Text(label, style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11, fontWeight: FontWeight.w500)),
            Text('৳${val.toInt()}', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return const SizedBox();
    return Column(
      children: transactions.take(3).map((tx) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: (tx.type == TransactionType.income ? AppColors.primaryGreen : Colors.redAccent).withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(tx.type == TransactionType.income ? Icons.add_rounded : Icons.remove_rounded, 
                color: tx.type == TransactionType.income ? AppColors.primaryGreen : Colors.redAccent, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.category, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold)),
                Text('${tx.date.day} ${_getMonthName(tx.date.month)}', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textGrey)),
              ],
            )),
            Text('৳${tx.amount.toInt()}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
        Text(subtitle, style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textGrey)),
      ],
    );
  }

  Widget _buildNoGoalPrompt() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Column(
        children: [
          Icon(Icons.track_changes_rounded, size: 40, color: AppColors.primaryGreen.withOpacity(0.2)),
          const SizedBox(height: 12),
          Text('No targets set', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textBlack)),
          const SizedBox(height: 4),
          Text('Tap the target icon to set limits.', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 12)),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
