# DocuScan - Card & Passbook OCR Scanner

A premium Flutter mobile application that scans physical credit/debit cards and bank passbooks, extracting structured information (card number, expiry, holder name, account number, IFSC) using on-device OCR and custom manual parsing logic.

---

## Features

### 1. Card Scanner
* Opens the device camera to scan debit/credit cards.
* Extracts **Card Number**, **Expiry Date**, and **Card Holder Name** (if available).
* Masks card numbers in the UI (e.g., `XXXX XXXX XXXX 1234`).
* Manually validates card numbers using the **Luhn Algorithm**.
* Displays a validation badge indicating Luhn check status.

### 2. Passbook / Bank Document Scanner
* Supports both direct **Camera Scan** and **Gallery Upload**.
* Extracts **Account Holder Name**, **Account Number**, and **IFSC Code** (if present).
* Isolates the correct account number from noisy elements like branch codes, phone numbers, and pincodes.
* Auto-corrects OCR spelling anomalies (e.g., IFSC codes with letter `O` or `o` in place of `0`).

---

## Core Algorithms (Implemented Manually)

No external libraries are used for parsing or validation. The core parsing rules are written in pure Dart in [parsers.dart](file:///e:/solulab_assignment/lib/core/utils/parsers.dart):

1. **Luhn Algorithm (`isValidCard`)**:
   * Evaluates the checksum of numeric sequences of length 9 to 19 to determine whether the card number is mathematically valid.
2. **Card Parser (`parseCard`)**:
   * Scans for card number candidates, correcting common OCR digit misreads (`O` -> `0`, `I`/`l`/`i` -> `1`, `S` -> `5`, `Z` -> `2`, `B` -> `8`).
   * Validates each candidate using the Luhn algorithm, retaining the longest valid sequence.
   * Matches expiry patterns (`MM/YY`, `MM-YY`, `MM/YYYY`, `MMYY`) and normalizes them to `MM/YY`.
   * Filters and scores non-digit uppercase lines to identify the cardholder name, ignoring metadata labels (VISA, MasterCard, Bank, etc.).
3. **Passbook Parser (`parsePassbook`)**:
   * Scans for IFSC alphanumeric patterns (`[A-Za-z]{4}[0Oo][A-Za-z0-9]{6}`), auto-repairing the 5th character to `0`.
   * Identifies the account number (9 to 18 digits) by checking for nearby keywords (e.g., `A/C`, `Account`, `No`) and downscoring phone numbers (10 digits starting with 6-9) and postal codes (6 digits).
   * Extracts names by locating label flags (e.g., `Name:`, `Holder:`, `Customer:`) or prefix markers (`MR.`, `MRS.`, `SHRI`, `SMT`), fallback scoring general alphabetic candidates.

---

## Steps to Run the Project

### Prerequisites
* Flutter SDK (3.10.x or above recommended)
* Android SDK / Xcode for iOS
* A physical device or emulator/simulator with camera capabilities

### Run Commands
1. Clone or copy the project folder into your workspace.
2. Navigate to the project root and get the dependencies:
   ```bash
   flutter pub get
   ```
3. Run the unit test suite to verify the parsing algorithms:
   ```bash
   flutter test
   ```
4. Connect your device/emulator and run the application:
   ```bash
   flutter run
   ```

---

## Libraries Used

* [**GetX** (`get: ^4.6.6`)](https://pub.dev/packages/get): For lightweight state management, reactive streams (`Rx`), and dependency injection.
* [**Camera** (`camera: ^0.12.0+1`)](https://pub.dev/packages/camera): For controlling device cameras, displaying real-time inline viewfinder previews, and snapping photos.
* [**Image Picker** (`image_picker: ^1.1.2`)](https://pub.dev/packages/image_picker): For picking/uploading images from the system gallery.
* [**Google ML Kit Text Recognition** (`google_mlkit_text_recognition: ^0.13.0`)](https://pub.dev/packages/google_mlkit_text_recognition): On-device ML Kit OCR for low-latency text extraction without external API overhead.

---

## Assumptions Made

1. **OCR Correction Bounds**:
   * OCR engine misreads digit segments frequently under poor lighting (e.g., replacing `0` with `O` or `1` with `I`/`l`). We assume these character replacements can be safely made inside numeric-dominant segments.
2. **Indian Bank Standard Formats**:
   * IFSC code follows the standard format: 4 alphabetical letters, followed by a `0` (zero), followed by 6 alphanumeric characters.
   * Account numbers are assumed to be 9 to 18 digits long. Phone numbers are assumed to be 10 digits beginning with 6, 7, 8, or 9, and pincodes are 6 digits.
3. **Cardholder Names**:
   * Cardholder names are assumed to consist of 2 to 4 alphabetic words, typically in uppercase, and located away from lines containing card brands (Visa, MasterCard, etc.) or terms like "VALID THRU".

---

## What Was Skipped and Why

1. **Backend / Cloud OCR Services**:
   * **Why**: To adhere strictly to the objective of offline-first local scanning and avoiding network latencies or billing costs. On-device Google ML Kit is used instead.
2. **Continuous Real-time OCR Stream Processing**:
   * **Why**: Real-time continuous processing of every camera feed frame (doing OCR 30 times per second) results in high CPU thrashing, high battery drainage, and very noisy OCR reads (blurry frames yield bad text). Instead, we use a live inline viewfinder preview, and run high-resolution OCR on-demand when the user clicks capture, which provides the highest text recognition accuracy and optimal device performance.
3. **External NLP/Parsing Libraries**:
   * **Why**: The assignment instructions explicitly command: *"You must NOT use any library for parsing extracted data."* Therefore, all extraction is performed via native Regex and manual scoring logic.
