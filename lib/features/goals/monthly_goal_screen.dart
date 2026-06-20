import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/goal_model.dart';
import 'package:pocketledger/models/transaction_model.dart';
import 'package:pocketledger/services/goal_service.dart';
import 'package:pocketledger/features/auth/widgets/custom_text_field.dart';
import 'package:pocketledger/models/account_model.dart';
import 'package:pocketledger/services/account_service.dart';
import 'package:pocketledger/services/transaction_service.dart';
import 'package:pocketledger/core/constants/app_constants.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pocketledger/core/widgets/scale_on_tap.dart';
import 'package:pocketledger/core/widgets/glass_card.dart';
import 'package:pocketledger/core/localization/app_localizations.dart';

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
  late ScrollController _monthScrollController;

  @override
  void initState() {
    super.initState();
    final activeMonthIndex = _currentMonth.month - 1;
    final initialOffset = (activeMonthIndex * 76.0) - 100.0;
    _monthScrollController = ScrollController(
      initialScrollOffset: initialOffset > 0 ? initialOffset : 0,
    );
  }

  @override
  void dispose() {
    _monthScrollController.dispose();
    super.dispose();
  }

  String get _monthYearKey => "${_currentMonth.month.toString().padLeft(2, '0')}-${_currentMonth.year}";
  String get _monthName => _getMonthName(_currentMonth.month);

  void _showSetGoalModal(GoalModel? currentGoal) {
    final incomeCtrl = TextEditingController(text: currentGoal?.incomeTarget.toInt().toString() ?? '');
    final expenseCtrl = TextEditingController(text: currentGoal?.expenseLimit.toInt().toString() ?? '');
    final savingsCtrl = TextEditingController(text: currentGoal?.savingsTarget.toInt().toString() ?? '');
    final emiCtrl = TextEditingController(text: currentGoal?.emi.toInt().toString() ?? '');

    final categoryCtrls = {
      'Home': TextEditingController(text: currentGoal?.categoryLimits['Home']?.toInt().toString() ?? ''),
      'Food': TextEditingController(text: currentGoal?.categoryLimits['Food']?.toInt().toString() ?? ''),
      'Wife': TextEditingController(text: currentGoal?.categoryLimits['Wife']?.toInt().toString() ?? ''),
      'Myself': TextEditingController(text: currentGoal?.categoryLimits['Myself']?.toInt().toString() ?? ''),
      'Other': TextEditingController(text: currentGoal?.categoryLimits['Other']?.toInt().toString() ?? ''),
    };

    final prevIncomeCtrl = TextEditingController(text: currentGoal?.initialProgressIncome.toInt().toString() ?? '');
    final prevExpenseCtrl = TextEditingController(text: currentGoal?.initialProgressExpense.toInt().toString() ?? '');
    final prevSavedCtrl = TextEditingController(text: currentGoal?.initialProgressSavings.toInt().toString() ?? '');

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
                children: [
                  Column(
                    children: [
                      Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Text('Target Settings', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ScaleOnTap(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                                child: Icon(Icons.close_rounded, color: AppColors.textGrey, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text('Set your targets for $_monthName ${_currentMonth.year}', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 32),

                  _buildModalInput('Monthly Income Target', incomeCtrl, Icons.payments_rounded, AppColors.brandPrimary),
                  const SizedBox(height: 16),
                  _buildModalInput('Monthly Savings Target', savingsCtrl, Icons.savings_rounded, Colors.amber.shade600),
                  const SizedBox(height: 16),
                  _buildModalInput('Overall Expense Limit', expenseCtrl, Icons.money_off_rounded, Colors.redAccent),
                  const SizedBox(height: 16),
                  _buildModalInput('Monthly EMI Target', emiCtrl, Icons.calendar_month_rounded, Colors.purple),

                  const SizedBox(height: 32),
                  ...categoryCtrls.entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildModalInput('${entry.key} Limit', entry.value, Icons.pie_chart_rounded, Colors.orangeAccent, isSmall: true),
                      )),

                  const SizedBox(height: 32),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text('INITIAL PROGRESS (ALREADY DONE)',
                          style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5))),
                  const SizedBox(height: 8),
                  Text('Add amounts done before using this app this month', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11)),
                  const SizedBox(height: 16),

                  _buildModalInput('Already Earned', prevIncomeCtrl, Icons.add_task_rounded, AppColors.brandPrimary, isSmall: true),
                  const SizedBox(height: 12),
                  _buildModalInput('Already Spent', prevExpenseCtrl, Icons.remove_done_rounded, Colors.redAccent, isSmall: true),
                  const SizedBox(height: 12),
                  _buildModalInput('Already Saved', prevSavedCtrl, Icons.done_all_rounded, Colors.amber.shade600, isSmall: true),

                  const SizedBox(height: 32),
                  ScaleOnTap(
                    onTap: () {
                      if (isLoading) return;
                      if (incomeCtrl.text.isEmpty) return;
                      setModalState(() => isLoading = true);

                      Map<String, double> categoryLimits = {};
                      for (var entry in categoryCtrls.entries) {
                        categoryLimits[entry.key] = double.tryParse(entry.value.text) ?? 0;
                      }

                      _goalService.setGoal(
                        monthYear: _monthYearKey,
                        incomeTarget: double.tryParse(incomeCtrl.text) ?? 0,
                        expenseLimit: double.tryParse(expenseCtrl.text) ?? 0,
                        savingsTarget: double.tryParse(savingsCtrl.text) ?? 0,
                        emi: double.tryParse(emiCtrl.text) ?? 0,
                        initialProgressIncome: double.tryParse(prevIncomeCtrl.text) ?? 0,
                        initialProgressExpense: double.tryParse(prevExpenseCtrl.text) ?? 0,
                        initialProgressSavings: double.tryParse(prevSavedCtrl.text) ?? 0,
                        categoryLimits: categoryLimits,
                      ).then((_) {
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
                          : Text('Update Targets', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
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

  Widget _buildModalInput(String label, TextEditingController ctrl, IconData icon, Color color, {bool isSmall = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<TransactionModel>>(
      stream: _goalService.getAllTransactions(),
      builder: (context, txSnapshot) {
        return StreamBuilder<GoalModel?>(
          stream: _goalService.getGoal(_monthYearKey),
          builder: (context, goalSnapshot) {
            if (txSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: AppColors.primaryBackground,
                body: Center(child: CircularProgressIndicator(color: AppColors.brandPrimary)),
              );
            }

            final allTransactions = txSnapshot.data ?? [];
            final transactions = allTransactions.where((tx) => tx.date.month == _currentMonth.month && tx.date.year == _currentMonth.year).toList();
            final goal = goalSnapshot.data;
            final filteredTransactions = transactions.where((tx) {
              if (tx.owner != AppConstants.ownerSelf) return false;
              final cat = tx.category.toLowerCase();
              final note = tx.note.toLowerCase();
              if (cat.contains('opening') || cat.contains('initial') || note.contains('opening') || note.contains('initial')) {
                return false;
              }
              return true;
            }).toList();

            double actualIncome = goal?.initialProgressIncome ?? 0;
            double actualExpense = goal?.initialProgressExpense ?? 0;
            double actualSaved = goal?.initialProgressSavings ?? 0;
            double actualEmi = 0;
            Map<String, double> expenseByCategory = {};

            for (var tx in filteredTransactions) {
              final cat = tx.category.toLowerCase();
              bool isSavings = cat.contains('sav') || tx.toAccountName?.toLowerCase().contains('sav') == true;

              if (isSavings) {
                actualSaved += tx.amount;
              } else {
                if (tx.type == TransactionType.income && cat == 'salary') {
                  actualIncome += tx.amount;
                }
                if (tx.type == TransactionType.expense) {
                  actualExpense += tx.amount;
                  expenseByCategory[tx.category] = (expenseByCategory[tx.category] ?? 0) + tx.amount;
                  if (cat.contains('emi') || cat.contains('loan repay') || cat.contains('loan repayment')) {
                    actualEmi += tx.amount;
                  }
                }
              }
            }

            final passiveRemaining = actualIncome - actualExpense - actualSaved;

            return ThemeBuilder(builder: (context) => Scaffold(
              backgroundColor: AppColors.primaryBackground,
              body: Stack(
                children: [
                  // Ambient background blobs
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
                    bottom: 120,
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
                  Column(
                    children: [
                      _buildPremiumHeader(goal, actualIncome, actualExpense, actualSaved, filteredTransactions, isDark),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader('Financial Health', 'Live status for this month'),
                              const SizedBox(height: 16),
                              HealthMeter(goal: goal, expense: actualExpense, income: actualIncome),
                              if (expenseByCategory.isNotEmpty) ...[
                                const SizedBox(height: 32),
                                _buildSectionHeader('Expense Breakdown', 'Where your money goes'),
                                const SizedBox(height: 16),
                                _buildExpensePieChart(expenseByCategory, actualExpense, isDark),
                              ],
                              const SizedBox(height: 32),
                              _buildSectionHeader('Category Targets', 'Limits vs Actual spending'),
                              const SizedBox(height: 16),
                              _buildCategoryTargetGrid(goal, expenseByCategory),
                              const SizedBox(height: 32),
                              _buildSectionHeader('Month Summary', 'Key figures at a glance'),
                              const SizedBox(height: 16),
                              _buildSummaryStats(actualIncome, actualExpense, actualSaved, passiveRemaining, actualEmi, goal?.emi ?? 0, isDark),
                              const SizedBox(height: 32),
                              _buildSectionHeader('Multi-Month Trends', 'Income, Expense, and Savings trends'),
                              const SizedBox(height: 16),
                              _buildMultiMonthTrendsChart(allTransactions, isDark),
                              const SizedBox(height: 32),
                              _buildSectionHeader('Recent Activity', 'Top movements this month'),
                              const SizedBox(height: 16),
                              _buildRecentActivity(filteredTransactions, isDark),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              floatingActionButton: ScaleOnTap(
                onTap: () => _showSetGoalModal(goal),
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
                  child: const Icon(Icons.track_changes_rounded, color: Colors.white, size: 28),
                ),
              ),
            )); // closes Scaffold + ThemeBuilder
          },
        );
      },
    );
  }

  void _exportToCSV(List<TransactionModel> txs) {
    if (txs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.get('no_transactions_to_export'))),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Date,Category,Amount,Type,Note,Account,To Account,Owner');

    for (var tx in txs) {
      final dateStr = "${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}";

      String escape(String? val) {
        if (val == null) return '';
        final clean = val.replaceAll('"', '""');
        if (clean.contains(',') || clean.contains('"') || clean.contains('\n')) {
          return '"$clean"';
        }
        return clean;
      }

      final row = [
        dateStr,
        escape(tx.category),
        tx.amount.toInt().toString(),
        tx.type.toString().split('.').last,
        escape(tx.note),
        escape(tx.accountName),
        escape(tx.toAccountName),
        escape(tx.owner),
      ];

      buffer.writeln(row.join(','));
    }

    Clipboard.setData(ClipboardData(text: buffer.toString())).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.brandPrimary,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text('Monthly sheet copied to clipboard as CSV!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        );
      }
    });
  }

  Widget _buildPremiumHeader(GoalModel? goal, double income, double expense, double saved, List<TransactionModel> txs, bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 5, 24, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16201D).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ScaleOnTap(
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.primaryText),
                ),
              ),
              Text('Monthly Analytics', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleOnTap(
                    onTap: () => _exportToCSV(txs),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(Icons.share_rounded, size: 20, color: AppColors.brandPrimary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ScaleOnTap(
                    onTap: () => _showSetGoalModal(goal),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(Icons.tune_rounded, size: 20, color: AppColors.brandPrimary),
                    ),
                  ),
                ],
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
        controller: _monthScrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 12,
        itemBuilder: (context, index) {
          final monthDate = DateTime(_currentMonth.year, index + 1);
          final isSelected = monthDate.month == _currentMonth.month;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ScaleOnTap(
              onTap: () {
                setState(() => _currentMonth = monthDate);
                if (_monthScrollController.hasClients) {
                  final targetOffset = (index * 76.0) - (MediaQuery.of(context).size.width / 2) + 38.0;
                  _monthScrollController.animateTo(
                    targetOffset.clamp(0.0, _monthScrollController.position.maxScrollExtent),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brandPrimary : AppColors.cardWhite.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: isSelected ? Colors.transparent : AppColors.brandPrimary.withValues(alpha: 0.08)),
                ),
                alignment: Alignment.center,
                child: Text(_getMonthName(index + 1),
                    style: GoogleFonts.outfit(
                      color: isSelected ? Colors.white : AppColors.textGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    )),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainCircleStats(GoalModel? goal, double income, double expense, double saved) {
    double effExpLimit = goal?.expenseLimit ?? 0;
    if (effExpLimit <= 0 && goal != null) {
      effExpLimit = goal.categoryLimits.values.fold(0.0, (a, b) => a + b);
    }

    double progressIncome = goal != null && goal.incomeTarget > 0 ? (income / goal.incomeTarget) : (income > 0 ? 1.0 : 0.0);
    double progressExpense = effExpLimit > 0 ? (expense / effExpLimit) : (income > 0 ? (expense / income) : 0);
    double savingsRatio = goal != null && goal.savingsTarget > 0 ? (saved / goal.savingsTarget) : (income > 0 ? (saved / income) : 0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _circleIndicator('Income', income, progressIncome.clamp(0, 1), AppColors.brandPrimary),
        _circleIndicator('Savings', saved, savingsRatio.clamp(0, 1), Colors.amber.shade600),
        _circleIndicator('Spent', expense, progressExpense.clamp(0, 1), Colors.redAccent),
      ],
    );
  }

  Widget _circleIndicator(String label, double val, double pct, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 4.5,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              Center(
                child: Icon(
                  label == 'Income'
                      ? Icons.arrow_downward_rounded
                      : label == 'Savings'
                          ? Icons.savings_rounded
                          : Icons.arrow_upward_rounded,
                  color: color,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textGrey)),
        const SizedBox(height: 2),
        Text('৳${val.toInt()}', style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
      ],
    );
  }

  String _getMonthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month < 1 || month > 12) return '';
    return names[month - 1];
  }

  Widget _buildExpensePieChart(Map<String, double> data, double total, bool isDark) {
    List<PieChartSectionData> sections = [];
    List<Widget> legendItems = [];

    final colors = [
      AppColors.brandPrimary,
      Colors.orangeAccent,
      Colors.redAccent,
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.pinkAccent,
      Colors.teal,
    ];

    int colorIndex = 0;
    for (var entry in data.entries) {
      if (entry.value <= 0) continue;
      final color = colors[colorIndex % colors.length];

      final pct = (entry.value / total) * 100;
      sections.add(PieChartSectionData(
        value: entry.value,
        color: color,
        radius: 18,
        showTitle: false,
      ));

      legendItems.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(entry.key, style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.textGrey, fontWeight: FontWeight.w500))),
              Text(
                '৳${entry.value.toInt()} (${pct.toStringAsFixed(1)}%)',
                style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textBlack),
              ),
            ],
          ),
        ),
      );

      colorIndex++;
    }

    return GlassCard(
      blur: 20,
      opacity: isDark ? 0.05 : 0.45,
      color: isDark ? const Color(0xFF16201D) : Colors.white,
      borderRadius: 24,
      border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.1)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 44,
                  sections: sections,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...legendItems,
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTargetGrid(GoalModel? goal, Map<String, double> actuals) {
    if (goal == null || goal.categoryLimits.isEmpty) return const SizedBox();

    final limits = goal.categoryLimits.entries.where((e) => e.value > 0).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: limits.length,
      itemBuilder: (context, i) {
        final entry = limits[i];
        final actual = actuals[entry.key] ?? 0;
        final progress = (actual / entry.value).clamp(0.0, 1.0);
        final isOver = actual > entry.value;

        Color cardBorderColor = isOver ? Colors.redAccent.withValues(alpha: 0.35) : AppColors.brandPrimary.withValues(alpha: 0.08);

        return GlassCard(
          blur: 15,
          opacity: isDark ? 0.04 : 0.45,
          color: isDark ? const Color(0xFF16201D) : Colors.white,
          borderRadius: 20,
          border: Border.all(color: cardBorderColor, width: isOver ? 1.5 : 1.0),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.key, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textBlack), overflow: TextOverflow.ellipsis),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('৳${actual.toInt()} / ৳${entry.value.toInt()}', style: GoogleFonts.outfit(fontSize: 10.5, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3.5,
                        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(isOver ? Colors.redAccent : AppColors.brandPrimary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryStats(double income, double expense, double saved, double remaining, double emiPaid, double emiTarget, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            _statTile('Net Saved', saved, Colors.amber.shade600, Icons.savings_rounded, isDark),
            const SizedBox(width: 12),
            _statTile('Pass. Rem.', remaining, AppColors.brandPrimary, Icons.account_balance_wallet_rounded, isDark),
          ],
        ),
        if (emiTarget > 0) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              _statTile('EMI Paid', emiPaid, Colors.purple, Icons.payment_rounded, isDark),
              const SizedBox(width: 12),
              _statTile('EMI Target', emiTarget, Colors.purple.shade300, Icons.track_changes_rounded, isDark),
            ],
          ),
        ],
      ],
    );
  }

  Widget _statTile(String label, double val, Color color, IconData icon, bool isDark) {
    return Expanded(
      child: GlassCard(
        blur: 15,
        opacity: isDark ? 0.04 : 0.45,
        color: isDark ? const Color(0xFF16201D) : Colors.white,
        borderRadius: 20,
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.08)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 12),
              Text(label, style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('৳${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => "${m[1]},")}',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(List<TransactionModel> transactions, bool isDark) {
    if (transactions.isEmpty) return const SizedBox();
    return Column(
      children: transactions.take(3).map((tx) {
        Color txColor = tx.type == TransactionType.income ? AppColors.brandPrimary : Colors.redAccent;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            blur: 15,
            opacity: isDark ? 0.04 : 0.45,
            color: isDark ? const Color(0xFF16201D) : Colors.white,
            borderRadius: 18,
            border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.08)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: txColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(tx.type == TransactionType.income ? Icons.add_rounded : Icons.remove_rounded, color: txColor, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.category, style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold)),
                      Text('${tx.date.day} ${_getMonthName(tx.date.month)}', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
                    ],
                  )),
                  Text(
                    '৳${tx.amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => "${m[1]},")}',
                    style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.bold, color: txColor),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
        Text(subtitle, style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMultiMonthTrendsChart(List<TransactionModel> allTransactions, bool isDark) {
    final now = DateTime.now();
    final months = List.generate(4, (i) {
      return DateTime(now.year, now.month - (3 - i), 1);
    });

    final monthlyData = months.map((m) {
      final filtered = allTransactions.where((tx) {
        if (tx.owner != AppConstants.ownerSelf) return false;
        if (tx.date.month != m.month || tx.date.year != m.year) return false;
        final cat = tx.category.toLowerCase();
        final note = tx.note.toLowerCase();
        if (cat.contains('opening') || cat.contains('initial') || note.contains('opening') || note.contains('initial')) {
          return false;
        }
        return true;
      }).toList();

      double income = 0;
      double expense = 0;
      double savings = 0;

      for (var tx in filtered) {
        final cat = tx.category.toLowerCase();
        bool isSavings = cat.contains('sav') || tx.toAccountName?.toLowerCase().contains('sav') == true;

        if (isSavings) {
          savings += tx.amount;
        } else {
          if (tx.type == TransactionType.income && cat == 'salary') {
            income += tx.amount;
          }
          if (tx.type == TransactionType.expense) {
            expense += tx.amount;
          }
        }
      }
      return {'income': income, 'expense': expense, 'savings': savings};
    }).toList();

    return GlassCard(
      blur: 20,
      opacity: isDark ? 0.05 : 0.45,
      color: isDark ? const Color(0xFF16201D) : Colors.white,
      borderRadius: 24,
      border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.1)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Trends Summary', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 12,
                  children: [
                    _buildLegendItem('In', AppColors.brandPrimary),
                    _buildLegendItem('Out', Colors.redAccent),
                    _buildLegendItem('Saved', Colors.amber.shade600),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxY(monthlyData) * 1.15,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          int idx = value.toInt();
                          if (idx >= 0 && idx < months.length) {
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(_getMonthName(months[idx].month), style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textGrey, fontWeight: FontWeight.bold)),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(monthlyData.length, (index) {
                    final data = monthlyData[index];
                    final income = data['income'] ?? 0;
                    final expense = data['expense'] ?? 0;
                    final savings = data['savings'] ?? 0;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: income,
                          color: AppColors.brandPrimary,
                          width: 7,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        BarChartRodData(
                          toY: expense,
                          color: Colors.redAccent,
                          width: 7,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        BarChartRodData(
                          toY: savings,
                          color: Colors.amber.shade600,
                          width: 7,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                      barsSpace: 3,
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getMaxY(List<Map<String, double>> data) {
    double maxVal = 1000.0;
    for (var m in data) {
      if ((m['income'] ?? 0) > maxVal) maxVal = m['income']!;
      if ((m['expense'] ?? 0) > maxVal) maxVal = m['expense']!;
      if ((m['savings'] ?? 0) > maxVal) maxVal = m['savings']!;
    }
    return maxVal;
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textBlack,
          ),
        ),
      ],
    );
  }
}

class HealthMeter extends StatelessWidget {
  final GoalModel? goal;
  final double expense;
  final double income;

  const HealthMeter({super.key, this.goal, required this.expense, required this.income});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double effExpLimit = goal?.expenseLimit ?? 0;
    if (effExpLimit <= 0 && goal != null) {
      effExpLimit = goal!.categoryLimits.values.fold(0.0, (a, b) => a + b);
    }

    double ratio = effExpLimit > 0 ? (expense / effExpLimit) : (income > 0 ? (expense / income) : 0);
    String status = 'Excellent';
    Color color = AppColors.brandPrimary;

    if (ratio > 1.0) {
      status = 'Critical';
      color = Colors.redAccent;
    } else if (ratio > 0.8) {
      status = 'Warning';
      color = Colors.orangeAccent;
    } else if (ratio > 0.5) {
      status = 'Good';
      color = Colors.blueAccent;
    }

    return GlassCard(
      blur: 20,
      opacity: isDark ? 0.05 : 0.45,
      color: isDark ? const Color(0xFF16201D) : Colors.white,
      borderRadius: 25,
      border: Border.all(color: color.withValues(alpha: 0.15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Monthly Budget Health', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(status, style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio.clamp(0, 1),
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('You have utilized ${(ratio * 100).toInt()}% of your budget.', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}

class NoGoalPrompt extends StatelessWidget {
  const NoGoalPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      blur: 20,
      opacity: isDark ? 0.05 : 0.45,
      color: isDark ? const Color(0xFF16201D) : Colors.white,
      borderRadius: 25,
      border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.1)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.track_changes_rounded, size: 40, color: AppColors.brandPrimary.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('Set Monthly Targets', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textBlack)),
            const SizedBox(height: 8),
            Text(
              'Set income targets and expense limits to get a detailed breakdown of your savings potential and financial health.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
