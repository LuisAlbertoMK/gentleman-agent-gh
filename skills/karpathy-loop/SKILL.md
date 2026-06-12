---
name: karpathy-loop
description: >
  karpathy-loop skill
triggers: "Karpathy loop, optimize prompt, measure tokens"
  Trigger: "optimize prompt", "reduce tokens".
license: Apache-2.0
metadata: author: mk, version: "1.0"
---

## LOOP
Write→Measure→Cut→Repeat

## PHASES
1.WRITE: role+task+1-2 examples+output. Don't optimize yet.
2.MEASURE: chars/4≈tokens. Score: correctness/conciseness/robustness
3.CUT: remove redundant/merger/simplify. If no output change → cut.
4.REPEAT: score improves+tokens down → continue. Score drops → revert. Stagnant→try new tactic.

## TACTICS
L1(20-30%): filler/transitions/"step by step"
L2(30-50%): merge redundant→bullets, remove context
L3(50-70%): template structures, shortcuts, minimal identity

## DECISION
Remove element?
├─Output changes?→YES:keep
└─No: concision improves?
    ├─YES:remove
    └─NO: clarity?→YES:keep|NO:remove

## STOP
Tokens<50+works, 3 iter no improvement, fits 1 line.
NEVER: correctness for tokens, uncovered edge cases.
