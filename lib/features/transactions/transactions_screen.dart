import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/transaction_model.dart';
import 'package:pocketledger/services/transaction_service.dart';
import 'package:pocketledger/core/widgets/skeleton_loader.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionService _transactionService = TransactionService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Income', 'Expense', 'Transfer', 'This Month', 'This Week'];
  int _currentLimit = 20; // Start with 20 items

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Transactions', style: GoogleFonts.montserrat(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_rounded, color: AppColors.brandPrimary, size: 30),
            onPressed: () => Navigator.pushNamed(context, '/add-transaction'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterBar(),
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
                      child: Text('Error loading transactions:\n${snapshot.error}', 
                        textAlign: TextAlign.center, 
                        style: const TextStyle(color: Colors.redAccent)),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final transactions = _applyFilter(snapshot.data!);

                if (transactions.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  physics: const BouncingScrollPhysics(),
                  itemCount: transactions.length + 1, // +1 for the Load More button
                  itemBuilder: (context, index) {
                    if (index == transactions.length) {
                      // Only show load more if we haven't filtered heavily
                      // and we are actually hitting the limit
                      if (snapshot.data!.length >= _currentLimit) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: TextButton.icon(
                              onPressed: () => setState(() => _currentLimit += 20),
                              icon: Icon(Icons.refresh_rounded, color: AppColors.brandPrimary),
                              label: Text('Load More', style: GoogleFonts.montserrat(color: AppColors.brandPrimary, fontWeight: FontWeight.bold)),
                              style: TextButton.styleFrom(
                                backgroundColor: AppColors.brandPrimary.withOpacity(0.1),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ),
                        );
                      } else {
                        return const SizedBox(height: 40); // Bottom padding
                      }
                    }
                    return _TransactionCard(transaction: transactions[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search by note, category, or amount...',
            hintStyle: GoogleFonts.montserrat(color: AppColors.textGrey, fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: AppColors.textGrey),
            suffixIcon: _searchQuery.isNotEmpty 
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: AppColors.textGrey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  List<TransactionModel> _applyFilter(List<TransactionModel> transactions) {
    final now = DateTime.now();
    
    // 1. First apply text search if it exists
    List<TransactionModel> filtered = transactions;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((tx) {
        final noteMatch = tx.note.toLowerCase().contains(_searchQuery);
        final categoryMatch = tx.category.toLowerCase().contains(_searchQuery);
        final amountMatch = tx.amount.toString().contains(_searchQuery);
        return noteMatch || categoryMatch || amountMatch;
      }).toList();
    }

    // 2. Then apply the chip filter
    switch (_selectedFilter) {
      case 'Income':
        return filtered.where((tx) => tx.type == TransactionType.income).toList();
      case 'Expense':
        return filtered.where((tx) => tx.type == TransactionType.expense).toList();
      case 'Transfer':
        return filtered.where((tx) => tx.type == TransactionType.transfer).toList();
      case 'This Month':
        return filtered.where((tx) => tx.date.month == now.month && tx.date.year == now.year).toList();
      case 'This Week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return filtered.where((tx) => tx.date.isAfter(weekAgo)).toList();
      default:
        return filtered;
    }
  }

  Widget _buildFilterBar() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brandPrimary : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? AppColors.brandPrimary : AppColors.brandPrimary.withOpacity(0.1),
                ),
                boxShadow: isSelected 
                  ? [BoxShadow(color: AppColors.brandPrimary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] 
                  : [],
              ),
              child: Text(
                filter,
                style: GoogleFonts.montserrat(
                  color: isSelected ? Colors.white : AppColors.secondaryText,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: AppColors.secondaryText.withOpacity(0.2)),
          const SizedBox(height: 24),
          Text('No Transactions Found', style: GoogleFonts.montserrat(color: AppColors.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Tap + to add a new record', style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 13)),
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
    
    Color typeColor;
    if (isIncome) typeColor = AppColors.brandPrimary;
    else if (isTransfer) typeColor = Colors.blue;
    else if (isOthers) typeColor = Colors.purpleAccent;
    else typeColor = Colors.redAccent;

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

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: typeColor.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left color indicator
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.transaction.category,
                              style: GoogleFonts.montserrat(color: AppColors.primaryText, fontSize: 16, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$amountPrefix${widget.transaction.amount.toInt()} Tk',
                            style: GoogleFonts.montserrat(color: typeColor, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(isTransfer ? Icons.swap_horiz_rounded : Icons.account_balance_wallet_rounded, size: 14, color: AppColors.secondaryText),
                              const SizedBox(width: 4),
                              Text(
                                isTransfer ? '${widget.transaction.accountName} → ${widget.transaction.toAccountName}' : widget.transaction.accountName,
                                style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          Text(
                            DateFormat('dd MMM').format(widget.transaction.date),
                            style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 12),
                          ),
                        ],
                      ),
                      
                      // Expandable Details
                      if (_isExpanded) ...[
                        const SizedBox(height: 16),
                        Divider(color: AppColors.secondaryText.withOpacity(0.1)),
                        const SizedBox(height: 16),
                        _buildDetailRow('Owner', widget.transaction.owner),
                        if (isTransfer) _buildDetailRow('To Owner', widget.transaction.toOwner ?? 'Unknown'),
                        _buildDetailRow('Type', widget.transaction.type.name.toUpperCase()),
                        if (widget.transaction.note.isNotEmpty) _buildDetailRow('Note', widget.transaction.note),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(value, style: GoogleFonts.montserrat(color: AppColors.primaryText, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
