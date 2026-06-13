import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/credit_card_model.dart';
import 'package:pocketledger/services/credit_card_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddCreditCardScreen extends StatefulWidget {
  final CreditCardModel? existingCard;

  const AddCreditCardScreen({Key? key, this.existingCard}) : super(key: key);

  @override
  State<AddCreditCardScreen> createState() => _AddCreditCardScreenState();
}

class _AddCreditCardScreenState extends State<AddCreditCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardService = CreditCardService();

  late TextEditingController _nicknameController;
  late TextEditingController _bankController;
  late TextEditingController _lastFourController;
  late TextEditingController _limitController;
  late TextEditingController _balanceController;
  late TextEditingController _aprController;
  late TextEditingController _closingDayController;
  late TextEditingController _dueDaysController;

  String _selectedNetwork = 'visa';
  int _selectedColorIndex = 0;
  String _selectedInterestType = 'apr';
  bool _isLoading = false;

  final List<String> _networks = ['visa', 'mastercard', 'amex', 'discover'];

  static const List<List<Color>> cardGradients = [
    [Color(0xFF2C3E50), Color(0xFF000000)], // Premium Black
    [Color(0xFF134E5E), Color(0xFF71B280)], // Greenish
    [Color(0xFF4B1248), Color(0xFFF0C27B)], // Gold Purple
    [Color(0xFF141E30), Color(0xFF243B55)], // Deep Blue
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.existingCard;
    _nicknameController = TextEditingController(text: c?.cardNickname ?? '');
    _bankController = TextEditingController(text: c?.bankName ?? '');
    _lastFourController = TextEditingController(text: c?.lastFourDigits ?? '');
    _limitController = TextEditingController(text: c != null ? c.creditLimit.toString() : '');
    _balanceController = TextEditingController(text: c != null ? c.outstandingBalance.toString() : '');
    _aprController = TextEditingController(text: c != null ? c.apr.toString() : '');
    _closingDayController = TextEditingController(text: c != null ? c.statementClosingDay.toString() : '25');
    _dueDaysController = TextEditingController(text: c != null ? c.paymentDueDays.toString() : '15');
    
    _selectedNetwork = c?.cardNetwork ?? 'visa';
    _selectedColorIndex = c?.cardColorIndex ?? 0;
    _selectedInterestType = c?.interestType ?? 'apr';

    _nicknameController.addListener(_updatePreview);
    _bankController.addListener(_updatePreview);
    _lastFourController.addListener(_updatePreview);
  }

  void _updatePreview() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nicknameController.removeListener(_updatePreview);
    _bankController.removeListener(_updatePreview);
    _lastFourController.removeListener(_updatePreview);

    _nicknameController.dispose();
    _bankController.dispose();
    _lastFourController.dispose();
    _limitController.dispose();
    _balanceController.dispose();
    _aprController.dispose();
    _closingDayController.dispose();
    _dueDaysController.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final card = CreditCardModel(
        id: widget.existingCard?.id ?? '',
        userId: userId,
        cardNickname: _nicknameController.text.trim(),
        bankName: _bankController.text.trim(),
        lastFourDigits: _lastFourController.text.trim(),
        cardNetwork: _selectedNetwork,
        creditLimit: double.tryParse(_limitController.text) ?? 0,
        outstandingBalance: double.tryParse(_balanceController.text) ?? 0,
        statementClosingDay: int.tryParse(_closingDayController.text) ?? 25,
        paymentDueDays: int.tryParse(_dueDaysController.text) ?? 15,
        apr: double.tryParse(_aprController.text) ?? 0,
        interestType: _selectedInterestType,
        cardColorIndex: _selectedColorIndex,
        createdAt: widget.existingCard?.createdAt ?? DateTime.now(),
      );

      if (widget.existingCard == null) {
        await _cardService.addCard(card);
      } else {
        await _cardService.updateCard(card);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine Bottom Sheet specific padding based on keyboard
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
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
              const SizedBox(height: 16),
              Text(
                widget.existingCard == null ? 'Add Credit Card' : 'Edit Credit Card',
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textBlack),
              ),
              const SizedBox(height: 16),
              _buildCardPreview(),
              const SizedBox(height: 24),

              _buildTextField('Card Nickname', _nicknameController, icon: Icons.label),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(child: _buildTextField('Bank Name', _bankController, icon: Icons.account_balance)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField('Last 4 Digits', _lastFourController, 
                      icon: Icons.numbers, 
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(child: _buildTextField('Credit Limit', _limitController, icon: Icons.money, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Current Balance', _balanceController, icon: Icons.account_balance_wallet, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(child: _buildTextField('Closing Day (1-28)', _closingDayController, icon: Icons.calendar_today, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Due in Days', _dueDaysController, icon: Icons.timer, keyboardType: TextInputType.number)),
                ],
              ),
               Text('Interest Rate Type', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text('APR %', style: TextStyle(color: _selectedInterestType == 'apr' ? Colors.white : AppColors.textBlack)),
                    selected: _selectedInterestType == 'apr',
                    selectedColor: AppColors.primaryGreen,
                    backgroundColor: AppColors.cardWhite,
                    onSelected: (val) => setState(() => _selectedInterestType = 'apr'),
                  ),
                  ChoiceChip(
                    label: Text('Monthly Flat %', style: TextStyle(color: _selectedInterestType == 'monthly_flat' ? Colors.white : AppColors.textBlack)),
                    selected: _selectedInterestType == 'monthly_flat',
                    selectedColor: AppColors.primaryGreen,
                    backgroundColor: AppColors.cardWhite,
                    onSelected: (val) => setState(() => _selectedInterestType = 'monthly_flat'),
                  ),
                  ChoiceChip(
                    label: Text('Annual Flat %', style: TextStyle(color: _selectedInterestType == 'annual_flat' ? Colors.white : AppColors.textBlack)),
                    selected: _selectedInterestType == 'annual_flat',
                    selectedColor: AppColors.primaryGreen,
                    backgroundColor: AppColors.cardWhite,
                    onSelected: (val) => setState(() => _selectedInterestType = 'annual_flat'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _selectedInterestType == 'apr'
                    ? 'Interest Rate (APR %)'
                    : _selectedInterestType == 'monthly_flat'
                        ? 'Monthly Flat Rate (%)'
                        : 'Annual Flat Rate (%)',
                _aprController,
                icon: Icons.percent,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              Text('Card Network', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _networks.map((net) {
                  final isSelected = _selectedNetwork == net;
                  return ChoiceChip(
                    label: Text(net.toUpperCase(), style: TextStyle(color: isSelected ? Colors.white : AppColors.textBlack)),
                    selected: isSelected,
                    selectedColor: AppColors.primaryGreen,
                    backgroundColor: AppColors.cardWhite,
                    onSelected: (val) => setState(() => _selectedNetwork = net),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              Text('Card Color Theme', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(4, (index) {
                  final isSelected = _selectedColorIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorIndex = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getColorForIndex(index),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          'Save Card',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

   Widget _buildCardPreview() {
    final gradient = cardGradients[_selectedColorIndex % cardGradients.length];
    final bank = _bankController.text.isEmpty ? 'Bank Name' : _bankController.text;
    final nickname = _nicknameController.text.isEmpty ? 'Card Nickname' : _nicknameController.text;
    final lastFour = _lastFourController.text.isEmpty ? '••••' : _lastFourController.text;
    
    return Container(
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [
          BoxShadow(color: gradient[0].withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.credit_card, size: 130, color: Colors.white.withValues(alpha: 0.05)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(bank, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Icon(
                    _selectedNetwork.toLowerCase() == 'visa'
                        ? Icons.payment
                        : Icons.credit_card,
                    color: Colors.white,
                    size: 26,
                  ),
                ],
              ),
              const Spacer(),
              Text(nickname, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text('•••• •••• •••• $lastFour', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, letterSpacing: 2, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColorForIndex(int index) {
    switch (index) {
      case 0: return const Color(0xFF2C3E50);
      case 1: return const Color(0xFF134E5E);
      case 2: return const Color(0xFF4B1248);
      case 3: return const Color(0xFF141E30);
      default: return const Color(0xFF2C3E50);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {IconData? icon, TextInputType keyboardType = TextInputType.text, int? maxLength}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13),
        prefixIcon: icon != null ? Icon(icon, color: AppColors.primaryGreen, size: 20) : null,
        filled: true,
        fillColor: AppColors.pageBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textGrey.withValues(alpha: 0.1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryGreen, width: 1.5),
        ),
        counterText: '',
      ),
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
    );
  }
}
