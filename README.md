# BLOODLINE — Godot 4 educational biology game

You are an erythrocyte travelling through the human circulatory system.
This build is the **vertical slice (Level 1 · The Lungs)** plus the shared systems every later level reuses.

## Run it
1. Install **Godot 4.3 or newer** (standard build, Forward+ renderer — the default).
2. Open Godot → *Import* → select `project.godot` → *Run* (F5).
   Open it once in the editor before exporting so Godot can import the resources.

## Controls
WASD move · Mouse look · Space up · Ctrl (or C) down · Shift boost · E interact · Tab encyclopedia · Esc pause

## Playing Level 1
1. Read the briefing. You start dark purple-red (oxygen-poor).
2. Swim downstream to a glowing pale-blue alveolus and press **E**.
3. Collect the light-blue O₂ molecules diffusing in from the alveoli. You turn bright red as haemoglobin saturates.
4. When saturated, take the knowledge check (5 questions, explanations after each).
5. Swim through the glowing ring (pulmonary vein) to finish. Progress and discoveries are saved.

## Where things are
| What | Where |
|---|---|
| Questions (edit/translate here) | `data/questions/level_1.json` (also level text and summary) |
| Encyclopedia entries | `data/encyclopedia/entries.json` |
| Save, settings, discoveries, scene fades | `autoload/game_state.gd` |
| Oxygen capacity / saturation | `autoload/oxygen_system.gd` (signals: `oxygen_changed`, `fully_saturated`) |
| Player + camera | `scripts/player/rbc_player.gd` |
| Level 1 logic | `scripts/gameplay/level_1.gd` |
| Procedural vessel / cell / illustrations | `scripts/gameplay/vessel_builder.gd`, `model_factory.gd` |
| Reusable UI (info panel, quiz, encyclopedia, HUD…) | `scripts/ui/`, `scenes/ui/` |

## Adding the next level
1. Copy `level_1.gd` → `level_2.gd` and a matching scene in `scenes/levels/`.
2. Create `data/questions/level_2.json` (same format).
3. Add an entry to `GameState.LEVELS`. Menu "Continue" and the completion screen's "Next mission" button pick it up automatically.
4. Add encyclopedia entries to `entries.json` and call `GameState.discover("id")` when the player meets them.
