// NOTICE: Created by NetHackJP contributor @satokiyon; latest change date: 2026-08-24.

import 'package:flutter/material.dart';

/// 各種ダイアログ（持ち物、全能力、倒した怪物、自主的な縛り等）のタイトル行判定および修飾描画ヘルパー
class DialogHeaderHelper {
  /// タイトルヘッダーとして完全一致判定するキーワード（日本語・英語）
  static const Set<String> _titleKeywords = {
    // --- 開示・能力・状態・実績系 ---
    '背景:',
    'Background:',
    '基本情報:',
    'Basics:',
    '能力値:',
    '現在の能力値:',
    '最終能力値:',
    'Base Attributes:',
    'Current Attributes:',
    'Final Attributes:',
    '状態:',
    '現在の状態:',
    '最終状態:',
    'Current Status:',
    'Final Status:',
    '能力:',
    '現在の能力:',
    '最終能力:',
    'Current Characteristics:',
    'Final Characteristics:',
    'その他:',
    'Other Properties:',
    'Miscellaneous:',
    '達成事項:',
    'Achievement:',
    'Achievements:',

    // --- 持ち物・アイテムカテゴリ系 ---
    '所持品:',
    'Inventory:',
    '最新メッセージ:',
    'Latest messages:',
    '武器',
    'Weapons',
    '防具',
    'Armor',
    '食べ物',
    '食品',
    'Food',
    'Comestibles',
    '指輪',
    'Rings',
    'お守り',
    '魔除け',
    '護符',
    'Amulets',
    '道具',
    'Tools',
    'ポーション',
    '薬',
    'Potions',
    '巻物',
    'Scrolls',
    '呪文の書',
    '魔法書',
    'Spellbooks',
    '杖',
    'Wands',
    'コイン',
    '金貨',
    'Coins',
    '宝石',
    '宝石/石',
    'Gems',
    'Gems/Stones',
    '巨石/彫像',
    'Boulders/Statues',
    '鉄球',
    'Iron balls',
    '鎖',
    'Chains',
    '毒液',
    'Venoms',
    '袋/箱の中の品物',
    'Bagged/Boxed items',

    // --- 倒した怪物系 ---
    '倒した怪物:',
    'Vanquished creatures:',
    '生成されたが倒していない怪物:',
    'Vanquished species:',
    '虐殺した怪物種:',
    '絶滅した怪物種:',
    '虐殺・絶滅した怪物種:',
    '根絶された種族:',
    '虐殺された種族:',
    'Genocided species:',
    'Extinct species:',
    'Genocided or extinct species:',

    // --- 自主的な縛り系 ---
    '自主的な縛り:',
    'Voluntary challenges:',
    '挑戦:',
    'Conduct:',

    // --- ショップ・オプション・ヘルプ系セクションヘッダー ---
    '販売中の商品:',
    'Fine goods for sale:',
    'すでに使用した未払い品:',
    'Unpaid articles already used up:',
    '方向キー:',
    'Directional keys:',
    'その他のキー:',
    'Miscellaneous keys:',
    '一般コマンド:',
    'General commands:',
    'ゲームコマンド:',
    'Game commands:',
    'デバッグモードのコマンド:',
    'Debug mode commands:',
    'メニュー操作キー:',
    'Menu control keys:',
    '複合オプション:',
    'Compound options:',
    'その他の設定:',
    'Other settings:',
  };

  /// プレイヤー能力値ダイアログの動的ヘッダー（例: "Satokの能力値（魔法使い）:", "Satok's attributes (Wizard):"）
  static final RegExp _playerAttributesRegex = RegExp(
    r"^(.+\s*の能力値（.+）:|.+\s*'s\s+attributes\s*\(.+\):)\s*$",
    caseSensitive: false,
  );

  /// 容器の中身ヘッダーの動的パターン（例: "袋 の中身:", "Contents of bag:"）
  static final RegExp _containerContentsRegex = RegExp(
    r'^(.+\s+の中身:|Contents\s+of\s+.+:)\s*$',
    caseSensitive: false,
  );

  /// 指定されたテキスト行がタイトルヘッダー行であるかどうかを判定
  static bool isDialogTitleHeader(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    // 完全一致キーワードチェック
    if (_titleKeywords.contains(trimmed)) {
      return true;
    }

    // プレイヤー能力値タイトルや容器の中身などの動的パターンチェック
    if (_playerAttributesRegex.hasMatch(trimmed) ||
        _containerContentsRegex.hasMatch(trimmed)) {
      return true;
    }

    return false;
  }

  /// タイトルヘッダー行を「バッジ / ピルスタイル」で装飾した Widget を生成して返す
  static Widget buildTitleHeaderBadge(String text, {double fontSize = 13.5}) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2214), // シックな暗色のアンバー/ゴールド系
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFFFC107).withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.label_important_outline_rounded,
            size: fontSize + 2,
            color: const Color(0xFFFFD54F),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text.trim(),
              style: TextStyle(
                color: const Color(0xFFFFD54F), // 鮮やかなゴールドカラー
                fontFamily: 'monospace',
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
