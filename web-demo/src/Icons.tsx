// Line icons (24×24, 1.8 stroke, round caps) in an SF Symbols-like style. Original paths.
import { useEffect, useState } from 'react'

const PATHS: Record<string, string> = {
  house: 'M4 10.5 12 4l8 6.5V19a1 1 0 0 1-1 1h-4.5v-5.5h-5V20H5a1 1 0 0 1-1-1z',
  stack: 'M12 4 3.5 8.5 12 13l8.5-4.5zM3.5 12.5 12 17l8.5-4.5M3.5 16 12 20.5 20.5 16',
  chart: 'M5 20V12M10 20V6M15 20v-9M20 20V9M3 20h18',
  calendar: 'M4.5 6.5h15v13h-15zM4.5 10.5h15M8.5 4v4M15.5 4v4',
  gear: 'M12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6zM12 3v2.5M12 18.5V21M3 12h2.5M18.5 12H21M5.6 5.6l1.8 1.8M16.6 16.6l1.8 1.8M5.6 18.4l1.8-1.8M16.6 7.4l1.8-1.8',
  plus: 'M12 5v14M5 12h14',
  chevron: 'm9.5 6 6 6-6 6',
  back: 'm14.5 6-6 6 6 6',
  flag: 'M6 21V4M6 4.5h10.5l-2 3.5 2 3.5H6',
  trophy: 'M8 4h8v5a4 4 0 0 1-8 0zM8 6H5a3 3 0 0 0 3 4M16 6h3a3 3 0 0 1-3 4M12 13v4M8.5 20h7M10 17h4',
  repeat: 'M17 3.5 20 6.5l-3 3M4 11.5v-1a4 4 0 0 1 4-4h12M7 20.5l-3-3 3-3M20 12.5v1a4 4 0 0 1-4 4H4',
  bell: 'M6 16.5V11a6 6 0 0 1 12 0v5.5l1.5 2h-15zM10 20.5a2 2 0 0 0 4 0',
  trash: 'M4.5 7h15M9.5 7V4.5h5V7M6.5 7l1 13h9l1-13',
  // list icons
  book: 'M5 4.5h10.5a2 2 0 0 1 2 2V20H7a2 2 0 0 1-2-2zM5 18a2 2 0 0 1 2-2h10.5',
  cap: 'M2.5 9.5 12 5l9.5 4.5L12 14zM6.5 11.5V16c3 2.5 8 2.5 11 0v-4.5M21.5 9.5v5',
  laptop: 'M5 6h14v9.5H5zM3 18.5h18',
  heart: 'M12 19.5S4 15 4 9.5A4 4 0 0 1 12 7a4 4 0 0 1 8 2.5c0 5.5-8 10-8 10z',
  dumbbell: 'M3 10v4M6 7.5v9M18 7.5v9M21 10v4M6 12h12',
  cart: 'M3 4.5h2.5l2 11h10l2-8H7M9.5 20a1 1 0 1 0 0-.1M16.5 20a1 1 0 1 0 0-.1',
  plane: 'M10.5 13.5 4 11l1.5-1.5 7.5 1 4.5-4.5a1.8 1.8 0 0 1 2.5 2.5L15.5 13l1 7.5L15 22l-2.5-6.5L9 19v2l-1.5 1L6 18l-4-1.5 1-1.5h2z',
  music: 'M9 17.5V6l10-2v11.5M9 17.5a2.5 2.5 0 1 1-5 0 2.5 2.5 0 0 1 5 0zM19 15.5a2.5 2.5 0 1 1-5 0 2.5 2.5 0 0 1 5 0z',
  star: 'm12 3.8 2.5 5.1 5.6.8-4 4 .9 5.5-5-2.6-5 2.6 1-5.5-4.1-4 5.6-.8z',
  briefcase: 'M4 8h16v11H4zM9 8V5.5h6V8M4 13h16',
}

export { LIST_ICON_NAMES as LIST_ICONS } from './domain'

export function Icon({ name, size = 22, className }: { name: string; size?: number; className?: string }) {
  return (
    <svg className={className} width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor"
      strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d={PATHS[name] ?? PATHS.star} />
    </svg>
  )
}

/**
 * Sun / moon / globe morph (after the reference icon animation): one circle that gains
 * meridians (globe), is bitten by a sliding mask (moon), or shrinks and grows rays (sun).
 */
export type MorphShape = 'globe' | 'moon' | 'sun'

export function MorphIcon({ shape, size = 30, color = 'currentColor' }: { shape: MorphShape; size?: number; color?: string }) {
  const id = `m-${size}`
  return (
    <svg width={size} height={size} viewBox="0 0 48 48" className={`morph morph-${shape}`} aria-hidden="true">
      <defs>
        <mask id={id}>
          <rect width="48" height="48" fill="#fff" />
          <circle className="morph-bite" cx="34" cy="16" r="11" fill="#000" />
        </mask>
      </defs>
      <g fill="none" stroke={color} strokeWidth="3.2" strokeLinecap="round">
        <circle className="morph-body" cx="24" cy="24" r="13" mask={`url(#${id})`} />
        <g className="morph-globe">
          <ellipse cx="24" cy="24" rx="5.5" ry="13" />
          <path d="M11 24h26" />
        </g>
        <g className="morph-rays">
          {Array.from({ length: 8 }, (_, i) => (
            <path key={i} d="M24 4.5v4" transform={`rotate(${i * 45} 24 24)`} />
          ))}
        </g>
      </g>
    </svg>
  )
}

/** Plays globe → moon → target once on mount, like the reference clip. */
export function useMorphIntro(target: MorphShape): MorphShape {
  const reduce = typeof matchMedia !== 'undefined' && matchMedia('(prefers-reduced-motion: reduce)').matches
  const [shape, setShape] = useState<MorphShape>(reduce ? target : 'globe')
  useEffect(() => {
    if (reduce) { setShape(target); return }
    const t1 = setTimeout(() => setShape('moon'), 350)
    const t2 = setTimeout(() => setShape(target), 900)
    return () => { clearTimeout(t1); clearTimeout(t2) }
  }, [target, reduce])
  return shape
}
