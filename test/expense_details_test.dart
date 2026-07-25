import 'package:ailocalmodel/domain/entities/expense_details.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detects a complete expense and generates formatted response', () {
    final result = ExpenseDetails.parseResponse('''
      {"is_expense":true,"amount":450,"currency":"INR","category":"Food","merchant":"Subway","date":"2026-07-25","description":"Lunch"}
    ''');

    expect(result.status, ExpenseDetectionStatus.complete);
    expect(result.isComplete, isTrue);
    expect(result.expense?.amount, 450);
    expect(result.expense?.currency, 'INR');
    expect(result.expense?.category, 'Food');
    expect(result.expense?.merchant, 'Subway');

    final formatted = result.toFormattedResponse();
    expect(formatted, startsWith('🤖 Model Output:'));
    expect(formatted, contains('✅ Expense Detected Successfully'));
    expect(formatted, contains('💵 Amount: INR 450'));
    expect(formatted, contains('🏷️ Category: Food'));
    expect(formatted, contains('🏪 Merchant: Subway'));
    expect(formatted, contains('Status: Complete'));
  });

  test('detects a complete expense without currency symbol (e.g. paid 500 for groceries)', () {
    final result = ExpenseDetails.parseResponse('''
      {"is_expense":true,"amount":500,"currency":"N/A","category":"Groceries","merchant":null,"date":null,"description":"groceries"}
    ''');

    expect(result.status, ExpenseDetectionStatus.complete);
    expect(result.isComplete, isTrue);
    expect(result.expense?.amount, 500);
    expect(result.expense?.currency, 'N/A');
    expect(result.expense?.category, 'Groceries');
  });

  test('detects incomplete expense when amount is missing', () {
    final result = ExpenseDetails.parseResponse('''
      {"is_expense":true,"amount":null,"currency":"INR","category":"Food"}
    ''');

    expect(result.status, ExpenseDetectionStatus.incomplete);
    expect(result.isComplete, isFalse);
    expect(result.failureReason, contains('Missing or invalid amount'));

    final formatted = result.toFormattedResponse();
    expect(formatted, contains('⚠️ Incomplete Expense Details'));
    expect(formatted, contains('Status: Incomplete'));
  });

  test('detects non-expense output', () {
    final result = ExpenseDetails.parseResponse('{"is_expense":false}');

    expect(result.status, ExpenseDetectionStatus.notAnExpense);
    expect(result.isComplete, isFalse);

    final formatted = result.toFormattedResponse();
    expect(formatted, contains('ℹ️ No Expense Detected'));
    expect(formatted, contains('Status: Not an Expense'));
  });

  test('handles malformed model output cleanly', () {
    final result = ExpenseDetails.parseResponse('Random model output');

    expect(result.status, ExpenseDetectionStatus.incomplete);
    expect(result.isComplete, isFalse);
    expect(result.failureReason, contains('Malformed model output'));
  });
}
