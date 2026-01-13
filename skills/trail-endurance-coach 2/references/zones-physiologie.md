# Zones & Physiology Reference

## Heart Rate Zones

Standard 5-zone model based on lactate thresholds:

| Zone | Name | % HRmax | % LTHR | RPE | Physiological Target |
|------|------|---------|--------|-----|---------------------|
| Z1 | Récupération | 50-60% | <80% | 1-2 | Active recovery, blood flow |
| Z2 | Endurance | 60-70% | 80-90% | 3-4 | Aerobic base, fat oxidation |
| Z3 | Tempo | 70-80% | 90-100% | 5-6 | Aerobic capacity, efficiency |
| Z4 | Seuil | 80-90% | 100-105% | 7-8 | Lactate threshold |
| Z5 | VO2max | 90-100% | >105% | 9-10 | Maximal oxygen uptake |

### Zone Calculation from Strava

Strava provides custom HR zones. Map to training targets:
```
Z1 max = athlete.hr_zones.z1.max (e.g., 132)
Z2 max = athlete.hr_zones.z2.max (e.g., 147)
Z3 max = athlete.hr_zones.z3.max (e.g., 162)
Z4 max = athlete.hr_zones.z4.max (e.g., 177)
Z5 = above Z4 max
```

---

## Power Zones (Running Power)

Based on FTP (Functional Threshold Power) or Critical Power:

| Zone | Name | % FTP | Application |
|------|------|-------|-------------|
| Z1 | Recovery | <55% | Easy runs |
| Z2 | Endurance | 55-75% | Long runs, base |
| Z3 | Tempo | 75-90% | Steady-state efforts |
| Z4 | Threshold | 90-105% | Threshold intervals |
| Z5 | VO2max | 105-120% | High intensity intervals |
| Z6 | Anaerobic | >120% | Short sprints, hills |

### Running Power Considerations

- More consistent than pace on varied terrain
- Less lag than HR (immediate feedback)
- Normalized Power (NP) accounts for variability
- Intensity Factor (IF) = NP / FTP

---

## Training Effect by Zone

### Z1-Z2: Aerobic Development
**Adaptations**:
- Increased mitochondrial density
- Enhanced capillarization
- Improved fat oxidation
- Cardiac stroke volume

**Time to adapt**: 4-8 weeks of consistent training

### Z3: Aerobic Power
**Adaptations**:
- Improved lactate clearance
- Running economy
- Glycogen sparing

**Optimal duration**: 20-60 min continuous

### Z4: Threshold
**Adaptations**:
- Raised lactate threshold
- Improved buffering capacity
- Mental toughness

**Optimal structure**: 2x20min or 3x15min with short recovery

### Z5: VO2max
**Adaptations**:
- Maximal oxygen uptake
- Cardiac output
- Fast-twitch recruitment

**Optimal structure**: 3-5min intervals, 1:1 or 2:1 work:rest

---

## Trail-Specific Considerations

### Uphill Physiology
- HR typically 10-15 bpm higher for same RPE vs flat
- Power is more reliable metric
- Muscular (quad) fatigue often limits before cardiovascular
- Walking poles shift load to upper body

**Training implication**: Use HR ceiling loosely on climbs, focus on sustainable effort

### Downhill Physiology
- Eccentric muscle damage accumulates
- HR often lower but perceived effort high
- Quad fatigue and DOMS risk
- Technical skill reduces energy cost

**Training implication**: Progressive exposure to descente, eccentric strengthening

### Altitude Considerations
- >1500m: reduced oxygen availability
- HR elevated for same effort
- Acclimatization: 2-3 weeks for full adaptation
- Race day: conservative pacing, expect slower times

---

## Key Metrics for Analysis

### Cardiac Decoupling
```
decoupling = (HR_second_half / pace_second_half) / (HR_first_half / pace_first_half) - 1
```
- <5%: Excellent aerobic fitness
- 5-10%: Normal
- >10%: Fatigue, overreaching, or underfueling

### Efficiency Factor (EF)
```
EF = normalized_pace / average_HR
```
Higher EF = better running economy. Track over time.

### Training Stress Score (TSS)
```
TSS = (duration_hours × IF² × 100)
```
- <150/week: Recovery
- 150-300: Maintenance
- 300-450: Building
- >450: High load (risk of overtraining)

---

## Recovery Indicators

### Signs of Adequate Recovery
- Morning HR within 5 bpm of baseline
- HRV stable or improving
- Sleep quality good
- Motivation high
- Performance maintained or improving

### Signs of Accumulated Fatigue
- Elevated resting HR (+10%)
- Depressed HRV
- Sleep disturbance
- Irritability, low motivation
- Performance decline despite training
- Elevated RPE for same output

**Action**: Insert recovery week, reduce volume 40-50%
