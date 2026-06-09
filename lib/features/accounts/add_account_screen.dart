import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/services/account_service.dart';
import 'package:pocketledger/features/auth/widgets/custom_text_field.dart';
import 'package:pocketledger/core/constants/app_constants.dart';
import 'package:pocketledger/core/widgets/scale_on_tap.dart';
import 'package:pocketledger/core/widgets/glass_card.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final AccountService _accountService = AccountService();
  
  final _nameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _branchNameController = TextEditingController();
  final _routingNumberController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  
  String _selectedType = 'Bank';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _ownerBalances = [
    {'owner': AppConstants.ownerSelf, 'controller': TextEditingController(text: '0')}
  ];

  final List<String> _owners = AppConstants.allowedOwners;

  final Map<String, IconData> _typeIcons = {
    'Bank': Icons.account_balance_outlined,
    'MFS': Icons.phone_android_outlined,
    'Cash': Icons.payments_outlined,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _accountNumberController.dispose();
    _cardNumberController.dispose();
    _branchNameController.dispose();
    _routingNumberController.dispose();
    _mobileNumberController.dispose();
    for (var row in _ownerBalances) {
      row['controller'].dispose();
    }
    super.dispose();
  }

  void _addOwnerRow() {
    if (_ownerBalances.length < _owners.length) {
      setState(() {
        _ownerBalances.add({
          'owner': _owners.firstWhere((o) => !_ownerBalances.any((ob) => ob['owner'] == o)),
          'controller': TextEditingController(text: '0')
        });
      });
    }
  }

  void _removeOwnerRow(int index) {
    if (_ownerBalances.length > 1) {
      setState(() {
        _ownerBalances.removeAt(index);
      });
    }
  }

  void _handleCreate() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter account name')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final Map<String, double> breakdown = {};
      for (var row in _ownerBalances) {
        final balance = double.tryParse(row['controller'].text) ?? 0;
        if (balance >= 0) {
          breakdown[row['owner']] = balance;
        }
      }

      await _accountService.createAccount(
        name: _nameController.text,
        type: _selectedType,
        breakdown: breakdown,
        accountNumber: _selectedType == 'Bank' && _accountNumberController.text.isNotEmpty ? _accountNumberController.text : null,
        cardNumber: _selectedType == 'Bank' && _cardNumberController.text.isNotEmpty ? _cardNumberController.text : null,
        branchName: _selectedType == 'Bank' && _branchNameController.text.isNotEmpty ? _branchNameController.text : null,
        routingNumber: _selectedType == 'Bank' && _routingNumberController.text.isNotEmpty ? _routingNumberController.text : null,
        mobileNumber: _selectedType == 'MFS' && _mobileNumberController.text.isNotEmpty ? _mobileNumberController.text : null,
      );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ThemeBuilder(builder: (context) => Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: ScaleOnTap(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(Icons.close, color: AppColors.primaryText, size: 24),
          ),
        ),
        title: Text(
          'New Account',
          style: GoogleFonts.outfit(
            color: AppColors.primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Blobs
          Positioned(
            top: 40, left: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandPrimary.withValues(alpha: isDark ? 0.08 : 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 80, right: -40,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentGold.withValues(alpha: isDark ? 0.06 : 0.04),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('CHOOSE ACCOUNT TYPE'),
                const SizedBox(height: 16),
                Row(
                  children: _typeIcons.entries.map((entry) => _buildTypeCard(entry.key, entry.value)).toList(),
                ),
                
                const SizedBox(height: 32),
                _buildSectionHeader('ACCOUNT NAME'),
                const SizedBox(height: 16),
                GlassCard(
                  blur: 15,
                  opacity: isDark ? 0.03 : 0.45,
                  color: isDark ? const Color(0xFF16201D) : Colors.white,
                  borderRadius: 24,
                  border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.05)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CustomTextField(
                      controller: _nameController,
                      hintText: 'e.g. DBBL, bKash, My Wallet',
                      icon: Icons.edit_note_outlined,
                    ),
                  ),
                ),

                // Optional bank card / mobile wallet details
                if (_selectedType == 'Bank' || _selectedType == 'MFS') ...[
                  const SizedBox(height: 32),
                  _buildSectionHeader(_selectedType == 'Bank' ? 'BANK ACCOUNT DETAILS (OPTIONAL)' : 'MOBILE WALLET DETAILS (OPTIONAL)'),
                  const SizedBox(height: 16),
                  GlassCard(
                    blur: 15,
                    opacity: isDark ? 0.03 : 0.45,
                    color: isDark ? const Color(0xFF16201D) : Colors.white,
                    borderRadius: 24,
                    border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.05)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedType == 'Bank') ...[
                            Row(
                              children: [
                                const Icon(Icons.security_rounded, color: Colors.redAccent, size: 14),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'For security, do not enter PINs, CVVs, or passwords.',
                                    style: GoogleFonts.outfit(
                                      color: Colors.redAccent,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            CustomTextField(
                              controller: _accountNumberController,
                              hintText: 'Account Number',
                              icon: Icons.badge_outlined,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _cardNumberController,
                              hintText: 'Card Number (e.g. last 4 digits)',
                              icon: Icons.credit_card_rounded,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _branchNameController,
                              hintText: 'Branch Name',
                              icon: Icons.location_on_outlined,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _routingNumberController,
                              hintText: 'Routing Number',
                              icon: Icons.tag_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ] else if (_selectedType == 'MFS') ...[
                            CustomTextField(
                              controller: _mobileNumberController,
                              hintText: 'Wallet Mobile Number',
                              icon: Icons.phone_android_rounded,
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader('INITIAL BALANCES BY OWNER'),
                    if (_ownerBalances.length < _owners.length)
                      ScaleOnTap(
                        onTap: _addOwnerRow,
                        child: Icon(Icons.add_circle_outline, color: AppColors.brandPrimary, size: 22),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                ...List.generate(_ownerBalances.length, (index) => _buildOwnerBalanceRow(context, index)),
                
                const SizedBox(height: 48),
                _buildCreateButton(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    )); // closes Scaffold + ThemeBuilder
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title, 
      style: GoogleFonts.outfit(
        color: AppColors.textGrey,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildOwnerBalanceRow(BuildContext context, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        blur: 15,
        opacity: isDark ? 0.03 : 0.45,
        color: isDark ? const Color(0xFF16201D) : Colors.white,
        borderRadius: 20,
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.05)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: isDark ? const Color(0xFF16201D) : Colors.white,
                    value: _ownerBalances[index]['owner'],
                    items: _owners.where((o) => !_ownerBalances.any((ob) => ob['owner'] == o) || o == _ownerBalances[index]['owner']).map((String owner) {
                      return DropdownMenuItem<String>(
                        value: owner, 
                        child: Text(owner, style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.textBlack)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _ownerBalances[index]['owner'] = val!),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _ownerBalances[index]['controller'],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: GoogleFonts.outfit(color: AppColors.textGrey),
                    prefixText: '৳ ',
                    prefixStyle: GoogleFonts.outfit(color: AppColors.brandPrimary, fontWeight: FontWeight.bold),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF283A35).withValues(alpha: 0.4) : const Color(0xFFF4F6F5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textBlack),
                ),
              ),
              if (_ownerBalances.length > 1)
                ScaleOnTap(
                  onTap: () => _removeOwnerRow(index),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCard(String type, IconData icon) {
    bool isSelected = _selectedType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ScaleOnTap(
          onTap: () => setState(() => _selectedType = type),
          child: GlassCard(
            blur: 15,
            opacity: isSelected ? 0.15 : (isDark ? 0.03 : 0.45),
            color: isSelected ? AppColors.brandPrimary : (isDark ? const Color(0xFF16201D) : Colors.white),
            borderRadius: 20,
            border: Border.all(
              color: isSelected ? AppColors.brandPrimary : (isDark ? const Color(0xFF283A35) : const Color(0xFFEEEEEE)),
              width: isSelected ? 2.0 : 1.0,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Icon(
                    icon, 
                    color: isSelected ? (isDark ? const Color(0xFF52B788) : AppColors.brandPrimary) : AppColors.secondaryText, 
                    size: 24
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type.toUpperCase(), 
                    style: GoogleFonts.outfit(
                      color: isSelected ? (isDark ? const Color(0xFF52B788) : AppColors.brandPrimary) : AppColors.secondaryText, 
                      fontSize: 10, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    )
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ScaleOnTap(
        onTap: _isLoading ? () {} : _handleCreate,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.brandPrimary,
                Color.fromARGB(
                  255,
                  (AppColors.brandPrimary.red + (isDark ? 10 : -10)).clamp(0, 255),
                  (AppColors.brandPrimary.green + (isDark ? 20 : -10)).clamp(0, 255),
                  (AppColors.brandPrimary.blue + (isDark ? 20 : -10)).clamp(0, 255),
                ),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandPrimary.withValues(alpha: isDark ? 0.4 : 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _isLoading 
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'Create Account', 
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
        ),
      ),
    );
  }
}
