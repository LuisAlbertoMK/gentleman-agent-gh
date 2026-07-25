# Quick Start — Gentleman Agent

**5 steps to start using the agent in 5 minutes.**

---

## What is this?

Gentleman Agent is an **AI software development team** with 22 specialized agents. Instead of a single chatbot, you get:

Each agent loads from 1-5 of 92 specialized skills as needed.

- 🏗️ **Lead Architect** (`gentleman-vMK`) — your Senior Architect mentor
- 🔒 **Specialists** (security, performance, frontend, etc.) — FREE TIER consultants
- 🧠 **Persistent memory** (Engram) — the agent remembers across sessions
- ✅ **Auto-verification** — triple check before any change

**In summary**: You ask for a task, the agent resolves it with its team, verifies it works, and documents what it learned.

---

## Step 1: Install

```bash
# Clone
git clone https://github.com/LuisAlbertoMK/gentleman-agent-gh.git
cd gentleman-agent-gh

# Windows
.\scripts\setup-install.ps1

# Linux/macOS
./scripts/install.sh
```

**Time**: ~2 minutes

---

## Step 2: Open OpenCode

```bash
# In the project folder
opencode
```

The `gentleman-vMK` agent loads automatically as default.

**Time**: ~10 seconds

---

## Step 3: Ask for your first task

Write something like:

```
Analyze my project and tell me what I can improve
```

or

```
Review this file and suggest optimizations
```

or

```
Create a test for this function
```

**The agent automatically**:
1. Detects your tech stack
2. Loads relevant skills
3. Delegates to specialists if needed
4. Verifies the changes
5. Documents in bitacora

**Time**: Variable depending on the task

---

## Step 4: Use useful shortcuts

| Shortcut | When to use |
|----------|-------------|
| `!score` | After changes to see the score |
| `!health` | If something fails or you want to diagnose |
| `!close` | When finishing the session |
| `!analisis` | For deep multi-agent analysis |
| `!ejecutar` | Execute analysis findings with parallel subagents (after `!analisis`) |

**Example**:
```
!score
```

---

## Step 5: Close session

```
!close
```

This automatically:
- Saves to bitacora
- Updates inter-track
- Syncs with global config
- Shows git status

---

## Next steps

1. **Read [AGENTS.md](AGENTS.md)** to understand the full protocol
2. **Explore skills** in `.agents/skills/` (92 available)
3. **Try `!analisis`** for multi-agent analysis of your project
4. **Check [CYCLE.md](CYCLE.md)** to see the current improvement cycle

---

## Tips for new users

- **You don't need to remember everything** — the agent knows when to apply each skill
- **Start simple** — ask for small tasks first
- **Use `!health`** if something fails — it gives you a complete diagnostic
- **The agent learns** — uses Engram to remember across sessions

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Agent not responding | `!health` to diagnose |
| Skill not loading | Check `.agents/skills/` exists |
| Low score | `!score` to recalculate |
| Git errors | `git status` to see the state |

---

*Last updated: 2026-07-18*
