import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/account_model.dart';
import 'package:pocketledger/models/transaction_model.dart';
import 'package:pocketledger/services/account_service.dart';
import 'package:pocketledger/services/transaction_service.dart';
import 'package:pocketledger/features/auth/widgets/custom_text_field.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionType initialType;
  const AddTransactionScreen({super.key, this.initialType = TransactionType.expense});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TransactionService _transactionService = TransactionService();
  final AccountService _accountService = AccountService();
  
  late TransactionType _selectedType;
  AccountModel? _selectedAccount;
  AccountModel? _toAccount; // For transfers
  String _selectedOwner = 'Self';
  String _toOwner = 'Self'; // For transfers
  
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedCategory;
  
  bool _isLoading = false;
  final List<String> _owners = ['Self', 'Father', 'Mother', 'Others'];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  void _handleSave() async {
    if (_selectedAccount == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select account and enter amount')),
      );
      return;
    }

    if (_selectedType == TransactionType.transfer && _toAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select destination account')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      
      if (_selectedType == TransactionType.transfer) {
        await _transactionService.addTransfer(
          fromAccountId: _selectedAccount!.id,
          fromAccountName: _selectedAccount!.name,
          fromOwner: _selectedOwner,
          toAccountId: _toAccount!.id,
          toAccountName: _toAccount!.name,
          toOwner: _toOwner,
          amount: amount,
          note: _noteController.text,
          category: _selectedCategory ?? 'Transfer',
        );
      } else {
        final transaction = TransactionModel(
          id: '',
          accountId: _selectedAccount!.id,
          accountName: _selectedAccount!.name,
          owner: _selectedOwner,
          amount: amount,
          type: _selectedType,
          category: _selectedCategory ?? (_selectedType == TransactionType.income ? 'Income' : 'Expense'),
          note: _noteController.text,
          date: DateTime.now(),
          userId: '', // Service handles this
        );
        await _transactionService.addTransaction(transaction);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.primaryText, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('New Record', style: GoogleFonts.montserrat(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<AccountModel>>(
        stream: _accountService.getAccounts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
          final accounts = snapshot.data!;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildTypeSelector(),
                const SizedBox(height: 40),
                
                Text('AMOUNT', style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                _buildAmountInput(),
                
                const SizedBox(height: 48),
                _buildSectionLabel(_selectedType == TransactionType.transfer ? 'FROM ACCOUNT' : 'ACCOUNT'),
                const SizedBox(height: 12),
                _buildAccountDropdown(accounts, isSource: true),
                
                const SizedBox(height: 24),
                _buildSectionLabel(_selectedType == TransactionType.transfer ? 'FROM OWNER' : 'OWNER'),
                const SizedBox(height: 12),
                _buildOwnerDropdown(isSource: true),

                if (_selectedType == TransactionType.transfer) ...[
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.brandPrimary.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_downward_rounded, color: AppColors.brandPrimary, size: 28),
                  ),
                  const SizedBox(height: 32),
                  
                  _buildSectionLabel('TO ACCOUNT'),
                  const SizedBox(height: 12),
                  _buildAccountDropdown(accounts, isSource: false),
                  
                  const SizedBox(height: 24),
                  _buildSectionLabel('TO OWNER'),
                  const SizedBox(height: 12),
                  _buildOwnerDropdown(isSource: false),
                ],

                const SizedBox(height: 36),
                _buildSectionLabel('CATEGORY'),
                const SizedBox(height: 12),
                _buildCategoryDropdown(),

                const SizedBox(height: 24),
                _buildSectionLabel('DETAILS'),
                const SizedBox(height: 12),
                _buildDetailsInputs(),

                const SizedBox(height: 48),
                _buildSaveButton(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label, 
        style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          _typeButton(TransactionType.expense, 'Expense'),
          _typeButton(TransactionType.income, 'Income'),
          _typeButton(TransactionType.transfer, 'Transfer'),
        ],
      ),
    );
  }

  Widget _typeButton(TransactionType type, String label) {
    bool isSelected = _selectedType == type;
    Color activeColor = AppColors.brandPrimary;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            _selectedCategory = null; // Reset category when type changes
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected ? [BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
          ),
          child: Text(label, 
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: isSelected ? Colors.white : AppColors.secondaryText,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            )),
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    Color activeColor = AppColors.brandPrimary;

    return IntrinsicWidth(
      child: TextField(
        controller: _amountController,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: GoogleFonts.montserrat(fontSize: 54, fontWeight: FontWeight.bold, color: AppColors.primaryText),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: '0',
          hintStyle: TextStyle(color: AppColors.secondaryText.withOpacity(0.3)),
          prefixText: '৳ ',
          prefixStyle: TextStyle(color: activeColor, fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAccountDropdown(List<AccountModel> accounts, {required bool isSource}) {
    final value = isSource ? _selectedAccount : _toAccount;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AccountModel>(
          value: value != null && accounts.any((a) => a.id == value.id) 
              ? accounts.firstWhere((a) => a.id == value.id) 
              : null,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.secondaryText),
          hint: Text('Select Account', style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 15)),
          items: accounts.map((acc) => DropdownMenuItem(
            value: acc,
            child: Text(acc.name, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 16)),
          )).toList(),
          onChanged: (val) => setState(() {
            if (isSource) _selectedAccount = val;
            else _toAccount = val;
          }),
        ),
      ),
    );
  }

  Widget _buildOwnerDropdown({required bool isSource}) {
    final value = isSource ? _selectedOwner : _toOwner;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.secondaryText),
          items: _owners.map((owner) => DropdownMenuItem(
            value: owner,
            child: Text(owner, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 16)),
          )).toList(),
          onChanged: (val) => setState(() {
            if (isSource) _selectedOwner = val!;
            else _toOwner = val!;
          }),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    List<String> categories = [];
    if (_selectedType == TransactionType.income) {
      categories = ['Income', 'Salary', 'Business', 'Other Income'];
    } else if (_selectedType == TransactionType.expense) {
      categories = ['Expense', 'Home', 'Wife Expense', 'My Expense', 'Other Expense'];
    } else {
      categories = ['Transfer', 'Monthly Savings', 'Other Transfer'];
    }

    // Ensure the selected category is valid for the current type
    if (_selectedCategory != null && !categories.contains(_selectedCategory)) {
      _selectedCategory = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory ?? categories.first,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.secondaryText),
          items: categories.map((cat) => DropdownMenuItem(
            value: cat,
            child: Text(cat, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 16)),
          )).toList(),
          onChanged: (val) => setState(() => _selectedCategory = val),
        ),
      ),
    );
  }

  Widget _buildDetailsInputs() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          CustomTextField(
            controller: _noteController,
            hintText: 'Note (optional)',
            icon: Icons.notes_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    Color activeColor = AppColors.brandPrimary;
                      
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: activeColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : Text('Save Record', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5)),
      ),
    );
  }
}
