import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/transaction_model.dart';
import 'package:pocketledger/services/transaction_service.dart';
import 'package:pocketledger/core/widgets/skeleton_loader.dart';
import 'package:intl/intl.dart';
import 'package:pocketledger/core/widgets/scale_on_tap.dart';
import 'package:pocketledger/core/widgets/glass_card.dart';
import 'package:pocketledger/core/localization/app_localizations.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionService _transactionService = TransactionService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _selectedFilter = 'All'; // Type filter: 'All', 'Income', 'Expense', 'Transfer'
  String _selectedCategoryFilter = 'All';
  String _selectedDateFilter = 'This Month'; // Date filter: 'This Month', 'This Week', 'All Time', 'Custom'
  DateTime? _selectedCustomMonth;
  DateTimeRange? _selectedCustomDateRange;
  int _currentLimit = 20;

  final List<String> _filters = ['All', 'Income', 'Expense', 'Transfer'];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ThemeBuilder(builder: (context) => Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Transactions',
          style: GoogleFonts.outfit(
            color: AppColors.primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          ScaleOnTap(
            onTap: () => Navigator.pushNamed(context, '/add-transaction'),
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandPrimary.withValues(alpha: 0.1),
              ),
              child: Icon(Icons.add_rounded, color: AppColors.brandPrimary, size: 24),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background ambient glowing circles
          Positioned(
            top: -20, right: -40,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandPrimary.withValues(alpha: isDark ? 0.08 : 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 150, left: -60,
            child: Container(
              width: 240, height: 240,
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
              _buildSearchBar(isDark),
              _buildActiveDateBanner(isDark),
              _buildFilterBar(isDark),
              Expanded(
                child: StreamBuilder<List<TransactionModel>>(
                  stream: _transactionService.getRecentTransactions(limit: _currentLimit),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        itemCount: 6,
                        itemBuilder: (context, index) => const SkeletonLoader(
                          width: double.infinity,
                          height: 100,
                          borderRadius: 20,
                          margin: EdgeInsets.only(bottom: 16),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Error loading transactions:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }

                    final transactions = _applyFilter(snapshot.data!);

                    if (transactions.isEmpty) {
                      return Column(
                        children: [
                          _buildCategoryFilterBar(snapshot.data!, isDark),
                          Expanded(child: _buildEmptyState()),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        _buildCategoryFilterBar(snapshot.data!, isDark),
                        _buildSummaryHeader(transactions, isDark),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            physics: const BouncingScrollPhysics(),
                            itemCount: transactions.length + 1,
                            itemBuilder: (context, index) {
                              if (index == transactions.length) {
                                if (snapshot.data!.length >= _currentLimit) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: ScaleOnTap(
                                        onTap: () => setState(() => _currentLimit += 20),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: AppColors.brandPrimary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.15)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.refresh_rounded, color: AppColors.brandPrimary, size: 18),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Load More',
                                                style: GoogleFonts.outfit(color: AppColors.brandPrimary, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  return const SizedBox(height: 40);
                                }
                              }
                              return _TransactionCard(transaction: transactions[index]);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    )); // closes Scaffold + ThemeBuilder
  }

  Widget _buildSummaryHeader(List<TransactionModel> transactions, bool isDark) {
    double totalIncome = 0;
    double totalExpense = 0;
    DateTime? minDate;
    DateTime? maxDate;

    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else if (tx.type == TransactionType.others) {
        if (tx.category.contains('Taken') || tx.category.contains('Received')) {
          totalIncome += tx.amount;
        } else {
          totalExpense += tx.amount;
        }
      } else if (tx.type == TransactionType.expense) {
        totalExpense += tx.amount;
      }

      if (minDate == null || tx.date.isBefore(minDate)) {
        minDate = tx.date;
      }
      if (maxDate == null || tx.date.isAfter(maxDate)) {
        maxDate = tx.date;
      }
    }

    final double totalCombined = totalIncome + totalExpense;
    final double ratio = totalCombined > 0 ? totalIncome / totalCombined : 0.5;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: GlassCard(
        blur: 15,
        opacity: isDark ? 0.05 : 0.45,
        color: isDark ? const Color(0xFF16201D) : Colors.white,
        borderRadius: 20,
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.1)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_downward_rounded, color: AppColors.brandPrimary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'TOTAL INCOME',
                            style: GoogleFonts.outfit(
                              color: AppColors.textGrey,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '৳${totalIncome.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => "${m[1]},")}',
                        style: GoogleFonts.outfit(
                          color: AppColors.brandPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_upward_rounded, color: Colors.redAccent, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'TOTAL EXPENSE',
                            style: GoogleFonts.outfit(
                              color: AppColors.textGrey,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '৳${totalExpense.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => "${m[1]},")}',
                        style: GoogleFonts.outfit(
                          color: Colors.redAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 6,
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
                  ),
                ),
              ),
              if (minDate != null && maxDate != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_rounded, color: AppColors.textGrey, size: 11),
                    const SizedBox(width: 6),
                    Text(
                      minDate.day == maxDate.day && minDate.month == maxDate.month && minDate.year == maxDate.year
                          ? DateFormat('dd MMM yyyy').format(minDate)
                          : '${DateFormat('dd MMM yyyy').format(minDate)} - ${DateFormat('dd MMM yyyy').format(maxDate)}',
                      style: GoogleFonts.outfit(
                        color: AppColors.textGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    final isFocused = _searchFocusNode.hasFocus;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: GlassCard(
        blur: 10,
        opacity: isDark ? 0.03 : 0.45,
        color: isDark ? const Color(0xFF16201D) : Colors.white,
        borderRadius: 16,
        border: Border.all(
          color: isFocused
              ? AppColors.brandPrimary.withValues(alpha: 0.4)
              : AppColors.brandPrimary.withValues(alpha: 0.08),
          width: isFocused ? 1.5 : 1.0,
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
          decoration: InputDecoration(
            hintText: AppLocalizations.get('search_by_note_category'),
            hintStyle: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: isFocused ? AppColors.brandPrimary : AppColors.textGrey, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? ScaleOnTap(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Icon(Icons.clear_rounded, color: AppColors.textGrey, size: 18),
                  )
                : ScaleOnTap(
                    onTap: () => _showCalendarPickerOptions(context),
                    child: Icon(Icons.calendar_month_rounded, color: AppColors.brandPrimary, size: 20),
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textBlack, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  List<TransactionModel> _applyFilter(List<TransactionModel> transactions) {
    final now = DateTime.now();
    List<TransactionModel> filtered = transactions;

    // 1. Date Filter
    if (_selectedDateFilter == 'This Month') {
      filtered = filtered.where((tx) => tx.date.month == now.month && tx.date.year == now.year).toList();
    } else if (_selectedDateFilter == 'This Week') {
      final weekAgo = now.subtract(const Duration(days: 7));
      filtered = filtered.where((tx) => tx.date.isAfter(weekAgo)).toList();
    } else if (_selectedDateFilter == 'Custom') {
      if (_selectedCustomDateRange != null) {
        final startOfDay = DateTime(_selectedCustomDateRange!.start.year, _selectedCustomDateRange!.start.month, _selectedCustomDateRange!.start.day);
        final endOfDay = DateTime(_selectedCustomDateRange!.end.year, _selectedCustomDateRange!.end.month, _selectedCustomDateRange!.end.day, 23, 59, 59);
        filtered = filtered.where((tx) => tx.date.isAfter(startOfDay.subtract(const Duration(seconds: 1))) && tx.date.isBefore(endOfDay.add(const Duration(seconds: 1)))).toList();
      } else if (_selectedCustomMonth != null) {
        filtered = filtered.where((tx) => tx.date.month == _selectedCustomMonth!.month && tx.date.year == _selectedCustomMonth!.year).toList();
      }
    }

    // 2. Search query filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((tx) {
        final noteMatch = tx.note.toLowerCase().contains(_searchQuery);
        final categoryMatch = tx.category.toLowerCase().contains(_searchQuery);
        final amountMatch = tx.amount.toString().contains(_searchQuery);
        return noteMatch || categoryMatch || amountMatch;
      }).toList();
    }

    // 3. Type filter
    switch (_selectedFilter) {
      case 'Income':
        filtered = filtered.where((tx) => tx.type == TransactionType.income).toList();
        break;
      case 'Expense':
        filtered = filtered.where((tx) => tx.type == TransactionType.expense).toList();
        break;
      case 'Transfer':
        filtered = filtered.where((tx) => tx.type == TransactionType.transfer).toList();
        break;
    }

    // 4. Category filter
    if ((_selectedFilter == 'Income' || _selectedFilter == 'Expense') && _selectedCategoryFilter != 'All') {
      filtered = filtered.where((tx) => tx.category == _selectedCategoryFilter).toList();
    }

    return filtered;
  }

  Widget _buildFilterBar(bool isDark) {
    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;

          Color selectedColor;
          if (filter == 'Income') selectedColor = AppColors.brandPrimary;
          else if (filter == 'Expense') selectedColor = Colors.redAccent;
          else if (filter == 'Transfer') selectedColor = Colors.blueAccent;
          else selectedColor = AppColors.brandPrimary;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ScaleOnTap(
              onTap: () => setState(() {
                _selectedFilter = filter;
                _selectedCategoryFilter = 'All';
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [selectedColor, selectedColor.withValues(alpha: 0.85)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : (isDark ? const Color(0xFF16201D).withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? selectedColor.withValues(alpha: 0.5)
                        : AppColors.brandPrimary.withValues(alpha: 0.08),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: selectedColor.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  filter,
                  style: GoogleFonts.outfit(
                    color: isSelected ? Colors.white : AppColors.secondaryText,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilterBar(List<TransactionModel> rawTransactions, bool isDark) {
    if (_selectedFilter != 'Income' && _selectedFilter != 'Expense') {
      return const SizedBox.shrink();
    }

    final typeStr = _selectedFilter.toLowerCase();
    final typeTransactions = rawTransactions.where((tx) => tx.type.toString().split('.').last == typeStr);
    
    final List<String> categoryFilters = ['All'];
    final uniqueCategories = typeTransactions.map((tx) => tx.category).toSet().toList();
    uniqueCategories.sort();
    categoryFilters.addAll(uniqueCategories);

    if (!categoryFilters.contains(_selectedCategoryFilter)) {
      _selectedCategoryFilter = 'All';
    }

    return Container(
      height: 34,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categoryFilters.length,
        itemBuilder: (context, index) {
          final cat = categoryFilters[index];
          final isSelected = _selectedCategoryFilter == cat;
          final Color themeColor = _selectedFilter == 'Income' ? AppColors.brandPrimary : Colors.redAccent;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ScaleOnTap(
              onTap: () => setState(() => _selectedCategoryFilter = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? themeColor.withValues(alpha: 0.15)
                      : (isDark ? const Color(0xFF16201D).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isSelected
                        ? themeColor.withValues(alpha: 0.4)
                        : AppColors.brandPrimary.withValues(alpha: 0.05),
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Icon(Icons.check_rounded, color: themeColor, size: 12),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      cat,
                      style: GoogleFonts.outfit(
                        color: isSelected ? themeColor : AppColors.secondaryText,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCalendarPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF16201D) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.15)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: AppColors.textGrey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Filter Transactions',
                  style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose how you want to filter dates',
                  style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13),
                ),
                const SizedBox(height: 20),
                _buildPickerOption(
                  icon: Icons.all_inclusive_rounded,
                  title: 'Show All Time',
                  subtitle: 'Remove date filters and show all transactions',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedDateFilter = 'All Time';
                      _selectedCustomMonth = null;
                      _selectedCustomDateRange = null;
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildPickerOption(
                  icon: Icons.today_rounded,
                  title: 'This Week',
                  subtitle: 'Show transactions from the last 7 days',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedDateFilter = 'This Week';
                      _selectedCustomMonth = null;
                      _selectedCustomDateRange = null;
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildPickerOption(
                  icon: Icons.calendar_month_rounded,
                  title: 'This Month',
                  subtitle: 'Show transactions from the current month',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedDateFilter = 'This Month';
                      _selectedCustomMonth = null;
                      _selectedCustomDateRange = null;
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildPickerOption(
                  icon: Icons.calendar_view_month_rounded,
                  title: 'Select Specific Month & Year',
                  subtitle: 'Filter by any specific month (e.g. March 2026)',
                  onTap: () {
                    Navigator.pop(context);
                    _showMonthYearPicker(context);
                  },
                ),
                const SizedBox(height: 10),
                _buildPickerOption(
                  icon: Icons.date_range_rounded,
                  title: 'Select Custom Date Range',
                  subtitle: 'Choose a specific start date and end date',
                  onTap: () {
                    Navigator.pop(context);
                    _selectDateRange(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isReset = false,
  }) {
    final themeColor = isReset ? Colors.redAccent : AppColors.brandPrimary;
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: themeColor.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(icon, color: themeColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 11.5)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textGrey, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final initialRange = _selectedCustomDateRange ?? DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );

    final pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.brandPrimary,
              onPrimary: Colors.white,
              surface: AppColors.cardWhite,
              onSurface: AppColors.textBlack,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() {
        _selectedCustomDateRange = pickedRange;
        _selectedCustomMonth = null;
        _selectedDateFilter = 'Custom';
      });
    }
  }

  void _showMonthYearPicker(BuildContext context) {
    int tempYear = (_selectedCustomMonth ?? DateTime.now()).year;
    int tempMonth = (_selectedCustomMonth ?? DateTime.now()).month;
    final List<int> years = List.generate(7, (index) => DateTime.now().year - 4 + index);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF16201D) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.15)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.textGrey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 20),
                Text(
                  'Select Month & Year',
                  style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left_rounded, color: AppColors.textBlack),
                      onPressed: () {
                        if (tempYear > years.first) {
                          setModalState(() => tempYear--);
                        }
                      },
                    ),
                    Text(
                      '$tempYear',
                      style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right_rounded, color: AppColors.textBlack),
                      onPressed: () {
                        if (tempYear < years.last) {
                          setModalState(() => tempYear++);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final monthNum = index + 1;
                    final isSelected = tempMonth == monthNum;
                    final monthName = DateFormat('MMM').format(DateTime(tempYear, monthNum));

                    return ScaleOnTap(
                      onTap: () => setModalState(() => tempMonth = monthNum),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.brandPrimary : AppColors.brandPrimary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.brandPrimary : AppColors.brandPrimary.withValues(alpha: 0.1),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          monthName,
                          style: GoogleFonts.outfit(
                            color: isSelected ? Colors.white : AppColors.textBlack,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: AppColors.brandPrimary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.brandPrimary, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          final selected = DateTime(tempYear, tempMonth);
                          Navigator.pop(context);
                          setState(() {
                            _selectedCustomMonth = selected;
                            _selectedCustomDateRange = null;
                            _selectedDateFilter = 'Custom';
                          });
                        },
                        child: Text('Apply', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDateRangeLabel() {
    if (_selectedDateFilter == 'Custom') {
      if (_selectedCustomDateRange != null) {
        final startStr = DateFormat('dd MMM yyyy').format(_selectedCustomDateRange!.start);
        final endStr = DateFormat('dd MMM yyyy').format(_selectedCustomDateRange!.end);
        return '$startStr - $endStr';
      } else if (_selectedCustomMonth != null) {
        return DateFormat('MMMM yyyy').format(_selectedCustomMonth!);
      }
    } else if (_selectedDateFilter == 'This Month') {
      return 'This Month (${DateFormat('MMMM yyyy').format(DateTime.now())})';
    } else if (_selectedDateFilter == 'This Week') {
      return 'This Week';
    }
    return 'All Time';
  }

  Widget _buildActiveDateBanner(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16201D).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: AppColors.brandPrimary, size: 16),
                const SizedBox(width: 8),
                Text(
                  _getDateRangeLabel(),
                  style: GoogleFonts.outfit(
                    color: AppColors.textBlack,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            ScaleOnTap(
              onTap: () => _showCalendarPickerOptions(context),
              child: Text(
                'Change',
                style: GoogleFonts.outfit(
                  color: AppColors.brandPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brandPrimary.withValues(alpha: 0.05),
            ),
            child: Icon(Icons.receipt_long_outlined, size: 54, color: AppColors.brandPrimary.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 20),
          Text(
            'No Transactions Found',
            style: GoogleFonts.outfit(color: AppColors.primaryText, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap the add button to insert a transaction',
            style: GoogleFonts.outfit(color: AppColors.secondaryText, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatefulWidget {
  final TransactionModel transaction;
  const _TransactionCard({required this.transaction});

  @override
  State<_TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<_TransactionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bool isIncome = widget.transaction.type == TransactionType.income;
    final bool isTransfer = widget.transaction.type == TransactionType.transfer;
    final bool isOthers = widget.transaction.type == TransactionType.others;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color typeColor;
    IconData typeIcon;
    if (isIncome) {
      typeColor = AppColors.brandPrimary;
      typeIcon = Icons.arrow_downward_rounded;
    } else if (isTransfer) {
      typeColor = Colors.blueAccent;
      typeIcon = Icons.swap_horiz_rounded;
    } else if (isOthers) {
      typeColor = Colors.purpleAccent;
      typeIcon = Icons.receipt_long_rounded;
    } else {
      typeColor = Colors.redAccent;
      typeIcon = Icons.arrow_upward_rounded;
    }

    String amountPrefix = '';
    if (isIncome) {
      amountPrefix = '+';
    } else if (isOthers) {
      if (widget.transaction.category.contains('Taken') || widget.transaction.category.contains('Received')) {
        amountPrefix = '+';
      } else {
        amountPrefix = '-';
      }
    } else if (!isTransfer) {
      amountPrefix = '-';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ScaleOnTap(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: GlassCard(
          blur: 15,
          opacity: isDark ? 0.04 : 0.45,
          color: isDark ? const Color(0xFF16201D) : Colors.white,
          borderRadius: 20,
          border: Border.all(color: typeColor.withValues(alpha: 0.12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: typeColor.withValues(alpha: 0.08),
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.transaction.category,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    color: AppColors.textBlack,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accentGold.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  widget.transaction.owner.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    color: AppColors.accentGold,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                isTransfer
                                    ? Icons.swap_horiz_rounded
                                    : Icons.account_balance_wallet_rounded,
                                size: 11,
                                color: AppColors.textGrey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  isTransfer
                                      ? '${widget.transaction.accountName} → ${widget.transaction.toAccountName}'
                                      : widget.transaction.accountName,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    color: AppColors.textGrey,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$amountPrefix${widget.transaction.amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => "${m[1]},")} ৳',
                          style: GoogleFonts.outfit(
                            color: typeColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          DateFormat('dd MMM').format(widget.transaction.date),
                          style: GoogleFonts.outfit(
                            color: AppColors.textGrey,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  firstCurve: Curves.easeInOut,
                  secondCurve: Curves.easeInOut,
                  sizeCurve: Curves.easeInOut,
                  crossFadeState: _isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    children: [
                      const SizedBox(height: 12),
                      Divider(color: AppColors.brandPrimary.withValues(alpha: 0.08)),
                      const SizedBox(height: 8),
                      _buildDetailRow('Owner Split', widget.transaction.owner),
                      if (isTransfer)
                        _buildDetailRow(
                          'To Owner',
                          widget.transaction.toOwner ?? 'Self',
                        ),
                      _buildDetailRow('Tx Type', widget.transaction.type.name.toUpperCase()),
                      if (widget.transaction.note.isNotEmpty)
                        _buildDetailRow('Note', widget.transaction.note),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: AppColors.textGrey,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: AppColors.textBlack,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
