# R8 / ProGuard rules for release builds.
#
# minifyEnabled and shrinkResources are both on, so anything reached only by
# reflection must be kept explicitly or it gets stripped and the app crashes at
# runtime — typically on first Firebase call, which is easy to miss because
# debug builds are unaffected.
#
# Firebase and Flutter ship their own consumer rules; these are the additions
# that are commonly still needed.

# ── Flutter ──────────────────────────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# The Flutter embedding references Play Core's deferred-component and
# split-install APIs, but this app doesn't use deferred components and doesn't
# depend on Play Core, so those classes are absent at compile time and R8 fails
# on the dangling references. Nothing here is reachable at runtime — suppress.
-dontwarn com.google.android.play.core.**

# ── Firebase / Google Play Services ──────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firestore maps documents onto model classes reflectively.
-keepclassmembers class * {
    @com.google.firebase.firestore.PropertyName <fields>;
    @com.google.firebase.firestore.PropertyName <methods>;
}

# ── Kotlin ───────────────────────────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

# ── Keep annotations and signatures used at runtime ──────────────────────────
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Preserve line numbers so Crashlytics stack traces stay readable.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
