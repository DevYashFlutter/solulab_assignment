import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/parsers.dart';

class PassbookScannerController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  CameraController? cameraController;
  var isCameraInitialized = false.obs;

  var isProcessing = false.obs;
  var imagePath = ''.obs;
  var bankDetails = Rxn<BankDetails>();
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

  Future<void> captureAndScanPassbook() async {
    if (cameraController == null || !isCameraInitialized.value) {
      errorMessage.value = 'Camera is not ready. Please wait or restart.';
      return;
    }

    try {
      errorMessage.value = '';
      isProcessing.value = true;

      final XFile photo = await cameraController!.takePicture();
      imagePath.value = photo.path;

      await _processImage(photo.path);
    } catch (e) {
      errorMessage.value = 'An error occurred during scanning: ${e.toString()}';
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> uploadFromGallery() async {
    try {
      errorMessage.value = '';
      isProcessing.value = true;

      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) {
        isProcessing.value = false;
        return;
      }

      imagePath.value = file.path;
      await _processImage(file.path);
    } catch (e) {
      errorMessage.value = 'An error occurred during scanning: ${e.toString()}';
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> _processImage(String path) async {
    // Initialize ML Kit Text Recognizer
    final inputImage = InputImage.fromFilePath(path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    // Parse OCR result
    final parsed = Parsers.parsePassbook(recognizedText.text);
    bankDetails.value = parsed;

    if (parsed.accountNumber.isEmpty) {
      errorMessage.value = 'Failed to extract a valid bank account number. Please ensure the document is clear.';
    }
  }

  void reset() {
    imagePath.value = '';
    bankDetails.value = null;
    errorMessage.value = '';
    isProcessing.value = false;
    // Re-initialize camera if it was disposed or lost
    if (cameraController == null || !cameraController!.value.isInitialized) {
      initializeCamera();
    }
  }
}
