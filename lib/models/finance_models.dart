class InvoiceModel {
  final int id;
  final String invoiceNumber;
  final int requestId;
  final double servicePrice;
  final double commissionRate;
  final double commissionAmount;
  final double providerNet;
  final double totalAmount;
  final double balance;
  final String paymentStatus;

  const InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.requestId,
    required this.servicePrice,
    required this.commissionRate,
    required this.commissionAmount,
    required this.providerNet,
    required this.totalAmount,
    required this.balance,
    required this.paymentStatus,
  });

  bool get isPaid => paymentStatus == 'paid';

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      requestId: json['request_id'] is int ? json['request_id'] : int.tryParse(json['request_id'].toString()) ?? 0,
      servicePrice: double.tryParse(json['service_price']?.toString() ?? '0') ?? 0.0,
      commissionRate: double.tryParse(json['commission_rate']?.toString() ?? '0') ?? 0.0,
      commissionAmount: double.tryParse(json['commission_amount']?.toString() ?? '0') ?? 0.0,
      providerNet: double.tryParse(json['provider_net']?.toString() ?? '0') ?? 0.0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      paymentStatus: json['payment_status']?.toString() ?? 'unpaid',
    );
  }
}

class ProviderFinanceModel {
  final double grossAmount;
  final double providerNetAmount;
  final double paidAmount;
  final double outstandingAmount;

  const ProviderFinanceModel({
    required this.grossAmount,
    required this.providerNetAmount,
    required this.paidAmount,
    required this.outstandingAmount,
  });

  factory ProviderFinanceModel.fromJson(Map<String, dynamic> json) {
    return ProviderFinanceModel(
      grossAmount: double.tryParse(json['gross_amount']?.toString() ?? '0') ?? 0.0,
      providerNetAmount: double.tryParse(json['provider_net_amount']?.toString() ?? '0') ?? 0.0,
      paidAmount: double.tryParse(json['paid_amount']?.toString() ?? '0') ?? 0.0,
      outstandingAmount: double.tryParse(json['outstanding_amount']?.toString() ?? '0') ?? 0.0,
    );
  }
}
