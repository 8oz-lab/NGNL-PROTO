# Erzeugt Modelle für Elkia mit der Tripo-API (Text zu 3D-Modell) und speichert sie als GLB.
#   houses:  assets/models/houses/     – das Spiel stellt jede GLB von dort automatisch an die Straße
#   bauten:  assets/models/buildings/  – Burg, Stadtmauer, Mauerturm, Stadttor
#   tutorial: assets/models/tutorial/  – Schatztruhe und Wegstein für das Steuerungs-Tutorial
#
# Voraussetzungen: Netzwerkzugriff auf api.tripo3d.ai (und den Download-Host der fertigen Modelle)
# und der Tripo-Schlüssel: entweder als „Network secret“ der Umgebung (wird automatisch als
# Authorization-Header angehängt) oder als Umgebungsvariable TRIPO_API_KEY.
# Aufruf: python3 tools/tripo_models.py SET [name ...]   (ohne Namen: alle Modelle des Sets)
import json
import os
import sys
import time
import urllib.request
from pathlib import Path

API = "https://api.tripo3d.ai/v2/openapi"
STYLE = ("stylized anime fantasy game asset, medieval european town, clean shapes, soft pastel colors, "
         "hand-painted look, single object, no people, no background")
HOUSES = {
    "stadthaus_blau": "two-story town house, white plaster walls with dark timber frame, steep blue slate roof, wooden door, flower boxes under the windows",
    "stadthaus_rot": "narrow three-story town house, cream walls, timber frame, red tiled roof with small dormer, round window in the gable",
    "baeckerei": "small bakery shop, stone ground floor with big shop window and awning, timber frame upper floor, orange roof, sign with a bread loaf",
    "taverne": "cozy tavern, stone and wood, wide porch with wooden pillars, chimney, hanging sign with a chess piece, green roof",
    "wohnhaus_klein": "small cottage, white walls, dark wooden beams, purple roof, chimney, little fence-free front step",
}
BAUTEN = {
    "burg": ("grand fairy-tale royal castle of a human kingdom, white stone walls, many slender round towers with blue conical roofs, "
             "red banners, large main keep and gatehouse, standing on a low rocky hill base", 30000),
    "mauer": ("long straight segment of a medieval stone city wall, crenellated battlements on top, light grey stone blocks, "
              "simple flat ends so segments can be placed in a row, about four times longer than high", 6000),
    "mauerturm": ("round medieval stone wall tower with crenellations and a blue conical roof, light grey stone, small arrow slits", 8000),
    "stadttor": ("medieval city gatehouse with one large open arched gateway in the middle, two round towers with blue conical roofs, "
                 "light grey stone, open wooden gate doors, red banners", 15000),
}
TUTORIAL = {
    "schatztruhe": ("ornate closed wooden treasure chest with gold trim and corner fittings, a few colorful gems on the lid, "
                    "sitting on the ground", 8000),
    "wegstein": ("small round carved stone pedestal with glowing blue rune lines, a floating blue crystal above it, "
                 "magical waypoint marker", 8000),
}
SETS = {
    "houses": ("assets/models/houses", {k: (v, 12000) for k, v in HOUSES.items()}),
    "bauten": ("assets/models/buildings", BAUTEN),
    "tutorial": ("assets/models/tutorial", TUTORIAL),
}


def call(method: str, path: str, body: dict | None = None) -> dict:
    req = urllib.request.Request(API + path, method=method, data=json.dumps(body).encode() if body else None)
    if os.environ.get("TRIPO_API_KEY"):
        req.add_header("Authorization", "Bearer " + os.environ["TRIPO_API_KEY"])
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=60) as r:
        data = json.load(r)
    if data.get("code") != 0:
        raise RuntimeError(f"Tripo-Fehler: {data}")
    return data["data"]


def find_glb(output: dict) -> str | None:
    for key in ("pbr_model", "model", "base_model"):
        url = output.get(key)
        if isinstance(url, dict):
            url = url.get("url")
        if url:
            return url
    return None


def generate(name: str, prompt: str, faces: int, out: Path) -> None:
    task = call("POST", "/task", {"type": "text_to_model", "prompt": f"{prompt}, {STYLE}",
                                  "texture": True, "pbr": False, "face_limit": faces})
    task_id = task["task_id"]
    print(f"{name}: Auftrag {task_id} gestartet")
    while True:
        time.sleep(5)
        info = call("GET", f"/task/{task_id}")
        status = info.get("status")
        print(f"  {name}: {status} {info.get('progress', '')}")
        if status == "success":
            break
        if status in ("failed", "cancelled", "banned", "expired", "unknown"):
            raise RuntimeError(f"{name}: Auftrag {status}")
    url = find_glb(info.get("output", {}))
    if not url:
        raise RuntimeError(f"{name}: keine Modell-Adresse in {info.get('output')}")
    target = out / f"{name}.glb"
    urllib.request.urlretrieve(url, target)
    print(f"{name}: gespeichert ({target.stat().st_size // 1024} KB)")


def main() -> None:
    folder, models = SETS[sys.argv[1]]
    out = Path(__file__).resolve().parent.parent / folder
    out.mkdir(parents=True, exist_ok=True)
    for name in sys.argv[2:] or list(models):
        prompt, faces = models[name]
        generate(name, prompt, faces, out)


if __name__ == "__main__":
    main()
