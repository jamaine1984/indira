# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**

# LiveKit
-keep class livekit.** { *; }
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }

# In-App Purchase
-keep class com.android.vending.billing.** { *; }

# Prevent stripping of annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses,EnclosingMethod

# Preserve R8/ProGuard rules for Gson/JSON serialization
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
