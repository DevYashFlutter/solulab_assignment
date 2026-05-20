# Google ML Kit ProGuard Rules
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-keep class com.google.android.gms.internal.mlkit_translate.** { *; }
-dontwarn com.google.android.gms.internal.mlkit_translate.**

# Camera & Pigeon Channel Rules
-keep class io.flutter.plugins.camera.** { *; }
-keep class dev.flutter.pigeon.** { *; }
-dontwarn io.flutter.plugins.camera.**
-dontwarn dev.flutter.pigeon.**

# General Android Support and Common Libraries
-dontwarn javax.annotation.**
-dontwarn sun.misc.Unsafe
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
