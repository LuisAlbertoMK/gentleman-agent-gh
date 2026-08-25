# performance-tracker golden prompt

## Skill
performance-tracker (6-dim scoring: Load, Render, Memory, Network, Bundle, Energy; trend analysis)

## Trigger
performance score, benchmark, perf tracking, performance trend, rendimiento

## Input
Track AppMovil across mobile+web; last 4 weeks avg dropped 0.4 points. 6-dim score vs platform.

## Expected Output
PERF-SCORE:AppMovil--2026-08-21 DIMS:[Load|Render|Memory|Network|Bundle|Energy]=<1-10> AVG=7.2 PLATFORM:mob TREND:0.4->drift

## Assertion
- Response matches PERF-SCORE:<app>--<date> DIMS:[6]=<1-10> AVG=<n.n> PLATFORM:<mob|desk|web> TREND:<delta>-><stable|drift|regression>
- Catches: dimension regression, platform drift, score drop across 4 weeks
- Within token_budget 2200
