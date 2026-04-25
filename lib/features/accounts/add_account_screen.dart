import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/services/account_service.dart';
import 'package:pocketledger/features/auth/widgets/custom_text_field.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final AccountService _accountService = AccountService();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  
  String _selectedType = 'Bank';
  String _selectedOwner = 'Self';
  bool _isLoading = false;

  final List<String> _owners = ['Self', 'Father', 'Mother', 'Others'];

  final Map<String, IconData> _typeIcons = {
    'Bank': Icons.account_balance_outlined,
    'MFS': Icons.phone_android_outlined,
    'Cash': Icons.payments_outlined,
  };

  void _handleCreate() async {
    if (_nameController.text.isEmpty || _balanceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _accountService.createAccount(
        name: _nameController.text,
        type: _selectedType,
        initialOwner: _selectedOwner,
        initialBalance: double.parse(_balanceController.text),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
            Text('CHOOSE ACCOUNT TYPE', 
              style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            Row(
              children: _typeIcons.entries.map((entry) => Expanded(
                child: _buildTypeCard(entry.key, entry.value),
              )).toList(),
            ),
            
            const SizedBox(height: 32),
            Text('ACCOUNT DETAILS', 
              style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                children: [
                  CustomTextField(
                    controller: _nameController,
                    hintText: 'Account Name (e.g. DBBL, bKash)',
                    icon: Icons.edit_note_outlined,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _balanceController,
                    hintText: 'Initial Balance (Tk)',
                    icon: Icons.account_balance_wallet_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            Text('ASSIGN INITIAL OWNER', 
              style: GoogleFonts.montserrat(color: AppColors.secondaryText, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.brandPrimary.withOpacity(0.1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedOwner,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.brandPrimary),
                  dropdownColor: AppColors.cardBackground,
                  style: GoogleFonts.montserrat(color: AppColors.primaryText, fontWeight: FontWeight.w600),
                  items: _owners.map((String owner) {
                    return DropdownMenuItem<String>(
                      value: owner,
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, size: 18, color: AppColors.secondaryText),
                          const SizedBox(width: 12),
                          Text(owner),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedOwner = val!),
                ),
              ),
            ),
            
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: AppColors.brandPrimary.withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Create Account', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(String type, IconData icon) {
    bool isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppColors.brandPrimary.withOpacity(0.3) : Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppColors.secondaryText, size: 28),
            const SizedBox(height: 8),
            Text(
              type,
              style: GoogleFonts.montserrat(
                color: isSelected ? Colors.white : AppColors.secondaryText,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
