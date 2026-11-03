import { useEffect, useMemo, useRef, useState } from 'react'
import {
  achievements, addDays, AppData, completeTask, completionsByDay, dayKey, emptyData, isOverdue, LIMITS, MILESTONES,
  parseData, parseDay, Priority, reopenTask, Repeat, streak, Task, TaskList, todayTasks, uid, weekDays,
} from './domain'
import { SkyScene, Sprite, SPRITES } from './Pixel'

const STORAGE_KEY = 'skyday-demo-v1'

function load(): AppData {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    return raw ? parseData(JSON.parse(raw)) : emptyData()
  } catch {
    return emptyData()
  }
}

type Tab = 'today' | 'lists' | 'progress'
type Screen =
  | { kind: 'tab' }
  | { kind: 'list'; id: string }
  | { kind: 'calendar' }
  | { kind: 'streaks' }
  | { kind: 'settings' }
type Sheet = { kind: 'task'; id?: string; dueDay?: string; listId?: string } | { kind: 'list'; id?: string } | null

const PRIORITY_LABEL = ['None', 'Low', 'Medium', 'High']
const REPEAT_LABEL: Record<string, string> = { '': 'Never', daily: 'Every day', weekly: 'Every week', monthly: 'Every month' }

export default function App() {
  const [data, setData] = useState<AppData>(load)
  const [tab, setTab] = useState<Tab>('today')
  const [screen, setScreen] = useState<Screen>({ kind: 'tab' })
  const [sheet, setSheet] = useState<Sheet>(null)
  const [undo, setUndo] = useState<{ msg: string; prev: AppData } | null>(null)
  const [saveError, setSaveError] = useState(false)
  const [now, setNow] = useState(() => new Date())
  const today = dayKey(now)

  useEffect(() => {
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify(data)); setSaveError(false) } catch { setSaveError(true) }
  }, [data])
  useEffect(() => { const t = setInterval(() => setNow(new Date()), 60_000); return () => clearInterval(t) }, [])
  useEffect(() => { if (!undo) return; const t = setTimeout(() => setUndo(null), 5000); return () => clearTimeout(t) }, [undo])

  const commit = (next: AppData, undoMsg?: string) => {
    if (undoMsg) setUndo({ msg: undoMsg, prev: data })
    setData(next)
  }
  const toggle = (t: Task) => {
    if (t.completed) commit(reopenTask(data, t.id))
    else commit(completeTask(data, t.id, new Date()), `Completed “${t.title}”`)
  }
  const openTab = (t: Tab) => { setTab(t); setScreen({ kind: 'tab' }) }
  const ctx: Ctx = { data, today, now, commit, toggle, setScreen, setSheet, openTab }

  let body: JSX.Element
  if (screen.kind === 'list') body = <ListDetail {...ctx} id={screen.id} />
  else if (screen.kind === 'calendar') body = <Calendar {...ctx} />
  else if (screen.kind === 'streaks') body = <Streaks {...ctx} />
  else if (screen.kind === 'settings') body = <Settings {...ctx} />
  else if (tab === 'today') body = <Today {...ctx} />
  else if (tab === 'lists') body = <Lists {...ctx} />
  else body = <ProgressTab {...ctx} />

  return (
    <div className="device">
      <div className="demo-badge" role="note">DEMO · browser preview, data stays in this browser</div>
      {saveError && <div className="banner" role="alert">Couldn’t save in this browser. Changes may be lost on reload.</div>}
      <main className="screen" key={screen.kind + tab}>{body}</main>
      <nav className="tabbar" aria-label="Main">
        {(['today', 'lists', 'progress'] as Tab[]).map(t => (
          <button key={t} className={tab === t ? 'tab active' : 'tab'} aria-current={tab === t ? 'page' : undefined} onClick={() => openTab(t)}>
            <span className="tab-icon" aria-hidden="true">{t === 'today' ? '⌂' : t === 'lists' ? '≡' : '▥'}</span>
            {t === 'today' ? 'Today' : t === 'lists' ? 'Lists' : 'Progress'}
          </button>
        ))}
      </nav>
      {undo && (
        <div className="toast" role="status">
          <span>{undo.msg}</span>
          <button onClick={() => { setData(undo.prev); setUndo(null) }}>Undo</button>
        </div>
      )}
      {sheet?.kind === 'task' && <TaskSheet {...ctx} sheet={sheet} close={() => setSheet(null)} />}
      {sheet?.kind === 'list' && <ListSheet {...ctx} id={sheet.id} close={() => setSheet(null)} />}
    </div>
  )
}

interface Ctx {
  data: AppData
  today: string
  now: Date
  commit: (d: AppData, undoMsg?: string) => void
  toggle: (t: Task) => void
  setScreen: (s: Screen) => void
  setSheet: (s: Sheet) => void
  openTab: (t: Tab) => void
}

// ---------- Shared pieces ----------

function fmtDay(k: string, today: string) {
  if (k === today) return 'Today'
  if (k === addDays(today, 1)) return 'Tomorrow'
  if (k === addDays(today, -1)) return 'Yesterday'
  return parseDay(k).toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' })
}
function fmtTime(t?: string) {
  if (!t) return ''
  const [h, m] = t.split(':').map(Number)
  return new Date(2000, 0, 1, h, m).toLocaleTimeString(undefined, { hour: 'numeric', minute: '2-digit' })
}

function TaskRow({ t, ctx, showDay }: { t: Task; ctx: Ctx; showDay?: boolean }) {
  const list = ctx.data.lists.find(l => l.id === t.listId)
  const overdue = isOverdue(t, ctx.today)
  const sub = t.subtasks.length ? `${t.subtasks.filter(s => s.done).length}/${t.subtasks.length}` : ''
  const meta = t.completed ? `Done${t.completedAt ? ' ' + new Date(t.completedAt).toLocaleTimeString(undefined, { hour: 'numeric', minute: '2-digit' }) : ''} · ${list?.name ?? ''}` : [
    overdue ? `Overdue · ${fmtDay(t.dueDay!, ctx.today)}` : t.dueDay && (showDay || t.dueDay !== ctx.today) ? fmtDay(t.dueDay, ctx.today) : t.dueDay ? 'Due Today' : '',
    fmtTime(t.dueTime), t.repeat ? '↻ repeats' : '', sub, list?.name,
  ].filter(Boolean).join(' · ')
  return (
    <div className={`row card${t.completed ? ' done' : ''}`}>
      <button className={`check${t.completed ? ' on' : ''}`} aria-label={`${t.completed ? 'Reopen' : 'Complete'} ${t.title}`}
        aria-pressed={t.completed} onClick={() => ctx.toggle(t)}>{t.completed ? '✓' : ''}</button>
      <button className="row-body" onClick={() => ctx.setSheet({ kind: 'task', id: t.id })}>
        <span className="row-title">{t.title}</span>
        {meta && <span className={overdue || (t.dueDay === ctx.today && !t.completed) ? 'row-meta urgent' : 'row-meta'}>{meta}</span>}
      </button>
      {t.priority === 3 && !t.completed && <span className="flag" aria-label="High priority">⚑</span>}
    </div>
  )
}

function Header({ title, children, variant }: { title: string; children?: React.ReactNode; variant?: 'day' | 'sunset' | 'night' }) {
  return (
    <header className="hero">
      <SkyScene variant={variant} />
      <div className="hero-content">
        <h1>{title}</h1>
        {children}
      </div>
    </header>
  )
}

function Back({ ctx, label = 'Back' }: { ctx: Ctx; label?: string }) {
  return <button className="back" onClick={() => ctx.setScreen({ kind: 'tab' })}>‹ {label}</button>
}

function ProgressRing({ done, total }: { done: number; total: number }) {
  const pct = total ? Math.round((done / total) * 100) : 0
  const r = 26, c = 2 * Math.PI * r
  return (
    <svg width="68" height="68" viewBox="0 0 68 68" role="img" aria-label={`${pct}% done`}>
      <circle cx="34" cy="34" r={r} fill="none" stroke="#D7F2FF" strokeWidth="8" />
      <circle cx="34" cy="34" r={r} fill="none" stroke="#0593C6" strokeWidth="8" strokeLinecap="round"
        strokeDasharray={`${(c * pct) / 100} ${c}`} transform="rotate(-90 34 34)" className="ring" />
      <text x="34" y="39" textAnchor="middle" className="ring-text">{pct}%</text>
    </svg>
  )
}

// ---------- Today ----------

function Today(ctx: Ctx) {
  const { data, today, now } = ctx
  const open = todayTasks(data, today)
  const doneToday = data.tasks.filter(t => t.completed && t.completedAt && dayKey(new Date(t.completedAt)) === today)
  const doneCount = data.completions.filter(c => c.day === today).length
  const s = streak(data, today)
  const upcoming = data.tasks.filter(t => !t.completed && t.dueDay && t.dueDay > today).sort((a, b) => a.dueDay!.localeCompare(b.dueDay!)).slice(0, 3)
  const unscheduled = data.tasks.filter(t => !t.completed && !t.dueDay)
  const h = now.getHours()
  const greet = h < 5 ? 'Still up' : h < 12 ? 'Good Morning' : h < 17 ? 'Good Afternoon' : 'Good Evening'
  const variant = h >= 20 || h < 5 ? 'night' : h >= 17 ? 'sunset' : 'day'
  const empty = data.tasks.length === 0

  return (
    <>
      <Header title={`${greet}${data.name ? `, ${data.name}` : ''}`} variant={variant}>
        <p className="overline">{now.toLocaleDateString(undefined, { weekday: 'long', month: 'long', day: 'numeric' })}</p>
        <div className="hero-actions">
          <button className="chip-streak" onClick={() => ctx.openTab('progress')}>🔥 {s.current} Day Streak</button>
          <button className="circle" aria-label="Calendar" onClick={() => ctx.setScreen({ kind: 'calendar' })}>▦</button>
        </div>
      </Header>
      <div className={empty ? 'content flat' : 'content'}>
        {!empty && (
          <button className="card progress-card" onClick={() => ctx.setScreen({ kind: 'calendar' })}>
            <ProgressRing done={doneCount} total={doneCount + open.length} />
            <span>
              <strong>{doneCount} of {doneCount + open.length} Tasks</strong>
              <small>{open.length === 0 && doneCount > 0 ? 'All clear for today' : 'completed today'}</small>
            </span>
            <span className="chev" aria-hidden="true">›</span>
          </button>
        )}
        <div className="section-head">
          <h2>Today</h2>
          <button className="add" aria-label="New task for today" onClick={() => ctx.setSheet({ kind: 'task', dueDay: today })}>+</button>
        </div>
        {empty ? (
          <div className="card empty">
            <Sprite rows={SPRITES.ISLAND} px={6} />
            <h3>No tasks yet</h3>
            <p>Add your first task and start building your streak.</p>
            <button className="primary" onClick={() => ctx.setSheet({ kind: 'task', dueDay: today })}>+ Add task</button>
          </div>
        ) : open.length === 0 && doneToday.length === 0 ? (
          <div className="card clear"><Sprite rows={SPRITES.CLOUD_SMALL} px={3} /><span><strong>Nothing due today</strong><small>Add something or plan ahead.</small></span></div>
        ) : null}
        {open.map(t => <TaskRow key={t.id} t={t} ctx={ctx} />)}
        {doneToday.map(t => <TaskRow key={t.id} t={t} ctx={ctx} />)}
        {upcoming.length > 0 && <><h2 className="sub">Coming up</h2>{upcoming.map(t => <TaskRow key={t.id} t={t} ctx={ctx} showDay />)}</>}
        {unscheduled.length > 0 && <><h2 className="sub">Someday</h2>{unscheduled.map(t => <TaskRow key={t.id} t={t} ctx={ctx} />)}</>}
      </div>
    </>
  )
}

// ---------- Lists ----------

function Lists(ctx: Ctx) {
  const { data } = ctx
  return (
    <>
      <Header title="Lists">
        <div className="hero-actions end"><button className="circle" aria-label="New list" onClick={() => ctx.setSheet({ kind: 'list' })}>+</button></div>
      </Header>
      <div className="content">
        {data.lists.map(l => {
          const n = data.tasks.filter(t => t.listId === l.id && !t.completed).length
          return (
            <button key={l.id} className="card list-card" style={{ ['--tint' as string]: l.color }} onClick={() => ctx.setScreen({ kind: 'list', id: l.id })}>
              <span className="list-icon" aria-hidden="true">{l.icon}</span>
              <span><strong>{l.name}</strong><small>{n} {n === 1 ? 'task' : 'tasks'}</small></span>
              <span className="chev" aria-hidden="true">›</span>
            </button>
          )
        })}
      </div>
    </>
  )
}

function ListDetail(ctx: Ctx & { id: string }) {
  const list = ctx.data.lists.find(l => l.id === ctx.id)
  const [showDone, setShowDone] = useState(false)
  if (!list) return <div className="content"><Back ctx={ctx} label="Lists" /><p>This list was deleted.</p></div>
  const tasks = ctx.data.tasks.filter(t => t.listId === list.id)
  const open = tasks.filter(t => !t.completed)
  const done = tasks.filter(t => t.completed)
  return (
    <div className="content page">
      <div className="nav-row">
        <Back ctx={ctx} label="Lists" />
        <button className="link" onClick={() => ctx.setSheet({ kind: 'list', id: list.id })}>Edit</button>
      </div>
      <div className="section-head">
        <h1 className="page-title">{list.icon} {list.name}</h1>
        <button className="add" aria-label={`New task in ${list.name}`} onClick={() => ctx.setSheet({ kind: 'task', listId: list.id })}>+</button>
      </div>
      {open.length === 0 && <p className="muted">No open tasks in this list.</p>}
      {open.map(t => <TaskRow key={t.id} t={t} ctx={ctx} showDay />)}
      {done.length > 0 && <button className="link" onClick={() => setShowDone(!showDone)}>{showDone ? 'Hide' : 'Show'} {done.length} completed</button>}
      {showDone && done.map(t => <TaskRow key={t.id} t={t} ctx={ctx} />)}
    </div>
  )
}

function ListSheet(ctx: Ctx & { id?: string; close: () => void }) {
  const existing = ctx.data.lists.find(l => l.id === ctx.id)
  const [name, setName] = useState(existing?.name ?? '')
  const [icon, setIcon] = useState(existing?.icon ?? '📚')
  const [color, setColor] = useState(existing?.color ?? '#0593C6')
  const [confirm, setConfirm] = useState(false)
  const valid = name.trim().length > 0
  const save = () => {
    if (!valid) return
    const l: TaskList = { id: existing?.id ?? uid(), name: name.trim().slice(0, LIMITS.listName), icon, color }
    ctx.commit({ ...ctx.data, lists: existing ? ctx.data.lists.map(x => (x.id === l.id ? l : x)) : [...ctx.data.lists, l] })
    ctx.close()
  }
  const remove = () => {
    if (!existing) return
    ctx.commit({
      ...ctx.data,
      lists: ctx.data.lists.filter(l => l.id !== existing.id),
      tasks: ctx.data.tasks.filter(t => t.listId !== existing.id),
    }, `Deleted list “${existing.name}”`)
    ctx.close()
    ctx.setScreen({ kind: 'tab' })
  }
  return (
    <Modal title={existing ? 'Edit List' : 'New List'} close={ctx.close} onSave={save} canSave={valid}>
      <label className="field"><span>Name</span><input autoFocus maxLength={LIMITS.listName} value={name} onChange={e => setName(e.target.value)} placeholder="e.g. Thesis" /></label>
      <fieldset className="field"><legend>Icon</legend><div className="chips">
        {['📚', '🎓', '💻', '❤', '🏋', '📖', '🛒', '✈', '🎵', '⭐'].map(i => <button key={i} className={i === icon ? 'chip on' : 'chip'} aria-pressed={i === icon} onClick={() => setIcon(i)}>{i}</button>)}
      </div></fieldset>
      <fieldset className="field"><legend>Color</legend><div className="chips">
        {['#0593C6', '#D83995', '#4F7FAE', '#3AA9C9', '#2A9D8F', '#D9962B'].map(c => <button key={c} className={c === color ? 'swatch on' : 'swatch'} style={{ background: c }} aria-label={`Color ${c}`} aria-pressed={c === color} onClick={() => setColor(c)} />)}
      </div></fieldset>
      {existing && ctx.data.lists.length > 1 && (confirm
        ? <div className="confirm"><p>Delete “{existing.name}” and its {ctx.data.tasks.filter(t => t.listId === existing.id).length} tasks?</p><button className="danger" onClick={remove}>Delete list</button><button className="link" onClick={() => setConfirm(false)}>Keep it</button></div>
        : <button className="danger ghost" onClick={() => setConfirm(true)}>Delete list…</button>)}
    </Modal>
  )
}

// ---------- Task sheet (Add Task / Task Detail) ----------

function TaskSheet(ctx: Ctx & { sheet: { id?: string; dueDay?: string; listId?: string }; close: () => void }) {
  const existing = ctx.data.tasks.find(t => t.id === ctx.sheet.id)
  const [t, setT] = useState<Task>(() => existing ?? {
    id: uid(), title: '', notes: '', listId: ctx.sheet.listId ?? ctx.data.lists[0].id, priority: 0 as Priority,
    dueDay: ctx.sheet.dueDay, subtasks: [], completed: false, createdAt: new Date().toISOString(),
  })
  const [newSub, setNewSub] = useState('')
  const [confirm, setConfirm] = useState(false)
  const titleRef = useRef<HTMLInputElement>(null)
  useEffect(() => { if (!existing) titleRef.current?.focus() }, [existing])
  const valid = t.title.trim().length > 0
  const set = (p: Partial<Task>) => setT(prev => ({ ...prev, ...p }))
  const save = () => {
    if (!valid) return
    const clean: Task = {
      ...t, title: t.title.replace(/\s+/g, ' ').trim().slice(0, LIMITS.title), notes: t.notes.slice(0, LIMITS.notes),
      repeatAnchor: t.repeat === 'monthly' && t.dueDay ? parseDay(t.dueDay).getDate() : undefined,
      reminder: t.dueDay && t.dueTime ? t.reminder : undefined,
    }
    ctx.commit({ ...ctx.data, tasks: existing ? ctx.data.tasks.map(x => (x.id === clean.id ? clean : x)) : [...ctx.data.tasks, clean] })
    ctx.close()
  }
  const remove = () => {
    ctx.commit({ ...ctx.data, tasks: ctx.data.tasks.filter(x => x.id !== t.id) }, `Deleted “${t.title}”`)
    ctx.close()
  }
  const addSub = () => {
    const title = newSub.trim()
    if (!title || t.subtasks.length >= LIMITS.subtasks) return
    set({ subtasks: [...t.subtasks, { id: uid(), title: title.slice(0, LIMITS.title), done: false }] })
    setNewSub('')
  }
  return (
    <Modal title={existing ? 'Task' : 'New Task'} close={ctx.close} onSave={save} canSave={valid} saveLabel={existing ? 'Save' : 'Add Task'}>
      {existing && (
        <button className={`complete-toggle${existing.completed ? ' on' : ''}`} onClick={() => { ctx.toggle(existing); ctx.close() }}>
          {existing.completed ? '✓ Completed · tap to reopen' : '○ Mark complete'}
        </button>
      )}
      <label className="field"><span>Title</span>
        <input ref={titleRef} maxLength={LIMITS.title} value={t.title} placeholder="Task title" onChange={e => set({ title: e.target.value })}
          onKeyDown={e => { if (e.key === 'Enter') save() }} aria-invalid={!valid} /></label>
      <label className="field"><span>Description</span>
        <textarea maxLength={LIMITS.notes} rows={2} value={t.notes} placeholder="Optional" onChange={e => set({ notes: e.target.value })} /></label>
      <div className="form-group">
        <label className="form-row"><span>List</span>
          <select value={t.listId} onChange={e => set({ listId: e.target.value })}>{ctx.data.lists.map(l => <option key={l.id} value={l.id}>{l.name}</option>)}</select></label>
        <label className="form-row"><span>Due date</span>
          <input type="date" min="2000-01-01" max="2100-12-31" value={t.dueDay ?? ''} onChange={e => set({ dueDay: e.target.value || undefined, ...(e.target.value ? {} : { dueTime: undefined, repeat: undefined }) })} /></label>
        <label className="form-row"><span>Time</span>
          <input type="time" disabled={!t.dueDay} value={t.dueTime ?? ''} onChange={e => set({ dueTime: e.target.value || undefined })} /></label>
        <label className="form-row"><span>Reminder</span>
          <select disabled={!t.dueTime} value={t.reminder ?? ''} onChange={e => set({ reminder: e.target.value === '' ? undefined : Number(e.target.value) })}>
            <option value="">None</option><option value="0">At time</option><option value="15">15 min before</option><option value="60">1 hour before</option><option value="1440">1 day before</option>
          </select></label>
        <label className="form-row"><span>Repeat</span>
          <select disabled={!t.dueDay} value={t.repeat ?? ''} onChange={e => set({ repeat: (e.target.value || undefined) as Repeat | undefined })}>
            {Object.entries(REPEAT_LABEL).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
          </select></label>
        <label className="form-row"><span>Priority</span>
          <select value={t.priority} onChange={e => set({ priority: Number(e.target.value) as Priority })}>{PRIORITY_LABEL.map((l, i) => <option key={l} value={i}>{l}</option>)}</select></label>
      </div>
      {t.reminder !== undefined && <p className="hint">Demo note: the browser preview shows reminders but cannot deliver them. The iOS app schedules a local notification.</p>}
      <fieldset className="field"><legend>Subtasks ({t.subtasks.filter(s => s.done).length}/{t.subtasks.length})</legend>
        {t.subtasks.map(s => (
          <div key={s.id} className="subtask">
            <button className={`check small${s.done ? ' on' : ''}`} aria-label={`${s.done ? 'Uncheck' : 'Check'} ${s.title}`} aria-pressed={s.done}
              onClick={() => set({ subtasks: t.subtasks.map(x => (x.id === s.id ? { ...x, done: !x.done } : x)) })}>{s.done ? '✓' : ''}</button>
            <span className={s.done ? 'struck' : ''}>{s.title}</span>
            <button className="icon-btn" aria-label={`Remove ${s.title}`} onClick={() => set({ subtasks: t.subtasks.filter(x => x.id !== s.id) })}>×</button>
          </div>
        ))}
        <div className="subtask add-sub">
          <input value={newSub} placeholder="Add subtask" maxLength={LIMITS.title} onChange={e => setNewSub(e.target.value)} onKeyDown={e => { if (e.key === 'Enter') addSub() }} />
          <button className="link" onClick={addSub} disabled={!newSub.trim()}>Add</button>
        </div>
      </fieldset>
      {existing && (confirm
        ? <div className="confirm"><p>Delete this task? You can undo right after.</p><button className="danger" onClick={remove}>Delete task</button><button className="link" onClick={() => setConfirm(false)}>Keep it</button></div>
        : <button className="danger ghost" onClick={() => setConfirm(true)}>Delete task…</button>)}
    </Modal>
  )
}

function Modal({ title, close, onSave, canSave, saveLabel = 'Save', children }: { title: string; close: () => void; onSave: () => void; canSave: boolean; saveLabel?: string; children: React.ReactNode }) {
  useEffect(() => {
    const k = (e: KeyboardEvent) => { if (e.key === 'Escape') close() }
    window.addEventListener('keydown', k)
    return () => window.removeEventListener('keydown', k)
  }, [close])
  return (
    <div className="scrim" onClick={close}>
      <div className="sheet" role="dialog" aria-modal="true" aria-label={title} onClick={e => e.stopPropagation()}>
        <div className="sheet-bar">
          <button className="link" onClick={close}>Cancel</button>
          <strong>{title}</strong>
          <button className="link bold" disabled={!canSave} onClick={onSave}>{saveLabel === 'Add Task' ? 'Add' : saveLabel}</button>
        </div>
        <div className="sheet-body">{children}</div>
        <button className="primary block" disabled={!canSave} onClick={onSave}>{saveLabel}</button>
      </div>
    </div>
  )
}

// ---------- Calendar ----------

function Calendar(ctx: Ctx) {
  const [selected, setSelected] = useState(ctx.today)
  const [month, setMonth] = useState(() => { const d = parseDay(ctx.today); return new Date(d.getFullYear(), d.getMonth(), 1, 12) })
  const cells = useMemo(() => {
    const first = dayKey(month)
    const offset = (month.getDay() + 6) % 7
    return Array.from({ length: 42 }, (_, i) => addDays(first, i - offset))
  }, [month])
  const busy = new Set(ctx.data.tasks.filter(t => !t.completed && t.dueDay).map(t => t.dueDay))
  const dayTasks = ctx.data.tasks.filter(t => t.dueDay === selected || (selected === ctx.today && isOverdue(t, ctx.today)))
  const doneOn = ctx.data.completions.filter(c => c.day === selected)
  const shift = (n: number) => setMonth(new Date(month.getFullYear(), month.getMonth() + n, 1, 12))
  return (
    <div className="content page">
      <Back ctx={ctx} label="Today" />
      <h1 className="page-title">Calendar</h1>
      <div className="card cal">
        <div className="cal-head">
          <button className="icon-btn" aria-label="Previous month" onClick={() => shift(-1)}>‹</button>
          <strong>{month.toLocaleDateString(undefined, { month: 'long', year: 'numeric' })}</strong>
          <button className="icon-btn" aria-label="Next month" onClick={() => shift(1)}>›</button>
        </div>
        <div className="cal-grid" role="grid">
          {['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map(d => <span key={d} className="dow">{d}</span>)}
          {cells.map(k => {
            const d = parseDay(k)
            const inMonth = d.getMonth() === month.getMonth()
            return (
              <button key={k} role="gridcell" aria-selected={k === selected} aria-label={d.toDateString()}
                className={['day', inMonth ? '' : 'out', k === selected ? 'sel' : '', k === ctx.today ? 'today' : ''].join(' ')}
                onClick={() => setSelected(k)}>
                {d.getDate()}{busy.has(k) && <i className="dot" />}
              </button>
            )
          })}
        </div>
        {selected !== ctx.today && <button className="link" onClick={() => { setSelected(ctx.today); setMonth(new Date(parseDay(ctx.today).getFullYear(), parseDay(ctx.today).getMonth(), 1, 12)) }}>Jump to today</button>}
      </div>
      <div className="section-head">
        <h2>{parseDay(selected).toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' })}</h2>
        <button className="add" aria-label="New task on this day" onClick={() => ctx.setSheet({ kind: 'task', dueDay: selected })}>+</button>
      </div>
      {dayTasks.length === 0 && doneOn.length === 0 && <p className="muted">Nothing planned for this day.</p>}
      {dayTasks.map(t => <TaskRow key={t.id} t={t} ctx={ctx} />)}
      {doneOn.length > 0 && <p className="muted">{doneOn.length} completed: {doneOn.map(c => c.title).join(', ')}</p>}
    </div>
  )
}

// ---------- Progress & Streaks ----------

function ProgressTab(ctx: Ctx) {
  const s = streak(ctx.data, ctx.today)
  const byDay = completionsByDay(ctx.data)
  const week = weekDays(ctx.today)
  const counts = week.map(k => byDay.get(k) ?? 0)
  const max = Math.max(ctx.data.dailyGoal, ...counts)
  const pastDays = week.filter(k => k <= ctx.today)
  const met = pastDays.filter(k => (byDay.get(k) ?? 0) >= ctx.data.dailyGoal).length
  const unlocked = achievements(s).filter(a => a.current >= a.target).length
  return (
    <>
      <Header title="Progress">
        <div className="hero-actions end"><button className="circle" aria-label="Settings" onClick={() => ctx.setScreen({ kind: 'settings' })}>⚙</button></div>
        <button className="streak-bubble" onClick={() => ctx.setScreen({ kind: 'streaks' })} aria-label={`${s.current} day streak. Open streaks and achievements`}>
          <Sprite rows={SPRITES.FLAME} px={4} /><span className="big">{s.current}</span><span>Day Streak</span>
        </button>
      </Header>
      <div className="content">
        <div className="stats">
          <div className="card stat"><b>{s.total}</b><small>Tasks Done</small></div>
          <div className="card stat"><b>{Math.round((met / pastDays.length) * 100)}%</b><small>This Week</small></div>
          <div className="card stat"><b>{unlocked}</b><small>Milestones</small></div>
        </div>
        <h2>Weekly Activity</h2>
        <div className="card chart" role="img" aria-label={`This week: ${week.map((k, i) => `${parseDay(k).toLocaleDateString(undefined, { weekday: 'short' })} ${counts[i]}`).join(', ')}`}>
          {week.map((k, i) => (
            <div key={k} className="bar-col">
              <span className="bar-val">{counts[i] || ''}</span>
              <div className={`bar${k === ctx.today ? ' now' : ''}${counts[i] >= ctx.data.dailyGoal ? ' met' : ''}`} style={{ height: `${Math.max(6, (counts[i] / max) * 100)}%` }} />
              <span className="bar-label">{parseDay(k).toLocaleDateString(undefined, { weekday: 'short' })}</span>
            </div>
          ))}
        </div>
        <div className="card goal">
          <span><strong>Daily goal</strong><small>{s.todayDone} of {s.goal} done today</small></span>
          <div className="stepper">
            <button aria-label="Lower daily goal" disabled={ctx.data.dailyGoal <= LIMITS.goalMin} onClick={() => ctx.commit({ ...ctx.data, dailyGoal: ctx.data.dailyGoal - 1 })}>−</button>
            <b aria-live="polite">{ctx.data.dailyGoal}</b>
            <button aria-label="Raise daily goal" disabled={ctx.data.dailyGoal >= LIMITS.goalMax} onClick={() => ctx.commit({ ...ctx.data, dailyGoal: ctx.data.dailyGoal + 1 })}>+</button>
          </div>
        </div>
        <button className="card list-card" onClick={() => ctx.setScreen({ kind: 'streaks' })}>
          <span className="list-icon" aria-hidden="true">🏆</span>
          <span><strong>Streak & Achievements</strong><small>{unlocked} of {achievements(s).length} unlocked</small></span>
          <span className="chev" aria-hidden="true">›</span>
        </button>
      </div>
    </>
  )
}

function Streaks(ctx: Ctx) {
  const s = streak(ctx.data, ctx.today)
  const start = Math.max(0, MILESTONES.filter(m => m <= s.current).length - 1)
  const track = MILESTONES.slice(start, start + 3)
  const list = achievements(s)
  const left = Math.max(0, s.goal - s.todayDone)
  return (
    <div className="content page">
      <Back ctx={ctx} label="Progress" />
      <h1 className="page-title">Streak</h1>
      <div className="card streak-hero"><Sprite rows={SPRITES.FLAME} px={6} /><span className="big">{s.current}</span><span>Day Streak · Best {s.longest}</span></div>
      <div className="card track" aria-label={`Milestones ${track.join(', ')} days`}>
        {track.map((m, i) => (
          <div key={m} className="track-step">
            {i > 0 && <span className={`track-line${s.current >= m ? ' on' : ''}`} />}
            <span className={`track-dot${s.current >= m ? ' on' : ''}`}>{s.current >= m ? '✓' : ''}</span>
            <b>{m}</b>
          </div>
        ))}
      </div>
      <p className="muted">{left === 0 ? 'Today counts. Come back tomorrow to keep it going.' : `Finish ${left} more ${left === 1 ? 'task' : 'tasks'} today to count this day.`}</p>
      <h2>Achievements {list.filter(a => a.current >= a.target).length}/{list.length}</h2>
      {list.map(a => (
        <div key={a.id} className={`card ach${a.current >= a.target ? ' on' : ''}`}>
          <span className="ach-badge" aria-hidden="true">{a.current >= a.target ? '★' : '☆'}</span>
          <span><strong>{a.title}</strong><small>{a.detail}</small></span>
          <span className="ach-count">{a.current >= a.target ? '✓' : `${a.current}/${a.target}`}</span>
        </div>
      ))}
    </div>
  )
}

// ---------- Settings ----------

function Settings(ctx: Ctx) {
  const [confirm, setConfirm] = useState(false)
  const [msg, setMsg] = useState('')
  const fileRef = useRef<HTMLInputElement>(null)
  const exportData = () => {
    const blob = new Blob([JSON.stringify(ctx.data, null, 2)], { type: 'application/json' })
    const a = document.createElement('a')
    a.href = URL.createObjectURL(blob)
    a.download = `skyday-backup-${ctx.today}.json`
    a.click()
    URL.revokeObjectURL(a.href)
    setMsg('Backup downloaded.')
  }
  const importData = async (f: File) => {
    try {
      if (f.size > 5_000_000) throw new Error('File is too large')
      ctx.commit(parseData(JSON.parse(await f.text())), 'Imported backup')
      setMsg('Backup imported.')
    } catch (e) {
      setMsg(`Import failed: ${(e as Error).message}. Your data was not changed.`)
    }
  }
  return (
    <div className="content page">
      <Back ctx={ctx} label="Progress" />
      <h1 className="page-title">Settings</h1>
      <div className="form-group">
        <label className="form-row"><span>Your name</span><input maxLength={40} value={ctx.data.name} placeholder="Optional" onChange={e => ctx.commit({ ...ctx.data, name: e.target.value })} /></label>
        <label className="form-row"><span>Daily goal</span>
          <select value={ctx.data.dailyGoal} onChange={e => ctx.commit({ ...ctx.data, dailyGoal: Number(e.target.value) })}>
            {Array.from({ length: LIMITS.goalMax }, (_, i) => i + 1).map(n => <option key={n} value={n}>{n} {n === 1 ? 'task' : 'tasks'}</option>)}
          </select></label>
      </div>
      <h2 className="sub">Reminders</h2>
      <p className="muted">Notifications are not available in the browser demo. In the iOS app, reminders are local notifications; previews hide task notes by default.</p>
      <h2 className="sub">Data & privacy</h2>
      <p className="muted">Everything stays in this browser’s local storage. Nothing is sent to a server. Clearing site data deletes it.</p>
      <div className="stack">
        <button className="secondary" onClick={exportData}>Export backup (JSON)</button>
        <button className="secondary" onClick={() => fileRef.current?.click()}>Import backup…</button>
        <input ref={fileRef} type="file" accept="application/json,.json" hidden onChange={e => { const f = e.target.files?.[0]; if (f) importData(f); e.target.value = '' }} />
        {confirm
          ? <div className="confirm"><p>Erase all tasks, lists and history from this browser? This cannot be undone.</p>
              <button className="danger" onClick={() => { ctx.commit(emptyData()); setConfirm(false); setMsg('All data erased.') }}>Erase everything</button>
              <button className="link" onClick={() => setConfirm(false)}>Cancel</button></div>
          : <button className="danger ghost" onClick={() => setConfirm(true)}>Erase all data…</button>}
        {msg && <p role="status" className="hint">{msg}</p>}
      </div>
      <h2 className="sub">About</h2>
      <p className="muted">Skyday web demo 1.0. Native app: SwiftUI, iOS 17+. No accounts, ads or tracking.</p>
    </div>
  )
}
