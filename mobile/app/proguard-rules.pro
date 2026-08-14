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

# Preserve line number information for readable stack traces / ANRs
# (usado junto com o mapping.txt gerado pelo R8 no Play Console).
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Gson faz parsing por reflexão nos nomes dos campos. As classes em
# api.ApiModels já usam @SerializedName em todos os campos, mas as
# classes abaixo são serializadas/desserializadas via Gson sem essa
# anotação (ex.: ItemVenda persistido como JSON na base Room). Sem
# manter os nomes dos campos, dados já gravados por utilizadores com
# uma build anterior (não ofuscada) deixariam de ser lidos após o
# upgrade para uma build ofuscada.
-keepclassmembers class tech.e258tech.paycore.repository.ItemVenda { *; }
-keepclassmembers class tech.e258tech.paycore.ui.LoginTerminalActivity$QrPayload { *; }
-keepclassmembers class tech.e258tech.paycore.AdminTerminalCriarActivity$QrActivacao { *; }

# Classes de resposta da API (Retrofit + Gson) — mantém os nomes dos
# campos anotados com @SerializedName mesmo com allowobfuscation.
-keepclassmembers,allowobfuscation class tech.e258tech.paycore.api.** {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keepattributes Signature
-keepattributes *Annotation*