import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/loan_model.dart';
import 'package:pocketledger/services/loan_service.dart';
import 'package:pocketledger/models/account_model.dart';
import 'package:pocketledger/services/account_service.dart';
import 'package:pocketledger/features/auth/widgets/custom_text_field.dart';
import 'package:pocketledger/core/constants/app_constants.dart';

class LoanDetailScreen extends StatefulWidget {
  final LoanModel loan;
  const LoanDetailScreen({super.key, required this.loan});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  final LoanService _loanService = LoanService();
  final AccountService _accountService = AccountService();
  
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  AccountModel? _sourceAccount;
  String _sourceOwner = AppConstants.ownerSelf;
  AccountModel? _destAccount;
  String _destOwner = AppConstants.ownerMother;
  bool _trackDestination = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final allowedOwners = AppConstants.allowedOwners;
    
    if (widget.loan.type == LoanType.taken) {
      // I am repaying money TO them
      if (allowedOwners.contains(widget.loan.personName)) {
        _destOwner = widget.loan.personName;
      } else {
        _destOwner = AppConstants.ownerOther;
      }
      _sourceOwner = AppConstants.ownerSelf;
    } else {
      // They are returning money TO me
      _destOwner = AppConstants.ownerSelf;
      if (allowedOwners.contains(widget.loan.personName)) {
        _sourceOwner = widget.loan.personName;
      } else {
        _sourceOwner = AppConstants.ownerOther;
      }
    }
    
    _trackDestination = true;
  }

  void _handleAddPayment() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an amount')));
      return;
    }

    final paymentAmount = double.tryParse(_amountController.text) ?? 0;
    if (paymentAmount <= 0) return;

    if (paymentAmount > widget.loan.remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment cannot exceed remaining balance')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _loanService.addRepayment(
        loanId: widget.loan.id,
        paymentAmount: paymentAmount,
        sourceAccountId: _sourceAccount?.id,
        sourceAccountName: _sourceAccount?.name,
        sourceOwner: _sourceOwner,
        destAccountId: _trackDestination ? _destAccount?.id : null,
        destAccountName: _trackDestination ? _destAccount?.name : null,
        destOwner: _trackDestination ? _destOwner : null,
        note: _noteController.text,
      );

      if (mounted) {
        Navigator.pop(context); // Close modal
        Navigator.pop(context); // Close detail screen
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddPaymentModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPaymentModal(),
    );
  }

  Widget _buildPaymentModal() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 32, left: 24, right: 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: StreamBuilder<List<AccountModel>>(
        stream: _accountService.getAccounts(),
        builder: (context, snapshot) {
          final accounts = snapshot.data ?? [];
          final isGiven = widget.loan.type == LoanType.given;
          
          return StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isGiven ? 'Receive from ${widget.loan.personName}' : 'Repay to ${widget.loan.personName}', 
                      style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryText)
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isGiven ? 'Money will be added to your account' : 'Record where the money is moving',
                      style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.secondaryText)
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _amountController,
                      hintText: 'Amount (Max: ${widget.loan.remainingAmount.toInt()})',
                      icon: Icons.attach_money_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    if (isGiven)
                      Container(
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.brandPrimary.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('GIVEN BY', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondaryText, letterSpacing: 1)),
                            const SizedBox(height: 12),
                            Text(widget.loan.personName, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryText)),
                          ],
                        ),
                      )
                    else
                      _buildFlowSection(
                        label: 'REPAY FROM (MY POCKET)',
                        account: _sourceAccount,
                        owner: _sourceOwner,
                        accounts: accounts,
                        onAccountChanged: (val) => setModalState(() => _sourceAccount = val),
                        onOwnerChanged: (val) => setModalState(() => _sourceOwner = val ?? AppConstants.ownerSelf),
                      ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isGiven ? 'Add to my App Account?' : 'Return to an App Account?', 
                            style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryText)
                          ),
                          Switch(
                            value: _trackDestination,
                            activeColor: AppColors.brandPrimary,
                            onChanged: (val) => setModalState(() => _trackDestination = val),
                          ),
                        ],
                      ),
                    ),
                    if (_trackDestination) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Icon(Icons.arrow_downward_rounded, color: AppColors.brandPrimary),
                      ),
                      _buildFlowSection(
                        label: isGiven ? 'RECEIVE INTO (MY POCKET)' : 'RETURN TO (THEIR POCKET)',
                        account: _destAccount,
                        owner: _destOwner,
                        accounts: accounts,
                        onAccountChanged: (val) => setModalState(() => _destAccount = val),
                        onOwnerChanged: (val) => setModalState(() => _destOwner = val ?? AppConstants.ownerSelf),
                      ),
                    ],
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _noteController,
                      hintText: 'Note (Optional)',
                      icon: Icons.notes_rounded,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () {
                          if (_sourceAccount == null && !isGiven) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select source account')));
                            return;
                          }
                          _handleAddPayment();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text('Confirm Transaction', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFlowSection({
    required String label,
    required AccountModel? account,
    required String owner,
    required List<AccountModel> accounts,
    required Function(AccountModel?) onAccountChanged,
    required Function(String?) onOwnerChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondaryText, letterSpacing: 1)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AccountModel>(
                    value: account != null && accounts.any((a) => a.id == account.id) 
                        ? accounts.firstWhere((a) => a.id == account.id) 
                        : null,
                    isExpanded: true,
                    hint: Text('None (Outside App)', style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.secondaryText)),
                    items: [
                      const DropdownMenuItem<AccountModel>(
                        value: null,
                        child: Text('None (Outside App)', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                      ),
                      ...accounts.map((acc) => DropdownMenuItem(
                        value: acc,
                        child: Text(acc.name, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
                      )),
                    ],
                    onChanged: onAccountChanged,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: owner,
                    isExpanded: true,
                    items: AppConstants.allowedOwners.map((o) => DropdownMenuItem(
                      value: o,
                      child: Text(o, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.brandPrimary)),
                    )).toList(),
                    onChanged: onOwnerChanged,
                  ),
                ),
              ),
            ],
          ),
          if (account != null) ...[
            const SizedBox(height: 8),
            Text('Current: ৳${account.breakdown[owner]?.toInt() ?? 0}', style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.secondaryText)),
          ]
        ],
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
        title: Text('Loan Details', style: GoogleFonts.montserrat(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: () => _showDeleteConfirmation(
              title: 'Delete Loan?',
              content: 'This will revert all balances and delete this loan forever.',
              onConfirm: _handleDeleteLoan,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          children: [
            _buildMainCard(),
            const SizedBox(height: 32),
            _buildRepaymentsList(),
          ],
        ),
      ),
      bottomNavigationBar: widget.loan.status == LoanStatus.pending ? _buildBottomBar() : null,
    );
  }

  void _showDeleteConfirmation({required String title, required String content, required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        content: Text(content, style: GoogleFonts.montserrat(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            }, 
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _handleDeleteLoan() async {
    setState(() => _isLoading = true);
    try {
      await _loanService.deleteLoan(widget.loan);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleDeleteRepayment(RepaymentModel repayment) async {
    setState(() => _isLoading = true);
    try {
      await _loanService.deleteRepayment(widget.loan.id, repayment);
      // Detail screen will refresh automatically via stream on parent, 
      // but since we are on the detail screen, we might need to pop or listen to stream
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildMainCard() {
    final isPaid = widget.loan.status == LoanStatus.paid;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))],
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.loan.personName, style: GoogleFonts.montserrat(color: AppColors.primaryText, fontSize: 24, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isPaid ? AppColors.brandPrimary.withOpacity(0.1) : Colors.orangeAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(isPaid ? 'PAID' : 'PENDING', 
                  style: GoogleFonts.montserrat(
                    color: isPaid ? AppColors.brandPrimary : Colors.orangeAccent, 
                    fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1,
                  )
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(widget.loan.type == LoanType.given ? 'Money you gave' : 'Money you took', 
              style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 13)),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statColumn('Total Amount', widget.loan.amount, AppColors.primaryText),
              _statColumn('Paid Back', widget.loan.amount - widget.loan.remainingAmount, AppColors.brandPrimary),
              _statColumn('Remaining', widget.loan.remainingAmount, widget.loan.remainingAmount > 0 ? Colors.redAccent : AppColors.brandPrimary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('৳ ${value.toInt()}', style: GoogleFonts.montserrat(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRepaymentsList() {
    if (widget.loan.repayments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text('No repayments yet.', style: GoogleFonts.montserrat(color: AppColors.secondaryText)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Repayment History', style: GoogleFonts.montserrat(color: AppColors.primaryText, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...widget.loan.repayments.map((rep) => Container(
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
                    Text('Payment', style: GoogleFonts.montserrat(color: AppColors.primaryText, fontWeight: FontWeight.w600)),
                    Text('${rep.date.day}/${rep.date.month}/${rep.date.year}', style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 12)),
                    if (rep.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(rep.note, style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 11)),
                    ]
                  ],
                ),
              ),
              Row(
                children: [
                  Text('৳ ${rep.amount.toInt()}', style: GoogleFonts.montserrat(color: AppColors.brandPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 20),
                    onPressed: () => _showDeleteConfirmation(
                      title: 'Delete Payment?',
                      content: 'This will restore the loan balance and revert account changes.',
                      onConfirm: () => _handleDeleteRepayment(rep),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: _showAddPaymentModal,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text('Add Payment', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        ),
      ),
    );
  }
}
