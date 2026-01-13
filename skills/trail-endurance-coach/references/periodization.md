# Periodization Reference

## Cycle Types

### 1. Base / Fondation (4-6 weeks)
**Objective**: Build aerobic foundation and general strength

| Parameter | Target |
|-----------|--------|
| Volume | 70-80% of peak |
| Intensity | 80% Z1-Z2, 15% Z3, 5% Z4+ |
| D+ focus | Moderate (50-70% of race ratio) |
| Strength | General: squats, lunges, core stability |

**Key Sessions**:
- Long run Z2 (progressively longer)
- Easy runs with strides
- Hill repeats (short, technique focus)
- 2x strength sessions/week

**Rationale**: Mitochondrial density, capillarization, fat oxidation capacity. Foundation for absorbing higher loads.

---

### 2. Development / Charge (3-4 weeks)
**Objective**: Develop lactate threshold and race-specific capacity

| Parameter | Target |
|-----------|--------|
| Volume | 90-100% of peak |
| Intensity | 65% Z1-Z2, 25% Z3-Z4, 10% Z5 |
| D+ focus | High (80-100% of race ratio) |
| Strength | Specific: eccentric, plyometric |

**Key Sessions**:
- Tempo runs at threshold (Z4)
- Long climbs at race effort
- Descente technique work
- Fartlek with terrain variation
- 2x specific strength/week

**Rationale**: Push lactate threshold higher, improve running economy on varied terrain, develop muscular endurance.

---

### 3. Specificity / Surcharge (2-3 weeks)
**Objective**: Final overload, race simulation

| Parameter | Target |
|-----------|--------|
| Volume | 100-110% peak (controlled) |
| Intensity | Race-specific distribution |
| D+ focus | Match or exceed race |
| Strength | Maintenance only |

**Key Sessions**:
- Back-to-back long days
- Race pace segments on similar terrain
- Test races (B/C priority)
- Mental rehearsal

**Rationale**: Peak training stress to trigger supercompensation. Test equipment, nutrition, pacing strategy.

---

### 4. Recovery / Décharge (1 week)
**Objective**: Absorb training, allow adaptation

| Parameter | Target |
|-----------|--------|
| Volume | 50-60% of previous week |
| Intensity | >90% Z1-Z2 |
| D+ focus | Minimal |
| Strength | Light mobility only |

**Key Sessions**:
- Easy runs, strict Z1
- Active recovery (walking, swimming)
- Mobility and stretching
- Sleep optimization

**Rationale**: Parasympathetic recovery, glycogen replenishment, tissue repair. Psychological freshness.

**Placement**: After every 2-3 weeks of load.

---

### 5. Taper / Affûtage (2-3 weeks)
**Objective**: Peak performance on race day

| Parameter | Week -3 | Week -2 | Week -1 |
|-----------|---------|---------|---------|
| Volume | -30% | -50% | -70% |
| Intensity | Maintain 1 quality | Short race-pace | Strides only |
| D+ | Moderate | Light | Minimal |
| Strength | Stop | None | None |

**Key Sessions**:
- Week -3: Last long effort (shortened), 1 tempo
- Week -2: Easy volume, short race-pace bursts
- Week -1: Activation runs, course preview if possible

**Rationale**: Research shows 2-3 week taper optimal. Maintain neuromuscular activation while maximizing glycogen stores and freshness.

---

## Planning Algorithm

### Step 1: Calculate Available Time
```
days_to_race = race_date - today
weeks_available = days_to_race / 7
```

### Step 2: Allocate Phases (by race type)

**Trail Court (<40km)**
| Weeks Available | Base | Dev | Spec | Taper |
|-----------------|------|-----|------|-------|
| 8-10 | 3 | 3 | 1 | 2 |
| 11-14 | 4 | 4 | 2 | 2 |
| 15+ | 5 | 5 | 2 | 2 |

**Trail Long (40-80km)**
| Weeks Available | Base | Dev | Spec | Taper |
|-----------------|------|-----|------|-------|
| 10-12 | 3 | 4 | 2 | 2-3 |
| 13-16 | 4 | 5 | 3 | 2-3 |
| 17+ | 5 | 6 | 3 | 3 |

**Ultra (>80km)**
| Weeks Available | Base | Dev | Spec | Taper |
|-----------------|------|-----|------|-------|
| 14-16 | 4 | 5 | 3 | 3 |
| 17-20 | 5 | 6 | 4 | 3 |
| 21+ | 6 | 7 | 4 | 3 |

### Step 3: Insert Recovery Weeks
- After every 2-3 load weeks, insert 1 recovery week
- Exception: Taper phase has no recovery weeks

### Step 4: Place Intermediate Races
- B races: Place in Specificity phase (good test)
- C races: Can be in Development (training through)
- Adjust surrounding weeks for mini-taper/recovery

---

## Cycle JSON Structure

```json
{
  "id": 1,
  "name": "Base - Endurance Fondamentale",
  "type": "base",
  "start_date": "2025-12-22",
  "end_date": "2026-01-11",
  "duration_weeks": 3,
  "status": "completed",
  "objective": "Construire le socle aérobie et la force générale",
  "focus": [
    "aerobic_base_z1_z2",
    "general_strength",
    "technique_running"
  ],
  "volume_targets": {
    "weekly_km_min": 40,
    "weekly_km_max": 55,
    "weekly_elevation_m": 1000,
    "long_run_km": 18,
    "strength_sessions": 2
  },
  "intensity_distribution": {
    "z1_z2_pct": 80,
    "z3_pct": 15,
    "z4_z5_pct": 5
  },
  "key_sessions": [
    "Sortie longue Z2 progressive",
    "Footing + gammes/éducatifs",
    "Côtes courtes technique",
    "Renforcement général"
  ],
  "rationale": "Phase de construction du socle aérobie nécessaire pour absorber les charges à venir. Développement de la capacité oxydative et de l'économie de course.",
  "adaptations": []
}
```

---

## Adaptation Triggers

When debriefs indicate issues, adjust cycles:

| Pattern Detected | Adaptation |
|------------------|------------|
| Recurring fatigue | Extend recovery weeks, reduce volume 10% |
| Weakness: descente | Add eccentric work, technical descente sessions |
| Weakness: montée | More vertical-focused long runs, power hiking |
| Crampes fin de course | Increase long run duration, nutrition practice |
| Mental difficulty | Add race simulations, break long runs into segments |
| Injury risk signals | Reduce intensity, increase mobility work |

Adaptations are logged in cycle's `adaptations` array with date and rationale.
