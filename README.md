# Escoba de 15 — Godot 4 Port
Converted from the original QuickBasic source `ESCOBA.BAS` (1997) to Godot 4.x (GDScript).

---

## What is Escoba de 15?
A classic Spanish card game played with a 40-card Spanish deck.
**Goal:** Capture cards from the table that sum to exactly **15**.
Score points for: most cards, most Oros (gold suit), most 7s, the 7 of Oros (velo),
and each *escoba* (clearing the entire table).
First player to reach the target score (default 21) wins.

---

## Project Structure

```
escoba_godot/
├── project.godot
├── scripts/
│   ├── CardData.gd       # Card encoding helpers (suit/number from card ID 1-40)
│   ├── GameLogic.gd      # All game rules + AI (translated from QB)
│   ├── GameScene.gd      # Main game UI controller
│   ├── CardNode.gd       # Clickable card widget
│   └── MainMenu.gd       # Main menu controller
└── scenes/
    ├── MainMenu.tscn     ← Build this (see below)
    ├── GameScene.tscn    ← Build this (see below)
    └── CardNode.tscn     ← Build this (see below)
```

---

## Scenes to Create in the Godot Editor

### 1. `CardNode.tscn`
Root: **Button** (script: `CardNode.gd`)
- Minimum size: 80 × 110
- Child: **Label** (name: `Label`, anchored center, autowrap off)

### 2. `MainMenu.tscn`
Root: **Control** (script: `MainMenu.gd`, full-rect anchor)
Children:
```
VBox (VBoxContainer, centered)
  Label            "ESCOBA DE 15"  (large font)
  Label            "¿Cuántos puntos para ganar?"
  SpinBox          name="TargetSpin"
  Label            "¿Quién baraja primero?"
  OptionButton     name="DealerOption"  items: ["Tú", "Yo"]
  Button           name="PlayButton"   text="¡Jugar!"
  Button           name="CreditsButton" text="Créditos"
Panel (name=CreditsPanel, visible=false)
  Label  text="Escoba v1.0\nConvertido de QuickBasic a Godot 4\nOriginal: 1997"
  Button name="CloseButton" text="Cerrar"
```

### 3. `GameScene.tscn`
Root: **Node2D** (script: `GameScene.gd`)
Children:
```
HFlowContainer  name="CompHandArea"    (top of screen, cards face-down)
HFlowContainer  name="TableArea"       (middle, clickable cards)
HFlowContainer  name="PlayerHandArea"  (bottom, player's cards)
Control name="UI"
  Label   name="StatusLabel"
  Label   name="ScoreLabel"
  Label   name="DeckLabel"
  Label   name="EscobasLabel"
  Label   name="ErrorLabel"   (red color for error messages)
  Button  name="ConfirmButton" text="✔ Confirmar jugada"
  Button  name="PassButton"    text="↩ Descartar selección"
  Label   name="EndTurnHint"  text="Esperando turno del ordenador..."
  Panel   name="RoundSummaryPanel" (visible=false, covers center)
    Label  name="Content"
    Button name="ContinueButton"
```

---

## Card Images
The original game used BMP files (`1O.BMP`, `7E.BMP`, etc.).
To use your original assets:
1. Convert the BMP files to PNG: `for f in *.BMP; do convert "$f" "${f%.BMP}.png"; done`
2. Place PNGs in `res://assets/cards/`
3. In `CardNode.gd` `_refresh()`, load the texture:
   ```gdscript
   var key = CardData.get_image_key(_card_id)   # e.g. "7E"
   var tex = load("res://assets/cards/%s.png" % key)
   $TextureRect.texture = tex
   ```
   Add a **TextureRect** child to CardNode.tscn and replace the Label display.

---

## Original → Godot Mapping

| QuickBasic | Godot |
|---|---|
| `cm(1-17)` | `logic.table_cards[]` |
| `cm(18-20)` | `logic.comp_hand[]` |
| `cm(21-23)` | `logic.player_hand[]` |
| `baraja(1-40)` | `logic.deck_state{}` |
| `JuegaCom` | `GameLogic._run_ai()` |
| `JuegaJug` | `GameScene._on_confirm_pressed()` |
| `ComparaJugada` | `GameLogic._score_and_compare()` |
| `PuntuaCoger!` | `GameLogic._score_take()` |
| `PuntuaDejar!` | `GameLogic._score_leave()` |
| `OrdenaMesa` | `GameLogic.sort_table()` |
| `Pasa15` | `GameLogic._pasa15()` |
| `PuedeCoger` | `GameLogic._can_take_with()` |
| `Pausa` / `Creditos` | Godot panels / signals |
| DOS interrupt `&H33` (mouse) | Godot built-in input |
| `GET`/`PUT` (BMP blitting) | Godot TextureRect |
| `SCREEN 12` (VGA 640×480) | Godot viewport (1280×720) |

---

## Notes
- The AI logic is a faithful translation of the original heuristic scoring from the QB source.
- The original game used XOR pixel blitting for card display; Godot handles rendering natively.
- Mouse detection via DOS interrupt `&H33` is replaced by Godot's signal-based input system.
- The `COPIAMEM.BI` include (memory copy for BMP loading) is not needed in Godot.
