class_name Threadit
## Inhalte für „Threadit“, das Forum im Browser NetSurfer 98: Communities, Beiträge, Kommentare.

const SUBS := {
	"blank": {"name": "Blank", "icon": "「」", "color": "#1c1c2e", "members": "2,4 Mio.", "online": "48.211", "desc": "Die Community rund um 「　」. Ungeschlagen in allem. Keine Fotos, weil es keine gibt."},
	"urbanlegends": {"name": "UrbanLegends", "icon": "?", "color": "#3b1f4f", "members": "890.000", "online": "3.333", "desc": "Unheimliche Geschichten aus dem Netz. Manche davon sind wahr."},
	"schach": {"name": "Schach", "icon": "♞", "color": "#5a3d1e", "members": "1,1 Mio.", "online": "12.040", "desc": "Partien, Turniere, Eröffnungen. Und neuerdings sehr viele Niederlagen."},
	"ligaderlegenden": {"name": "LigaDerLegenden", "icon": "L", "color": "#0a323c", "members": "3,8 Mio.", "online": "91.552", "desc": "Alles zu Liga der Legenden: Patches, Ranglisten, Frust."},
	"counterspike": {"name": "CounterSpike", "icon": "⌖", "color": "#2b2f33", "members": "2,2 Mio.", "online": "40.118", "desc": "Counter-Spike: GO. Clips, Ränge, Ausreden."},
	"gaming": {"name": "Gaming", "icon": "▶", "color": "#1a5fb4", "members": "12,6 Mio.", "online": "210.004", "desc": "Alles über Spiele. Außer über 「　」. Darüber wird schon genug geredet."},
}

const THREADS := [
	{"id": "fakten", "sub": "blank", "pinned": true, "flair": "Megathread", "author": "Mod_Bot", "score": 60120, "age": "vor 12 Tagen", "ncom": "8.640",
		"title": "[MEGATHREAD] Alle bestätigten Fakten über 「　」",
		"body": ["1. Der Name besteht nur aus Leerzeichen.", "2. Auf Platz 1 in über 280 Spielen. Niederlagen: keine.", "3. Fast nur nachts online.", "4. Lehnt jedes Treffen, jedes Turnier und jede Kamera ab.", "5. Tausendfach als Cheater gemeldet. Bestätigt: nie.", "Bitte keine Spekulationen über Wohnorte. Danke."],
		"comments": [["Mod_Bot", 900, "Ergänzungen bitte nur mit Quelle."], ["Gamerin_Mia", 2210, "Punkt 6: Antwortet auf Herausforderungen manchmal mit einem einzigen Wort: „Okay.“ Danach verliert man."]]},
	{"id": "simultan", "sub": "blank", "flair": "Neuigkeit", "author": "SchachNerd_88", "score": 48211, "age": "vor 3 Std.", "ncom": "4.812",
		"title": "「　」 hat heute Nacht die komplette Top 10 der Schach-Weltrangliste geschlagen. Gleichzeitig.",
		"body": ["Zehn Bretter, zehn Großmeister, eine Online-Simultanpartie um 3 Uhr nachts.", "Ergebnis: 10 zu 0. Die längste Partie hat 31 Züge gedauert.", "Laut Protokoll hat 「　」 nebenbei noch ein Ranglistenspiel in Liga der Legenden gewonnen."],
		"comments": [
			["GM_Eisenhart", 9120, "Ich war Brett 4. Ich möchte nicht darüber reden.", [["SchachNerd_88", 2311, "Respekt, dass du dich überhaupt meldest."], ["xX_Herausforderer_Xx", 840, "willkommen im club"]]],
			["Elo_Rechner", 5502, "Wenn man die Ergebnisse in eine Elo-Zahl umrechnet, kommt etwas heraus, das meine Tabelle nicht mehr darstellen kann."],
			["Skeptiker99", 1203, "Fake. Niemand spielt zehn Partien gleichzeitig ohne Fehler.", [["Mod_Bot", 3001, "Die Partien sind öffentlich einsehbar. Es ist kein Fake.", [["Skeptiker99", 2988, "ok."]]]]],
			["NachtEule", 640, "Warum spielen die eigentlich immer um 3 Uhr nachts?"]]},
	{"id": "zwei", "sub": "blank", "flair": "Theorie", "author": "Detektiv_Laplace", "score": 31877, "age": "vor 9 Std.", "ncom": "2.904",
		"title": "Theorie: 「　」 sind zwei Personen. Hier sind meine Beweise.",
		"body": ["Ich habe 600 Partien ausgewertet. Es gibt zwei völlig verschiedene Spielstile, die sich innerhalb einer Partie abwechseln.", "Stil A liest den Gegner: Bluffs, Psychotricks, Fallen. Spielt, als wüsste er, was du gerade denkst.", "Stil B rechnet: perfekte Züge, keine Emotionen, keine Fehler. Wie eine Maschine.", "Zusammen ergibt das etwas, das nicht zu schlagen ist. Allein wären sie vielleicht nur Weltklasse."],
		"comments": [
			["Anonym", 7004, "Du liegst richtig.", [["Detektiv_Laplace", 4410, "Woher weißt du das?", [["Anonym", 6120, "…"]]]]],
			["IGL_Professor", 3380, "Das würde erklären, warum unsere Strategien nie funktionieren. Wir haben uns auf einen Gegner vorbereitet."],
			["Gamerin_Mia", 912, "Geschwister vielleicht? Ein Team, das sich blind versteht."]]},
	{"id": "niederlagen", "sub": "blank", "flair": "Humor", "author": "xX_Herausforderer_Xx", "score": 22950, "age": "vor 2 Tagen", "ncom": "3.122",
		"title": "Meine 37 Niederlagen gegen 「　」, sortiert von „knapp“ bis „ich will nicht mehr“",
		"body": ["Platz 37: Schach, verloren in 12 Zügen. War eigentlich ganz okay.", "Platz 12: Poker. Ich hatte ein Full House. Sie hatten nichts und haben trotzdem gewonnen, weil ich ausgestiegen bin.", "Platz 1: Schere, Stein, Papier. Best of 99. Endstand 0 zu 50.", "Ich trete morgen wieder an."],
		"comments": [
			["T0PLANE_SCREAMER", 8800, "DAS MIT DEM POKER IST MIR AUCH PASSIERT", [["xX_Herausforderer_Xx", 3020, "endlich versteht mich jemand"]]],
			["Psychologe_Dr_K", 2405, "Ab Niederlage 20 spricht man fachlich von einer Beziehung."],
			["SupportQueen", 1630, "0 zu 50 in Schere, Stein, Papier ist statistisch eigentlich nicht möglich. Und trotzdem."]]},
	{"id": "foto", "sub": "blank", "flair": "Frage", "author": "Fotojaeger", "score": 15402, "age": "vor 1 Tag", "ncom": "1.377",
		"title": "Hat irgendjemand jemals ein Foto von 「　」 gesehen?",
		"body": ["Eine Agentur hat zehn Millionen für ein einziges Foto geboten. Abgelehnt.", "Das Weltfinale: siebenmal abgelehnt.", "Gibt es überhaupt einen Beweis, dass da echte Menschen hinter dem Konto sitzen?"],
		"comments": [
			["Esports_Insider", 4120, "Ich kenne jemanden, der jemanden kennt, der die Lieferadresse gesehen hat. Angeblich stehen davor nur Energy-Drink-Kartons."],
			["KI_Forscher", 2050, "Wir haben geprüft, ob es eine KI sein könnte. Ergebnis: Eine KI würde nicht so gemein bluffen."],
			["Fotojaeger", 980, "Update: Ich habe eine Nachricht geschickt. Antwort: „Nein.“ Mehr nicht."]]},
	{"id": "leeres-konto", "sub": "urbanlegends", "flair": "Legende", "author": "Gruselfan", "score": 9402, "age": "vor 4 Tagen", "ncom": "1.020",
		"title": "Die Legende vom Konto ohne Namen",
		"body": ["Man sagt, wer gegen das Konto mit dem leeren Namen antritt, verliert garantiert.", "Man sagt auch, dass es um Punkt 3:33 Uhr online geht.", "Ich habe beides ausprobiert. Es stimmt."],
		"comments": [["GM_Eisenhart", 1550, "Kann ich bestätigen. Leider."], ["Gruselfan", 400, "Schreibt mir, wenn ihr gewonnen habt. Bisher hat das noch niemand."]]},
	{"id": "aufgabe", "sub": "schach", "flair": "Turnier", "author": "Schachreporter", "score": 12033, "age": "vor 5 Std.", "ncom": "640",
		"title": "GM_Eisenhart hört nach 22 Jahren vorerst auf: „Ich weiß nicht mal, gegen wie viele ich gespielt habe.“",
		"body": ["Der langjährige Großmeister hat heute bekannt gegeben, vorerst keine Online-Partien mehr zu spielen.", "Auslöser war seine 48. Niederlage in Folge gegen dasselbe Konto."],
		"comments": [["Elo_Rechner", 2100, "Gönn dir die Pause. Gegen die verliert jeder."], ["GM_Eisenhart", 4800, "Danke euch. Ich spiele jetzt erst mal Dame. Gegen meine Oma."]]},
	{"id": "challenger", "sub": "ligaderlegenden", "flair": "Diskussion", "author": "RankedSorgen", "score": 18760, "age": "vor 6 Std.", "ncom": "2.210",
		"title": "Challenger #1 hat 2.847 Siege und 0 Niederlagen. Wie ist das überhaupt möglich?",
		"body": ["Ich habe nachgerechnet: Das sind 2.847 Partien ohne eine einzige Niederlage.", "Platz 2 hat 1.204 LP. Platz 1 hat 4.812.", "Die Lücke ist größer als der Abstand zwischen Platz 2 und Platz 50.000."],
		"comments": [
			["DämonenKönig_Mid", 9900, "Ich habe gegen sie gespielt. Ich mache gerade eine Pause."],
			["T0PLANE_SCREAMER", 6100, "SMURF", [["RankedSorgen", 3200, "Ein Smurf ist ein Zweitkonto. Das hier ist das Hauptkonto.", [["T0PLANE_SCREAMER", 4100, "OK DANN SUPER-SMURF"]]]]],
			["JungleGott_KR", 2300, "Ich habe das Replay 40-mal angeschaut. Fragt mich nicht."]]},
	{"id": "verlassen", "sub": "counterspike", "flair": "Clip", "author": "Silber_Elite_Sven", "score": 14320, "age": "vor 8 Std.", "ncom": "1.180",
		"title": "Heute gegen 「　」 gematcht. Alle zehn Spieler haben das Match verlassen. Ich war einer davon.",
		"body": ["Ich sehe den Namen im Ladebildschirm und denke: lustig, ein leerer Name.", "Dann sehe ich den Rang: The Global Elite. Profilrang 40.", "Ich habe nicht nachgedacht. Ich habe einfach auf Verlassen geklickt. Die anderen neun auch."],
		"comments": [
			["AWP_Legende", 7700, "Kluge Entscheidung. Ich bin geblieben. 16 zu 0."],
			["HeadshotMaschine", 5050, "Ich auch. Ich weiß immer noch nicht, woher die Schüsse kamen."],
			["Silber_Elite_Sven", 2100, "Wie lange ist eigentlich die Sperre fürs Verlassen?", [["Mod_Bot", 1800, "Für Matches gegen dieses Konto gibt es keine Sperre. Wir verstehen das."]]]]},
	{"id": "goat", "sub": "gaming", "flair": "Diskussion", "author": "Gamer_Grübler", "score": 8840, "age": "vor 1 Tag", "ncom": "5.330",
		"title": "Wer ist der beste Gamer aller Zeiten? (Nein, nicht 「　」, die zählen nicht)",
		"body": ["Jeder Thread endet bei denselben Leerzeichen. Lasst uns mal über Menschen reden.", "Also: Wer ist der beste Gamer aller Zeiten, wenn man 「　」 rausnimmt?"],
		"comments": [["Gamerin_Mia", 6100, "「　」"], ["NachtEule", 5800, "「　」"], ["Gamer_Grübler", 4100, "Ich habe doch gesagt, die zählen nicht.", [["xX_Herausforderer_Xx", 7000, "Dann gibt es keine Antwort."]]]]},
]


static func find(sub: String, id: String) -> Dictionary:
	for t in THREADS:
		if t["sub"] == sub and t["id"] == id:
			return t
	return {}


## Ursprüngliche Punktzahl eines Beitrags („id“) oder Kommentars („id.0.1“).
static func score_of(key: String) -> int:
	var parts := key.split(".")
	for t in THREADS:
		if t["id"] != parts[0]:
			continue
		if parts.size() == 1:
			return t["score"]
		var list: Array = t["comments"]
		var node: Array = []
		for i in range(1, parts.size()):
			node = list[int(parts[i])]
			list = node[3] if node.size() > 3 else []
		return node[1]
	return 0
