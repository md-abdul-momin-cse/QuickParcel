import 'package:flutter/material.dart';
import 'package:quick_parcel/services/database.dart';

class DriverVerifiedBadge extends StatelessWidget {
  final String driverId;
  final bool compact;

  const DriverVerifiedBadge({
    super.key,
    required this.driverId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (driverId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<bool>(
      stream: DatabaseMethods().getDriverVerificationStream(driverId),
      initialData: false,
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 7 : 10,
            vertical: compact ? 3 : 5,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_rounded,
                color: Colors.white,
                size: compact ? 14 : 16,
              ),
              SizedBox(width: compact ? 4 : 6),
              Text(
                compact ? 'Verified' : 'Verified Driver',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 10 : 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
