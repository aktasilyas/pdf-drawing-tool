# R8 rules for the release build (#192). Flutter's Gradle plugin adds the
# engine rules; plugins ship their own consumer rules.

# Crashlytics: readable Java/Kotlin stack traces and custom exceptions.
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# The Flutter engine references Play Core (deferred components), which this
# app does not use.
-dontwarn com.google.android.play.core.**

# No rules needed for: drift (pure Dart), sqlite3_flutter_libs (native .so,
# no reflection), pdfx (android.graphics.pdf.PdfRenderer), pdf (pure Dart).
# The release workflow's emulator smoke test is the guard for missing rules.
