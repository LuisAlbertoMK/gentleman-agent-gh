---
name: karpathy-loop
description: "Iterative prompt optimization loop — write, measure, cut, repeat with progressive compression levels and decision gates"
triggers: "Karpathy loop, optimize prompt, measure tokens"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: mk
  version: "2.0"
  changelog: "2.0: merged karpathy-prompt (style/rules/budget)"
---

Trigger: "optimize prompt", "reduce tokens", "Karpathy prompt", "less tokens", "context compilation".
## STYLE (absorbed from karpathy-prompt)5 RULES: 1)ID+TASK=ENOUGH, 2)MINIMAL(no 10+lists/paragraphs), 3)FORMAT=INSTRUCT("Respond ONLY in JSON:{...}"), 4)CONSTRAINTS=FORMAT(max X/code only), 5)IMPLICIT CoT(no "step by step"; "Reason ONLY if ambiguous")WIKI: L1 raw→L2 LLM-compiled→L3 index.md (~200t). Pre-compile files→~3-5K map→use as inputANTI: "detailed"→"precise", "step by step"→omit, "10+ rules"→2-3 constraints, "verbose identity"→role+task+outputBUDGET: ID+TASK ~20-50 | +example +100-200 | +constraints +50-100 | +output +30-50. OPTIMAL ~50-300
## LOOPWrite→Measure→Cut→Repeat
## PHASES1.WRITE: role+task+1-2 examples+output. Don't optimize yet.2.MEASURE: chars/4≈tokens. Score: correctness/conciseness/robustness3.CUT: remove redundant/merger/simplify. If no output change → cut.4.REPEAT: score improves+tokens down → continue. Score drops → revert. Stagnant→try new tactic.
## TACTICSL1(20-30%): filler/transitions/"step by step"L2(30-50%): merge redundant→bullets, remove contextL3(50-70%): template structures, shortcuts, minimal identity
## DECISIONRemove element?├─Output changes?→YES:keep└─No: concision improves?    ├─YES:remove    └─NO: clarity?→YES:keep|NO:remove
## STOPTokens<50+works, 3 iter no improvement, fits 1 line.NEVER: correctness for tokens, uncovered edge cases.
