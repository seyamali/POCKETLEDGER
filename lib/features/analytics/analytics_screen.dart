import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/services/goal_service.dart';
import 'package:pocketledger/models/goal_model.dart';
import 'package:pocketledger/models/transaction_model.dart';
import 'package:pocketledger/core/widgets/glass_card.dart';
import 'package:pocketledger/core/constants/app_constants.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final GoalService _goalService = GoalService();
  int _touchedPieIndex = -1;
  String _selectedPeriod = 'This Month';
  String _selectedOwner = 'All';

  // Returns the DateTime for the currently selected period (used for preset filters)
  (int month, int year) _getPeriodMonthYear() {
    final now = DateTime.now();
    if (_selectedPeriod == 'Last Month') {
      final lastMonth = now.month == 1 ? 12 : now.month - 1;
      final year = now.month == 1 ? now.year - 1 : now.year;
      return (lastMonth, year);
    }
    // Default to current month for 'This Month'
    return (now.month, now.year);
  }

  // Selected custom date range (null when not set)
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  // Show modal bottom sheet with filter options (period and member selection)
  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        String tempPeriod = _selectedPeriod;
        String tempOwner = _selectedOwner;
        DateTime? tempStart = _rangeStart;
        DateTime? tempEnd = _rangeEnd;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textGrey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Filter Analytics',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textBlack),
                  ),
                  const SizedBox(height: 20),

                  // Period Title
                  Text(
                    'Time Period',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('This Month', tempPeriod == 'This Month', () {
                        setModalState(() {
                          tempPeriod = 'This Month';
                          tempStart = null;
                          tempEnd = null;
                        });
                      }),
                      _buildFilterChip('Last Month', tempPeriod == 'Last Month', () {
                        setModalState(() {
                          tempPeriod = 'Last Month';
                          tempStart = null;
                          tempEnd = null;
                        });
                      }),
                      _buildFilterChip(
                        tempPeriod == 'Custom' && tempStart != null && tempEnd != null
                            ? '${DateFormat('MMM d').format(tempStart!)} - ${DateFormat('MMM d').format(tempEnd!)}'
                            : 'Custom Range',
                        tempPeriod == 'Custom',
                        () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                            initialDateRange: tempStart != null && tempEnd != null 
                                ? DateTimeRange(start: tempStart!, end: tempEnd!) 
                                : null,
                          );
                          if (picked != null) {
                            setModalState(() {
                              tempPeriod = 'Custom';
                              tempStart = picked.start;
                              tempEnd = picked.end;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Member Title
                  Text(
                    'Filter by Member',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('All Members', tempOwner == 'All', () {
                        setModalState(() => tempOwner = 'All');
                      }),
                      ...AppConstants.allowedOwners.map((owner) {
                        return _buildFilterChip(owner, tempOwner == owner, () {
                          setModalState(() => tempOwner = owner);
                        });
                      }),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedPeriod = tempPeriod;
                          _selectedOwner = tempOwner;
                          _rangeStart = tempStart;
                          _rangeEnd = tempEnd;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Apply Filters',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.outfit(color: isSelected ? Colors.white : AppColors.textBlack, fontSize: 13, fontWeight: FontWeight.w600)),
      selected: isSelected,
      selectedColor: AppColors.primaryGreen,
      backgroundColor: AppColors.cardWhite,
      onSelected: (_) => onTap(),
    );
  }

  String _getMonthYearKey() {
    final (m, y) = _getPeriodMonthYear();
    return "${m.toString().padLeft(2, '0')}-$y";
  }

  String _getPeriodLabel() {
    if (_rangeStart != null && _rangeEnd != null) {
      final fmt = DateFormat('MMM d, yyyy');
      return '${fmt.format(_rangeStart!)} - ${fmt.format(_rangeEnd!)}';
    }
    final (m, y) = _getPeriodMonthYear();
    return DateFormat('MMMM yyyy').format(DateTime(y, m));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text('Analytics', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textBlack)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textBlack, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Modern filter button – opens a modal bottom sheet
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: _showFilterOptions,
              child: GlassCard(
                borderRadius: 20,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list_rounded, color: AppColors.primaryGreen, size: 18),
                      const SizedBox(width: 6),
                      Text('Filter', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: (_rangeStart != null && _rangeEnd != null)
            ? _goalService.getTransactionsForDateRange(_rangeStart!, _rangeEnd!)
            : _goalService.getTransactionsForMonth(_getPeriodMonthYear().$1, _getPeriodMonthYear().$2),
        builder: (context, txSnapshot) {
          final allTxs = txSnapshot.data ?? [];
          final txs = _selectedOwner == 'All'
              ? allTxs
              : allTxs.where((tx) => tx.owner == _selectedOwner).toList();

          return StreamBuilder<GoalModel?>(
            stream: _goalService.getGoal(_getMonthYearKey()),
            builder: (context, goalSnapshot) {
              final goal = goalSnapshot.data;

              // Calculate totals from transactions
              double income = 0;
              double expense = 0;
              double actualEmi = 0;
              double actualSaved = goal?.initialProgressSavings ?? 0;
              for (var tx in txs) {
                final cat = tx.category.toLowerCase();
                bool isSavings = cat.contains('sav') || tx.toAccountName?.toLowerCase().contains('sav') == true;

                if (isSavings) {
                  actualSaved += tx.amount;
                } else {
                  if (tx.type == TransactionType.income) income += tx.amount;
                  if (tx.type == TransactionType.expense) {
                    expense += tx.amount;
                    if (cat.contains('emi') || cat.contains('loan repay') || cat.contains('loan repayment')) {
                      actualEmi += tx.amount;
                    }
                  }
                }
              }
              double net = income - expense;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Period & Member label row
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16, top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.textGrey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(_getPeriodLabel(), style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textGrey)),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.person_rounded, size: 16, color: AppColors.textGrey),
                              const SizedBox(width: 6),
                              Text('Member: $_selectedOwner', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textGrey)),
                            ],
                          ),
                        ),

                        // ── Summary Cards ──
                        _buildSummaryRow(income, expense, net),
                        const SizedBox(height: 20),

                        // ── Goals Progress (if set) ──
                        if (goal != null) ...[
                          _buildGoalsSection(goal, income, expense, net, actualEmi, actualSaved),
                          const SizedBox(height: 20),
                        ],

                        // ── Expense Breakdown Pie ──
                        if (txs.isEmpty)
                          _buildEmptyState()
                        else ...[
                          _buildExpensePieChart(txs),
                          const SizedBox(height: 20),
                          _buildWeeklyBarChart(txs),
                          const SizedBox(height: 60),
                        ],
                      ]),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.insert_chart_outlined_rounded, size: 64, color: AppColors.textGrey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No transactions this period', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
            const SizedBox(height: 6),
            Text('Add transactions to see analytics', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(double income, double expense, double net) {
    return Row(
      children: [
        Expanded(child: _buildMiniCard('Income', income, AppColors.success, Icons.arrow_downward_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _buildMiniCard('Expense', expense, AppColors.error, Icons.arrow_upward_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _buildMiniCard('Net', net, net >= 0 ? AppColors.primaryGreen : AppColors.error, Icons.account_balance_wallet_outlined)),
      ],
    );
  }

  Widget _buildMiniCard(String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(title, style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('৳${amount.abs().toInt()}', style: GoogleFonts.outfit(color: amount < 0 ? AppColors.error : AppColors.textBlack, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSection(GoalModel goal, double income, double expense, double net, double actualEmi, double actualSaved) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primaryGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.track_changes_rounded, color: AppColors.primaryGreen, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Monthly Goals', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
            ],
          ),
          const SizedBox(height: 20),
          if (goal.incomeTarget > 0)
            _buildGoalProgress('Income Target', income, goal.incomeTarget, AppColors.success, Icons.arrow_downward_rounded),
          if (goal.expenseLimit > 0) ...[
            const SizedBox(height: 16),
            _buildGoalProgress('Expense Limit', expense, goal.expenseLimit, AppColors.error, Icons.arrow_upward_rounded, isLimit: true),
          ],
          if (goal.savingsTarget > 0) ...[
            const SizedBox(height: 16),
            _buildGoalProgress('Savings Target', actualSaved, goal.savingsTarget, Colors.blue, Icons.savings_rounded),
          ],
          if (goal.emi > 0) ...[
            const SizedBox(height: 16),
            _buildGoalProgress('EMI Target', actualEmi, goal.emi, Colors.purple, Icons.calendar_month_rounded),
          ],
          // Category Limits from Goal
          if (goal.categoryLimits.isNotEmpty) ...[
            const SizedBox(height: 20),
            Divider(color: AppColors.borderLight, height: 1),
            const SizedBox(height: 16),
            Text('Category Limits', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textGrey)),
            const SizedBox(height: 12),
            ...goal.categoryLimits.entries.map((entry) {
              // We don't have txs here, so pass 0 for now — actual category spending tracked externally
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCatLimitProgress(entry.key, entry.value),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalProgress(String label, double current, double target, Color color, IconData icon, {bool isLimit = false}) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final bool isExceeded = isLimit && current > target;
    final bool isAchieved = !isLimit && current >= target;
    final effectiveColor = isExceeded ? AppColors.error : (isAchieved ? AppColors.success : color);
    final remaining = (target - current).abs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: effectiveColor),
                const SizedBox(width: 6),
                Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textBlack)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('৳${current.toInt()} / ৳${target.toInt()}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: isExceeded ? AppColors.error : AppColors.textGrey)),
                if (isExceeded)
                  Text('Exceeded by ৳${remaining.toInt()}', style: GoogleFonts.outfit(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w500))
                else if (isAchieved)
                  Text('Goal achieved! 🎉', style: GoogleFonts.outfit(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600))
                else
                  Text('৳${remaining.toInt()} to go', style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textGrey)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: effectiveColor.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
          ),
        ),
      ],
    );
  }

  Widget _buildCatLimitProgress(String category, double limit) {
    final colors = [Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.amber, Colors.pink];
    final color = colors[category.length % colors.length];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(category, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textBlack)),
          ],
        ),
        Text('Limit: ৳${limit.toInt()}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textGrey)),
      ],
    );
  }

  Widget _buildExpensePieChart(List<TransactionModel> txs) {
    final expenses = txs.where((t) => t.type == TransactionType.expense).toList();
    if (expenses.isEmpty) return const SizedBox();

    final Map<String, double> categoryTotals = {};
    for (var tx in expenses) {
      categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0) + tx.amount;
    }
    final sortedCategories = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final double totalExpense = expenses.fold(0, (s, t) => s + t.amount);

    final List<Color> colors = [AppColors.error, Colors.orange, Colors.amber.shade700, Colors.blue, Colors.purple, Colors.teal];
    List<PieChartSectionData> sections = [];

    for (int i = 0; i < sortedCategories.length && i < 6; i++) {
      final isTouched = i == _touchedPieIndex;
      final value = sortedCategories[i].value;
      final percentage = (value / totalExpense * 100);

      sections.add(PieChartSectionData(
        color: colors[i % colors.length],
        value: value,
        title: isTouched ? '৳${value.toInt()}' : '${percentage.toStringAsFixed(0)}%',
        radius: isTouched ? 64.0 : 52.0,
        titleStyle: GoogleFonts.outfit(fontSize: isTouched ? 13.0 : 11.0, fontWeight: FontWeight.bold, color: Colors.white),
      ));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: Icon(Icons.pie_chart_rounded, color: AppColors.error, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Expense Breakdown', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 46),
            child: Text('Tap a slice to see amount', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textGrey)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                        _touchedPieIndex = -1;
                        return;
                      }
                      _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 36,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Legend with amounts
          Column(
            children: List.generate(sections.length, (i) {
              final amount = sortedCategories[i].value;
              final percentage = (amount / totalExpense * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[i % colors.length], borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(sortedCategories[i].key, style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textBlack, fontWeight: FontWeight.w600))),
                    Text('${percentage.toStringAsFixed(1)}%', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textGrey)),
                    const SizedBox(width: 12),
                    Text('৳${amount.toInt()}', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart(List<TransactionModel> txs) {
    List<double> incomeWeeks = [0, 0, 0, 0];
    List<double> expenseWeeks = [0, 0, 0, 0];

    for (var tx in txs) {
      int weekIndex = ((tx.date.day - 1) ~/ 7).clamp(0, 3);
      if (tx.type == TransactionType.income) incomeWeeks[weekIndex] += tx.amount;
      if (tx.type == TransactionType.expense) expenseWeeks[weekIndex] += tx.amount;
    }

    double maxVal = 0;
    for (int i = 0; i < 4; i++) {
      if (incomeWeeks[i] > maxVal) maxVal = incomeWeeks[i];
      if (expenseWeeks[i] > maxVal) maxVal = expenseWeeks[i];
    }
    if (maxVal == 0) maxVal = 1000;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: const Icon(Icons.bar_chart_rounded, color: Colors.blue, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Weekly Overview', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.25,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => AppColors.cardWhite,
                    tooltipBorder: BorderSide(color: AppColors.borderLight),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = rodIndex == 0 ? 'Income' : 'Expense';
                      return BarTooltipItem('$label\n৳${rod.toY.toInt()}', GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: rod.color));
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 6), child: Text('W${v.toInt() + 1}', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.w600))),
                    reservedSize: 28,
                  )),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxVal / 4,
                  getDrawingHorizontalLine: (_) => FlLine(color: AppColors.borderLight, strokeWidth: 1, dashArray: [4, 4]),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(4, (i) => BarChartGroupData(
                  x: i,
                  barsSpace: 4,
                  barRods: [
                    BarChartRodData(toY: incomeWeeks[i], color: AppColors.success, width: 12, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                    BarChartRodData(toY: expenseWeeks[i], color: AppColors.error, width: 12, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                  ],
                )),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(AppColors.success, 'Income'),
              const SizedBox(width: 20),
              _legendDot(AppColors.error, 'Expense'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
