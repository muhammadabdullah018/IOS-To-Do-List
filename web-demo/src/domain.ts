// Skyday demo domain: a small TypeScript port of the rules in Packages/SkydayKit.
// Pure functions only; the UI calls these and persists the result to localStorage.

export type DayKey = string // "YYYY-MM-DD", local calendar day
export type Priority = 0 | 1 | 2 | 3
export type Repeat = 'daily' | 'weekly' | 'monthly'

export interface Subtask { id: string; title: string; done: boolean }

export interface Task {
  id: string
  title: string
  notes: string
  listId: string
  priority: Priority
  dueDay?: DayKey
  dueTime?: string // "HH:MM"
  reminder?: number // minutes before due time
  repeat?: Repeat
  repeatAnchor?: number // day of month for monthly repeats, so 31st survives short months
  subtasks: Subtask[]
  completed: boolean
  completedAt?: string
  createdAt: string
}

export interface TaskList { id: string; name: string; icon: string; color: string }

export interface Completion { id: string; taskId: string; title: string; day: DayKey; at: string }

export interface AppData {
  version: 1
  name: string
  dailyGoal: number
  lists: TaskList[]
  tasks: Task[]
  completions: Completion[]
}

export const LIST_ICON_NAMES = ['book', 'cap', 'laptop', 'heart', 'dumbbell', 'cart', 'plane', 'music', 'star', 'briefcase']

export const LIMITS = { title: 200, notes: 2000, listName: 40, subtasks: 50, goalMin: 1, goalMax: 20 }

export const uid = () =>
  globalThis.crypto?.randomUUID?.() ?? `${Date.now().toString(36)}-${Math.random().toString(36).slice(2)}`

// ---------- Days ----------

const pad = (n: number) => String(n).padStart(2, '0')

export function dayKey(d: Date): DayKey {
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
}

export function parseDay(k: DayKey): Date {
  const [y, m, d] = k.split('-').map(Number)
  return new Date(y, m - 1, d, 12) // noon avoids DST edge hours
}

export function addDays(k: DayKey, n: number): DayKey {
  const d = parseDay(k)
  d.setDate(d.getDate() + n)
  return dayKey(d)
}

export function isValidDay(k: unknown): k is DayKey {
  if (typeof k !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(k)) return false
  const d = parseDay(k)
  return dayKey(d) === k && d.getFullYear() >= 2000 && d.getFullYear() <= 2100
}

/** Monday-start week containing `k`. */
export function weekDays(k: DayKey): DayKey[] {
  const d = parseDay(k)
  const offset = (d.getDay() + 6) % 7
  const monday = addDays(k, -offset)
  return Array.from({ length: 7 }, (_, i) => addDays(monday, i))
}

// ---------- Recurrence ----------

function addMonths(k: DayKey, months: number, anchor: number): DayKey {
  const d = parseDay(k)
  const target = new Date(d.getFullYear(), d.getMonth() + months, 1, 12)
  const lastDay = new Date(target.getFullYear(), target.getMonth() + 1, 0).getDate()
  target.setDate(Math.min(anchor, lastDay))
  return dayKey(target)
}

export function nextOccurrence(task: Pick<Task, 'repeat' | 'repeatAnchor'>, from: DayKey): DayKey {
  switch (task.repeat) {
    case 'daily': return addDays(from, 1)
    case 'weekly': return addDays(from, 7)
    case 'monthly': return addMonths(from, 1, task.repeatAnchor ?? parseDay(from).getDate())
    default: return from
  }
}

// ---------- Task actions (return new data, never mutate) ----------

export function completeTask(data: AppData, id: string, now: Date): AppData {
  const today = dayKey(now)
  const task = data.tasks.find(t => t.id === id)
  if (!task || task.completed) return data // idempotent
  const event: Completion = { id: uid(), taskId: id, title: task.title, day: today, at: now.toISOString() }
  let updated: Task
  if (task.repeat) {
    // One record per series: move the due day forward, never clone the task.
    let next = nextOccurrence(task, task.dueDay ?? today)
    while (next <= today) next = nextOccurrence(task, next)
    updated = { ...task, dueDay: next, subtasks: task.subtasks.map(s => ({ ...s, done: false })) }
  } else {
    updated = { ...task, completed: true, completedAt: now.toISOString() }
  }
  return { ...data, tasks: data.tasks.map(t => (t.id === id ? updated : t)), completions: [...data.completions, event] }
}

export function reopenTask(data: AppData, id: string): AppData {
  const task = data.tasks.find(t => t.id === id)
  if (!task || !task.completed) return data
  const lastIndex = data.completions.map(c => c.taskId).lastIndexOf(id)
  return {
    ...data,
    tasks: data.tasks.map(t => (t.id === id ? { ...t, completed: false, completedAt: undefined } : t)),
    completions: data.completions.filter((_, i) => i !== lastIndex),
  }
}

export function isOverdue(t: Task, today: DayKey): boolean {
  return !t.completed && !!t.dueDay && t.dueDay < today
}

/** Open tasks for Today: overdue first, then by time, then priority. */
export function todayTasks(data: AppData, today: DayKey): Task[] {
  return data.tasks
    .filter(t => !t.completed && t.dueDay && t.dueDay <= today)
    .sort((a, b) =>
      Number(isOverdue(b, today)) - Number(isOverdue(a, today)) ||
      (a.dueTime ?? '99').localeCompare(b.dueTime ?? '99') ||
      b.priority - a.priority ||
      a.createdAt.localeCompare(b.createdAt))
}

// ---------- Streaks ----------

export function completionsByDay(data: AppData): Map<DayKey, number> {
  const m = new Map<DayKey, number>()
  for (const c of data.completions) m.set(c.day, (m.get(c.day) ?? 0) + 1)
  return m
}

export interface StreakSummary { current: number; longest: number; todayDone: number; goal: number; total: number }

/** A day counts when completions >= goal. Today not yet counting does not break the streak. */
export function streak(data: AppData, today: DayKey): StreakSummary {
  const byDay = completionsByDay(data)
  const goal = data.dailyGoal
  const qualifies = (k: DayKey) => (byDay.get(k) ?? 0) >= goal
  let current = 0
  let cursor = qualifies(today) ? today : addDays(today, -1)
  while (qualifies(cursor)) { current++; cursor = addDays(cursor, -1) }
  let longest = 0
  let run = 0
  let prev: DayKey | undefined
  for (const k of [...byDay.keys()].filter(qualifies).sort()) {
    run = prev && addDays(prev, 1) === k ? run + 1 : 1
    longest = Math.max(longest, run)
    prev = k
  }
  return { current, longest: Math.max(longest, current), todayDone: byDay.get(today) ?? 0, goal, total: data.completions.length }
}

export const MILESTONES = [3, 7, 14, 30, 60, 100]

export function achievements(s: StreakSummary) {
  return [
    { id: 'first', title: 'First step', detail: 'Complete your first task', current: Math.min(s.total, 1), target: 1 },
    { id: 'warm', title: 'Warming up', detail: 'Reach a 3-day streak', current: Math.min(s.longest, 3), target: 3 },
    { id: 'star', title: 'Consistent', detail: 'Reach a 7-day streak', current: Math.min(s.longest, 7), target: 7 },
    { id: 'climb', title: 'Steady climb', detail: 'Reach a 14-day streak', current: Math.min(s.longest, 14), target: 14 },
    { id: 'fifty', title: 'Fifty finished', detail: 'Complete 50 tasks', current: Math.min(s.total, 50), target: 50 },
    { id: 'month', title: 'Month master', detail: 'Reach a 30-day streak', current: Math.min(s.longest, 30), target: 30 },
  ]
}

// ---------- Storage & import validation ----------

export function emptyData(): AppData {
  return {
    version: 1, name: '', dailyGoal: 3, tasks: [], completions: [],
    lists: [
      { id: 'inbox', name: 'Personal', icon: 'heart', color: '#D83995' },
      { id: uid(), name: 'University', icon: 'cap', color: '#0593C6' },
      { id: uid(), name: 'Work', icon: 'laptop', color: '#4F7FAE' },
    ],
  }
}

const str = (v: unknown, max: number) => (typeof v === 'string' ? v.slice(0, max) : '')

/** Validates untrusted JSON (localStorage or an imported file). Throws on bad shape. */
export function parseData(raw: unknown): AppData {
  if (!raw || typeof raw !== 'object') throw new Error('Not a Skyday backup')
  const r = raw as Record<string, unknown>
  if (r.version !== 1 || !Array.isArray(r.lists) || !Array.isArray(r.tasks) || !Array.isArray(r.completions)) {
    throw new Error('Not a Skyday backup')
  }
  const lists: TaskList[] = r.lists.slice(0, 100).map((l: any) => ({
    id: str(l?.id, 64) || uid(), name: str(l?.name, LIMITS.listName) || 'List', icon: LIST_ICON_NAMES.includes(l?.icon) ? l.icon : 'book',
    color: /^#[0-9A-Fa-f]{6}$/.test(l?.color) ? l.color : '#0593C6',
  }))
  if (lists.length === 0) throw new Error('Backup has no lists')
  const listIds = new Set(lists.map(l => l.id))
  const tasks: Task[] = r.tasks.slice(0, 5000).map((t: any) => ({
    id: str(t?.id, 64) || uid(),
    title: str(t?.title, LIMITS.title).trim() || 'Untitled',
    notes: str(t?.notes, LIMITS.notes),
    listId: listIds.has(t?.listId) ? t.listId : lists[0].id,
    priority: ([0, 1, 2, 3].includes(t?.priority) ? t.priority : 0) as Priority,
    dueDay: isValidDay(t?.dueDay) ? t.dueDay : undefined,
    dueTime: typeof t?.dueTime === 'string' && /^([01]\d|2[0-3]):[0-5]\d$/.test(t.dueTime) ? t.dueTime : undefined,
    reminder: Number.isInteger(t?.reminder) && t.reminder >= 0 && t.reminder <= 10080 ? t.reminder : undefined,
    repeat: ['daily', 'weekly', 'monthly'].includes(t?.repeat) ? t.repeat : undefined,
    repeatAnchor: Number.isInteger(t?.repeatAnchor) && t.repeatAnchor >= 1 && t.repeatAnchor <= 31 ? t.repeatAnchor : undefined,
    subtasks: Array.isArray(t?.subtasks)
      ? t.subtasks.slice(0, LIMITS.subtasks).map((s: any) => ({ id: str(s?.id, 64) || uid(), title: str(s?.title, LIMITS.title), done: s?.done === true }))
      : [],
    completed: t?.completed === true,
    completedAt: typeof t?.completedAt === 'string' ? t.completedAt : undefined,
    createdAt: typeof t?.createdAt === 'string' ? t.createdAt : new Date().toISOString(),
  }))
  const completions: Completion[] = r.completions.slice(0, 50000)
    .filter((c: any) => isValidDay(c?.day))
    .map((c: any) => ({ id: str(c?.id, 64) || uid(), taskId: str(c?.taskId, 64), title: str(c?.title, LIMITS.title), day: c.day, at: str(c?.at, 40) }))
  const goal = Number.isInteger(r.dailyGoal) ? Math.min(LIMITS.goalMax, Math.max(LIMITS.goalMin, r.dailyGoal as number)) : 3
  return { version: 1, name: str(r.name, 40), dailyGoal: goal, lists, tasks, completions }
}
