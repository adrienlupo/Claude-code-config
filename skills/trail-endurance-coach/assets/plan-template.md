# Training Plan Template

Use this template structure when generating human-readable plan output.

## Full Plan Overview Format

```markdown
# 🏃 Plan de Préparation: [RACE_NAME]

**Objectif**: [RACE_NAME] - [DATE]
**Distance**: [DISTANCE]km | **D+**: [ELEVATION]m | **Type**: [CATEGORY]

**Durée de préparation**: [WEEKS] semaines
**Généré le**: [TODAY]

---

## 📊 Vue Globale des Cycles

| # | Cycle | Type | Dates | Durée | Statut |
|---|-------|------|-------|-------|--------|
| 1 | [NAME] | [TYPE] | [START] → [END] | [X] sem | ✅/🔄/⏳ |

---

## 📅 Détail des Cycles

### CYCLE [N]: [NAME] [EMOJI]

📅 **[START_DATE] → [END_DATE]** ([DURATION] semaines)

🎯 **Objectif**: [OBJECTIVE]

**Focus physiologique**:
- [FOCUS_1]
- [FOCUS_2]
- [FOCUS_3]

**Séances clés**:
- [SESSION_1]
- [SESSION_2]
- [SESSION_3]

**Cibles volume**:
- Kilométrage: [KM_MIN]-[KM_MAX] km/semaine
- Dénivelé: [ELEVATION]m/semaine
- Sortie longue: jusqu'à [LONG_RUN]km

💡 **Rationale**: [RATIONALE_TEXT]

[IF ADAPTATIONS]
⚠️ **Adaptations appliquées**:
- [DATE]: [ADAPTATION_DESCRIPTION]
[/IF]

---

### 🔄 Semaine de Récupération

📅 **[START_DATE] → [END_DATE]**

🎯 Récupération active, assimilation des adaptations

- Volume: -40% à -50%
- Intensité: Z1 stricte
- Focus: Mobilité, sommeil, nutrition

---
```

## Cycle Status Emojis

- ✅ `completed` - Cycle terminé
- 🔄 `in_progress` - Cycle en cours
- ⏳ `upcoming` - Cycle à venir

## Cycle Type Emojis

- 🏗️ Base / Fondation
- 📈 Development / Charge
- 🎯 Specificity / Surcharge
- 🔄 Recovery / Décharge
- ✨ Taper / Affûtage

## Current Week Detail Format

```markdown
## 📍 Cette Semaine: [WEEK_ID]

**Cycle actuel**: [CYCLE_NAME] ([CYCLE_TYPE])
**Période**: [START] → [END]

### Objectifs de la semaine
- Volume cible: [TARGET_KM]km
- D+ cible: [TARGET_ELEV]m
- Séances qualité: [QUALITY_COUNT]

### Progression
| Métrique | Réalisé | Cible | % |
|----------|---------|-------|---|
| Distance | [X]km | [Y]km | [Z]% |
| Dénivelé | [X]m | [Y]m | [Z]% |
| Temps | [X]h | [Y]h | [Z]% |

### Distribution zones (réalisé)
- Z1-Z2: [X]% (cible: [Y]%)
- Z3: [X]% (cible: [Y]%)
- Z4-Z5: [X]% (cible: [Y]%)

### Recommandations pour les jours restants
[COACHING_RECOMMENDATIONS]
```

## Activity Analysis Format

```markdown
## 🏃 Analyse: [ACTIVITY_NAME]

**Date**: [DATE] | **Type**: [SPORT_TYPE]
**Distance**: [KM]km | **D+**: [ELEV]m | **Durée**: [DURATION]

### Métriques clés
| Métrique | Valeur | Analyse |
|----------|--------|---------|
| Allure moy | [PACE]/km | [COMMENT] |
| FC moyenne | [HR] bpm | Zone [X] |
| Puissance NP | [NP]W | IF [X] |

### Distribution zones
[Z1]: ████████░░ [X]%
[Z2]: ██████░░░░ [X]%
[Z3]: ████░░░░░░ [X]%
[Z4]: ██░░░░░░░░ [X]%
[Z5]: ░░░░░░░░░░ [X]%

### 📊 Analyse coaching

**Type de séance**: [SESSION_TYPE]
**Alignement objectifs**: [✓/⚠] [EXPLANATION]

**Observations physiologiques**:
- [OBS_1]
- [OBS_2]

**Notes techniques**:
- [NOTE_1]
- [NOTE_2]

**Récupération recommandée**: [RECOVERY_REC]

**Axes de développement**:
- [DEV_1]
- [DEV_2]

### 🎯 À retenir
> [KEY_TAKEAWAY]

**Note globale**: [RATING]/A
```
