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
    
    final categoryCtrls = {
      'Expense': TextEditingController(text: currentGoal?.categoryLimits['Expense']?.toInt().toString() ?? ''),
      'Home': TextEditingController(text: currentGoal?.categoryLimits['Home']?.toInt().toString() ?? ''),
      'Wife Expense': TextEditingController(text: currentGoal?.categoryLimits['Wife Expense']?.toInt().toString() ?? ''),
      'My Expense': TextEditingController(text: currentGoal?.categoryLimits['My Expense']?.toInt().toString() ?? ''),
      'Other Expense': TextEditingController(text: currentGoal?.categoryLimits['Other Expense']?.toInt().toString() ?? ''),
    };

    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 32, left: 24, right: 24,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primaryBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Set Goals for $_monthName ${_currentMonth.year}', 
                  style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                const SizedBox(height: 24),
                
                CustomTextField(
                  controller: incomeCtrl,
                  hintText: 'Income Target (৳)',
                  icon: Icons.arrow_downward_rounded,
                  keyboardType: TextInputType.number,
                ),
                
                const SizedBox(height: 24),
                Align(alignment: Alignment.centerLeft, child: Text('EXPENSE CATEGORY LIMITS', style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 11, fontWeight: FontWeight.bold))),
                const SizedBox(height: 12),
                
                ...categoryCtrls.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CustomTextField(
                    controller: entry.value,
                    hintText: '${entry.key} Limit (৳)',
                    icon: Icons.pie_chart_outline_rounded,
                    keyboardType: TextInputType.number,
                  ),
                )).toList(),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      if (incomeCtrl.text.isEmpty) return;
                      setModalState(() => isLoading = true);

                      double totalExpenseLimit = 0;
                      Map<String, double> categoryLimits = {};
                      
                      for (var entry in categoryCtrls.entries) {
                        double limit = double.tryParse(entry.value.text) ?? 0;
                        categoryLimits[entry.key] = limit;
                        totalExpenseLimit += limit;
                      }
                      
                      await _goalService.setGoal(
                        monthYear: _monthYearKey,
                        incomeTarget: double.parse(incomeCtrl.text),
                        expenseLimit: totalExpenseLimit,
                        savingsTarget: 0, // Unused
                        categoryLimits: categoryLimits,
                      );
                      
                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Save Goals', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Monthly Goal', style: GoogleFonts.montserrat(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: _goalService.getTransactionsForMonth(_currentMonth.month, _currentMonth.year),
        builder: (context, txSnapshot) {
          return StreamBuilder<GoalModel?>(
            stream: _goalService.getGoal(_monthYearKey),
            builder: (context, goalSnapshot) {
              
              if (txSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
              }

              final transactions = txSnapshot.data ?? [];
              final goal = goalSnapshot.data;

              // Calculate actuals
              double actualIncome = 0;
              double actualExpense = 0;
              double actualSaved = 0; // 'Savings' category — not a real expense
              Map<String, double> expenseByCategory = {};

              for (var tx in transactions) {
                // Exclude Opening Balance — account setup entries, not real income
                if (tx.category == 'Opening Balance') continue;
                
                if (tx.type == TransactionType.income) actualIncome += tx.amount;
                if (tx.type == TransactionType.expense) {
                  actualExpense += tx.amount;
                  expenseByCategory[tx.category] = (expenseByCategory[tx.category] ?? 0) + tx.amount;
                }
                // Track savings transfers from the Savings page
                if (tx.type == TransactionType.transfer && tx.category == 'Savings Transfer') {
                  actualSaved += tx.amount;
                }
              }

              final passiveSavings = actualIncome - actualExpense - actualSaved;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildMonthSelector(),
                    const SizedBox(height: 24),
                    
                    if (goal == null)
                      _buildNoGoalCard()
                    else
                      Column(
                        children: [
                          _buildMainProgressCard(goal, actualIncome, actualExpense, passiveSavings, expenseByCategory),
                          const SizedBox(height: 24),
                          _buildSummaryGrid(actualIncome, actualExpense, actualSaved, goal.expenseLimit),
                        ],
                      ),

                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('TRANSACTIONS THIS MONTH', style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                    const SizedBox(height: 12),
                    _buildTransactionSnapshot(transactions),
                  ],
                ),
              );
            }
          );
        }
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.brandPrimary, size: 20),
          onPressed: () => _changeMonth(-1),
        ),
        Text('$_monthName ${_currentMonth.year}', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.brandPrimary, size: 20),
          onPressed: () => _changeMonth(1),
        ),
      ],
    );
  }

  Widget _buildNoGoalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Icon(Icons.track_changes_rounded, size: 64, color: AppColors.brandPrimary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No Goal Set', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
          const SizedBox(height: 8),
          Text('Set an income target and expense limit to track your financial health this month.', 
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 13, height: 1.5)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showSetGoalModal(null),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text('Set Goal', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildMainProgressCard(GoalModel goal, double actualIncome, double actualExpense, double passiveSavings, Map<String, double> expenseByCategory) {
    double incomeProgress = goal.incomeTarget > 0 ? (actualIncome / goal.incomeTarget) : 0;
    double expenseProgress = goal.expenseLimit > 0 ? (actualExpense / goal.expenseLimit) : 0;
    
    // Cap progress at 1.0 for the UI bar
    if (incomeProgress > 1.0) incomeProgress = 1.0;
    if (expenseProgress > 1.0) expenseProgress = 1.0;

    String statusText = '🟢 On Track';
    Color statusColor = AppColors.brandPrimary;
    
    if (actualExpense > goal.expenseLimit) {
      statusText = '🔴 Over Budget';
      statusColor = Colors.redAccent;
    } else if (actualExpense > (goal.expenseLimit * 0.8)) {
      statusText = '🟡 Warning';
      statusColor = Colors.orangeAccent;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(statusText, style: GoogleFonts.montserrat(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16)),
              GestureDetector(
                onTap: () => _showSetGoalModal(goal),
                child: const Icon(Icons.settings_outlined, color: AppColors.secondaryText, size: 22),
              )
            ],
          ),
          const SizedBox(height: 32),
          
          _buildProgressBar('Income Progress', actualIncome, goal.incomeTarget, AppColors.brandPrimary, incomeProgress),
          const SizedBox(height: 24),
          _buildProgressBar('Overall Expense Progress', actualExpense, goal.expenseLimit, Colors.redAccent, expenseProgress),
          
          if (goal.categoryLimits.keys.any((k) => (goal.categoryLimits[k] ?? 0) > 0)) ...[
            const SizedBox(height: 32),
            Text('CATEGORY BREAKDOWN', style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            ...goal.categoryLimits.entries.where((e) => e.value > 0).map((entry) {
              double catActual = expenseByCategory[entry.key] ?? 0;
              double catProgress = catActual / entry.value;
              if (catProgress > 1.0) catProgress = 1.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildProgressBar(entry.key, catActual, entry.value, Colors.redAccent.withOpacity(0.8), catProgress, isSmall: true),
              );
            }).toList(),
          ],
          
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Text('Passive Remaining Balance', style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text('৳ ${passiveSavings.toInt()}', style: GoogleFonts.montserrat(color: Colors.amber.shade600, fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double actual, double limit, Color color, double progress, {bool isSmall = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(label, 
                style: GoogleFonts.montserrat(color: AppColors.primaryText, fontWeight: isSmall ? FontWeight.w500 : FontWeight.w600, fontSize: isSmall ? 11 : 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text('${actual.toInt()} / ${limit.toInt()} Tk', 
              style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontWeight: isSmall ? FontWeight.w500 : FontWeight.w600, fontSize: isSmall ? 11 : 13)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.1),
            color: color,
            minHeight: isSmall ? 4 : 8,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryGrid(double actualIncome, double actualExpense, double actualSaved, double expenseLimit) {
    double remaining = expenseLimit - actualExpense;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _miniCard('Income', actualIncome, AppColors.brandPrimary)),
            const SizedBox(width: 12),
            Expanded(child: _miniCard('Expense', actualExpense, Colors.redAccent)),
            const SizedBox(width: 12),
            Expanded(child: _miniCard('Remaining', remaining, remaining < 0 ? Colors.redAccent : AppColors.brandPrimary)),
          ],
        ),
        if (actualSaved > 0) ...[
          const SizedBox(height: 12),
          _miniCard('Saved This Month 🏦', actualSaved, Colors.amber.shade600),
        ],
      ],
    );
  }

  Widget _miniCard(String title, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Text(title, style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('৳${value.toInt()}', style: GoogleFonts.montserrat(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }



  Widget _buildTransactionSnapshot(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text('No transactions recorded this month.', style: GoogleFonts.montserrat(color: AppColors.secondaryText)),
      );
    }

    return Column(
      children: transactions.take(5).map((tx) {
        bool isIncome = tx.type == TransactionType.income;
        bool isTransfer = tx.type == TransactionType.transfer;
        
        Color iconColor = isIncome ? AppColors.brandPrimary : (isTransfer ? Colors.blue : Colors.redAccent);
        String prefix = isIncome ? '+' : (isTransfer ? '' : '-');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.brandPrimary.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.category, style: GoogleFonts.montserrat(color: AppColors.primaryText, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    Text('${tx.date.day}/${tx.date.month}/${tx.date.year}', style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 11)),
                  ],
                ),
              ),
              Text('$prefix${tx.amount.toInt()}', style: GoogleFonts.montserrat(color: iconColor, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
