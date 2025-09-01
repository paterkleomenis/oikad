# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Preserve Flutter engine
-dontwarn io.flutter.embedding.**

# Keep package info classes
-keep class android.content.pm.PackageInfo { *; }
-keep class android.content.pm.ApplicationInfo { *; }

# Keep Supabase/Dio related classes
-keep class io.supabase.** { *; }
-keep class com.dio.** { *; }
-keepnames class retrofit2.** { *; }

# Keep serialization classes
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep OIKAD specific classes
-keep class com.oikad.app.** { *; }

# Keep file provider
-keep class androidx.core.content.FileProvider { *; }

# Keep permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# Keep Android Intent Plus
-keep class dev.fluttercommunity.plus.androidintent.** { *; }

# Remove debug logging in release builds
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}
