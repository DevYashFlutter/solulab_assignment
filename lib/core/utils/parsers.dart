class CardDetails {
  final String cardNumber;
  final String expiryDate;
  final String cardHolderName;
  final bool isValid;

  CardDetails({required this.cardNumber, required this.expiryDate, required this.cardHolderName, required this.isValid});

  @override
  String toString() {
    return 'CardDetails(cardNumber: $cardNumber, expiryDate: $expiryDate, cardHolderName: $cardHolderName, isValid: $isValid)';
  }
}

class BankDetails {
  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;

  BankDetails({required this.accountHolderName, required this.accountNumber, required this.ifscCode});

  @override
  String toString() {
    return 'BankDetails(accountHolderName: $accountHolderName, accountNumber: $accountNumber, ifscCode: $ifscCode)';
  }
}

class Parsers {
  /// Manually validates a card number using the Luhn Algorithm.
  static bool isValidCard(String cardNumber) {
    // Strip non-digit characters
    String cleanNum = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanNum.isEmpty || cleanNum.length < 9 || cleanNum.length > 19) {
      return false;
    }

    int sum = 0;
    bool alternate = false;

    // Iterate from right to left
    for (int i = cleanNum.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanNum[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  /// Parses credit/debit card information from raw OCR text.
  static CardDetails parseCard(String rawText) {
    String cleanText = rawText.replaceAll('\r', '');
    List<String> lines = cleanText.split('\n').map((l) => l.trim()).toList();

    String cardNumber = '';
    String expiryDate = '';
    String cardHolderName = '';

    // 1. CARD NUMBER EXTRACTION
    // Repair OCR misreads for number checking
    String cleanCardNumberCandidate(String candidate) {
      return candidate
          .replaceAll(RegExp(r'[\s\-]'), '') // remove spaces/hyphens
          .replaceAll('O', '0')
          .replaceAll('o', '0')
          .replaceAll('I', '1')
          .replaceAll('l', '1')
          .replaceAll('i', '1')
          .replaceAll('S', '5')
          .replaceAll('s', '5')
          .replaceAll('Z', '2')
          .replaceAll('z', '2')
          .replaceAll('B', '8');
    }

    // Try finding card number via regex matching digit-like runs on each trimmed line
    final cardPattern = RegExp(r'[0-9OoilSzSB\- ]{13,30}');
    String bestCardNumber = '';

    for (String line in lines) {
      Iterable<Match> matches = cardPattern.allMatches(line);
      for (final match in matches) {
        String candidate = line.substring(match.start, match.end);
        String cleaned = cleanCardNumberCandidate(candidate);

        if (RegExp(r'^\d{13,19}$').hasMatch(cleaned)) {
          if (isValidCard(cleaned)) {
            if (cleaned.length > bestCardNumber.length) {
              bestCardNumber = cleaned;
            }
          }
        }
      }
    }
    cardNumber = bestCardNumber;

    // 2. EXPIRY DATE EXTRACTION
    final expiryRegex1 = RegExp(r'\b(0[1-9]|1[0-2])\s*[\/-]\s*([2-9][0-9])\b'); // MM/YY or MM-YY
    final expiryRegex2 = RegExp(r'\b(0[1-9]|1[0-2])\s*[\/-]\s*(20[2-9][0-9])\b'); // MM/YYYY
    final expiryRegex3 = RegExp(r'\b(0[1-9]|1[0-2])\s*([2-9][0-9])\b'); // MMYY (4 digits)

    Match? expMatch = expiryRegex1.firstMatch(cleanText);
    if (expMatch != null) {
      expiryDate = '${expMatch.group(1)}/${expMatch.group(2)}';
    } else {
      expMatch = expiryRegex2.firstMatch(cleanText);
      if (expMatch != null) {
        String year = expMatch.group(2)!;
        expiryDate = '${expMatch.group(1)}/${year.substring(year.length - 2)}';
      } else {
        expMatch = expiryRegex3.firstMatch(cleanText);
        if (expMatch != null) {
          expiryDate = '${expMatch.group(1)}/${expMatch.group(2)}';
        }
      }
    }

    // 3. CARD HOLDER NAME EXTRACTION
    List<MapEntry<String, double>> nameCandidates = [];
    final cardBlacklist = RegExp(
      r'(visa|mastercard|rupay|amex|discover|express|card|debit|credit|bank|valid|thru|good|from|exp|expiry|date|month|year|platinum|gold|classic|signature|world|premier|electron|payment|issued|customer|holder)',
      caseSensitive: false,
    );

    for (String line in lines) {
      // Clean and ignore irrelevant lines
      if (line.length < 4 || line.length > 28) continue;
      if (line.contains(RegExp(r'\d'))) continue; // names shouldn't contain digits
      if (cardBlacklist.hasMatch(line)) continue;

      // Ensure it contains only letters, spaces, dots
      if (!RegExp(r'^[A-Za-z\s\.]+$').hasMatch(line)) continue;

      List<String> words = line.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      if (words.length < 2 || words.length > 4) continue;

      double score = 10.0;

      // Check casing (all caps is common on cards)
      if (line == line.toUpperCase()) {
        score += 15.0;
      } else {
        score += 5.0;
      }

      // Exact 2 or 3 words is typical
      if (words.length == 2 || words.length == 3) {
        score += 10.0;
      }

      nameCandidates.add(MapEntry(line, score));
    }

    if (nameCandidates.isNotEmpty) {
      nameCandidates.sort((a, b) => b.value.compareTo(a.value));
      cardHolderName = nameCandidates.first.key;
    }

    return CardDetails(
      cardNumber: cardNumber,
      expiryDate: expiryDate,
      cardHolderName: cardHolderName,
      isValid: cardNumber.isNotEmpty && isValidCard(cardNumber),
    );
  }

  /// Parses bank passbook information from raw OCR text.
  static BankDetails parsePassbook(String rawText) {
    String cleanText = rawText.replaceAll('\r', '');
    List<String> lines = cleanText.split('\n').map((l) => l.trim()).toList();

    String accountHolderName = '';
    String accountNumber = '';
    String ifscCode = '';

    // 1. IFSC CODE EXTRACTION
    // Pattern: 4 letters, then 0 (possibly misread as O/o), then 6 letters/digits
    final ifscRegex = RegExp(r'\b([A-Za-z]{4})([0Oo])([A-Za-z0-9]{6})\b');
    Match? ifscMatch = ifscRegex.firstMatch(cleanText);
    if (ifscMatch != null) {
      String bankCode = ifscMatch.group(1)!.toUpperCase();
      String branchCode = ifscMatch.group(3)!.toUpperCase();
      ifscCode = '${bankCode}0$branchCode'; // Force the 5th character to '0'
    }

    // 2. ACCOUNT NUMBER EXTRACTION
    // Indian bank accounts are usually 9 to 18 digits.
    List<MapEntry<String, double>> accountCandidates = [];

    String cleanAccNumCandidate(String candidate) {
      return candidate
          .replaceAll(RegExp(r'[\s\-:A-Za-z]'), '') // remove everything except digits
          .replaceAll('O', '0')
          .replaceAll('o', '0')
          .replaceAll('I', '1')
          .replaceAll('l', '1')
          .replaceAll('i', '1')
          .replaceAll('S', '5')
          .replaceAll('s', '5')
          .replaceAll('Z', '2')
          .replaceAll('z', '2')
          .replaceAll('B', '8');
    }

    final numberPattern = RegExp(r'\b[0-9OoilSzSB\-]{9,19}\b');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      Iterable<Match> numMatches = numberPattern.allMatches(line);

      for (final match in numMatches) {
        String rawCandidate = line.substring(match.start, match.end);
        String cleaned = cleanAccNumCandidate(rawCandidate);

        // Account numbers are typically 9 to 18 digits
        if (cleaned.length >= 9 && cleaned.length <= 18) {
          double score = 10.0;

          // Check surrounding text for labels
          String surroundingText = '';
          if (i > 0) surroundingText += '${lines[i - 1]} ';
          surroundingText += line;
          if (i < lines.length - 1) surroundingText += ' ${lines[i + 1]}';
          surroundingText = surroundingText.toLowerCase();

          if (surroundingText.contains('a/c') ||
              surroundingText.contains('account') ||
              surroundingText.contains('acno') ||
              surroundingText.contains('acc')) {
            score += 30.0;
          }

          // Penalize if it looks like a phone number (10 digits starting with 6-9)
          if (cleaned.length == 10 && RegExp(r'^[6-9]').hasMatch(cleaned)) {
            score -= 15.0;
          }

          // Penalize if it's a pincode (6 digits)
          if (cleaned.length == 6) {
            score -= 20.0;
          }

          // Penalize if it is identical to IFSC numbers
          if (ifscCode.contains(cleaned)) {
            score -= 25.0;
          }

          accountCandidates.add(MapEntry(cleaned, score));
        }
      }
    }

    if (accountCandidates.isNotEmpty) {
      accountCandidates.sort((a, b) => b.value.compareTo(a.value));
      accountNumber = accountCandidates.first.key;
    }

    // 3. ACCOUNT HOLDER NAME EXTRACTION
    List<MapEntry<String, double>> nameCandidates = [];
    final passbookBlacklist = RegExp(
      r'(bank|branch|ifsc|date|account|a/c|address|phone|mobile|cif|nominee|saving|current|statement|ledger|passbook|micr|rtgs|neft|trans|balance|deposit|withdrawal|amount|printed|page|sheet|shri|mr|mrs|ms|smt|dr|customer|holder)',
      caseSensitive: false,
    );

    // Look for lines containing labels first
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      String lowerLine = line.toLowerCase();

      // Check if line contains a name label
      if (lowerLine.contains('name') || lowerLine.contains('holder') || lowerLine.contains('customer') || lowerLine.contains('c/o')) {
        // Strip label
        String possibleName = line
            .replaceAll(
              RegExp(
                r'(name of account holder|name of a/c holder|account holder name|holder name|customer name|c/o|name|holder|customer)[:\- ]+',
                caseSensitive: false,
              ),
              '',
            )
            .trim();

        if (possibleName.isNotEmpty && possibleName.length >= 4 && possibleName.length <= 30 && !possibleName.contains(RegExp(r'\d'))) {
          // Verify it matches alphabetic structure
          if (RegExp(r'^[A-Za-z\s\.]+$').hasMatch(possibleName)) {
            nameCandidates.add(MapEntry(possibleName, 50.0)); // High score for direct label match
          }
        } else if (possibleName.isEmpty && i < lines.length - 1) {
          // Check next line if label is on its own line
          String nextLine = lines[i + 1];
          if (nextLine.isNotEmpty &&
              nextLine.length >= 4 &&
              nextLine.length <= 30 &&
              !nextLine.contains(RegExp(r'\d')) &&
              RegExp(r'^[A-Za-z\s\.]+$').hasMatch(nextLine)) {
            nameCandidates.add(MapEntry(nextLine, 40.0));
          }
        }
      }

      // Check for prefix patterns like Mr., Mrs., Shri
      if (lowerLine.contains(RegExp(r'\b(mr|mrs|ms|shri|smt|dr)\.?\s+[a-z]'))) {
        String possibleName = line.trim();
        if (possibleName.length >= 4 && possibleName.length <= 30 && !possibleName.contains(RegExp(r'\d'))) {
          nameCandidates.add(MapEntry(possibleName, 45.0));
        }
      }

      // General candidate sweep
      if (line.length >= 4 &&
          line.length <= 26 &&
          !line.contains(RegExp(r'\d')) &&
          !passbookBlacklist.hasMatch(line) &&
          RegExp(r'^[A-Za-z\s\.]+$').hasMatch(line)) {
        List<String> words = line.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        if (words.length >= 2 && words.length <= 4) {
          double score = 10.0;
          if (line == line.toUpperCase()) score += 10.0;
          nameCandidates.add(MapEntry(line, score));
        }
      }
    }

    if (nameCandidates.isNotEmpty) {
      nameCandidates.sort((a, b) => b.value.compareTo(a.value));
      accountHolderName = nameCandidates.first.key;
    }

    return BankDetails(accountHolderName: accountHolderName, accountNumber: accountNumber, ifscCode: ifscCode);
  }
}
