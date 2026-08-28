# Basic ProGuard rules for Flutter + Firebase
# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }

# Firebase and Google Play services
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep JSON-model classes if reflection is used
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep annotation attributes
-keepattributes *Annotation*

# Keep native method names
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
