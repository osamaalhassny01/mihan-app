class CurrencyHelper {
  /// Format amount in English digits with clean formatting
  static String format(dynamic amount) {
    if (amount == null) return '0';
    double val = 0.0;
    if (amount is num) {
      val = amount.toDouble();
    } else {
      val = double.tryParse(amount.toString()) ?? 0.0;
    }

    // Format with no decimal if whole number, else up to 2 decimal places
    String numStr;
    if (val == val.roundToDouble()) {
      numStr = val.toInt().toString();
    } else {
      numStr = val.toStringAsFixed(2);
    }

    // Convert Arabic-Indic numerals to Latin digits if any
    numStr = toLatinDigits(numStr);
    return numStr;
  }

  /// Ensure digits are strictly English (0-9)
  static String toLatinDigits(String input) {
    const arabicIndic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const latin = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    String res = input;
    for (int i = 0; i < 10; i++) {
      res = res.replaceAll(arabicIndic[i], latin[i]);
    }
    return res;
  }
}
