import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../core/utils/parsers.dart';

class CardScannerController extends GetxController {
  CameraController? cameraController;
  var isCameraInitialized = false.obs;

  var isProcessing = false.obs;
  var imagePath = ''.obs;
  var cardDetails = Rxn<CardDetails>();
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    initializeCamera();
  }

  @override
  void onClose() {
    cameraController?.dispose();
    super.onClose();
  }

  Future<void> initializeCamera() async {
    try {
      isCameraInitialized.value = false;
      errorMessage.value = '';
      
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        errorMessage.value = 'No cameras detected on this device.';
        return;
      }

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await cameraController!.initialize();
      isCameraInitialized.value = true;
    } catch (e) {
      errorMessage.value = 'Failed to initialize camera: ${e.toString()}';
    }
  }

  Future<void> captureAndScanCard() async {
    if (cameraController == null || !isCameraInitialized.value) {
      errorMessage.value = 'Camera is not ready. Please wait or restart.';
      return;
    }

    try {
      errorMessage.value = '';
      isProcessing.value = true;

      final XFile photo = await cameraController!.takePicture();
      imagePath.value = photo.path;

      // Initialize ML Kit Text Recognizer
      final inputImage = InputImage.fromFilePath(photo.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      // Parse OCR result
      final parsed = Parsers.parseCard(recognizedText.text);
      cardDetails.value = parsed;

      if (parsed.cardNumber.isEmpty) {
        errorMessage.value = 'Failed to extract a valid card number. Please align the card and try again.';
      } else if (!parsed.isValid) {
        errorMessage.value = 'Invalid card number according to Luhn check validation.';
      }
    } catch (e) {
      errorMessage.value = 'An error occurred during scanning: ${e.toString()}';
    } finally {
      isProcessing.value = false;
    }
  }

  void reset() {
    imagePath.value = '';
    cardDetails.value = null;
    errorMessage.value = '';
    isProcessing.value = false;
    // Re-initialize camera if it was disposed or lost
    if (cameraController == null || !cameraController!.value.isInitialized) {
      initializeCamera();
    }
  }
}
