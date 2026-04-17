import { useEffect, useRef, useState } from 'react'
import { useInView } from '../hooks/useInView'

const STATS = [
  { icon: 'download',           value: 5000,   suffix: '+', label: 'Downloads',            iconBg: 'rgba(115,92,0,0.12)',   iconBorder: 'rgba(115,92,0,0.25)',   color: 'var(--primary)'           },
  { icon: 'receipt_long',       value: 120000, suffix: '+', label: 'Transactions Logged',  iconBg: 'rgba(60,105,41,0.12)',  iconBorder: 'rgba(60,105,41,0.25)',  color: 'var(--secondary)'         },
  { icon: 'volunteer_activism', value: 10,     suffix: '%', label: 'Tithe Auto-Calculated', iconBg: 'rgba(173,48,47,0.12)', iconBorder: 'rgba(173,48,47,0.25)', color: 'var(--tertiary)'          },
  { icon: 'star',               value: 4.9,    suffix: '★', label: 'User Rating',           iconBg: 'rgba(212,175,55,0.15)', iconBorder: 'rgba(212,175,55,0.3)', color: 'var(--primary-container)', isFloat: true },
]

function CountUp({ target, suffix, isFloat, active }) {
  const [display, setDisplay] = useState(0)
  const rafRef = useRef(null)

  useEffect(() => {
    if (!active) return
    const duration = 1600
    const start = performance.now()
    const step = (now) => {
      const elapsed = now - start
      const t = Math.min(elapsed / duration, 1)
      const eased = 1 - Math.pow(1 - t, 3)
      const current = isFloat ? +(eased * target).toFixed(1) : Math.floor(eased * target)
      setDisplay(current)
      if (t < 1) rafRef.current = requestAnimationFrame(step)
    }
    rafRef.current = requestAnimationFrame(step)
    return () => cancelAnimationFrame(rafRef.current)
  }, [active, target, isFloat])

  const formatted = isFloat
    ? display.toFixed(1)
    : display >= 1000
      ? display.toLocaleString()
      : display

  return <>{formatted}{suffix}</>
}

export default function Stats() {
  const [ref, visible] = useInView({ threshold: 0.3 })

  return (
    <section ref={ref} style={{
      background: 'var(--surface-container)',
      borderTop: '1px solid var(--outline-variant)',
      borderBottom: '1px solid var(--outline-variant)',
      padding: 'clamp(40px, 6vw, 64px) 24px',
    }}>
      <div className="stats-grid" style={{
        maxWidth: 1280, margin: '0 auto',
        display: 'grid',
        gridTemplateColumns: 'repeat(4, 1fr)',
        gap: 24,
      }}>
        {STATS.map((s, i) => (
          <div
            key={s.label}
            className={`anim-hidden${visible ? ` anim-fade-up delay-${i * 100}` : ''}`}
            style={{
              textAlign: 'center', padding: '28px 16px',
              background: 'var(--surface)',
              border: '1px solid var(--outline-variant)',
              transition: 'transform 0.3s cubic-bezier(0.22,1,0.36,1), box-shadow 0.3s',
              cursor: 'default',
            }}
            onMouseEnter={e => { e.currentTarget.style.transform = 'translateY(-5px)'; e.currentTarget.style.boxShadow = '0 16px 40px rgba(0,0,0,0.09)' }}
            onMouseLeave={e => { e.currentTarget.style.transform = 'translateY(0)'; e.currentTarget.style.boxShadow = 'none' }}
          >
            <div style={{
              width: 48, height: 48, borderRadius: '50%',
              background: s.iconBg,
              border: `1px solid ${s.iconBorder}`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              margin: '0 auto 16px',
              transition: 'transform 0.4s cubic-bezier(0.34,1.56,0.64,1)',
            }}
              onMouseEnter={e => e.currentTarget.style.transform = 'scale(1.15) rotate(-8deg)'}
              onMouseLeave={e => e.currentTarget.style.transform = 'scale(1) rotate(0deg)'}
            >
              <span className="material-symbols-outlined" style={{
                fontSize: 22, color: s.color,
                fontVariationSettings: s.icon === 'star' ? "'FILL' 1" : "'FILL' 0",
              }}>{s.icon}</span>
            </div>
            <p className="font-headline" style={{
              fontSize: 'clamp(28px, 3.5vw, 40px)', fontWeight: 900,
              color: s.color, lineHeight: 1, marginBottom: 8,
            }}>
              <CountUp target={s.value} suffix={s.suffix} isFloat={s.isFloat} active={visible} />
            </p>
            <p className="font-label" style={{
              fontSize: 11, textTransform: 'uppercase', letterSpacing: '0.12em',
              color: 'var(--on-surface-variant)',
            }}>{s.label}</p>
          </div>
        ))}
      </div>

      <style>{`
        @media (max-width: 768px) {
          .stats-grid { grid-template-columns: repeat(2, 1fr) !important; }
        }
        @media (max-width: 480px) {
          .stats-grid { grid-template-columns: 1fr !important; }
        }
      `}</style>
    </section>
  )
}
