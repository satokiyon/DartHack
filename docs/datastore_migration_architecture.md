# SharedPreferencesAsync（Jetpack DataStore）移行および設定データ管理仕様書

本書は、DartHack（NetHackJP Flutter ポート）における設定永続化層を従来の Legacy `SharedPreferences`（XML / `FlutterSharedPreferences`）から `SharedPreferencesAsync` / `SharedPreferencesWithCache`（Android Jetpack DataStore / protobuf）へ完全移行した背景、移行アーキテクチャ、実装詳細、テスト検証、および**将来の設定項目追加・スキーマ変更時におけるガイドライン**を記録した設計ドキュメントです。

---

## 1. 移行の背景と技術的課題

### 1.1 Flutter 公式推奨と Legacy SharedPreferences の非推奨化
Flutter 公式の `shared_preferences` パッケージ（v2.3.0 以降、特に v2.5.0+）において、従来の同期キャッシュ型 API（`SharedPreferences.getInstance()`）はレガシー API として位置づけられ、非同期型の `SharedPreferencesAsync` および必要に応じてメモリキャッシュを伴う `SharedPreferencesWithCache` の利用が強く推奨されるようになりました。

### 1.2 Android プラットフォームにおける二重ストレージ問題
Android ネイティブ層において、`shared_preferences` パッケージのバックエンドは以下のように根本的に異なります：
- **Legacy API (`SharedPreferences.getInstance()`)**:
  - 保存先: `/data/user/0/<package>/shared_prefs/FlutterSharedPreferences.xml`
  - 形式: Android 標準の SharedPreferences XML
  - 特徴: キーに `flutter.` プレフィックスが付与され、型情報（`VGhpcyBpcyB0aGUgcHJlZml4...`）が埋め込まれる。
- **Modern API (`SharedPreferencesAsync` / `SharedPreferencesWithCache`)**:
  - 保存先: `/data/user/0/<package>/files/datastore/...`
  - 形式: Android Jetpack DataStore（Protocol Buffers バイナリ形式）
  - 特徴: Kotlin Coroutines と Flow をベースとした堅牢な非同期 I/O。

> [!WARNING] 設定消失（初期化）のリスク
> バックエンドが異なるため、旧バージョンのアプリがインストールされた端末に新バージョンを上書きインストールした場合、DataStore 側には旧 XML のデータが自動では引き継がれません。何の移行処理も行わずに新 API を呼び出すと、**既存ユーザーが設定した操作パネル配置、BGM/SE音量、チュートリアル設定、ハードモードフラグ等がすべて消失して初期化される重大障害**が発生します。

### 1.3 パフォーマンス要件（キャッシュの必要性）
純粋な `SharedPreferencesAsync` を直接使用すると、`getString()` や `getBool()` の呼び出しごとに JNI 往復（MethodChannel / Pigeon JNI）および DataStore の Flow 読み出しが発生します。
DartHack の起動時や設定画面表示時には数十〜百個の設定キーを一括で参照するため、同期メモリキャッシュを提供する `SharedPreferencesWithCache` を採用し、**「起動時に全キーを一括ロードした後は同期キャッシュからゼロ遅延で取得」「書き込み時は同期キャッシュを即座に更新しつつ DataStore へ非同期永続化」** というハイブリッド構成を採用する必要がありました。

---

## 2. 移行計画と設計判断（Architecture Decisions）

開発にあたり、以下の 4 つの重要設計判断を行いました：

| # | 検討項目 | 採用した設計 | 理由・効果 |
|---|---|---|---|
| **1** | アクセス手段 | 共通ラッパー `AppPrefs` を導入（内部で `SharedPreferencesWithCache` を利用） | アプリ本体 11 ファイルからの呼び出しを統一。起動時の初期化、排他制御、システムキー保護、テスト用モック注入を一元管理。 |
| **2** | 旧 XML データの扱い | 移行完了後に `legacyPrefs.clear()` で完全消去 | 端末内部ストレージの肥大化と不要な二重管理を防止。ユーザーの明示的選択に従う。 |
| **3** | 例外安全性（消去条件） | DataStore への全型コピーと完了フラグ永続化が**両方とも正常完了した直後のみ**旧 XML を消去 | 移行途中のクラッシュや電源断時にも旧 XML が残り、次回起動時に安全に再試行可能。 |
| **4** | システム保護キーの管理 | `AppPrefs.isSystemKey(key)` による多重防御（`__` プレフィックス＋既知キー） | 設定画面の「設定リセット」や「JSON エクスポート/インポート」で移行完了フラグやアセット管理キーが消去・上書きされる事故を防御。 |

---

## 3. 実装アーキテクチャ

### 3.1 クラス構造とデータフロー (`lib/utils/app_prefs.dart`)

```mermaid
flowchart TD
    subgraph App_Boot [アプリ起動フェーズ (main.dart)]
        Start([main 実行]) --> Bind[WidgetsFlutterBinding.ensureInitialized]
        Bind --> GetInst[await AppPrefs.getInstance]
    end

    subgraph AppPrefs_Init [AppPrefs.getInstance() 内部処理]
        GetInst --> CheckComp{Completer 存在?}
        CheckComp -- Yes --> WaitComp[進行中の Future を待機]
        CheckComp -- No --> InitDataStore[SharedPreferencesAsync 初期化]
        InitDataStore --> CheckFlag{完了フラグ確認<br/>__datastore_migration_v1_completed__}
        
        CheckFlag -- true (移行済 / 新規) --> CreateCache[SharedPreferencesWithCache.create]
        CheckFlag -- false (未移行) --> ScanLegacy[旧 SharedPreferences.getInstance<br/>legacyPrefs.getKeys]
        
        ScanLegacy --> CopyLoop[全キーを DataStore へ型安全コピー<br/>bool / int / double / String / List]
        CopyLoop --> WriteFlag[完了フラグを DataStore に永続化<br/>setBool: true]
        WriteFlag --> ClearLegacy[旧 XML を完全消去<br/>legacyPrefs.clear]
        ClearLegacy --> CreateCache
        
        CreateCache --> MemCache[(メモリ同期キャッシュ<br/>全キー一括ロード完了)]
        MemCache --> RetInst[AppPrefs シングルトン返却]
    end

    subgraph App_Runtime [実行時アクセス]
        RetInst --> Read["同期読み出し: prefs.getBool, getInt, getString, getKeys...<br/>(ゼロ遅延・ディスクI/Oなし)"]
        RetInst --> Write["非同期書き込み: await prefs.setBool, setInt, setDouble...<br/>(メモリ即座更新 ＋ DataStore非同期永続化)"]
        RetInst --> Reset["設定リセット: await prefs.clearUserPreferences()<br/>(isSystemKey を除外して削除)"]
    end
```

### 3.2 システム保護キー（System Keys）の仕様
以下のキーはユーザー設定ではなく、アプリの内部状態および整合性を管理するシステムキーとして定義されています：

1. **移行完了フラグ**:
   - `__datastore_migration_v1_completed__` (`bool`): DataStore への移行が成功したことを示す。
2. **アセット展開・バージョン管理キー**:
   - `verDat` (`int`): 端末ストレージに展開されたデータファイルアセットのバージョン。
   - `datadir` (`String`): 端末ストレージ上の NetHack データフォルダ絶対パス。
   - `cCoreBuildId` (`String`): 展開された C コア共有ライブラリのビルド識別子。
3. **将来のシステム拡張**:
   - 先頭が `__`（ダブルアンダースコア）で始まるすべてのキー。

#### 保護ルール
- **設定リセット (`clearUserPreferences()` / `_resetAppSettings()`)**:
  - `AppPrefs.isSystemKey(key)` が `true` のキーは一切削除せず、ユーザー設定（操作パッド設定、BGM音量等）のみを削除します。
- **設定 JSON エクスポート (`_exportSettings()`)**:
  - システムキーは JSON 出力に含まれません（プライベートな端末パスやバージョンが外部に漏洩・コピーされるのを防止）。
- **設定 JSON インポート (`_importSettings()`)**:
  - 外部 JSON にシステムキーが含まれていた場合でも、`isSystemKey` チェックにより上書きを完全に無視（スキップ）します。

### 3.3 新規インストール端末でのライフサイクル
新規端末では旧 SharedPreferences の XML ファイルが存在しません：
1. 初回起動時、`__datastore_migration_v1_completed__` は `false`。
2. `legacyPrefs.getKeys()` は空集合（0 件）。
3. コピーループは 0 回でスキップされ、DataStore に `__datastore_migration_v1_completed__ = true` が書き込まれる。
4. `legacyPrefs.clear()` が呼ばれ、正常に完了。
5. デフォルト設定（`DefaultsHelper.applyDefaults()` 等）が DataStore に書き込まれる。
6. 2回目以降の起動ではフラグが `true` のため、マイグレーション処理は一切行われず DataStore から復元される。

---

## 4. テスト検証体制

単体テストおよび Widget テストにおいて、ネイティブ OS なしで DataStore および Legacy の動作を決定論的に検証できるよう、テストインフラを整備しました。

### 4.1 テスト用モック設計 (`AppPrefs.setMockInitialValues`)
- `package:shared_preferences_platform_interface` の `InMemorySharedPreferencesAsync` を活用。
- `AppPrefs.setMockInitialValues(Map<String, Object> values)` を呼び出すことで：
  1. シングルトンインスタンスと `Completer` をリセット。
  2. Legacy 側のモック値を設定。
  3. `SharedPreferencesAsyncPlatform.instance` を `InMemorySharedPreferencesAsync.withData(initialData)` で自動バインド。
  4. マイグレーション完了フラグを付与して即座に使用可能な状態を提供。

### 4.2 実施テスト一覧 (`test/shared_preferences_upgrade_test.dart`)

| テストケース | 検証内容 | 結果 |
|---|---|:---:|
| **旧 XML からの全データ移行と消去** | double, int, bool, String, List<String> が DataStore に完全コピーされ、完了後に `legacyPrefs.getKeys()` が空になること | **PASS** |
| **2回目以降のマイグレーションスキップ（冪等性）** | 完了フラグが存在する場合、旧 XML に異なる値があっても上書きされず DataStore の値が優先されること | **PASS** |
| **新規インストール端末の初回・次回起動** | 旧データが空の状態で初回起動し、フラグが保存され、設定値が次回起動に引き継がれること | **PASS** |
| **設定リセット時のシステムキー保護** | `clearUserPreferences()` 実行後、`verDat`, `datadir`, `cCoreBuildId`, `__*__` が残り、ユーザー設定のみ消去されること | **PASS** |
| **並行呼び出し時の排他制御** | 複数箇所から同時に `AppPrefs.getInstance()` を呼び出しても `Completer` により初期化が 1 回しか行われないこと | **PASS** |
| **DefaultsHelper 連携マージ** | アセット更新時に既存ユーザー設定が維持され、新しい defaults.nh オプションが安全に補完されること | **PASS** |

> 全ユニットテスト（`flutter test` 205 件）および静的解析（`flutter analyze`）にて警告・エラー 0 件を確認済み。

---

## 5. 将来の設定データ仕様変更ガイドライン

今後、新しい設定項目の追加、データ型の変更、または設定の移行・廃止を行う開発者は、以下のガイドラインに従ってください。

### 5.1 新しい設定項目の追加手順
1. **キー名の命名規則**:
   - ユーザー設定: スネークケース（例: `auto_open_doors`, `vibration_strength`）
   - defaults.nh 連動オプション: `nh_opt_<NetHackオプション名>`（例: `nh_opt_autopickup`, `nh_opt_name`）
   - システム管理用キー: `__<機能名>__`（例: `__sound_cache_version__`）
2. **読み出しと書き込み**:
   - 必ず `final prefs = await AppPrefs.getInstance();` を経由してアクセスしてください。直接 `SharedPreferences.getInstance()` や `SharedPreferencesAsync()` を呼んではなりません。
   ```dart
   final prefs = await AppPrefs.getInstance();
   final isAutoOpen = prefs.getBool('auto_open_doors') ?? true;
   await prefs.setBool('auto_open_doors', false);
   ```
3. **DefaultsHelper 連動オプションの場合**:
   - `lib/utils/defaults_helper.dart` の `managedKeys` セットに NetHack オプション名を追加してください。
   - `syncFromFileToPrefs` および `syncFromPrefsToFile` にパース・シリアライズ処理を追加してください。

### 5.2 既存設定のデータ型変更・スキーママイグレーション手順
もし将来、既存のキー（例: `int` だった設定を `String` や `Map` に変更するなど）の構造変更が必要になった場合：

1. **バージョンフラグの導入**:
   - `AppPrefs` に新しいマイグレーションフラグ（例: `__datastore_migration_v2_completed__`）を定義します。
2. **マイグレーション関数の追加**:
   - `AppPrefs.getInstance()` 内で v2 フラグをチェックし、未完了ならマイグレーション関数を実行します。
   ```dart
   final isV2Migrated = await asyncPrefs.getBool('__datastore_migration_v2_completed__') ?? false;
   if (!isV2Migrated) {
     await _migrateToV2(asyncPrefs);
     await asyncPrefs.setBool('__datastore_migration_v2_completed__', true);
   }
   ```
3. **安全な型変換**:
   - 既存の値を `asyncPrefs.getInt(...)` 等で取得し、新形式に変換して `asyncPrefs.setString(...)` 等で保存、旧キーが不要であれば `asyncPrefs.remove(...)` します。

### 5.3 テスト作成時のルール
新しい画面や機能の単体テスト（Widget テスト）を作成する際は、`setUp` 内で必ず `AppPrefs.setMockInitialValues` を呼び出してください：

```dart
setUp(() async {
  await AppPrefs.setMockInitialValues({
    'selected_language': 'ja',
    'pad_opacity': 0.8,
  });
});
```
これにより、`SharedPreferencesAsyncPlatform` の未設定エラー（`Bad state: The SharedPreferencesAsyncPlatform instance must be set.`）を確実に防止できます。

---

## 6. クラウドバックアップ方針（設定データ除外とセーブデータ保護）

### 6.1 設計方針: 設定データ（DataStore）のクラウドバックアップ除外
DartHack では、**設定データ（Jetpack DataStore: `files/datastore` および旧 SharedPreferences: `shared_prefs`）を Google ドライブ等のクラウド自動バックアップの対象から意図的に除外** しています。

#### 理由と背景
1. **将来のバージョン乖離・スキーマ不整合リスクの排除**:
   - アプリの設定構造やUIレイアウトは、アップデートに伴い今後も機能追加や改修が入る可能性があります。
   - 数年ぶりに別機種へ機種変更した際など、Google ドライブに長期間保管されていた「古すぎる設定データ」が最新バージョンのアプリへ勝手にリストアされると、予期せぬ型不整合やレイアウト崩れ、壊れたキー値による起動障害を引き起こすリスクがあります。
2. **新規クリーン環境での安全起動**:
   - 機種変更時、新端末では常に最新のデフォルト設定（`DefaultsHelper.applyDefaults()`）が適用されるため、最も安定した状態でゲームを開始できます。

### 6.2 セーブデータ・スコアファイルのバックアップ維持
一方で、プレイヤーがダンジョンを探索した進行状況（セーブデータ `save/`）、ハイスコア（`record`）、行動ログ（`logfile`, `xlogfile`）などのゲーム資産は、**`backup_rules.xml` および `data_extraction_rules.xml` により自動バックアップ対象として堅牢に保護** されています。

```xml
<!-- sys/flutter/android/app/src/main/res/xml/data_extraction_rules.xml -->
<data-extraction-rules>
    <cloud-backup>
        <!-- NetHack データ本体（セーブデータ、スコアファイル等）のみを安全に保護 -->
        <include domain="file" path="nethackdir" />
    </cloud-backup>
    <device-transfer>
        <include domain="file" path="nethackdir" />
    </device-transfer>
</data-extraction-rules>
```

これにより、**「機種変更しても大切なセーブデータやハイスコアは自動で引き継がれつつ、設定データは古すぎるゴミデータによる破壊リスクを避けて最新のクリーンなデフォルトで初期化される」** という理想的で安全な運用設計を維持しています。

