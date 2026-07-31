# kotlinx.serialization keeps its generated serializers via companion objects.
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.**

-keepclassmembers class com.jarvis.wlan.** {
    *** Companion;
}
-keepclasseswithmembers class com.jarvis.wlan.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# OkHttp pulls in optional platform classes that are absent on Android.
-dontwarn okhttp3.internal.platform.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
