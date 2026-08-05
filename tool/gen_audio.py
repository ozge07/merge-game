"""Merge Game ses efektlerini sıfırdan sentezler (saf stdlib, telifsiz).

Hiçbir dış kütüphane ve hiçbir hazır ses dosyası kullanılmıyor; dalga formları
`math` ile üretilip `wave` ile yazılıyor. Böylece telifli hiçbir içerik projeye
girmiyor.

Oyunun karakteri cam/zil: kısa, berrak, temiz tınılar. Birleşme sesi seviyeyle
birlikte bir üst notaya çıkıyor, böylece yüksek seviyeye tırmanmak kulakla da
duyuluyor.

    python3 tool/gen_audio.py
"""

import math
import os
import random
import struct
import wave

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                   "assets", "audio")
os.makedirs(OUT, exist_ok=True)
random.seed(7)


def write(name, samples, peak=0.85):
    """Tek kanallı 16 bit WAV yazar ve tepe seviyesini normalize eder."""
    hi = max(abs(s) for s in samples) or 1.0
    gain = peak / hi
    data = b"".join(
        struct.pack("<h", int(max(-1.0, min(1.0, s * gain)) * 32767))
        for s in samples
    )
    with wave.open(os.path.join(OUT, name), "w") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(data)
    print(f"{name:16} {len(samples) / SR:.2f}s  {len(data) // 1024}KB")


def n_samples(seconds):
    return int(SR * seconds)


def fade_edges(buf, ms=4):
    """Baştaki ve sondaki tıkırtıyı almak için kısa bir açılma/kapanma."""
    k = min(n_samples(ms / 1000), len(buf) // 2)
    for i in range(k):
        buf[i] *= i / k
        buf[-1 - i] *= i / k
    return buf


def mix(*layers):
    length = max(len(l) for l in layers)
    out = [0.0] * length
    for layer in layers:
        for i, s in enumerate(layer):
            out[i] += s
    return out


def bell(freq, dur=0.5, decay=7.0, amp=1.0):
    """Cam/zil tınısı: temel nota + tam olmayan üst harmonikler.

    Harmonikler tam kat olmadığı için ses org gibi değil, cam gibi duyuluyor.
    """
    total = n_samples(dur)
    kismi = [(1.0, 1.0), (2.76, 0.45), (5.40, 0.22), (8.93, 0.10)]
    out = []
    for i in range(total):
        t = i / SR
        zarf = math.exp(-decay * (i / total))
        deger = 0.0
        for oran, agirlik in kismi:
            # Üst harmonikler daha hızlı sönüyor; gerçek zillerde de öyle.
            deger += (
                math.sin(2 * math.pi * freq * oran * t)
                * agirlik
                * math.exp(-decay * 0.55 * oran * (i / total))
            )
        out.append(deger * zarf * amp)
    return fade_edges(out)


def click(dur=0.06, decay=30.0, tone=520.0):
    """Kısa, yumuşak dokunuş sesi."""
    total = n_samples(dur)
    out = []
    for i in range(total):
        t = i / SR
        zarf = math.exp(-decay * (i / total))
        gurultu = (random.random() * 2 - 1) * 0.35
        out.append((math.sin(2 * math.pi * tone * t) + gurultu) * zarf)
    return fade_edges(out)


def sweep(f0, f1, dur=0.5, decay=4.0):
    """Frekansı kayan parlak bir süpürme; kutlamalarda kullanılıyor."""
    total = n_samples(dur)
    out, faz = [], 0.0
    for i in range(total):
        oran = i / total
        frekans = f0 + (f1 - f0) * oran
        faz += 2 * math.pi * frekans / SR
        out.append(math.sin(faz) * math.exp(-decay * oran))
    return fade_edges(out)


def sequence(notes, gap, dur=0.45, decay=7.0):
    """Notaları belirli aralıklarla üst üste bindirir (arpej)."""
    parcalar = []
    for sira, freq in enumerate(notes):
        sessizlik = [0.0] * n_samples(gap * sira)
        parcalar.append(sessizlik + bell(freq, dur=dur, decay=decay))
    return mix(*parcalar)


# Pentatonik dizi: hangi ikisi çalarsa çalsın uyumlu duyuluyor.
SCALE = [523.25, 587.33, 698.46, 783.99, 880.00, 1046.50, 1174.66, 1396.91]


def main():
    # Boş kareye obje koyma: kısa ve yumuşak.
    write("place.wav", click(tone=440))

    # Sürükleyip bırakma: biraz daha tok.
    write("drop.wav", click(dur=0.08, decay=26, tone=300))

    # Geçersiz hamle: alçak, kısa bir uyarı.
    write("invalid.wav", click(dur=0.10, decay=18, tone=170))

    # Birleşme sesi seviyeye göre tizleşiyor: merge1..merge8.
    for i, freq in enumerate(SCALE, start=1):
        write(f"merge{i}.wav", bell(freq, dur=0.55, decay=6.5))

    # Zincir: iki nota üst üste, yükselen.
    write("chain.wav", sequence([783.99, 1046.50], gap=0.07, dur=0.5))

    # Yüksek seviye tebriği: üç notalı parlak arpej + süpürme.
    write(
        "praise.wav",
        mix(
            sequence([659.25, 830.61, 987.77], gap=0.075, dur=0.6, decay=5.5),
            [s * 0.35 for s in sweep(600, 1800, dur=0.5, decay=5)],
        ),
    )

    # Çok yüksek seviye: daha uzun, daha görkemli.
    write(
        "fanfare.wav",
        mix(
            sequence(
                [523.25, 659.25, 783.99, 1046.50], gap=0.09, dur=0.8,
                decay=4.2,
            ),
            [s * 0.4 for s in sweep(400, 2400, dur=0.75, decay=3.5)],
        ),
    )

    # Oyun bitti: alçalan üç nota.
    write("gameover.wav", sequence([440.0, 349.23, 261.63], gap=0.16, dur=0.7,
                                   decay=4.0))

    # Menü ve kart düğmeleri.
    write("button.wav", click(dur=0.05, decay=34, tone=660))


if __name__ == "__main__":
    main()
