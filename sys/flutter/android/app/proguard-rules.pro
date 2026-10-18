# WorkManager & Room Database
-keep class * extends androidx.work.impl.WorkDatabase {
    public <init>();
}
-keep class androidx.work.impl.WorkDatabase_Impl {
    public <init>();
}
-keep class androidx.work.** { *; }
-keep class androidx.room.** { *; }

# Google Mobile Ads (AdMob)
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }

# SharedPreferences Android（Pigeon JNI 版）および package:jni の Kotlin コルーチン連携の保護
# shared_preferences_android 2.5.0 以降は Dart 側から JNI 経由でクラス名・メンバー名を
# 文字列で参照するが、同パッケージは consumerProguardFiles を同梱していない。
# R8 による難読化・削除が起きると NoSuchFieldError / ClassNotFoundException で
# 設定の読み書き時にネイティブクラッシュするため、参照対象をピンポイントで保護する。
# ※ 参照対象の一覧は jni パッケージの lib/src/kotlin.dart（JClass.forName / *FieldId / *MethodId）と
#    一致させること。jni をアップグレードした際は必ず再確認すること。

# Pigeon 生成クラス（SharedPreferencesApiRegistrar、FlutterError 等）をクラス名で参照
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# suspend fun の戻り値（kotlin.Result）の値フィールド
-keep class kotlin.Result {
    java.lang.Object value;
}
# 失敗結果の例外フィールドと、Dart 側例外を Kotlin へ返す際のコンストラクタ（エラー経路でのみ使用）
-keep class kotlin.Result$Failure {
    java.lang.Throwable exception;
    <init>(java.lang.Throwable);
}
# COROUTINE_SUSPENDED 判定用
-keep class kotlin.coroutines.intrinsics.IntrinsicsKt {
    public static java.lang.Object getCOROUTINE_SUSPENDED();
}
-keep class kotlin.coroutines.intrinsics.CoroutineSingletons { *; }
# void を返す suspend fun の完了値
-keep class kotlin.Unit {
    public static final kotlin.Unit INSTANCE;
}
# Dart 側 Future 完了時に Kotlin コルーチンを再開する
-keep interface kotlin.coroutines.Continuation {
    public void resumeWith(java.lang.Object);
}
