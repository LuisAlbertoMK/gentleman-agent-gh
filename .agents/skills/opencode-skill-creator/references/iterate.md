# How to Think About Improvements

1. **Generalize** — Skills may be used millions of times. Don't overfit to a few examples. If a stubborn issue won't fix with small tweaks, try different metaphors or patterns.

2. **Keep the prompt lean** — Remove things that aren't pulling their weight. Read transcripts, not just outputs. If the skill makes the model waste time on unproductive steps, cut them.

3. **Explain the why** — LLMs have theory of mind. Transmit understanding of the task. If you're writing ALWAYS/NEVER in all caps, reframe and explain the reasoning instead.

4. **Look for repeated work** — If all test cases independently wrote the same helper script, bundle it in `scripts/`. Saves every future invocation from reinventing the wheel.

Take your time and really mull things over. Write a draft, then look anew and improve.

## Blind Comparison (Advanced)

For rigorous A/B comparison (e.g., "is the new version actually better?"), use the blind comparison system. Read `agents/comparator.md` and `agents/analyzer.md`. Give two outputs to an independent agent without identifying which is which, let it judge, then analyze why the winner won. This is optional — human review is usually sufficient.
