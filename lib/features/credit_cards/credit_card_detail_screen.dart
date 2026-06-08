import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/credit_card_model.dart';
import 'package:pocketledger/services/credit_card_service.dart';
import 'package:pocketledger/features/credit_cards/add_credit_card_screen.dart';

class CreditCardDetailScreen extends StatefulWidget {
  final String cardId;

  const CreditCardDetailScreen({Key? key, required this.cardId}) : super(key: key);

  @override
  State<CreditCardDetailScreen> createState() => _CreditCardDetailScreenState();
}

class _CreditCardDetailScreenState extends State<CreditCardDetailScreen> {
  final CreditCardService _cardService = CreditCardService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.primaryGreen),
        title: Text(
          'Card Details',
          style: GoogleFonts.outfit(
            color: AppColors.textBlack,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _deleteCard(context, widget.cardId),
          ),
        ],
      ),
      body: StreamBuilder<List<CreditCardModel>>(
        stream: _cardService.getCards(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final cards = snapshot.data!;
          final cardIndex = cards.indexWhere((c) => c.id == widget.cardId);
          
          if (cardIndex == -1) {
            return Center(child: Text('Card not found', style: TextStyle(color: AppColors.error)));
          }

          final card = cards[cardIndex];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardVisual(card),
                const SizedBox(height: 24),
                _buildUtilizationBar(card),
                const SizedBox(height: 24),
                _buildDueCycleInfo(card),
                const SizedBox(height: 24),
                _buildActionButtons(card),
                const SizedBox(height: 24),
                // (Future: Transaction History StreamBuilder matching `creditCardId`)
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardVisual(CreditCardModel card) {
    const gradients = [
      [Color(0xFF2C3E50), Color(0xFF000000)], // Premium Black
      [Color(0xFF134E5E), Color(0xFF71B280)], // Greenish
      [Color(0xFF4B1248), Color(0xFFF0C27B)], // Gold Purple
      [Color(0xFF141E30), Color(0xFF243B55)], // Deep Blue
    ];
    final gradient = gradients[card.cardColorIndex % gradients.length];

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [
          BoxShadow(color: gradient[0].withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(card.bankName, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              Icon(card.cardNetwork.toLowerCase() == 'visa' ? Icons.payment : Icons.credit_card, color: Colors.white, size: 28),
            ],
          ),
          const Spacer(),
          Text(card.cardNickname, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text('**** **** **** ${card.lastFourDigits}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, letterSpacing: 2, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildUtilizationBar(CreditCardModel card) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Available Credit', style: GoogleFonts.outfit(color: AppColors.textGrey)),
              Text('৳${card.availableCredit.toStringAsFixed(2)}', style: GoogleFonts.outfit(color: AppColors.textBlack, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: card.utilizationPercent,
              backgroundColor: AppColors.pageBackground,
              valueColor: AlwaysStoppedAnimation<Color>(
                card.utilizationPercent > 0.8 ? AppColors.error : AppColors.primaryGreen,
              ),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Outstanding: ৳${card.outstandingBalance.toStringAsFixed(2)}', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13)),
              Text('Limit: ৳${card.creditLimit.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDueCycleInfo(CreditCardModel card) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: card.daysUntilDue <= 3 ? Border.all(color: AppColors.error.withOpacity(0.5), width: 2) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment Due', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13)),
                const SizedBox(height: 8),
                Text('${card.daysUntilDue} Days', style: GoogleFonts.outfit(color: card.daysUntilDue <= 3 ? AppColors.error : AppColors.textBlack, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Min: ৳${card.minimumPayment.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next Statement', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13)),
                const SizedBox(height: 8),
                Text('${card.daysUntilStatement} Days', style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Closes on ${card.statementClosingDay}th', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(CreditCardModel card) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddCreditCardScreen(existingCard: card),
              );
            },
            icon: Icon(Icons.edit, color: AppColors.primaryGreen),
            label: Text('Edit Card', style: GoogleFonts.outfit(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.primaryGreen),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to AddTransactionScreen with creditCardId pre-filled for payment
            },
            icon: const Icon(Icons.payment, color: Colors.white),
            label: Text('Pay Bill', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteCard(BuildContext context, String cardId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: const Text('Are you sure you want to delete this credit card? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _cardService.deleteCard(cardId);
      if (context.mounted) {
        Navigator.pop(context); // Go back to credit cards screen
      }
    }
  }
}
