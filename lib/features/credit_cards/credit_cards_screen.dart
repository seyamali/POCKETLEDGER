import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/credit_card_model.dart';
import 'package:pocketledger/services/credit_card_service.dart';
import 'package:pocketledger/features/credit_cards/add_credit_card_screen.dart';
import 'package:pocketledger/features/credit_cards/credit_card_detail_screen.dart';

class CreditCardsScreen extends StatefulWidget {
  const CreditCardsScreen({Key? key}) : super(key: key);

  @override
  State<CreditCardsScreen> createState() => _CreditCardsScreenState();
}

class _CreditCardsScreenState extends State<CreditCardsScreen> {
  final CreditCardService _cardService = CreditCardService();

  static const List<List<Color>> cardGradients = [
    [Color(0xFF2C3E50), Color(0xFF000000)], // Premium Black
    [Color(0xFF134E5E), Color(0xFF71B280)], // Greenish
    [Color(0xFF4B1248), Color(0xFFF0C27B)], // Gold Purple
    [Color(0xFF141E30), Color(0xFF243B55)], // Deep Blue
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Credit Cards',
          style: GoogleFonts.outfit(
            color: AppColors.textBlack,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle, color: AppColors.primaryGreen, size: 28),
            onPressed: () => _showAddCardSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<CreditCardModel>>(
        stream: _cardService.getCards(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: AppColors.error)));
          }

          final cards = snapshot.data ?? [];
          if (cards.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return _buildCardItem(card);
            },
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
          Icon(Icons.credit_card, size: 80, color: AppColors.textGrey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No Credit Cards yet',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a credit card to track your\nbalances, bills, and due dates.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showAddCardSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Add Card',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(CreditCardModel card) {
    final gradient = cardGradients[card.cardColorIndex % cardGradients.length];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CreditCardDetailScreen(cardId: card.id)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Pattern (simulated chip/logo)
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(Icons.credit_card, size: 150, color: Colors.white.withOpacity(0.05)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        card.bankName,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        card.cardNetwork.toLowerCase() == 'visa'
                            ? Icons.payment
                            : Icons.credit_card,
                        color: Colors.white,
                        size: 28,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    card.cardNickname,
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '**** **** **** ${card.lastFourDigits}',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Outstanding',
                            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            '৳${card.outstandingBalance.toStringAsFixed(2)}',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Due in',
                            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            '${card.daysUntilDue} days',
                            style: GoogleFonts.outfit(
                              color: card.daysUntilDue <= 3 ? AppColors.error : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCardSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddCreditCardScreen(),
    );
  }
}
