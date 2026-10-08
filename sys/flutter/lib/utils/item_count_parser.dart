/// アイテム名からの数量パースおよび個数選択ガード判定ユーティリティ
class ItemCountParser {
  /// アイテム文字列からスタック最大個数（maxCount）を取得する。
  ///
  /// NetHack の表示規則:
  /// - 行頭にアクセラレータプレフィックス（例: "a - ", "( ) " 等）が存在する場合がある。
  /// - スタック（2個以上）の場合、プレフィックス除去後の行頭は必ず符号なし数字で始まる
  ///   （例: "4個の食料", "10本の+1矢", "4 rations of food", "10 +1 darts"）。
  /// - 単数（1個）の場合、文字またはエンチャント符号（+ / -）で始まる
  ///   （例: "+1 短剣", "呪われていない短剣", "a +1 dagger", "an uncursed dagger"）。
  static int parseMaxCount(String text) {
    var trimmed = text.trim();

    // 行頭のアクセラレータ記号（"a - ", "b ) " 等）を除去
    final accMatch = RegExp(r'^[a-zA-Z0-9$#\-]\s*[-)]\s*').firstMatch(trimmed);
    if (accMatch != null) {
      trimmed = trimmed.substring(accMatch.end).trim();
    }

    // 店の商品価格プレフィックス（例: "27 Zm, ", "150 zm , ", "50 zorkmids, " 等）を除去
    final priceMatch = RegExp(r'^\d+\s*(?:zm|zorkmids?|金貨)\s*,\s*', caseSensitive: false).firstMatch(trimmed);
    if (priceMatch != null) {
      trimmed = trimmed.substring(priceMatch.end).trim();
    }

    // プレフィックス除去後の先頭が符号なし整数で始まる場合のみ数量として抽出
    final countMatch = RegExp(r'^(\d+)').firstMatch(trimmed);
    if (countMatch != null) {
      final val = int.tryParse(countMatch.group(1)!);
      if (val != null && val > 0) {
        return val;
      }
    }

    return 1;
  }

  /// メニュープロンプトおよび選択モード（menuHow）から、個数選択（長押しスライダー）が有効な画面かを判定する。
  ///
  /// ブラックリスト方式を採用:
  /// 明確に個数指定が無効または未対応と判明している操作（飲む、読む、装備、支払い等）のみをガードし、
  /// それ以外（ドロップ、矢筒、浸す、袋・箱への出し入れ、投げる、持ち物一覧、未確認の操作等）はすべて個数選択を許可する。
  static bool isQuantitySelectionAllowed(String prompt, int menuHow) {
    final lower = prompt.toLowerCase();

    // 1. 支払い（Cコアが部分支払いに未対応）
    if (lower.contains("pay") || prompt.contains("支払")) {
      return false;
    }

    if (menuHow > 1) {
      // 複数選択: 支払い以外はすべて有効
      return true;
    }

    // 2. 単一選択で個数指定が明確に無効な操作（ブラックリスト）
    // - 飲む (q): 1ターンに1服のみ
    if (lower.contains("drink") || lower.contains("quaff") || prompt.contains("飲")) {
      return false;
    }
    // - 読む (r): 1巻物・1本単位
    if (lower.contains("read") || prompt.contains("読")) {
      return false;
    }
    // - 食べる (e): 1ターン1個単位
    if (lower.contains("eat") || prompt.contains("食")) {
      return false;
    }
    // - 防具・装飾品の装着/脱着 (W, P, T, R)
    if (lower.contains("wear") ||
        lower.contains("put on") ||
        prompt.contains("身につけ") ||
        prompt.contains("着") ||
        lower.contains("take off") ||
        lower.contains("remove") ||
        prompt.contains("はずす") ||
        prompt.contains("脱ぐ")) {
      return false;
    }
    // - 武器の装備・構え (w)
    if (lower.contains("wield") || prompt.contains("構え") || prompt.contains("装備")) {
      return false;
    }
    // - 杖を振る (z)
    if (lower.contains("zap") || prompt.contains("振")) {
      return false;
    }
    // - 名付け (#name)
    if (lower.contains("name") || lower.contains("call") || prompt.contains("名付")) {
      return false;
    }
    // - 識別 (scroll of identify)
    if (lower.contains("identify") || prompt.contains("識別")) {
      return false;
    }
    // - 充填 (scroll of charging)
    if (lower.contains("charge") || prompt.contains("充填")) {
      return false;
    }
    // - 油塗り
    if (lower.contains("grease") || prompt.contains("油を塗")) {
      return false;
    }

    // 上記以外の操作（ドロップ、矢筒、浸す、袋・箱への出し入れ、投げる、持ち物一覧等）はすべて許可
    return true;
  }
}
