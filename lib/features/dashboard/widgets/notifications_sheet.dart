import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/credit_card_model.dart';
import 'package:pocketledger/services/credit_card_service.dart';

class NotificationsSheet extends StatelessWidget {
  const NotificationsSheet({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const NotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CreditCardService cardService = CreditCardService();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.notifications_active_rounded, color: AppColors.primaryGreen, size: 28),
              const SizedBox(width: 12),
              Text(
                'Notifications',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Flexible(
            child: StreamBuilder<List<CreditCardModel>>(
              stream: cardService.getCards(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final cards = snapshot.data!;
                final dueCards = cards.where((c) => c.daysUntilDue <= 7 && c.outstandingBalance > 0).toList();
                
                // Sort by urgency
                dueCards.sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));

                if (dueCards.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, color: AppColors.primaryGreen, size: 60),
                          const SizedBox(height: 16),
                          Text(
                            'All caught up!',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textBlack,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You have no pending alerts or upcoming payments.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(color: AppColors.textGrey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: dueCards.length,
                  itemBuilder: (context, index) {
                    final card = dueCards[index];
                    final isUrgent = card.daysUntilDue <= 3;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isUrgent ? AppColors.error.withValues(alpha: 0.1) : AppColors.primaryGreen.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isUrgent ? AppColors.error.withValues(alpha: 0.3) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isUrgent ? AppColors.error.withValues(alpha: 0.2) : AppColors.primaryGreen.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.credit_card_rounded,
                              color: isUrgent ? AppColors.error : AppColors.primaryGreen,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${card.cardNickname} Payment Due',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textBlack,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Min Payment: ৳${card.minimumPayment.toStringAsFixed(0)}',
                                  style: GoogleFonts.outfit(
                                    color: AppColors.textGrey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                isUrgent ? 'URGENT' : 'UPCOMING',
                                style: GoogleFonts.outfit(
                                  color: isUrgent ? AppColors.error : AppColors.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${card.daysUntilDue} Days',
                                style: GoogleFonts.outfit(
                                  color: isUrgent ? AppColors.error : AppColors.textBlack,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
