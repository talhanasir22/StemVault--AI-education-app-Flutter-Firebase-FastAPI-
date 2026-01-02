class Payment {
  String paymentID;
  double amount;
  DateTime paymentDate;
  String paymentMethod;
  String transactionStatus;

  Payment({
    required this.paymentID,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    required this.transactionStatus,
  });

  Map<String, dynamic> toJson() {
    return {
      'paymentID': paymentID,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'transactionStatus': transactionStatus,
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      paymentID: json['paymentID'],
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['paymentDate']),
      paymentMethod: json['paymentMethod'],
      transactionStatus: json['transactionStatus'],
    );
  }
}
