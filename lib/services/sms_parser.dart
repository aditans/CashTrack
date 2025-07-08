Map<String, dynamic> parseSms(String body) {
  double? amount;
  String? type;
  String? name;
  String lower = body.toLowerCase();

  // SBI-specific: If 'sbi' or 'Refno' in message, try to match amount after 'debited by'
  if ((lower.contains('sbi') || lower.contains('refno')) && lower.contains('debited by')) {
    final sbiAmount = RegExp(r'debited by\s*([\d,.]+)', caseSensitive: false).firstMatch(body);
    if (sbiAmount != null) {
      amount = double.tryParse(sbiAmount.group(1)!.replaceAll(',', ''));

    }
  } else {
    // General amount regex
    final amountRegex = RegExp(r'(rs\.?|inr\.?|₹)\s?([\d,]+(\.\d{1,2})?)', caseSensitive: false);
    final match = amountRegex.firstMatch(body);
    if (match != null) {
      amount = double.tryParse(match.group(2)!.replaceAll(',', ''));
    }
  }

  // Detect transaction type
  if (lower.contains('debited') || lower.contains('sent rs')) {
    type = 'debit';
  } else if (lower.contains('credited') || lower.contains('received from')) {
    type = 'credit';
  } else if (lower.contains('otp')) {
    return {'type': 'otp'};
  } else {
    return {'type': 'other'};
  }

  // Extract counterparty name (same as before)
  if (type != null) {
    final hdfcTo = RegExp(r'To\s+([A-Z\s]+)\s+On', caseSensitive: false).firstMatch(body);
    if (hdfcTo != null) name = hdfcTo.group(1)?.trim();

    final iciciFrom = RegExp(r'from\s+([A-Z\s]+)\.?\s+UPI', caseSensitive: false).firstMatch(body);
    if (iciciFrom != null) name = iciciFrom.group(1)?.trim();

    final iciciTo = RegExp(r';\s+([A-Z][A-Z\s]{3,})\s+(credited|debited)', caseSensitive: false).firstMatch(body);
    if (iciciTo != null) name = iciciTo.group(1)?.trim();

    final sbiTo = RegExp(r'trf to\s+([A-Z\s]+)\s+Ref', caseSensitive: false).firstMatch(body);
    if (sbiTo != null) name = sbiTo.group(1)?.trim();

    final hdfcFromVPA = RegExp(r'from VPA\s+(.+?)\s+\(UPI', caseSensitive: false).firstMatch(body);
    if (hdfcFromVPA != null) name = hdfcFromVPA.group(1)?.trim();

    if (name == null) {
      final fallback = RegExp(
        r'(?:paid to|received from|sent to|from)\s+((?!Rs|INR|₹)[A-Z\s]{3,})',
        caseSensitive: false,
      ).firstMatch(body);
      if (fallback != null) name = fallback.group(1)?.trim();
    }
  }

  return {
    'amount': amount,
    'type': type,
    'name': name ?? 'Unknown',
  };
}
