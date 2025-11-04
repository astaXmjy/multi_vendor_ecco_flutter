import 'package:anu_app/config/theme.dart';
import 'package:flutter/material.dart';

class TrustBadgesWidget extends StatefulWidget {
  final double? minOrderValue; // For free shipping threshold
  final List<TrustBadge>? customBadges; // Optional custom badges

  const TrustBadgesWidget({
    Key? key,
    this.minOrderValue = 500,
    this.customBadges,
  }) : super(key: key);

  @override
  State<TrustBadgesWidget> createState() => _TrustBadgesWidgetState();
}

class _TrustBadgesWidgetState extends State<TrustBadgesWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  List<TrustBadge> _badges = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupBadges();
  }

  void _initializeAnimations() {
    // Slide animation for initial appearance
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    // Pulse animation for highlight effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _slideController.forward();
    _startPulseAnimation();
  }

  void _startPulseAnimation() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  void _setupBadges() {
    if (widget.customBadges != null) {
      _badges = widget.customBadges!;
    } else {
      _badges = [
        TrustBadge(
          title: 'Free Shipping',
          subtitle: 'On orders above ₹${widget.minOrderValue?.toInt() ?? 500}',
          icon: Icons.local_shipping,
          iconColor: const Color(0xFF4CAF50),
          backgroundColor: Colors.white,
          borderColor: Colors.grey.shade200,
          isHighlighted: false,
          customImage:
              'assets/icons/free.png', // You can replace with your image path
        ),
        TrustBadge(
          title: '7-Day Returns',
          subtitle: 'Easy & hassle-free',
          icon: Icons.keyboard_return,
          iconColor: const Color(0xFF2196F3),
          backgroundColor: Colors.white,
          borderColor: Colors.grey.shade200,
          isHighlighted: false,
          customImage:
              'assets/icons/return.png', // You can replace with your image path
        ),
        TrustBadge(
          title: '100% Authentic',
          subtitle: 'Genuine products only',
          icon: Icons.verified,
          iconColor: const Color(0xFFFF5722),
          backgroundColor: Colors.white,
          borderColor: Colors.grey.shade200,
          isHighlighted: false,
          customImage:
              'assets/icons/authentic.png', // You can replace with your image path
        ),
        TrustBadge(
          title: '24/7 Support',
          subtitle: 'Always here to help',
          icon: Icons.support_agent,
          iconColor: const Color(0xFF9C27B0),
          backgroundColor: Colors.white,
          borderColor: Colors.grey.shade200,
          isHighlighted: false,
          customImage:
              'assets/icons/made.png', // You can replace with your image path
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.verified_user,
                    color: AppTheme.primaryColor,
                    size: isTablet ? 20 : 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Why Choose Us',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 20 : 16),
            _buildBadgesGrid(isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesGrid(bool isTablet) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isTablet ? 1.1 : 1.0,
      ),
      itemCount: _badges.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 200 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: _buildBadgeCard(_badges[index], isTablet),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBadgeCard(TrustBadge badge, bool isTablet) {
    return GestureDetector(
      onTap: () => _onBadgeTap(badge),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        decoration: BoxDecoration(
          color: badge.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: badge.borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon or Custom Image
            Container(
              width: isTablet ? 48 : 40,
              height: isTablet ? 48 : 40,
              decoration: BoxDecoration(
                color: badge.iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: badge.customImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.asset(
                        badge.customImage!,
                        width: isTablet ? 48 : 40,
                        height: isTablet ? 48 : 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            badge.icon,
                            color: badge.iconColor,
                            size: isTablet ? 24 : 20,
                          );
                        },
                      ),
                    )
                  : Icon(
                      badge.icon,
                      color: badge.iconColor,
                      size: isTablet ? 24 : 20,
                    ),
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              badge.title,
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isTablet ? 6 : 4),
            Text(
              badge.subtitle,
              style: TextStyle(
                fontSize: isTablet ? 12 : 10,
                color: Colors.grey[600],
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _onBadgeTap(TrustBadge badge) {
    // Add haptic feedback
    // HapticFeedback.lightImpact();

    // You can add navigation or show more details here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${badge.title}: ${badge.subtitle}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}

// Model class for Trust Badge
class TrustBadge {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final bool isHighlighted;
  final String? customImage; // Path to your custom image

  TrustBadge({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    this.isHighlighted = false,
    this.customImage,
  });
}
