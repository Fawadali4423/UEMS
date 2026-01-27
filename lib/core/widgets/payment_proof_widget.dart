import 'package:flutter/material.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';

/// Widget to show clickable payment proof image to admin
class PaymentProofWidget extends StatelessWidget {
  final String? proofUrl;
  final String? proofBase64;
  final bool isDark;

  const PaymentProofWidget({
    super.key,
    this.proofUrl,
    this.proofBase64,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (proofUrl == null && proofBase64 == null) {
      return GlassmorphismCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: isDark ? Colors.grey[500] :Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              'No proof uploaded',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return GlassmorphismCard(
      padding: const EdgeInsets.all(12),
      onTap: () => _showFullProof(context),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.image_rounded,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Proof',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to view full image',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.open_in_full_rounded,
            size: 18,
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  void _showFullProof(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: proofUrl != null
                    ? Image.network(
                        proofUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          size: 100,
                          color: Colors.grey,
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image_not_supported, size: 100),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
