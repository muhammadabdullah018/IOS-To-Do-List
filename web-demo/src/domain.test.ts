import { describe, expect, it } from 'vitest'
import { addDays, AppData, completeTask, emptyData, nextOccurrence, parseData, reopenTask, streak, Task, todayTasks, weekDays } from './domain'

const now = new Date(2026, 10, 3, 9, 0) // 3 Nov 2026, local
const today = '2026-11-03'

function task(p: Partial<Task> = {}): Task {
  return { id: p.id ?? 't1', title: 'Task', notes: '', listId: 'inbox', priority: 0, subtasks: [], completed: false, createdAt: '2026-11-01T00:00:00Z', ...p }
}
function withTasks(...tasks: Task[]): AppData {
  return { ...emptyData(), lists: [{ id: 'inbox', name: 'P', icon: 'x', color: '#000000' }], tasks }
}

describe('days', () => {
  it('adds days across month and year ends', () => {
    expect(addDays('2026-12-31', 1)).toBe('2027-01-01')
    expect(addDays('2028-03-01', -1)).toBe('2028-02-29')
  })
  it('builds a Monday-start week', () => {
    const w = weekDays(today) // Tuesday
    expect(w[0]).toBe('2026-11-02')
    expect(w[6]).toBe('2026-11-08')
  })
})

describe('recurrence', () => {
  it('keeps the 31st across short months', () => {
    const t = { repeat: 'monthly' as const, repeatAnchor: 31 }
    expect(nextOccurrence(t, '2027-01-31')).toBe('2027-02-28')
    expect(nextOccurrence(t, '2027-02-28')).toBe('2027-03-31')
  })
  it('completing a repeating task advances it without duplicating', () => {
    const d = completeTask(withTasks(task({ repeat: 'daily', dueDay: today })), 't1', now)
    expect(d.tasks).toHaveLength(1)
    expect(d.tasks[0].dueDay).toBe('2026-11-04')
    expect(d.tasks[0].completed).toBe(false)
    expect(d.completions).toHaveLength(1)
  })
  it('rolls a missed repeating task forward past today', () => {
    const d = completeTask(withTasks(task({ repeat: 'weekly', dueDay: '2026-10-01' })), 't1', now)
    expect(d.tasks[0].dueDay! > today).toBe(true)
  })
})

describe('complete and undo', () => {
  it('is idempotent and reversible', () => {
    let d = completeTask(withTasks(task({ dueDay: today })), 't1', now)
    expect(completeTask(d, 't1', now)).toBe(d)
    d = reopenTask(d, 't1')
    expect(d.tasks[0].completed).toBe(false)
    expect(d.completions).toHaveLength(0)
  })
  it('orders overdue before today', () => {
    const d = withTasks(task({ id: 'a', dueDay: today }), task({ id: 'b', dueDay: '2026-11-01' }), task({ id: 'c' }))
    expect(todayTasks(d, today).map(t => t.id)).toEqual(['b', 'a'])
  })
})

describe('streak', () => {
  const done = (day: string, n: number) => Array.from({ length: n }, (_, i) => ({ id: day + i, taskId: 'x', title: 'x', day, at: '' }))
  it('counts consecutive goal days and does not break on an unfinished today', () => {
    const d = { ...withTasks(), dailyGoal: 2, completions: [...done('2026-11-01', 2), ...done('2026-11-02', 3), ...done(today, 1)] }
    const s = streak(d, today)
    expect(s.current).toBe(2)
    expect(s.todayDone).toBe(1)
  })
  it('a missed day resets current but keeps longest', () => {
    const d = { ...withTasks(), dailyGoal: 1, completions: [...done('2026-10-28', 1), ...done('2026-10-29', 1), ...done('2026-10-30', 1), ...done(today, 1)] }
    const s = streak(d, today)
    expect(s.current).toBe(1)
    expect(s.longest).toBe(3)
  })
})

describe('import validation', () => {
  it('rejects malformed input', () => {
    expect(() => parseData(null)).toThrow()
    expect(() => parseData({ version: 2 })).toThrow()
    expect(() => parseData({ version: 1, lists: [], tasks: [], completions: [] })).toThrow()
  })
  it('sanitises fields', () => {
    const d = parseData({
      version: 1, dailyGoal: 999, lists: [{ id: 'l', name: 'L', icon: 'x', color: 'red' }],
      tasks: [{ id: 't', title: 'x'.repeat(500), listId: 'missing', priority: 9, dueDay: '2026-02-30', dueTime: '25:00' }],
      completions: [{ day: 'bad' }],
    })
    expect(d.dailyGoal).toBe(20)
    expect(d.lists[0].color).toBe('#0593C6')
    expect(d.tasks[0].title).toHaveLength(200)
    expect(d.tasks[0].listId).toBe('l')
    expect(d.tasks[0].priority).toBe(0)
    expect(d.tasks[0].dueDay).toBeUndefined()
    expect(d.tasks[0].dueTime).toBeUndefined()
    expect(d.completions).toHaveLength(0)
  })
})
