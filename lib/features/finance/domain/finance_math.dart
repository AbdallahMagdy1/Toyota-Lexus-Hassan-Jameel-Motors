import 'finance_models.dart';

/// The website's finance estimate — field-for-field the object
/// `computeFinance` returns in financeMath.ts.
final class FinanceEstimate {
  const FinanceEstimate({
    required this.period,
    required this.monthly,
    required this.firstPay,
    required this.lastPay,
    required this.managementFees,
    required this.total,
    required this.minFirstPay,
  });

  final int period;
  final double monthly;
  final double firstPay;
  final double lastPay;
  final double managementFees;
  final double total;
  final double minFirstPay;

  /// Amount actually financed (cash price − down payment).
  double financed(double price) => price - firstPay;

  /// Cost of finance = total payable − cash price.
  double costOfFinance(double price) => total - price;
}

/// EXACT port of the website's computeFinance (financeMath.ts):
///  • bank rates are percentages (8.00 = 8%), divided by 100 here;
///  • profit is charged on (price − downPayment) — the balloon is NOT
///    deducted from the financed base, only from the monthly numerator;
///  • management fees get +15% VAT (VAT applies to fees only);
///  • you pay (period − 1) monthly installments plus the final balloon.
FinanceEstimate computeFinance(
  double price,
  FinanceBank bank,
  int period, {
  double? customFirstPay,
}) {
  final firstRate = bank.advancedPaymentRate / 100;
  final lastRate = bank.lastPaymentRate / 100;
  final mgmtRate = bank.managementFees / 100;
  final financeRate = bank.financeRate / 100;

  final minFirstPay = (firstRate * price).roundToDouble();
  final firstPayPrice = (customFirstPay != null && customFirstPay > 0)
      ? customFirstPay
      : firstRate * price;
  final lastPayPrice = lastRate * price;
  final financeAmount = price - firstPayPrice;

  var addAmount = financeAmount * financeRate * (period / 12);
  var managementFeesAmount = 0.0;
  if (addAmount != 0 && mgmtRate > 0) {
    managementFeesAmount = financeAmount * mgmtRate;
    managementFeesAmount += managementFeesAmount * 0.15; // +15% VAT on fees
    addAmount += managementFeesAmount;
  }

  final denom = period > 1 ? period - 1 : 1;
  var monthly = (financeAmount + addAmount - lastPayPrice) / denom;
  if (monthly < 0) monthly = 0;
  final total = monthly * denom + lastPayPrice + firstPayPrice;

  return FinanceEstimate(
    period: period,
    monthly: monthly,
    firstPay: firstPayPrice,
    lastPay: lastPayPrice,
    managementFees: managementFeesAmount,
    total: total,
    minFirstPay: minFirstPay,
  );
}

/// Website's affordablePrice — the max financeable price for a target
/// monthly payment + balloon over a period.
double affordablePrice(double monthly, int period, double lastBatch) =>
    monthly * (period > 1 ? period - 1 : 1) + (lastBatch < 0 ? 0 : lastBatch);
