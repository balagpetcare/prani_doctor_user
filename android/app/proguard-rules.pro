# Keep Firebase / Flutter / Gson for release shrinking.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

-keepattributes *Annotation*
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
