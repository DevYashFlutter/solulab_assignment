import 'package:flutter_test/flutter_test.dart';
import 'package:solulab_assignment/core/utils/parsers.dart';

void main() {
  group('Luhn Validation Algorithm Tests', () {
    test('Valid card numbers should pass', () {
      // Valid Luhn numbers
      expect(Parsers.isValidCard('79927398713'), isTrue);
      expect(Parsers.isValidCard('49927398716'), isTrue);
      expect(Parsers.isValidCard('378282246310005'), isTrue);
      // Real-world dummy card numbers
      expect(Parsers.isValidCard('4388576018402621'), isTrue);
    });

    test('Invalid card numbers should fail', () {
      // Invalid Luhn numbers
      expect(Parsers.isValidCard('79927398714'), isFalse);
      expect(Parsers.isValidCard('49927398717'), isFalse);
      expect(Parsers.isValidCard('378796799762468'), isFalse);
      // Empty or too short/long
      expect(Parsers.isValidCard(''), isFalse);
      expect(Parsers.isValidCard('123'), isFalse);
      expect(Parsers.isValidCard('123456789012345678901'), isFalse);
    });
  });

  group('Card Parser Tests', () {
    test('Extracts valid card number, MM/YY expiry, and holder name from noisy OCR text', () {
      const rawText = '''
      HDFC BANK
      DEBIT CARD
      4388 576O 184O 2621
      VALD THRU 12/28
      JOHN DOE
      PLATINUM
      ''';

      final details = Parsers.parseCard(rawText);
      expect(details.cardNumber, equals('4388576018402621')); // repaired 'O' -> '0'
      expect(details.expiryDate, equals('12/28'));
      expect(details.cardHolderName, equals('JOHN DOE'));
      expect(details.isValid, isTrue);
    });

    test('Handles alternative expiry formats (MM-YY, MMYY) and hyphens in card number', () {
      const rawText = '''
      STATE BANK OF INDIA
      4388-5760-1840-2621
      EXPIRY 10-29
      JANE H SMITH
      ''';

      final details = Parsers.parseCard(rawText);
      expect(details.cardNumber, equals('4388576018402621'));
      expect(details.expiryDate, equals('10/29'));
      expect(details.cardHolderName, equals('JANE H SMITH'));
      expect(details.isValid, isTrue);
    });

    test('Ignores invalid card numbers failing Luhn algorithm', () {
      const rawText = '''
      VISA CLASSIC
      1234 5678 1234 5678
      VALID 06/25
      A B JONES
      ''';

      final details = Parsers.parseCard(rawText);
      expect(details.cardNumber, isEmpty); // invalid Luhn -> ignored
      expect(details.isValid, isFalse);
    });
  });

  group('Passbook Parser Tests', () {
    test('Extracts IFSC (with OCR repair), Account Number (ignoring phone/pincode), and Holder Name', () {
      const rawText = '''
      STATE BANK OF INDIA
      BRANCH: ANDHERI EAST, MUMBAI - 400069
      IFSC Code: SBINo001234
      Name of A/c Holder: MR SANJAY KUMAR
      Account No: 123456789012
      Mobile No: 9876543210
      ''';

      final details = Parsers.parsePassbook(rawText);
      expect(details.ifscCode, equals('SBIN0001234')); // repaired 'o' -> '0'
      expect(details.accountNumber, equals('123456789012')); // ignored phone and pincode
      expect(details.accountHolderName, equals('MR SANJAY KUMAR'));
    });

    test('Extracts Account Holder Name from label when next line contains the name', () {
      const rawText = '''
      UNION BANK OF INDIA
      A/c No: 987654321098
      IFSC: UBIN0531234
      Name of A/c Holder:
      RITA SHARMA
      DATE OF PRINT: 20/05/2026
      ''';

      final details = Parsers.parsePassbook(rawText);
      expect(details.accountNumber, equals('987654321098'));
      expect(details.ifscCode, equals('UBIN0531234'));
      expect(details.accountHolderName, equals('RITA SHARMA'));
    });
  });
}
