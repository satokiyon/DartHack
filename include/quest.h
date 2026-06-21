/* Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-21. */
/* NetHack 5.0	quest.h	$NHDT-Date: 1781973086 2026/06/20 16:31:26 $  $NHDT-Branch: NetHack-5.0 $:$NHDT-Revision: 1.16 $ */
/* Copyright (c) Mike Stephenson 1991.                            */
/* NetHack may be freely redistributed.  See license for details. */

#ifndef QUEST_H
#define QUEST_H

struct q_score {              /* クエストの「スコアカード」 */
    Bitfield(first_start, 1); /* 初回のみ設定 */
    Bitfield(met_leader, 1);  /* リーダーに会ったことがある */
    Bitfield(not_ready, 3);   /* 属性不一致などで拒否された */
    Bitfield(pissed_off, 1);  /* リーダーを怒らせた */
    Bitfield(got_quest, 1);   /* クエスト任務を受けた */
    Bitfield(killed_leader, 1); /* クエストリーダーを倒した */

    Bitfield(first_locate, 1); /* 初回のみ設定 */
    Bitfield(met_intermed, 1); /* locate 対象が人物の場合に使用 */
    Bitfield(got_final, 1);    /* 最終クエスト任務を受けた */

    Bitfield(made_goal, 3);      /* ゴール階層に到達した回数 */
    Bitfield(met_nemesis, 1);    /* 以前に宿敵へ会ったことがある */
    Bitfield(killed_nemesis, 1); /* 宿敵を倒したときに設定 */
    Bitfield(in_battle, 1);      /* 宿敵と戦闘中に設定 */

    Bitfield(cheater, 1);          /* 不正行為を検出した場合に設定 */
    Bitfield(touched_artifact, 1); /* 特別メッセージ用 */
    Bitfield(offered_artifact, 1); /* リーダーへ捧げた */
    Bitfield(got_thanks, 1);       /* リーダーからの最終メッセージ受領 */

    /* questpgr コードで、メッセージが代名詞を使う際に使用
       （モンスター生成まで待たずゲーム開始時に設定する。
       各1ビットでも足りるが、関係者に中性は実質いない） */
    Bitfield(ldrgend, 2); /* リーダーの性別: 0=male, 1=female, 2=neuter */
    Bitfield(nemgend, 2); /* 宿敵の性別 */
    Bitfield(godgend, 2); /* 神の性別 */

    /* リーダーが変身・蘇生などしても、在/不在を追跡する */
    Bitfield(leader_is_dead, 1);
    unsigned leader_m_id;
};

#define MIN_QUEST_ALIGN 20 /* 開始には最低この align.record が必要 */
/* 注: align 20 は enlightenment (cmd.c) で表示される "pious" と一致 */
#define MIN_QUEST_LEVEL 14 /* 開始には最低この u.ulevel が必要 */
/* 注: exp.lev. 14 は 5番目の称号ランクの閾値 (class title, role.c) */

#endif /* QUEST_H */

