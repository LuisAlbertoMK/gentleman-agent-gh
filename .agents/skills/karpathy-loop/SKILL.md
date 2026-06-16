---
name: karpathy-loop
description: "Iterative prompt optimization loop — write, measure, cut, repeat with progressive compression levels and decision gates"
triggers: "Karpathy loop, optimize prompt, measure tokens"
license: Apache-2.0
metadata: author: mk, version: "1.0"
---

Trigger: "optimize prompt", "reduce tokens".
## LOOPWriteâ†’Measureâ†’Cutâ†’Repeat
## PHASES1.WRITE: role+task+1-2 examples+output. Don't optimize yet.2.MEASURE: chars/4â‰ˆtokens. Score: correctness/conciseness/robustness3.CUT: remove redundant/merger/simplify. If no output change â†’ cut.4.REPEAT: score improves+tokens down â†’ continue. Score drops â†’ revert. Stagnantâ†’try new tactic.
## TACTICSL1(20-30%): filler/transitions/"step by step"L2(30-50%): merge redundantâ†’bullets, remove contextL3(50-70%): template structures, shortcuts, minimal identity
## DECISIONRemove element?â”œâ”€Output changes?â†’YES:keepâ””â”€No: concision improves?    â”œâ”€YES:remove    â””â”€NO: clarity?â†’YES:keep|NO:remove
## STOPTokens<50+works, 3 iter no improvement, fits 1 line.NEVER: correctness for tokens, uncovered edge cases.
