import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/services/account_service.dart';
import 'package:pocketledger/features/auth/widgets/custom_text_field.dart';
import 'package:pocketledger/core/constants/app_constants.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final AccountService _accountService = AccountService();
  final _nameController = TextEditingController();
  
  String _selectedType = 'Bank';
  bool _isLoading = false;

  // New state for multiple owners
  final List<Map<String, dynamic>> _ownerBalances = [
    {'owner': AppConstants.ownerSelf, 'controller': TextEditingController(text: '0')}
  ];

  final List<String> _owners = AppConstants.allowedOwners;

  final Map<String, IconData> _typeIcons = {
    'Bank': Icons.account_balance_outlined,
    'MFS': Icons.phone_android_outlined,
    'Cash': Icons.payments_outlined,
  };

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
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('New Account', style: GoogleFonts.montserrat(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('CHOOSE ACCOUNT TYPE'),
            const SizedBox(height: 16),
            Row(
              children: _typeIcons.entries.map((entry) => Expanded(
                child: _buildTypeCard(entry.key, entry.value),
              )).toList(),
            ),
            
            const SizedBox(height: 32),
            _buildSectionHeader('ACCOUNT NAME'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(24),
              ),
              child: CustomTextField(
                controller: _nameController,
                hintText: 'e.g. DBBL, bKash, My Wallet',
                icon: Icons.edit_note_outlined,
              ),
            ),
            
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('INITIAL BALANCES BY OWNER'),
                if (_ownerBalances.length < _owners.length)
                  IconButton(
                    onPressed: _addOwnerRow,
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.brandPrimary),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...List.generate(_ownerBalances.length, (index) => _buildOwnerBalanceRow(index)),
            
            const SizedBox(height: 48),
            _buildCreateButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, 
      style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2));
  }

  Widget _buildOwnerBalanceRow(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _ownerBalances[index]['owner'],
                items: _owners.where((o) => !_ownerBalances.any((ob) => ob['owner'] == o) || o == _ownerBalances[index]['owner']).map((String owner) {
                  return DropdownMenuItem<String>(value: owner, child: Text(owner, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600)));
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
                prefixText: '৳ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: AppColors.primaryBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
            ),
          ),
          if (_ownerBalances.length > 1)
            IconButton(
              onPressed: () => _removeOwnerRow(index),
              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(String type, IconData icon) {
    bool isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppColors.secondaryText, size: 24),
            const SizedBox(height: 8),
            Text(type, style: GoogleFonts.montserrat(color: isSelected ? Colors.white : AppColors.secondaryText, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleCreate,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : Text('Create Account', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
