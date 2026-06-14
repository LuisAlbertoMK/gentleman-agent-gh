---
name: karpathy-prompt
description: >  karpathy-prompt skill
triggers: "Karpathy, less tokens, context compilation"
license: Apache-2.0
metadata: author: mk, version: "1.1"
---

Trigger: "mÃ©todo Karpathy", "less tokens".
## FUNDAMENTAL"Write like explaining to smart junior dev sitting next to you." Less=more.
## 5 RULES1.ID+TASK=ENOUGH: "Eres [role]. Task:[t]"2.MINIMAL: no 10+ lists, no paragraphs. Yes 1-2 examples, output format.3.FORMAT=INSTRUCT: "Respond ONLY in JSON:{...}"4.CONSTRAINTS=FORMAT: max X, code only, ignore all except X5.IMPLICIT CoT: no "think step by step". If needed:"Reason ONLY if ambiguous."
## WIKIL1 Raw sources | L2 LLM-compiled | L3 index.md (~200t)Pre-compiled: 1)files, 2)~3-5K map, 3)use as input
## ANTI| NO | YES ||"detailed"|"precise"||"step by step"|omit||10+ rules|2-3 constraints||verbose identity|role+task+output|
## BUDGETID+TASK: ~20-50 | +example: +100-200 | +constraints:+50-100 | +output:+30-50OPTIMAL: ~50-300
