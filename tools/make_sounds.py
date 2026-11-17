#!/usr/bin/env python3
"""Synthesizes every sound in Tiny Tunes Studio.

    python3 tools/make_sounds.py

All sounds are made from scratch here (waves, noise, envelopes, Karplus-Strong
plucks), so there are no third-party samples to license or attribute. The
instrument, drum and silly sounds are adapted from Rainbow Keys.

Output (OGG Vorbis, mono, 32 kHz, via ffmpeg):
  assets/sounds/<instrument>_<midi>.ogg   piano, xylo, flute, guitar for MIDI 43..84
  assets/sounds/drum_*.ogg, silly_*.ogg, cheer/fanfare/applause/tick.ogg
  assets/backing/<song id>.ogg            karaoke backing track for each song in
                                          assets/songs/songs.json (4-beat count-in,
                                          soft melody guide, bass, chords, drums)
"""
import json
import os
import subprocess
import tempfile
import wave

import numpy as np
from scipy.signal import lfilter

SR = 32000
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
SOUNDS = os.path.join(ROOT, 'assets', 'sounds')
BACKING = os.path.join(ROOT, 'assets', 'backing')
SONGS = os.path.join(ROOT, 'assets', 'songs', 'songs.json')
TONAL_RANGE = range(43, 85)  # G2..C6: guitar chords low, melodies, xylophone sparkle
COUNT_IN_BEATS = 4
rng = np.random.default_rng(7)


def mtof(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def t_axis(dur):
    return np.arange(int(SR * dur)) / SR


def env(dur, attack=0.004, decay=1.0):
    """Fast attack, exponential decay (decay = time to fall about 60 dB)."""
    t = t_axis(dur)
    a = np.clip(t / attack, 0, 1)
    return a * np.exp(-6.9 * t / decay)


def osc(kind, freq, dur):
    """freq may be a number or an array (for glides); returns the waveform."""
    t = t_axis(dur)
    f = np.asarray(freq, dtype=float)
    if f.ndim and len(f) < len(t):  # a short glide holds its last frequency
        f = np.concatenate([f, np.full(len(t) - len(f), f[-1])])
    f = np.broadcast_to(f, t.shape)
    ph = 2 * np.pi * np.cumsum(f) / SR
    if kind == 'sine':
        return np.sin(ph)
    if kind == 'tri':
        return 2 / np.pi * np.arcsin(np.sin(ph))
    if kind == 'square':
        return np.sign(np.sin(ph)) * 0.6
    if kind == 'saw':
        return 2 * ((ph / (2 * np.pi)) % 1.0) - 1
    raise ValueError(kind)


def glide(f1, f2, dur):
    return f1 * (f2 / f1) ** (t_axis(dur) / dur)


def noise(dur):
    return rng.uniform(-1, 1, int(SR * dur))


def onepole_lp(x, cutoff):
    a = np.exp(-2 * np.pi * cutoff / SR)
    return lfilter([1 - a], [1, -a], x)


def bandpass(x, lo, hi):
    return onepole_lp(x, hi) - onepole_lp(x, lo)


def highpass(x, cutoff):
    return x - onepole_lp(x, cutoff)


def mix(*parts, dur=None):
    n = max(int(SR * at) + len(p) for p, at in parts) if dur is None else int(SR * dur)
    out = np.zeros(n)
    for p, at in parts:
        s = int(SR * at)
        seg = p[: max(0, n - s)]
        out[s:s + len(seg)] += seg
    return out


def write_ogg(path, x, peak_db=-3.0, normalise=True):
    x = np.asarray(x, dtype=float)
    fade = min(len(x), int(SR * 0.01))
    x[-fade:] *= np.linspace(1, 0, fade)
    if normalise:
        x = x / (np.max(np.abs(x)) or 1) * 10 ** (peak_db / 20)
    data = (np.clip(x, -1, 1) * 32767).astype('<i2').tobytes()
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
        wav_path = tmp.name
    try:
        with wave.open(wav_path, 'wb') as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(data)
        subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wav_path, '-c:a', 'libvorbis', '-q:a', '4',
                        '-map_metadata', '-1', path], check=True)
    finally:
        os.remove(wav_path)


def save(name, x, gain_db=0.0):
    write_ogg(os.path.join(SOUNDS, name + '.ogg'), x, -3 + gain_db)


# ---------- instruments (one file per note) ----------

def piano(f, d=1.8):
    x = (osc('tri', f, d) * env(d, 0.004, 1.6)
         + 0.6 * osc('sine', f * 1.002, d) * env(d, 0.004, 2.0)
         + 0.3 * osc('sine', f * 2, d) * env(d, 0.004, 0.8)
         + 0.12 * osc('sine', f * 3, d) * env(d, 0.003, 0.45))
    x += 0.06 * bandpass(noise(d), 1500, 4000) * env(d, 0.001, 0.03)
    return x


def xylo(f):
    f *= 2
    d = 0.8
    return (osc('sine', f, d) * env(d, 0.002, 0.55)
            + 0.25 * osc('sine', f * 3, d) * env(d, 0.002, 0.12)
            + 0.08 * osc('sine', f * 6.3, d) * env(d, 0.001, 0.05)
            + 0.1 * bandpass(noise(d), 2000, 6000) * env(d, 0.001, 0.015))


def flute(f, d=1.2):
    t = t_axis(d)
    vib = 1 + 0.006 * np.sin(2 * np.pi * 5.2 * t) * np.clip((t - 0.15) / 0.2, 0, 1)
    body = osc('sine', f * vib, d) + 0.18 * osc('sine', 2 * f * vib, d) + 0.05 * osc('sine', 3 * f * vib, d)
    breath = 0.12 * bandpass(noise(d), f * 0.8, f * 3)
    shape = np.clip(t / 0.06, 0, 1) * np.clip((d - t) / 0.25, 0, 1)
    chiff = 0.15 * bandpass(noise(d), 2000, 6000) * env(d, 0.002, 0.04)
    return (body + breath) * shape + chiff


def guitar(f, d=2.0):
    """Karplus-Strong plucked string with a soft pick."""
    n = int(SR * d)
    period = SR / f
    p = int(period)
    frac = period - p
    buf = onepole_lp(rng.uniform(-1, 1, p + 2), min(6000, f * 8))
    out = np.zeros(n)
    ring = list(buf[:p])
    decay = 0.996 if f < 200 else 0.993
    idx = 0
    prev = 0.0
    for i in range(n):
        cur = ring[idx]
        nxt = ring[(idx + 1) % p]
        val = decay * ((1 - frac) * 0.5 * (cur + nxt) + frac * 0.5 * (prev + cur))
        prev = cur
        out[i] = cur
        ring[idx] = val
        idx = (idx + 1) % p
    out += 0.3 * osc('sine', f, d) * env(d, 0.003, 1.2)  # body warmth
    return out * np.clip(t_axis(d) / 0.002, 0, 1)


# ---------- drums ----------

def kick():
    d = 0.45
    return (osc('sine', glide(160, 45, d), d) * env(d, 0.002, 0.42)
            + 0.15 * bandpass(noise(d), 1000, 5000) * env(d, 0.001, 0.01))


def snare():
    d = 0.25
    return (0.7 * highpass(noise(d), 1500) * env(d, 0.001, 0.2)
            + 0.5 * osc('tri', glide(200, 150, d), d) * env(d, 0.001, 0.1))


def clap():
    d = 0.3
    burst = lambda dd: bandpass(noise(dd), 900, 2500) * env(dd, 0.001, dd)
    return mix((burst(0.02), 0), (burst(0.02), 0.012), (burst(0.02), 0.024),
               (0.6 * bandpass(noise(0.25), 900, 2500) * env(0.25, 0.002, 0.18), 0.03), dur=d)


def hat():
    d = 0.12
    return highpass(noise(d), 7000) * env(d, 0.001, 0.07)


def crash():
    d = 1.5
    return (highpass(noise(d), 5000) * env(d, 0.002, 1.3)
            + 0.4 * bandpass(noise(d), 3000, 9000) * env(d, 0.002, 0.7))


def tom(f1, f2):
    d = 0.5
    return osc('sine', glide(f1, f2, d), d) * env(d, 0.002, 0.45)


def bell():
    d = 0.5
    x = osc('square', 560, d) + osc('square', 845, d)
    return bandpass(x, 500, 1400) * env(d, 0.001, 0.35)


def shaker():
    d = 0.18
    t = t_axis(d)
    shape = np.clip(t / 0.03, 0, 1) * np.exp(-t / 0.05)
    return bandpass(noise(d), 4000, 10000) * shape


# ---------- silly sounds ----------

def boing():
    d = 0.6
    t = t_axis(d)
    freq = glide(180, 420, d) + 70 * np.sin(2 * np.pi * 14 * t) * (1 - t / d)
    return osc('sine', freq, d) * env(d, 0.005, 0.6)


def pop():
    d = 0.15
    return (osc('sine', glide(300, 1400, 0.07), d) * env(d, 0.002, 0.09)
            + 0.3 * bandpass(noise(d), 1500, 3500) * env(d, 0.001, 0.02))


def quack():
    one = lambda: bandpass(osc('saw', glide(420, 300, 0.15), 0.15), 700, 1800) * env(0.15, 0.01, 0.15)
    return mix((one(), 0), (one(), 0.19), dur=0.4)


def zap():
    d = 0.35
    return onepole_lp(osc('square', glide(1800, 120, d), d), 5000) * env(d, 0.002, 0.33)


def bubbles():
    parts = []
    for k in range(6):
        f = rng.uniform(260, 520)
        parts.append((osc('sine', glide(f, f * 2.5, 0.06), 0.06) * env(0.06, 0.003, 0.06), k * 0.07))
    return mix(*parts, dur=0.5)


def whistle(f1, f2, d):
    t = t_axis(d)
    freq = glide(f1, f2, d) * (1 + 0.025 * np.sin(2 * np.pi * 7 * t))
    a = np.clip(t / 0.03, 0, 1) * np.clip((d - t) / 0.08, 0, 1)
    return osc('sine', freq, d) * a


def trill():
    parts = [(osc('sine', 1250 if k % 2 else 950, 0.05) * env(0.05, 0.003, 0.05), k * 0.045) for k in range(10)]
    return mix(*parts, dur=0.5)


# ---------- rewards ----------

def musicbox(f, d=2.0):
    f *= 2
    return (osc('sine', f, d) * env(d, 0.002, 1.8)
            + 0.22 * osc('sine', f * 2, d) * env(d, 0.002, 0.6)
            + 0.14 * osc('sine', f * 3.01, d) * env(d, 0.002, 0.35)
            + 0.05 * osc('tri', f * 4, d) * env(d, 0.001, 0.15))


def arpeggio(notes, step, tail=1.2):
    parts = [(musicbox(mtof(m))[: int(SR * tail)], i * step) for i, m in enumerate(notes)]
    sparkle = [(0.4 * osc('sine', mtof(96 + (k % 3) * 4), 0.08) * env(0.08, 0.002, 0.08), 0.05 + k * 0.06)
               for k in range(6)]
    return mix(*parts, *sparkle)


def applause():
    """A small crowd: hundreds of short claps, swelling in and fading out."""
    d = 3.0
    parts = []
    for _ in range(420):
        at = rng.uniform(0, d - 0.1) ** 1.15 / (d - 0.1) ** 0.15
        c = bandpass(noise(0.03), rng.uniform(700, 1100), rng.uniform(2000, 3200)) * env(0.03, 0.001, 0.03)
        parts.append((c * rng.uniform(0.4, 1.0), at))
    x = mix(*parts, dur=d)
    t = t_axis(d)
    return x * np.clip(t / 0.3, 0, 1) * np.clip((d - t) / 1.2, 0, 1)


# ---------- karaoke backing ----------

CHORDS = {
    'C': [48, 52, 55], 'F': [53, 57, 60], 'G': [55, 59, 62], 'Am': [57, 60, 64],
    'Dm': [50, 53, 57], 'Em': [52, 55, 59], 'G7': [55, 59, 65], 'D': [50, 54, 57],
}


def pad(midis, d):
    t = t_axis(d)
    x = sum(osc('tri', mtof(m + 12), d) + 0.3 * osc('sine', mtof(m + 24) * 1.003, d) for m in midis)
    shape = np.clip(t / 0.08, 0, 1) * np.clip((d - t) / 0.12, 0, 1)
    return onepole_lp(x * shape, 2500)


def bass(m, d):
    f = mtof(m - 12)
    t = t_axis(d)
    x = osc('sine', f, d) + 0.35 * osc('tri', 2 * f, d)
    return x * np.clip(t / 0.01, 0, 1) * np.exp(-t / 0.5) * np.clip((d - t) / 0.03, 0, 1)


def render_backing(song):
    bpm, tpb, bar = song['bpm'], song['tpb'], song['beatsPerBar']
    beat = 60.0 / bpm
    tick = beat / tpb
    notes = [n for line in song['lines'] for n in line]
    total_ticks = sum(n[2] for n in notes)
    assert total_ticks == sum(c[1] for c in song['chords']), f"{song['id']}: chords and notes differ in length"
    start = COUNT_IN_BEATS * beat
    length = start + total_ticks * tick + 2.0
    melody, harmony, drums = [], [], []

    # Count-in: four woodblock ticks, the first one higher.
    for k in range(COUNT_IN_BEATS):
        f = 1600 if k == 0 else 1200
        drums.append((osc('sine', f, 0.06) * env(0.06, 0.001, 0.05), k * beat))

    at = start
    for _syl, midi, ticks in notes:
        d = ticks * tick
        # musicbox() plays an octave up, so halve the frequency to sound at the sung pitch.
        melody.append((musicbox(mtof(midi) / 2, min(1.6, d + 0.6)), at))
        at += d

    at = start
    for name, ticks in song['chords']:
        d = ticks * tick
        mids = CHORDS[name]
        harmony.append((0.22 * pad(mids, d), at))
        # Bass: root on each beat-pair, fifth in between.
        beats_in = max(1, round(d / beat))
        step = 2 if bar % 2 == 0 and beats_in >= 2 else 1
        for b in range(0, beats_in, step):
            m = mids[0] if (b // step) % 2 == 0 else mids[2]
            harmony.append((0.5 * bass(m, step * beat * 0.95), at + b * beat))
        at += d

    beats_total = int(round(total_ticks / tpb))
    k, h, s = kick(), hat(), snare()
    for b in range(beats_total):
        t0 = start + b * beat
        pos = b % bar
        if pos == 0 or (bar == 4 and pos == 2):
            drums.append((0.55 * k, t0))
        if (bar == 4 and pos in (1, 3)) or (bar == 2 and pos == 1):
            drums.append((0.25 * s, t0))
        drums.append((0.12 * h, t0))
        drums.append((0.06 * h, t0 + beat / 2))
    # A gentle cymbal and chord at the end.
    drums.append((0.3 * crash(), start + total_ticks * tick))

    out = (0.55 * mix(*melody, dur=length) + mix(*harmony, dur=length) + mix(*drums, dur=length))
    out = out / (np.max(np.abs(out)) or 1) * 10 ** (-4 / 20)
    write_ogg(os.path.join(BACKING, song['id'] + '.ogg'), out, normalise=False)
    return length


def main():
    os.makedirs(SOUNDS, exist_ok=True)
    os.makedirs(BACKING, exist_ok=True)
    for name, fn in [('piano', piano), ('xylo', xylo), ('flute', flute), ('guitar', guitar)]:
        for m in TONAL_RANGE:
            save(f'{name}_{m}', fn(mtof(m)))
    for name, x in [('kick', kick()), ('snare', snare()), ('clap', clap()), ('hat', hat()),
                    ('crash', crash()), ('tomlow', tom(140, 80)), ('tomhigh', tom(260, 170)),
                    ('bell', bell()), ('shaker', shaker())]:
        save('drum_' + name, x)
    # Sustained whistles sound far louder than short hits at the same peak, so they get -10 dB.
    for name, x, g in [('boing', boing(), 0), ('pop', pop(), 0), ('quack', quack(), 0), ('zap', zap(), 0),
                       ('bubbles', bubbles(), 0), ('up', whistle(500, 1800, 0.5), -10),
                       ('down', whistle(1600, 300, 0.6), -10), ('trill', trill(), 0)]:
        save('silly_' + name, x, g)
    save('cheer', arpeggio([72, 76, 79, 84], 0.08))
    save('fanfare', arpeggio([67, 72, 76, 79, 76, 79, 84], 0.13, tail=1.6))
    save('applause', applause(), -4)
    save('tick', osc('sine', 1400, 0.06) * env(0.06, 0.001, 0.05), -6)
    with open(SONGS, encoding='utf-8') as f:
        songs = json.load(f)['songs']
    for song in songs:
        secs = render_backing(song)
        print(f"  backing {song['id']}: {secs:.1f} s")
    print('wrote', len(os.listdir(SOUNDS)), 'sounds and', len(songs), 'backing tracks')


if __name__ == '__main__':
    main()
