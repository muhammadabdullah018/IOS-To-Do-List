// Original Skyday sprites as character grids (same grids as Skyday/DesignSystem/PixelArt.swift),
// rendered as crisp SVG rects. One character = one art pixel; '.' is transparent.

const CLOUD = [
  '...........WWWWWW...........',
  '.........WWWWWWWWWW.........',
  '....WWWW.WWWWWWWWWWW........',
  '...WWWWWWWWWWWWWWWWWW.WWW...',
  '..WWWWWWWWWWWWWWWWWWWWWWWW..',
  '.WWWWWWWWWWWWWWWWWWWWWWWWWW.',
  'WWWWWWWWWWWWWWWWWWWWWWWWWWWW',
  'WWWWWWWWWWWWWWWWWWWWWWWWWWWW',
  '.SSSSSSSSSSSSSSSSSSSSSSSSSS.',
  '...SSSSSSSSSSSSSSSSSSSSSS...',
]
const CLOUD_SMALL = ['.....WWWW.....', '...WWWWWWW....', '.WWWWWWWWWWWW.', 'WWWWWWWWWWWWWW', 'WWWWWWWWWWWWWW', '.SSSSSSSSSSSS.']
const MOUNTAIN = [
  '..........WW..........',
  '.........WWWW.........',
  '........WWMMWW........',
  '.......MMMMMMMM.......',
  '......MMMMMMMMMM......',
  '.....MMMMMMMMMMMM.....',
  '....MMMMMMMMMMMMMM....',
  '...MMMMMMMMMMMMMMMM...',
  '..MMMMMMMMMMMMMMMMMM..',
  '.MMMMMMMMMMMMMMMMMMMM.',
  'MMMMMMMMMMMMMMMMMMMMMM',
]
const ISLAND = [
  '..........PPPP............',
  '........PPPPPPPP..........',
  '......PPPPKPPPPPPP........',
  '.....PPPPPPPPPKPPPP.......',
  '......PPPKPPPPPPPP........',
  '........PPPPPPPP..........',
  '...........RR.............',
  '...........RR.............',
  '...........RR....WWW......',
  '...........RR...WWWWWW....',
  '..GGGGGGGGGGGGGGGGGGGGGG..',
  '.GGGGGGGGGGGGGGGGGGGGGGGG.',
  '..EEEEEEEEEEEEEEEEEEEEEE..',
  '....EEEEEEEEEEEEEEEEEE....',
  '......EEEEEEEEEEEEEE......',
  '........EEEEEEEEEE........',
  '..........EEEEEE..........',
  '............EE............',
]
const FLAME = ['....F....', '...FFF...', '..FFFFF..', '.FFFYFFF.', '.FFYYYFF.', 'FFFYYYFFF', 'FFYYPYYFF', '.FFYYYFF.', '..FFFFF..']

const PALETTE: Record<string, string> = {
  W: '#FFFFFF', S: '#C6E8F6', M: '#7FB6D6', P: '#F4A6CF', K: '#D83995', R: '#8A5A3C',
  G: '#5DBB63', E: '#9C6B4A', F: '#F2913D', Y: '#F5B932',
}

export const SPRITES = { CLOUD, CLOUD_SMALL, MOUNTAIN, ISLAND, FLAME }

export function Sprite({ rows, px = 3, className, style }: { rows: string[]; px?: number; className?: string; style?: React.CSSProperties }) {
  const w = Math.max(...rows.map(r => r.length))
  const rects: JSX.Element[] = []
  rows.forEach((row, y) => {
    let x = 0
    while (x < row.length) {
      const c = row[x]
      const color = PALETTE[c]
      if (!color) { x++; continue }
      let end = x + 1
      while (end < row.length && row[end] === c) end++
      rects.push(<rect key={`${x}-${y}`} x={x} y={y} width={end - x} height={1} fill={color} />)
      x = end
    }
  })
  return (
    <svg className={className} style={style} width={w * px} height={rows.length * px} viewBox={`0 0 ${w} ${rows.length}`}
      shapeRendering="crispEdges" aria-hidden="true">
      {rects}
    </svg>
  )
}

/** Layered pixel sky used as every screen header. */
export function SkyScene({ variant = 'day' }: { variant?: 'day' | 'sunset' | 'night' }) {
  return (
    <div className={`sky sky-${variant}`} aria-hidden="true">
      <Sprite rows={CLOUD} px={4} className="cloud c1" />
      <Sprite rows={CLOUD_SMALL} px={3} className="cloud c2" />
      <Sprite rows={CLOUD_SMALL} px={2} className="cloud c3" />
      <Sprite rows={MOUNTAIN} px={5} className="mountain" />
    </div>
  )
}
