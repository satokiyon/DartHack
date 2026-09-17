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
        res = subprocess.run(cmd, capture_output=True, text=True, check=True)
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
    true_peak: float = -1.0,
    is_stereo: bool = False,
    bitrate: str = "64k",
    start_offset: Optional[float] = None,
    duration: Optional[float] = None,
    highpass_cutoff: Optional[int] = None
) -> bool:
    """
    音源を正規化・Opus変換して出力する。
    - 先頭無音の自動除去 (silenceremove)
    - 不要低域ハイパスフィルター (highpass)
    - EBU R128 ラウドネス正規化 (loudnorm)
    - Ogg Opus (48kHz) 出力
    """
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # フィルタチェインの構築
    filters = []

    # 1. 先頭の無音トリミング (しきい値 -50dB、10ms以上の無音をカット)
    filters.append("silenceremove=start_periods=1:start_duration=0.01:start_threshold=-50dB")

    # 2. ハイパスフィルター（小型スピーカーでの音割れ・低域濁り防止）
    if highpass_cutoff is not None and highpass_cutoff > 0:
        filters.append(f"highpass=f={highpass_cutoff}")

    # 3. EBU R128 ラウドネス正規化
    filters.append(f"loudnorm=I={target_lufs}:TP={true_peak}:LRA=11")

    filter_str = ",".join(filters)

    cmd = ["ffmpeg", "-y"]

    if start_offset is not None and start_offset > 0:
        cmd.extend(["-ss", f"{start_offset:.3f}"])

    if duration is not None and duration > 0:
        cmd.extend(["-t", f"{duration:.3f}"])

    cmd.extend(["-i", str(input_path)])
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
        res = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"変換エラー ({input_path.name}): {e.stderr}")
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
