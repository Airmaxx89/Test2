#!/usr/bin/env python3
"""
Generates all original sound effects and ambient loops for Nordmark Legends.
Everything here is synthesized from scratch (sine/triangle tones, filtered
noise) using only the Python standard library - no copyrighted or
third-party audio is used or referenced. Same spirit as generate_textures.py.

Run: python3 tools/generate_sounds.py
Output: assets/audio/sfx/*.wav, assets/audio/ambient/*.wav
"""
import math
import random
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 22050

ROOT = Path(__file__).resolve().parent.parent
SFX_DIR = ROOT / "assets" / "audio" / "sfx"
AMBIENT_DIR = ROOT / "assets" / "audio" / "ambient"
SFX_DIR.mkdir(parents=True, exist_ok=True)
AMBIENT_DIR.mkdir(parents=True, exist_ok=True)


def write_wav(path: Path, samples: list) -> None:
    with wave.open(str(path), "w") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SAMPLE_RATE)
        frames = b"".join(
            struct.pack("<h", max(-32767, min(32767, int(s * 32767))))
            for s in samples
        )
        f.writeframes(frames)


def fade(samples: list, fade_len: int) -> list:
    n = len(samples)
    fade_len = min(fade_len, n // 2)
    for i in range(fade_len):
        samples[i] *= i / fade_len
        samples[n - 1 - i] *= i / fade_len
    return samples


def tone(freq: float, duration: float, volume: float = 0.5, shape: str = "sine", decay: float = 0.0) -> list:
    n = int(SAMPLE_RATE * duration)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        if shape == "triangle":
            v = 2.0 * abs(2.0 * ((freq * t) % 1.0) - 1.0) - 1.0
        else:
            v = math.sin(2 * math.pi * freq * t)
        env = math.exp(-decay * t) if decay > 0 else 1.0
        out.append(v * volume * env)
    return out


def lowpass_noise(duration: float, volume: float = 0.3, cutoff: float = 0.05, seed: int = 0) -> list:
    rng = random.Random(seed)
    n = int(SAMPLE_RATE * duration)
    out = []
    prev = 0.0
    for _ in range(n):
        white = rng.uniform(-1.0, 1.0)
        prev += cutoff * (white - prev)
        out.append(prev * volume)
    return out


def concat(*tracks) -> list:
    out = []
    for t in tracks:
        out.extend(t)
    return out


def gen_button_click() -> list:
    return fade(tone(1400, 0.04, volume=0.35, decay=60.0), int(SAMPLE_RATE * 0.005))


def gen_hit() -> list:
    s = lowpass_noise(0.15, volume=0.5, cutoff=0.35, seed=1)
    for i in range(len(s)):
        s[i] *= math.exp(-14.0 * (i / SAMPLE_RATE))
    return fade(s, int(SAMPLE_RATE * 0.005))


def gen_item_pickup() -> list:
    a = tone(880.0, 0.06, volume=0.3, decay=18.0)
    b = tone(1320.0, 0.08, volume=0.3, decay=14.0)
    return fade(concat(a, b), int(SAMPLE_RATE * 0.005))


def gen_level_up() -> list:
    notes = [523.25, 659.25, 784.0]
    parts = [tone(f, 0.18, volume=0.32, shape="triangle", decay=6.0) for f in notes]
    return fade(concat(*parts), int(SAMPLE_RATE * 0.01))


def gen_quest_complete() -> list:
    notes = [523.25, 659.25, 784.0, 1046.5]
    parts = [tone(f, 0.16, volume=0.3, shape="triangle", decay=5.0) for f in notes]
    return fade(concat(*parts), int(SAMPLE_RATE * 0.01))


def gen_forest_ambient() -> list:
    duration = 6.0
    base = lowpass_noise(duration, volume=0.06, cutoff=0.02, seed=42)
    for i in range(len(base)):
        t = i / SAMPLE_RATE
        base[i] *= 1.0 + 0.3 * math.sin(2 * math.pi * 0.08 * t)
    return fade(base, int(SAMPLE_RATE * 0.3))


def gen_campfire_crackle() -> list:
    duration = 5.0
    n = int(SAMPLE_RATE * duration)
    rng = random.Random(7)
    out = lowpass_noise(duration, volume=0.045, cutoff=0.015, seed=8)
    t = 0.0
    while t < duration - 0.05:
        t += rng.uniform(0.05, 0.35)
        idx = int(t * SAMPLE_RATE)
        if idx >= n:
            break
        pop_len = int(SAMPLE_RATE * rng.uniform(0.01, 0.03))
        pop_vol = rng.uniform(0.08, 0.22)
        for j in range(pop_len):
            if idx + j >= n:
                break
            decay = math.exp(-40.0 * j / SAMPLE_RATE)
            out[idx + j] += rng.uniform(-1.0, 1.0) * pop_vol * decay
    return fade(out, int(SAMPLE_RATE * 0.3))


def main() -> None:
    sfx = {
        "button_click.wav": gen_button_click(),
        "hit.wav": gen_hit(),
        "item_pickup.wav": gen_item_pickup(),
        "level_up.wav": gen_level_up(),
        "quest_complete.wav": gen_quest_complete(),
    }
    for name, samples in sfx.items():
        write_wav(SFX_DIR / name, samples)
        print("wrote", SFX_DIR / name)

    ambient = {
        "forest_ambient.wav": gen_forest_ambient(),
        "campfire_crackle.wav": gen_campfire_crackle(),
    }
    for name, samples in ambient.items():
        write_wav(AMBIENT_DIR / name, samples)
        print("wrote", AMBIENT_DIR / name)


if __name__ == "__main__":
    main()
