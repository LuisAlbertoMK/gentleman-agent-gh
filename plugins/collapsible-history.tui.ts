/**
 * opencode-collapsible-history-tui — v0.1.0 (TUI part)
 * Split from collapsible-history.ts — opencode v1.18.25 path plugins must
 * export EITHER server OR tui in default, not both. This file is TUI-only.
 *
 * Loaded as second path plugin alongside collapsible-history.ts (server).
 * See DESIGN.md — slot: sidebar_content, OPT-IN via opencode.json plugin array.
 * SAFE: Node-compatible only, no Bun APIs.
 */

export const PLUGIN_NAME = "opencode-collapsible-history"
export const PLUGIN_VERSION = "0.1.0"
export const TUI_PLUGIN_ID = `${PLUGIN_NAME}-tui`
const SNIPPET_LEN = 80

// ─── In-memory collapsed state (TUI-process-local) ──────────────────────────
// Mirrors server file state but isolated to TUI process memory.

const collapsedState = new Map<string, Set<string>>()
const turnOrder = new Map<string, string[]>()
const selectedIndex = new Map<string, number>()

// ─── Helpers (pure, testable, Node-compatible) ──────────────────────────────

export function truncate(text: string, max = SNIPPET_LEN): string {
  if (!text) return ""
  const single = text.replace(/\s+/g, " ").trim()
  return single.length > max ? single.slice(0, max) + "…" : single
}

export function estimateTokens(text: string): number {
  if (!text) return 0
  return Math.ceil(text.length / 4)
}

export function formatTime(d: Date = new Date()): string {
  const h = String(d.getHours()).padStart(2, "0")
  const m = String(d.getMinutes()).padStart(2, "0")
  return `${h}:${m}`
}

export type TurnGroup = {
  turnId: string
  sessionId: string
  userText: string
  snippet: string
  timestamp: string
  tokenCount: number
  collapsed: boolean
  partCount: number
}

export function groupMessagesByTurn(
  sessionId: string,
  messages: Array<{ role: string; text?: string; parts?: Array<{ text?: string }> }>,
): TurnGroup[] {
  const groups: TurnGroup[] = []
  let idx = 0
  for (const m of messages) {
    if (m.role !== "user") continue
    const raw = (m.text ?? m.parts?.map((p) => p.text ?? "").join("\n") ?? "").trim()
    if (!raw) continue
    const turnId = `${sessionId}:${idx}`
    groups.push({
      turnId,
      sessionId,
      userText: raw,
      snippet: truncate(raw, SNIPPET_LEN),
      timestamp: formatTime(new Date()),
      tokenCount: estimateTokens(raw),
      collapsed: false,
      partCount: m.parts?.length ?? 1,
    })
    idx++
  }
  const collapsed = collapsedState.get(sessionId)
  return groups.map((g, i) => {
    const isLast = i === groups.length - 1
    const isCollapsed = collapsed ? collapsed.has(g.turnId) : !isLast
    return { ...g, collapsed: isCollapsed }
  })
}

export function isCollapsed(sessionId: string, turnId: string): boolean {
  return collapsedState.get(sessionId)?.has(turnId) ?? false
}

export function toggleCollapsed(sessionId: string, turnId: string): boolean {
  let set = collapsedState.get(sessionId)
  if (!set) {
    set = new Set()
    collapsedState.set(sessionId, set)
  }
  if (set.has(turnId)) {
    set.delete(turnId)
    return false
  }
  set.add(turnId)
  return true
}

export function collapseAll(sessionId: string): void {
  const order = turnOrder.get(sessionId) ?? []
  collapsedState.set(sessionId, new Set(order))
}

export function expandAll(sessionId: string): void {
  collapsedState.set(sessionId, new Set())
}

export function navigateSelection(sessionId: string, dir: 1 | -1): number {
  const order = turnOrder.get(sessionId) ?? []
  if (order.length === 0) return 0
  const cur = selectedIndex.get(sessionId) ?? order.length - 1
  const next = Math.max(0, Math.min(order.length - 1, cur + dir))
  selectedIndex.set(sessionId, next)
  return next
}

export function syncTurnOrder(sessionId: string, groups: TurnGroup[]): void {
  turnOrder.set(sessionId, groups.map((g) => g.turnId))
  const sel = selectedIndex.get(sessionId)
  if (sel === undefined || sel >= groups.length) {
    selectedIndex.set(sessionId, Math.max(0, groups.length - 1))
  }
}

// ─── TUI Slot (SolidJS @opentui/solid JSX) ─────────────────────────────────
/* eslint-disable @typescript-eslint/no-explicit-any */
export const tui = async (api: any) => {
  if (!api?.slots?.register) return

  let solid: any = null
  try {
    solid = await import("@opentui/solid").catch(() => null)
  } catch {
    solid = null
  }

  const createSignal = solid?.createSignal as
    | ((v: boolean) => [() => boolean, (v: boolean) => void])
    | undefined

  const CollapsibleHistorySlot = (props: { sessionId?: string }) => {
    const sid: string = props.sessionId ?? api.state?.session?.current?.() ?? "unknown"
    const placeholder = `Collapsible history — ${PLUGIN_NAME} v${PLUGIN_VERSION}`
    const hint = "Enter/o toggle · c collapse all · a expand all · j/k navigate"

    if (createSignal && solid?.jsx) {
      const [expanded] = createSignal(true)
      void expanded
      return (solid as any).jsx("box", {
        style: { flexDirection: "column", gap: 1 },
        children: [
          (solid as any).jsx("text", { children: placeholder }),
          (solid as any).jsx("text", { dim: true, children: hint }),
        ],
      })
    }

    return `${placeholder}\n${hint}\n[${sid}]`
  }

  try {
    api.slots.register({
      id: PLUGIN_NAME,
      slot: "sidebar_content",
      render: CollapsibleHistorySlot,
      keys: [
        { key: "enter", handler: ({ sessionId }: any) => toggleCollapsed(sessionId, turnOrder.get(sessionId)?.[selectedIndex.get(sessionId) ?? 0] ?? "") },
        { key: "o", handler: ({ sessionId }: any) => toggleCollapsed(sessionId, turnOrder.get(sessionId)?.[selectedIndex.get(sessionId) ?? 0] ?? "") },
        { key: "c", handler: ({ sessionId }: any) => collapseAll(sessionId) },
        { key: "a", handler: ({ sessionId }: any) => expandAll(sessionId) },
        { key: "j", handler: ({ sessionId }: any) => navigateSelection(sessionId, 1) },
        { key: "k", handler: ({ sessionId }: any) => navigateSelection(sessionId, -1) },
      ],
    })
  } catch {
    try {
      api.slots.register({
        id: PLUGIN_NAME,
        slot: "session_history" as any,
        render: CollapsibleHistorySlot,
      })
    } catch {
      // no slot available — still loads safely
    }
  }

  api.lifecycle?.onDispose?.(() => {})
}

// ─── Module default (TUI only) ─────────────────────────────────────────────
// opencode v1.18.25: path plugin default must contain EITHER server OR tui.
export default {
  id: TUI_PLUGIN_ID,
  name: PLUGIN_NAME,
  version: PLUGIN_VERSION,
  tui,
}
