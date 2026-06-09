import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/account_model.dart';
import 'package:pocketledger/models/transaction_model.dart';
import 'package:pocketledger/services/account_service.dart';
import 'package:pocketledger/services/transaction_service.dart';
import 'package:pocketledger/core/constants/app_constants.dart';
import 'package:pocketledger/services/category_service.dart';
import 'package:pocketledger/models/category_model.dart';
import 'package:pocketledger/models/credit_card_model.dart';
import 'package:pocketledger/services/credit_card_service.dart';
import 'package:pocketledger/core/constants/app_icons.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionType initialType;
  const AddTransactionScreen({super.key, this.initialType = TransactionType.expense});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TransactionService _transactionService = TransactionService();
  final AccountService _accountService = AccountService();
  final CategoryService _categoryService = CategoryService();
  final CreditCardService _creditCardService = CreditCardService();
  
  late TransactionType _selectedType;
  AccountModel? _selectedAccount;
  AccountModel? _toAccount; // For transfers
  String _selectedOwner = AppConstants.ownerSelf;
  String _toOwner = AppConstants.ownerSelf; // For transfers
  
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedCategory;
  String? _selectedCreditCardId;
  String? _selectedCreditCardName;
  bool _isCreditCardPayment = false;
  
  bool _isLoading = false;
  final List<String> _owners = AppConstants.allowedOwners;
  bool _initializedArgs = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedArgs) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is TransactionType) {
        _selectedType = args;
      } else if (args is Map<String, dynamic>) {
        if (args['type'] is TransactionType) {
          _selectedType = args['type'] as TransactionType;
        }
        if (args['account'] is AccountModel) {
          _selectedAccount = args['account'] as AccountModel;
        }
        if (args['creditCardId'] is String) {
          _selectedCreditCardId = args['creditCardId'] as String;
        }
        if (args['creditCardName'] is String) {
          _selectedCreditCardName = args['creditCardName'] as String;
        }
        if (args['isCreditCardPayment'] is bool) {
          _isCreditCardPayment = args['isCreditCardPayment'] as bool;
        }
        if (args['category'] is String) {
          _selectedCategory = args['category'] as String;
        }
      }
      _initializedArgs = true;
    }
  }

  void _handleSave() async {
    final bool isCreditCard = _selectedType == TransactionType.expense && 
        _selectedCreditCardId != null && 
        !_isCreditCardPayment;

    if (!isCreditCard && _selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select payment source')),
      );
      return;
    }

    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter amount')),
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
          accountId: isCreditCard ? '' : _selectedAccount!.id,
          accountName: isCreditCard ? (_selectedCreditCardName ?? 'Credit Card') : _selectedAccount!.name,
          owner: isCreditCard ? 'Self' : _selectedOwner,
          amount: amount,
          type: _selectedType,
          category: _selectedCategory ?? (_selectedType == TransactionType.income ? 'Income' : 'Expense'),
          note: _noteController.text,
          date: DateTime.now(),
          userId: '', // Service handles this
          creditCardId: _selectedType == TransactionType.expense ? _selectedCreditCardId : null,
          isCreditCardPayment: _isCreditCardPayment,
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
    final Color accentColor = _selectedType == TransactionType.income 
        ? AppColors.primaryGreen 
        : (_selectedType == TransactionType.expense ? Colors.redAccent : Colors.blueAccent);

    return ThemeBuilder(builder: (context) => Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: StreamBuilder<List<AccountModel>>(
        stream: _accountService.getAccounts(),
        builder: (context, accountSnapshot) {
          if (!accountSnapshot.hasData) return Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
          final accounts = accountSnapshot.data!;

          return StreamBuilder<List<CreditCardModel>>(
            stream: _creditCardService.getCards(),
            builder: (context, cardSnapshot) {
              final cards = cardSnapshot.data ?? [];

              return Stack(
                children: [
                  Column(
                    children: [
                      // ── Premium Header ──
                      Container(
                        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 20),
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: Icon(Icons.close_rounded, color: AppColors.textBlack, size: 28),
                                ),
                                _buildTypeSwitch(),
                                const SizedBox(width: 48),
                              ],
                            ),
                            const SizedBox(height: 30),
                            _buildMassiveAmountInput(accentColor),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),

                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStepTitle('Source', 'Where is this from?'),
                              const SizedBox(height: 16),
                              _buildHorizontalPaymentSourceSelector(accounts: accounts, cards: cards),
                              
                              if (_isCreditCardPayment) ...[
                                const SizedBox(height: 24),
                                _buildStepTitle('Paying Bill For', 'Destination card'),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.credit_card_rounded, color: AppColors.error),
                                      const SizedBox(width: 12),
                                      Text(
                                        _selectedCreditCardName ?? 'Credit Card',
                                        style: GoogleFonts.outfit(
                                          color: AppColors.textBlack,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              
                              if (_selectedCreditCardId == null && !_isCreditCardPayment) ...[
                                const SizedBox(height: 32),
                                _buildStepTitle('Source Member', 'Who is sending?'),
                                const SizedBox(height: 16),
                                _buildMemberChips(isSource: true),
                              ],

                              if (_selectedType == TransactionType.transfer) ...[
                                const SizedBox(height: 32),
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
                                    child: const Icon(Icons.swap_vert_rounded, color: Colors.blueAccent, size: 24),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                _buildStepTitle('Destination', 'Where is it going?'),
                                const SizedBox(height: 16),
                                _buildHorizontalAccountSelector(accounts, isSource: false),
                                
                                const SizedBox(height: 32),
                                _buildStepTitle('Destination Member', 'Who is receiving?'),
                                const SizedBox(height: 16),
                                _buildMemberChips(isSource: false),
                              ],

                              const SizedBox(height: 32),
                              _buildStepTitle('Category', 'What kind of transaction?'),
                              const SizedBox(height: 16),
                              _buildCategoryGrid(accentColor),

                              const SizedBox(height: 32),
                              _buildStepTitle('Notes', 'Add extra details'),
                              const SizedBox(height: 16),
                              _buildNoteInput(),
                              
                              const SizedBox(height: 120),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── Confirm Button ──
                  Positioned(
                    bottom: 30, left: 24, right: 24,
                    child: _buildActionBtn(accentColor),
                  ),
                ],
              );
            },
          );
        },
      ),
    )); // closes Scaffold + ThemeBuilder
  }

  Widget _buildStepTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(subtitle, style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 12)),
      ],
    );
  }

  Widget _buildTypeSwitch() {
    if (_isCreditCardPayment) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        child: Text(
          'CARD PAYMENT',
          style: GoogleFonts.outfit(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 1,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _typeIcon(TransactionType.expense, Icons.remove_rounded, Colors.redAccent),
          _typeIcon(TransactionType.income, Icons.add_rounded, AppColors.primaryGreen),
          _typeIcon(TransactionType.transfer, Icons.swap_horiz_rounded, Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _typeIcon(TransactionType type, IconData icon, Color color) {
    bool isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedType = type;
        _selectedCategory = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: isSelected ? Colors.white : AppColors.textGrey, size: 20),
      ),
    );
  }

  Widget _buildMassiveAmountInput(Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('৳', style: GoogleFonts.outfit(color: color, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              IntrinsicWidth(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 56, fontWeight: FontWeight.bold, letterSpacing: -1),
                  cursorColor: color,
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: Color(0xFFE0E0E0)),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(_selectedType.toString().split('.').last.toUpperCase(), 
          style: GoogleFonts.outfit(color: color.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
      ],
    );
  }

  Widget _buildHorizontalAccountSelector(List<AccountModel> accounts, {bool isSource = true}) {
    final selected = isSource ? _selectedAccount : _toAccount;
    return SizedBox(
      height: 54,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: accounts.length,
        itemBuilder: (context, i) {
          final acc = accounts[i];
          final isSelected = selected?.id == acc.id;
          return GestureDetector(
            onTap: () => setState(() {
              if (isSource) _selectedAccount = acc;
              else _toAccount = acc;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryGreen : AppColors.cardWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected 
                  ? [BoxShadow(color: AppColors.primaryGreen.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))]
                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5, offset: const Offset(0, 2))],
              ),
              alignment: Alignment.center,
              child: Text(acc.name, 
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.white : AppColors.textBlack, 
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMemberChips({bool isSource = true}) {
    final selectedOwner = isSource ? _selectedOwner : _toOwner;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _owners.map((owner) {
        final isSelected = selectedOwner == owner;
        return GestureDetector(
          onTap: () => setState(() {
            if (isSource) {
              _selectedOwner = owner;
            } else {
              _toOwner = owner;
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accentGold : AppColors.cardWhite,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)],
            ),
            child: Text(owner, 
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.white : AppColors.textBlack, 
                fontWeight: FontWeight.bold,
                fontSize: 13,
              )),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryGrid(Color color) {
    if (_isCreditCardPayment) {
      final cardPaymentCategories = [
        {'name': 'Credit Card Payment', 'icon': Icons.credit_card_rounded, 'color': color},
      ];
      if (_selectedCategory != 'Credit Card Payment') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedCategory = 'Credit Card Payment';
            });
          }
        });
      }
      return _buildGrid(cardPaymentCategories, color);
    }

    if (_selectedType == TransactionType.transfer) {
      final transferCategories = [
        {'name': 'Transfer', 'icon': Icons.swap_horiz_rounded},
        {'name': 'Savings', 'icon': Icons.savings_rounded},
      ];
      return _buildGrid(transferCategories, color);
    }

    return StreamBuilder<List<CategoryModel>>(
      stream: _categoryService.getCategories(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error: ${snapshot.error}',
                style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }

        final typeStr = _selectedType == TransactionType.income ? 'income' : 'expense';
        final filtered = snapshot.data!
            .where((cat) => cat.type == typeStr)
            .toList();

        final items = filtered.map((cat) => {
          'name': cat.name,
          'icon': AppIcons.getIconFromCode(cat.iconCode),
          'color': Color(cat.colorValue),
        }).toList();

        if (items.isEmpty) {
          return Center(
            child: Text(
              'No categories found',
              style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13),
            ),
          );
        }

        // Auto-select first category if selected category is not in list
        final hasSelected = items.any((item) => item['name'] == _selectedCategory);
        if (!hasSelected && items.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedCategory = items.first['name'] as String;
              });
            }
          });
        }

        return _buildGrid(items, color);
      },
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> categories, Color color) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.1,
      ),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final cat = categories[i];
        final isSelected = (_selectedCategory ?? categories.first['name']) == cat['name'];
        final itemColor = cat['color'] as Color? ?? color;

        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat['name']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? itemColor : AppColors.cardWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isSelected 
                ? [BoxShadow(color: itemColor.withValues(alpha: 0.2), blurRadius: 8)]
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(cat['icon'] as IconData, color: isSelected ? Colors.white : itemColor.withValues(alpha: 0.8), size: 24),
                const SizedBox(height: 8),
                Text(cat['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(color: isSelected ? Colors.white : AppColors.textBlack, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoteInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: TextField(
        controller: _noteController,
        style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Add a note...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: InputBorder.none,
          icon: Icon(Icons.sticky_note_2_rounded, color: AppColors.primaryGreen.withValues(alpha: 0.5), size: 20),
        ),
      ),
    );
  }

  Widget _buildActionBtn(Color color) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : Text('Save Transaction', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHorizontalPaymentSourceSelector({
    required List<AccountModel> accounts,
    required List<CreditCardModel> cards,
    bool isSource = true,
  }) {
    if (_selectedType != TransactionType.expense || !isSource || _isCreditCardPayment) {
      return _buildHorizontalAccountSelector(accounts, isSource: isSource);
    }

    final int totalCount = accounts.length + cards.length;
    return SizedBox(
      height: 54,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: totalCount,
        itemBuilder: (context, i) {
          if (i < accounts.length) {
            final acc = accounts[i];
            final isSelected = _selectedAccount?.id == acc.id && _selectedCreditCardId == null;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedAccount = acc;
                _selectedCreditCardId = null;
                _selectedCreditCardName = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryGreen : AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected 
                    ? [BoxShadow(color: AppColors.primaryGreen.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))]
                    : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5, offset: const Offset(0, 2))],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      color: isSelected ? Colors.white : AppColors.primaryGreen.withValues(alpha: 0.7),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(acc.name, 
                      style: GoogleFonts.outfit(
                        color: isSelected ? Colors.white : AppColors.textBlack, 
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      )),
                  ],
                ),
              ),
            );
          } else {
            final card = cards[i - accounts.length];
            final isSelected = _selectedCreditCardId == card.id;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedCreditCardId = card.id;
                _selectedCreditCardName = '${card.bankName} ${card.cardNickname}';
                _selectedAccount = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.error : AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected 
                    ? [BoxShadow(color: AppColors.error.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))]
                    : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5, offset: const Offset(0, 2))],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.credit_card_rounded,
                      color: isSelected ? Colors.white : AppColors.error.withValues(alpha: 0.7),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text('${card.bankName} (${card.lastFourDigits})', 
                      style: GoogleFonts.outfit(
                        color: isSelected ? Colors.white : AppColors.textBlack, 
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      )),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
