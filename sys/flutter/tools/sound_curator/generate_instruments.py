#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
generate_instruments.py
オープンSoundFont (GeneralUser GS / FluidR3) と FluidSynth を用いて、
NetHackの楽器音 47 種を一括サンプリング・Opus変換・生成するスクリプト。
"""

import os
import sys
import struct
import subprocess
import urllib.request
import zipfile
from pathlib import Path

CUR_DIR = Path(__file__).resolve().parent
BIN_DIR = CUR_DIR / "bin"
TEMP_DIR = CUR_DIR / "temp"
SOUNDS_DIR = CUR_DIR.parent.parent / "assets" / "sounds"

# 1. 簡易 SMF (Standard MIDI File) Format 0 生成関数 (ピュアPython)
def write_midi_file(filepath: Path, program: int, note: int, velocity: int = 100, duration_ticks: int = 192, division: int = 96):
    """単一ノート演奏のMIDIファイル (Format 0) を生成する"""
    def to_varlen(val: int) -> bytes:
        buf = []
        buf.append(val & 0x7F)
        val >>= 7
        while val > 0:
            buf.append((val & 0x7F) | 0x80)
            val >>= 7
        buf.reverse()
        return bytes(buf)

    events = bytearray()
    
    # Delta-time 0: Program Change (Ch 0)
    events.extend(to_varlen(0))
    events.extend(bytes([0xC0, program & 0x7F]))

    # Delta-time 0: Note On
    events.extend(to_varlen(0))
    events.extend(bytes([0x90, note & 0x7F, velocity & 0x7F]))

    # Delta-time duration_ticks: Note Off
    events.extend(to_varlen(duration_ticks))
    events.extend(bytes([0x80, note & 0x7F, 0]))

    # Delta-time 96 ticks: End of Track (余韻の確保)
    events.extend(to_varlen(96))
    events.extend(bytes([0xFF, 0x2F, 0x00]))

    # ヘッダチャンク (MThd, len 6, format 0, tracks 1, division)
    header = struct.pack(">4sIHHH", b"MThd", 6, 0, 1, division)

    # トラックチャンク (MTrk, len, data)
    track = struct.pack(">4sI", b"MTrk", len(events)) + bytes(events)

    filepath.parent.mkdir(parents=True, exist_ok=True)
    filepath.write_bytes(header + track)

# 2. FluidSynth & SoundFont の準備
def ensure_fluidsynth() -> Path:
    """Windows用 fluidsynth.exe の存在を確認・ダウンロード"""
    exe_path = BIN_DIR / "fluidsynth.exe"
    if exe_path.exists():
        return exe_path

    BIN_DIR.mkdir(parents=True, exist_ok=True)
    zip_url = "https://github.com/FluidSynth/fluidsynth/releases/download/v2.6.0/fluidsynth-v2.6.0-win10-x64-cpp11.zip"
    zip_path = BIN_DIR / "fluidsynth.zip"
    print(f"FluidSynth をダウンロード中: {zip_url} ...")
    urllib.request.urlretrieve(zip_url, zip_path)

    print("解凍中...")
    with zipfile.ZipFile(zip_path, 'r') as z:
        for member in z.infolist():
            # bin/ 配下の exe や dll を BIN_DIR に展開
            name = member.filename
            if name.endswith(".exe") or name.endswith(".dll"):
                filename = Path(name).name
                with z.open(member) as src, open(BIN_DIR / filename, "wb") as dst:
                    dst.write(src.read())
    
    if zip_path.exists():
        zip_path.unlink()

    print(f"FluidSynth 準備完了: {exe_path}")
    return exe_path

def ensure_soundfont() -> Path:
    """SoundFont (.sf2) の存在を確認・ダウンロード"""
    sf2_path = BIN_DIR / "FluidR3_GM.sf2"
    if sf2_path.exists() and sf2_path.stat().st_size > 1000000:
        return sf2_path

    BIN_DIR.mkdir(parents=True, exist_ok=True)
    sf2_url = "https://raw.githubusercontent.com/urish/cinto/master/media/FluidR3%20GM.sf2"
    print(f"SoundFont (FluidR3 GM) をダウンロード中 (約140MB): {sf2_url} ...")

    def report_hook(block_num, block_size, total_size):
        if total_size > 0:
            percent = (block_num * block_size / total_size) * 100
            if block_num % 1000 == 0 or percent >= 100:
                print(f"  ダウンロード進捗: {percent:.1f}% ({block_num * block_size // 1024 // 1024}MB / {total_size // 1024 // 1024}MB)")

    req = urllib.request.Request(sf2_url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req) as resp, open(sf2_path, 'wb') as out_f:
        total_size = int(resp.headers.get('Content-Length', 0))
        downloaded = 0
        block_size = 1024 * 64
        while True:
            chunk = resp.read(block_size)
            if not chunk:
                break
            out_f.write(chunk)
            downloaded += len(chunk)
            if downloaded % (1024 * 1024 * 10) < block_size:
                print(f"  ダウンロード中: {downloaded // 1024 // 1024}MB / {total_size // 1024 // 1024}MB")

    print(f"SoundFont 準備完了: {sf2_path}")
    return sf2_path

# 3. 楽器マッピング定義
# GM Program Numbers (0-indexed):
# 73: Flute, 75: Pan Flute, 69: English Horn, 56: Trumpet, 46: Orchestral Harp, 45: Pizzicato Strings
# 60: French Horn, 67: Baritone Sax, 112: Tinkle Bell, 116: Taiko Drum, 117: Melodic Tom

NOTE_OCTAVE_4 = {
    "C": 60, "D": 62, "E": 64, "F": 65, "G": 67, "A": 69, "B": 71
}
NOTE_OCTAVE_5 = {
    "C": 72, "D": 74, "E": 76, "F": 77, "G": 79, "A": 81, "B": 83
}
NOTE_OCTAVE_3 = {
    "C": 48, "D": 50, "E": 52, "F": 53, "G": 55, "A": 57, "B": 59
}

INSTRUMENTS_VARIABLE = [
    {"name": "sound_Wooden_Flute", "program": 73, "notes": NOTE_OCTAVE_5, "duration": 250},
    {"name": "sound_Magic_Flute", "program": 75, "notes": NOTE_OCTAVE_5, "duration": 250},
    {"name": "sound_Tooled_Horn", "program": 69, "notes": NOTE_OCTAVE_4, "duration": 250},
    {"name": "sound_Bugle", "program": 56, "notes": NOTE_OCTAVE_4, "duration": 250},
    {"name": "sound_Wooden_Harp", "program": 46, "notes": NOTE_OCTAVE_4, "duration": 300},
    {"name": "sound_Magic_Harp", "program": 45, "notes": NOTE_OCTAVE_4, "duration": 300}, # Pizzicato Harp
]

INSTRUMENTS_FIXED = [
    {"filename": "sound_Frost_Horn.ogg", "program": 60, "note": 60, "duration": 350},
    {"filename": "sound_Fire_Horn.ogg", "program": 67, "note": 48, "duration": 350},
    {"filename": "sound_Bell.ogg", "program": 112, "note": 72, "duration": 400},
    {"filename": "sound_Drum_Of_Earthquake.ogg", "program": 116, "note": 48, "duration": 400},
    {"filename": "sound_Leather_Drum.ogg", "program": 117, "note": 48, "duration": 300},
]

def render_midi_to_wav(fluidsynth_exe: Path, sf2_path: Path, mid_path: Path, wav_path: Path):
    """FluidSynth を呼び出して MIDI を WAV にレンダリング"""
    cmd = [
        str(fluidsynth_exe),
        "-F", str(wav_path),
        "-r", "48000",
        str(sf2_path),
        str(mid_path)
    ]
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

def generate_all_instruments():
    from process_audio import normalize_and_convert

    fluidsynth_exe = ensure_fluidsynth()
    sf2_path = ensure_soundfont()

    TEMP_DIR.mkdir(parents=True, exist_ok=True)
    SOUNDS_DIR.mkdir(parents=True, exist_ok=True)

    generated_count = 0

    print("\n--- 音階バリエーション楽器 (42ファイル) のサンプリング開始 ---")
    for inst in INSTRUMENTS_VARIABLE:
        prefix = inst["name"]
        prog = inst["program"]
        duration = inst["duration"]
        for note_name, note_val in inst["notes"].items():
            out_filename = f"{prefix}_{note_name}.ogg"
            mid_file = TEMP_DIR / f"{prefix}_{note_name}.mid"
            wav_file = TEMP_DIR / f"{prefix}_{note_name}.wav"
            ogg_file = SOUNDS_DIR / out_filename

            write_midi_file(mid_file, prog, note_val, velocity=105, duration_ticks=duration)
            render_midi_to_wav(fluidsynth_exe, sf2_path, mid_file, wav_file)
            
            # EBU R128 (-14 LUFS) & Opus 変換
            ok = normalize_and_convert(wav_file, ogg_file, target_lufs=-14.0, is_stereo=False)
            if ok:
                generated_count += 1
                print(f"[{generated_count}/47] 生成完了: {out_filename}")

    print("\n--- 固定演奏楽器 (5ファイル) のサンプリング開始 ---")
    for inst in INSTRUMENTS_FIXED:
        out_filename = inst["filename"]
        prog = inst["program"]
        note_val = inst["note"]
        duration = inst["duration"]

        mid_file = TEMP_DIR / f"{out_filename}.mid"
        wav_file = TEMP_DIR / f"{out_filename}.wav"
        ogg_file = SOUNDS_DIR / out_filename

        write_midi_file(mid_file, prog, note_val, velocity=110, duration_ticks=duration)
        render_midi_to_wav(fluidsynth_exe, sf2_path, mid_file, wav_file)

        ok = normalize_and_convert(wav_file, ogg_file, target_lufs=-14.0, is_stereo=False)
        if ok:
            generated_count += 1
            print(f"[{generated_count}/47] 生成完了: {out_filename}")

    print(f"\n合計 {generated_count} / 47 の楽器音を生成しました！ 出力先: {SOUNDS_DIR}")

if __name__ == "__main__":
    generate_all_instruments()
