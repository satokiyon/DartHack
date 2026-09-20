#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
process_audio.py
ffmpeg を使用した効果音のポストプロセス（無音トリム・EBU R128ラウドネス正規化・Opusエンコード）。
"""

import subprocess
import json
from pathlib import Path
from typing import Optional, Dict, Any

def get_audio_info(file_path: Path) -> Dict[str, Any]:
    """ffprobe を使用して音声ファイルのメタデータを取得する"""
    cmd = [
        "ffprobe",
        "-v", "error",
        "-select_streams", "a:0",
        "-show_entries", "stream=codec_name,channels,sample_rate,duration:format=duration",
        "-of", "json",
        str(file_path)
    ]
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace", check=True)
        data = json.loads(res.stdout)
        stream = data.get("streams", [{}])[0]
        duration = float(stream.get("duration") or data.get("format", {}).get("duration", 0.0))
        return {
            "codec": stream.get("codec_name", "unknown"),
            "channels": int(stream.get("channels", 2)),
            "sample_rate": int(stream.get("sample_rate", 48000)),
            "duration": duration
        }
    except Exception as e:
        return {"error": str(e), "duration": 0.0, "channels": 2, "sample_rate": 48000}

def normalize_and_convert(
    input_path: Path,
    output_path: Path,
    target_lufs: float = -14.0,
    true_peak: float = -1.5,
    is_stereo: bool = False,
    bitrate: str = "64k",
    start_offset: Optional[float] = None,
    duration: Optional[float] = None,
    highpass_cutoff: Optional[int] = None,
    mode: str = "auto"  # "auto", "sfx" (peak norm + comp), "bgm" (loudnorm)
) -> bool:
    """
    音源を正規化・Opus変換して出力する。
    - 短音効果音（< 3.0s または mode="sfx"）:
        先頭無音トリミング (-45dB) + 軽コンプレッサー + ピーク正規化 (-1.5 dBFS)
        ※ 短音に対する loudnorm の過度な誤減衰・無音化を完全に防止する。
    - 長尺・BGM音源（mode="bgm" または (mode="auto" and >= 3.0s)）:
        曲頭を壊さないソフト無音処理 (-60dB) + EBU R128 ラウドネス正規化 (loudnorm)
        ※ BGMモード時はデフォルトで target_lufs=-18.0, is_stereo=True, bitrate="96k" を推奨。
    """
    output_path.parent.mkdir(parents=True, exist_ok=True)

    info = get_audio_info(input_path)
    file_dur = duration if duration is not None else info.get("duration", 0.0)

    use_sfx_mode = (mode == "sfx") or (mode == "auto" and file_dur < 3.0)
    is_bgm_mode = (mode == "bgm")

    # BGMモード時のパラメータ自動補正（未指定またはデフォルト値の場合）
    if is_bgm_mode:
        if target_lufs == -14.0:
            target_lufs = -18.0
        if bitrate == "64k":
            bitrate = "96k"

    base_filters = []
    # 1. 先頭の無音トリミング
    # BGMの場合は曲頭のフェードインやパッド音を切り落とさないよう -60dB の極めてソフトな閾値で処理
    if is_bgm_mode:
        base_filters.append("silenceremove=start_periods=1:start_duration=0.01:start_threshold=-60dB")
    else:
        base_filters.append("silenceremove=start_periods=1:start_duration=0.01:start_threshold=-45dB")

    # 2. ハイパスフィルター（任意）
    if highpass_cutoff is not None and highpass_cutoff > 0:
        base_filters.append(f"highpass=f={highpass_cutoff}")

    if use_sfx_mode:
        # 短音効果音モード: 軽いコンプレッサーで音圧を整え、ピークを目標値（例: -1.5dB）に正規化
        # コンプレッサーでアタックを保ちつつ実効音量を補強
        comp_filter = "acompressor=threshold=-16dB:ratio=2.5:attack=10:release=100:makeup=2dB"
        detect_filters = base_filters + [comp_filter, "volumedetect"]
        detect_str = ",".join(detect_filters)

        cmd_det = ["ffmpeg", "-i", str(input_path), "-vn"]
        if start_offset is not None and start_offset > 0:
            cmd_det.extend(["-ss", f"{start_offset:.3f}"])
        if duration is not None and duration > 0:
            cmd_det.extend(["-t", f"{duration:.3f}"])
        cmd_det.extend(["-af", detect_str, "-f", "null", "-"])

        det_res = subprocess.run(cmd_det, capture_output=True, text=True, encoding="utf-8", errors="replace")
        max_v = 0.0
        det_stderr = det_res.stderr or ""
        for l in det_stderr.splitlines():
            if "max_volume" in l:
                try:
                    max_v = float(l.split("max_volume:")[1].replace("dB", "").strip())
                except Exception:
                    max_v = 0.0
                break

        # 目標ピーク値 (true_peak) に合わせるゲイン
        gain = true_peak - max_v
        final_filters = base_filters + [comp_filter, f"volume={gain:.2f}dB"]
        filter_str = ",".join(final_filters)
    else:
        # 長尺・BGMモード: EBU R128 ラウドネス正規化
        final_filters = base_filters + [f"loudnorm=I={target_lufs}:TP={true_peak}:LRA=11"]
        filter_str = ",".join(final_filters)

    cmd = ["ffmpeg", "-y"]

    if start_offset is not None and start_offset > 0:
        cmd.extend(["-ss", f"{start_offset:.3f}"])

    if duration is not None and duration > 0:
        cmd.extend(["-t", f"{duration:.3f}"])

    cmd.extend(["-i", str(input_path)])
    cmd.append("-vn")
    cmd.extend(["-af", filter_str])
    cmd.extend(["-ar", "48000"])

    # チャンネル数 (SEはモノラル、環境音・音楽はステレオ)
    if is_stereo:
        cmd.extend(["-ac", "2"])
    else:
        cmd.extend(["-ac", "1"])

    # Opus コーデック指定
    cmd.extend(["-c:a", "libopus", "-b:a", bitrate])
    cmd.append(str(output_path))

    try:
        res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace", check=True)
        return True
    except subprocess.CalledProcessError as e:
        err_msg = e.stderr or ""
        print(f"変換エラー ({input_path.name}): {err_msg}")
        return False

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 3:
        print("Usage: python process_audio.py <input> <output.ogg> [--stereo]")
        sys.exit(1)
    
    inp = Path(sys.argv[1])
    out = Path(sys.argv[2])
    stereo = "--stereo" in sys.argv
    success = normalize_and_convert(inp, out, is_stereo=stereo)
    if success:
        print(f"変換成功: {out}")
    else:
        print("変換失敗")
        sys.exit(1)
