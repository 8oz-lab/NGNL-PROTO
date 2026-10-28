# Erzeugt Tetos gesprochene Zeilen (assets/audio/teto/teto_XX.ogg) aus den japanischen Texten in
# scripts/intro/fall_sequence.gd. Sprachmodell: Kokoro v1.0 (Apache-2.0), Stimme: eigene Mischung aus
# den Kokoro-Stimmen jf_alpha und jf_tebukuro.
#
# Einrichtung (einmalig):
#   python3 -m venv tts && . tts/bin/activate
#   pip install kokoro-onnx soundfile "misaki[ja]"
#   curl -LO https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/kokoro-v1.0.onnx
#   curl -LO https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/voices-v1.0.bin
# Aufruf (im Ordner mit den beiden Modelldateien):
#   python tools/make_teto_voice.py PFAD/ZUM/PROJEKT
import re
import sys
from pathlib import Path

import numpy as np
import soundfile as sf
from kokoro_onnx import Kokoro
from misaki import ja

# Lesungen, die die Aussprache-Erkennung sonst falsch wählt
FIX = {"四つ": "よっつ", "六つ": "むっつ", "八つ": "やっつ"}
MIX = {"jf_alpha": 0.45, "jf_tebukuro": 0.55}
SPEED = 1.04

project = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
source = (project / "scripts/intro/fall_sequence.gd").read_text(encoding="utf-8")
# Jede Zeile in LINES endet mit dem japanischen Text als letztem String
lines = re.findall(r'^\t\t"([^"]*[ぁ-んァ-ン][^"]*)"\],?$', source, re.M)
out = project / "assets/audio/teto"
out.mkdir(parents=True, exist_ok=True)

g2p = ja.JAG2P()
kokoro = Kokoro("kokoro-v1.0.onnx", "voices-v1.0.bin")
style = sum(w * kokoro.get_voice_style(v) for v, w in MIX.items())
for i, line in enumerate(lines):
    text = line
    for a, b in FIX.items():
        text = text.replace(a, b)
    phonemes = g2p(text)
    phonemes = phonemes if isinstance(phonemes, str) else phonemes[0]
    audio, sr = kokoro.create(phonemes, voice=style, speed=SPEED, is_phonemes=True)
    a = np.asarray(audio, dtype=np.float32)
    loud = np.where(np.abs(a) > 0.01)[0]
    a = a[max(0, loud[0] - int(0.03 * sr)): loud[-1] + int(0.12 * sr)]
    a = a / np.abs(a).max() * 0.89
    sf.write(out / f"teto_{i:02d}.ogg", a, sr, format="OGG", subtype="VORBIS")
    print(f"{i:2d}  {len(a) / sr:4.1f} s  {line}")
