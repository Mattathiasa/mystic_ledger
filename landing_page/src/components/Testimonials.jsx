import { useEffect, useRef, useState, useSyncExternalStore } from 'react'
import { useInView } from '../hooks/useInView'

function useVisibleCount() {
  const getSnapshot = () => window.innerWidth
  const subscribe = (cb) => { window.addEventListener('resize', cb); return () => window.removeEventListener('resize', cb) }
  const w = typeof window !== 'undefined' ? useSyncExternalStore(subscribe, getSnapshot, () => 1280) : 1280
  return w <= 640 ? 1 : w <= 1024 ? 2 : 3
}

const testimonials = [
  {
    quote: 'Finally a finance app that does not feel like a spreadsheet. The journal aesthetic makes me actually want to open it every day.',
    author: 'A Grateful Archivist',
    role: 'Daily user · Salary tracker',
    icon: 'auto_stories',
  },
  {
    quote: 'The tithe calculator alone is worth it. I set it to Weekly and it tells me exactly what to give on Sunday. No math, no guilt.',
    author: 'A Faithful Steward',
    role: 'Sacred Giving feature',
    icon: 'volunteer_activism',
  },
  {
    quote: 'Offline mode saved me when I was traveling with no data. Everything synced perfectly the moment I got back on Wi-Fi.',
    author: 'A Wandering Merchant',
    role: 'Offline-first user',
    icon: 'cloud_sync',
  },
  {
    quote: 'The Insights tab opened my eyes. I had no idea I was spending that much on Carriage. Mystic Ledger changed my habits.',
    author: 'A Shrewd Accountant',
    role: 'Insights power user',
    icon: 'bar_chart',
  },
  {
    quote: 'I love that it tracks the Savings Vault separately. Watching it grow gives me the same feeling as leveling up a game.',
    author: 'A Diligent Saver',
    role: 'Savings Vault user',
    icon: 'savings',
  },
]

export default function Testimonials() {
  const [ref, visible] = useInView()
  const [index, setIndex] = useState(0)
  const VISIBLE = useVisibleCount()
  const [sliding, setSliding] = useState(false)
  const [direction, setDirection] = useState('next')
  const autoRef = useRef(null)

  const total = testimonials.length

  const go = (dir) => {
    if (sliding) return
    setDirection(dir)
    setSliding(true)
    setTimeout(() => {
      setIndex(i => dir === 'next' ? (i + 1) % total : (i - 1 + total) % total)
      setSliding(false)
    }, 300)
    resetAuto()
  }

  const resetAuto = () => {
    clearInterval(autoRef.current)
    autoRef.current = setInterval(() => go('next'), 4500)
  }

  useEffect(() => {
    if (visible) {
      autoRef.current = setInterval(() => {
        setDirection('next')
        setSliding(true)
        setTimeout(() => {
          setIndex(i => (i + 1) % total)
          setSliding(false)
        }, 300)
      }, 4500)
    }
    return () => clearInterval(autoRef.current)
  }, [visible, total])

  // Show VISIBLE cards cycling
  const cards = Array.from({ length: VISIBLE }, (_, i) => testimonials[(index + i) % total])

  return (
    <section ref={ref} style={{
      padding: 'clamp(48px, 8vw, 96px) 24px',
      background: 'var(--surface-container-low)',
      borderTop: '1px solid var(--outline-variant)',
      overflow: 'hidden',
    }}>
      <div style={{ maxWidth: 1280, margin: '0 auto' }}>

        <div className={`anim-hidden${visible ? ' anim-fade-up delay-0' : ''}`}
          style={{ textAlign: 'center', marginBottom: 'clamp(32px, 5vw, 56px)' }}>
          <span className="font-label" style={{
            color: 'var(--primary)', fontWeight: 700, fontSize: 11,
            textTransform: 'uppercase', letterSpacing: '0.25em', display: 'block', marginBottom: 10,
          }}>What the Scribes Say</span>
          <h2 className="font-headline" style={{ fontSize: 'clamp(26px, 4vw, 38px)', fontWeight: 700 }}>
            Voices from the Archive
          </h2>
        </div>

        {/* Cards */}
        <div className={`anim-hidden${visible ? ' anim-fade-in delay-200' : ''}`}>
          <div className="testimonials-grid" style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(3, 1fr)',
            gap: 24,
            transform: sliding ? (direction === 'next' ? 'translateX(-24px)' : 'translateX(24px)') : 'translateX(0)',
            opacity: sliding ? 0 : 1,
            transition: 'transform 0.3s cubic-bezier(0.22,1,0.36,1), opacity 0.3s ease',
          }}>
            {cards.map((t, i) => (
              <div
                key={`${t.author}-${i}`}
                className="testimonial-card"
                style={{
                  background: 'var(--surface)',
                  border: '1px solid var(--outline-variant)',
                  padding: 32,
                  display: 'flex', flexDirection: 'column', gap: 20,
                  position: 'relative',
                }}
              >
                {/* Decorative quote mark */}
                <span className="font-headline" style={{
                  position: 'absolute', top: 12, left: 18,
                  fontSize: 72, lineHeight: 1, color: 'var(--primary-container)',
                  opacity: 0.35, pointerEvents: 'none', userSelect: 'none',
                }}>"</span>

                <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginTop: 20 }}>
                  <div style={{
                    width: 44, height: 44, borderRadius: '50%',
                    background: 'var(--surface-container)',
                    border: '1px solid var(--outline-variant)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    flexShrink: 0, transition: 'background 0.2s, border-color 0.2s',
                  }}
                    onMouseEnter={e => { e.currentTarget.style.background = 'var(--primary)'; e.currentTarget.querySelector('span').style.color = '#fff' }}
                    onMouseLeave={e => { e.currentTarget.style.background = 'var(--surface-container)'; e.currentTarget.querySelector('span').style.color = 'var(--primary)' }}
                  >
                    <span className="material-symbols-outlined" style={{ fontSize: 22, color: 'var(--primary)', transition: 'color 0.2s' }}>{t.icon}</span>
                  </div>
                  <div>
                    <p style={{ fontWeight: 700, fontSize: 14 }}>{t.author}</p>
                    <p className="font-label" style={{ fontSize: 10, textTransform: 'uppercase', letterSpacing: '0.1em', color: 'var(--on-surface-variant)' }}>{t.role}</p>
                  </div>
                </div>

                <p style={{ fontSize: 15, lineHeight: 1.75, color: 'var(--on-surface-variant)', fontStyle: 'italic' }}>
                  {t.quote}
                </p>

                <div style={{ display: 'flex', gap: 3 }}>
                  {[...Array(5)].map((_, si) => (
                    <span key={si} className="material-symbols-outlined" style={{
                      fontSize: 16, color: 'var(--primary-container)',
                      fontVariationSettings: "'FILL' 1",
                    }}>star</span>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Controls */}
        <div className={`anim-hidden${visible ? ' anim-fade-up delay-300' : ''}`}
          style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 20, marginTop: 36 }}>

          {/* Prev */}
          <button onClick={() => go('prev')} style={{
            width: 40, height: 40, border: '1px solid var(--outline-variant)',
            background: 'var(--surface)', cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            transition: 'background 0.2s, border-color 0.2s, transform 0.2s',
          }}
            onMouseEnter={e => { e.currentTarget.style.background = 'var(--primary)'; e.currentTarget.style.borderColor = 'var(--primary)'; e.currentTarget.querySelector('span').style.color = '#fff' }}
            onMouseLeave={e => { e.currentTarget.style.background = 'var(--surface)'; e.currentTarget.style.borderColor = 'var(--outline-variant)'; e.currentTarget.querySelector('span').style.color = 'var(--primary)' }}
          >
            <span className="material-symbols-outlined" style={{ fontSize: 20, color: 'var(--primary)', transition: 'color 0.2s' }}>arrow_back</span>
          </button>

          {/* Dots */}
          <div style={{ display: 'flex', gap: 8 }}>
            {testimonials.map((_, i) => (
              <button key={i} onClick={() => { if (!sliding) { setDirection(i > index ? 'next' : 'prev'); setSliding(true); setTimeout(() => { setIndex(i); setSliding(false) }, 300); resetAuto() } }} style={{
                width: i === index ? 24 : 8, height: 8,
                background: i === index ? 'var(--primary)' : 'var(--outline-variant)',
                border: 'none', borderRadius: 99, cursor: 'pointer', padding: 0,
                transition: 'width 0.3s ease, background 0.3s ease',
              }} />
            ))}
          </div>

          {/* Next */}
          <button onClick={() => go('next')} style={{
            width: 40, height: 40, border: '1px solid var(--outline-variant)',
            background: 'var(--surface)', cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            transition: 'background 0.2s, border-color 0.2s, transform 0.2s',
          }}
            onMouseEnter={e => { e.currentTarget.style.background = 'var(--primary)'; e.currentTarget.style.borderColor = 'var(--primary)'; e.currentTarget.querySelector('span').style.color = '#fff' }}
            onMouseLeave={e => { e.currentTarget.style.background = 'var(--surface)'; e.currentTarget.style.borderColor = 'var(--outline-variant)'; e.currentTarget.querySelector('span').style.color = 'var(--primary)' }}
          >
            <span className="material-symbols-outlined" style={{ fontSize: 20, color: 'var(--primary)', transition: 'color 0.2s' }}>arrow_forward</span>
          </button>
        </div>

      </div>

      <style>{`
        @media (max-width: 1024px) {
          .testimonials-grid { grid-template-columns: 1fr 1fr !important; }
        }
        @media (max-width: 640px) {
          .testimonials-grid { grid-template-columns: 1fr !important; }
        }
      `}</style>
    </section>
  )
}
