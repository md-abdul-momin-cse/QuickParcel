import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sslcommerz/sslcommerz.dart';
import 'package:flutter_sslcommerz/model/SSLCSdkType.dart';
import 'package:flutter_sslcommerz/model/SSLCTransactionInfoModel.dart';
import 'package:flutter_sslcommerz/model/SSLCommerzInitialization.dart';
import 'package:flutter_sslcommerz/model/SSLCurrencyType.dart';

class BillingResult {
  final String orderId;
  final String paymentStatus;
  final String paymentMethod;
  final String paymentProvider;
  final String? transactionId;
  final double paidAmount;

  const BillingResult({
    required this.orderId,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.paymentProvider,
    required this.paidAmount,
    this.transactionId,
  });
}

class UnpaidBillItem {
  final String orderId;
  final double amount;
  final String senderName;
  final String senderPhone;
  final String receiverName;
  final String receiverPhone;
  final String pickupAddress;
  final String dropoffAddress;
  final String packageSize;
  final String packageDescription;
  final String distance;
  final String estimatedTime;
  final String createdAt;

  const UnpaidBillItem({
    required this.orderId,
    required this.amount,
    required this.senderName,
    required this.senderPhone,
    required this.receiverName,
    required this.receiverPhone,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.packageSize,
    required this.packageDescription,
    required this.distance,
    required this.estimatedTime,
    required this.createdAt,
  });
}

class BillingPage extends StatefulWidget {
  final String? orderId;
  final double? amount;
  final String? customerName;
  final String? customerPhone;
  final String customerEmail;
  final List<UnpaidBillItem>? unpaidBills;

  const BillingPage({
    super.key,
    required this.orderId,
    required this.amount,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
  }) : unpaidBills = null;

  const BillingPage.unpaid({
    super.key,
    required this.unpaidBills,
    required this.customerEmail,
  }) : orderId = null,
       amount = null,
       customerName = null,
       customerPhone = null;

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  String _paymentMethod = 'cash';
  bool _loading = false;
  int _selectedBillIndex = 0;

  bool get _isUnpaidListMode =>
      widget.unpaidBills != null && widget.unpaidBills!.isNotEmpty;

  UnpaidBillItem get _selectedBill {
    if (_isUnpaidListMode) {
      return widget.unpaidBills![_selectedBillIndex];
    }

    return UnpaidBillItem(
      orderId: widget.orderId ?? '',
      amount: widget.amount ?? 0,
      senderName: widget.customerName ?? '',
      senderPhone: widget.customerPhone ?? '',
      receiverName: '',
      receiverPhone: '',
      pickupAddress: '',
      dropoffAddress: '',
      packageSize: '',
      packageDescription: '',
      distance: '',
      estimatedTime: '',
      createdAt: '',
    );
  }

  Future<void> _handlePayment() async {
    if (_paymentMethod == 'cash') {
      Navigator.pop(
        context,
        BillingResult(
          orderId: _selectedBill.orderId,
          paymentStatus: 'CashOnDelivery',
          paymentMethod: 'Cash',
          paymentProvider: 'Cash',
          paidAmount: _selectedBill.amount,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final sslcommerz = Sslcommerz(
        initializer: SSLCommerzInitialization(
          multi_card_name: 'visa,master,bkash,rocket',
          currency: SSLCurrencyType.BDT,
          product_category: 'Package Delivery',
          sdkType: SSLCSdkType.TESTBOX,
          store_id: 'abdul67f7d33d97f1e',
          store_passwd: 'abdul67f7d33d97f1e@ssl',
          total_amount: _selectedBill.amount,
          tran_id: _selectedBill.orderId,
        ),
      );

      final SSLCTransactionInfoModel result = await sslcommerz.payNow();
      final status = (result.status ?? '').toLowerCase();
      final isSuccess = status == 'valid' || status == 'validated';

      if (!isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status == 'failed'
                    ? 'Payment failed. Please try again.'
                    : 'Payment cancelled by user',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      Navigator.pop(
        context,
        BillingResult(
          orderId: _selectedBill.orderId,
          paymentStatus: 'Paid',
          paymentMethod: 'Online',
          paymentProvider: 'SSLCommerz',
          transactionId: result.tranId,
          paidAmount: _selectedBill.amount,
        ),
      );
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment plugin not initialized. Please fully restart the app.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment session error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryText =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withOpacity(0.7);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Billing & Payment'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Bill',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '৳ ${_selectedBill.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Order: ${_selectedBill.orderId}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (_isUnpaidListMode) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      Icons.pending_actions_rounded,
                      color: theme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Unpaid Bills',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.unpaidBills!.length} due',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: (widget.unpaidBills!.length * 86.0).clamp(
                    90.0,
                    280.0,
                  ),
                  child: ListView.builder(
                    itemCount: widget.unpaidBills!.length,
                    itemBuilder: (context, index) {
                      final bill = widget.unpaidBills![index];
                      final selected = index == _selectedBillIndex;

                      return InkWell(
                        onTap: () => setState(() => _selectedBillIndex = index),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: selected
                                ? theme.primaryColor.withOpacity(0.12)
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? theme.primaryColor
                                  : theme.dividerColor,
                              width: selected ? 1.6 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selected
                                    ? Icons.check_circle_rounded
                                    : Icons.receipt_outlined,
                                color: theme.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bill.orderId,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${bill.senderName} -> ${bill.receiverName}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '৳ ${bill.amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: theme.primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Selected Order Details',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _detailText(
                        'Sender',
                        '${_selectedBill.senderName} (${_selectedBill.senderPhone})',
                      ),
                      _detailText(
                        'Receiver',
                        '${_selectedBill.receiverName} (${_selectedBill.receiverPhone})',
                      ),
                      _detailText('Pickup', _selectedBill.pickupAddress),
                      _detailText('Dropoff', _selectedBill.dropoffAddress),
                      _detailText(
                        'Package',
                        _selectedBill.packageDescription.isEmpty
                            ? _selectedBill.packageSize
                            : '${_selectedBill.packageSize} | ${_selectedBill.packageDescription}',
                      ),
                      _detailText(
                        'Distance',
                        '${_selectedBill.distance} | ${_selectedBill.estimatedTime}',
                      ),
                      _detailText(
                        'Created',
                        _formatDateTime(_selectedBill.createdAt),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const SizedBox(height: 14),
              Text(
                'Select Payment Type',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _methodCard(
                title: 'Cash on Delivery',
                subtitle: 'Pay when parcel is delivered',
                value: 'cash',
                icon: Icons.payments_outlined,
              ),
              const SizedBox(height: 12),
              _methodCard(
                title: 'Online Payment (SSLCommerz)',
                subtitle: 'bKash, Rocket, Visa/Mastercard',
                value: 'online',
                icon: Icons.credit_score_outlined,
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handlePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _paymentMethod == 'cash'
                              ? 'Confirm Cash Order'
                              : 'Pay Now',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _methodCard({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    final selected = _paymentMethod == value;
    final theme = Theme.of(context);
    final secondaryText =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withOpacity(0.7);

    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? theme.primaryColor.withOpacity(0.12)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? theme.primaryColor : theme.dividerColor,
            width: selected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.primaryColor.withOpacity(0.14),
              child: Icon(icon, color: theme.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: secondaryText),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? theme.primaryColor : secondaryText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailText(String label, String value) {
    final cleanValue = value.trim().isEmpty ? 'N/A' : value.trim();
    final theme = Theme.of(context);
    final secondaryText =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withOpacity(0.7);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: secondaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              cleanValue,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String raw) {
    if (raw.trim().isEmpty) return 'N/A';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    final twoDigitMonth = local.month.toString().padLeft(2, '0');
    final twoDigitDay = local.day.toString().padLeft(2, '0');
    final twoDigitHour = local.hour.toString().padLeft(2, '0');
    final twoDigitMinute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$twoDigitMonth-$twoDigitDay $twoDigitHour:$twoDigitMinute';
  }
}
