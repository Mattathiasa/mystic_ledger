import { useEffect, useState } from 'react'

const TICKER_ITEMS = [
  '✦ ETB Currency',
  '✦ Firebase Sync',
  '✦ Offline Ready',
  '✦ Free to Begin',
  '✦ Sacred Giving',
  '✦ Multi-Account',
  '✦ Tithe Calculator',
  '✦ Debt Tracker',
  '✦ Monthly Insights',
  '✦ Savings Vault',
]

function Ticker() {
  const items = [...TICKER_ITEMS, ...TICKER_ITEMS] // duplicate for seamless loop
  return (
    <div className="ticker-wrap">
      <div className="ticker-track">
        {items.map((item, i) => (
          <span key={i} className="font-label" style={{
            fontSize: 11, textTransform: 'uppercase', letterSpacing: '0.18em',
            color: 'var(--on-surface-variant)', padding: '0 32px', whiteSpace: 'nowrap',
          }}>{item}</span>
        ))}
      </div>
    </div>
  )
}

export default function Hero() {
  const [mounted, setMounted] = useState(false)
  useEffect(() => { const t = setTimeout(() => setMounted(true), 80); return () => clearTimeout(t) }, [])

  return (
    <>
      <section id="hero" style={{
        position: 'relative', minHeight: 820,
        display: 'flex', alignItems: 'center',
        overflow: 'hidden', padding: '80px 24px 60px',
      }}>
        {/* Ambient glow blobs */}
        <div style={{
          position: 'absolute', inset: 0, pointerEvents: 'none', overflow: 'hidden',
        }}>
          <div style={{
            position: 'absolute', top: '10%', right: '5%',
            width: 480, height: 480, borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(212,175,55,0.1) 0%, transparent 70%)',
            animation: 'floatY 8s ease-in-out infinite',
          }} />
          <div style={{
            position: 'absolute', bottom: '5%', left: '10%',
            width: 320, height: 320, borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(60,105,41,0.07) 0%, transparent 70%)',
            animation: 'floatY 10s ease-in-out infinite reverse',
          }} />
        </div>

        <div style={{ maxWidth: 1280, margin: '0 auto', width: '100%' }}>
          <div className="hero-grid">

            {/* ── Copy ── */}
            <div style={{ zIndex: 10 }}>
              <span
                className={`font-label anim-hidden${mounted ? ' anim-fade-up delay-0' : ''}`}
                style={{
                  color: 'var(--primary)', fontWeight: 700,
                  textTransform: 'uppercase', letterSpacing: '0.3em',
                  fontSize: 12, display: 'block', marginBottom: 16,
                }}
              >
                Volume I: Financial Awakening
              </span>

              <h1
                className={`font-headline shimmer-text anim-hidden${mounted ? ' anim-fade-up delay-100' : ''}`}
                style={{
                  fontSize: 'clamp(48px, 7vw, 88px)',
                  fontWeight: 900, lineHeight: 1.05, marginBottom: 24,
                }}
              >
                Mystic Ledger
              </h1>

              <p
                className={`anim-hidden${mounted ? ' anim-fade-up delay-200' : ''}`}
                style={{
                  fontSize: 'clamp(16px, 1.8vw, 20px)',
                  color: 'var(--on-surface-variant)',
                  maxWidth: 500, marginBottom: 36,
                  lineHeight: 1.75, fontStyle: 'italic',
                }}
              >
                Track your money like a story — where every transaction is a chapter,
                every account a vessel, and your wealth a{' '}
                <span className="ink-underline drawn" style={{ fontStyle: 'normal', fontWeight: 700, color: 'var(--primary)' }}>
                  living journal
                </span>.
              </p>

              {/* Trust badges */}
              <div
                className={`hero-badges anim-hidden${mounted ? ' anim-fade-up delay-300' : ''}`}
                style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginBottom: 32 }}
              >
                {['ETB Currency', 'Firebase Sync', 'Offline Ready', 'Free to Begin'].map((b, i) => (
                  <span key={b} className="font-label hero-badge" style={{
                    fontSize: 10, textTransform: 'uppercase', letterSpacing: '0.12em',
                    padding: '5px 12px',
                    border: '1px solid var(--outline-variant)',
                    color: 'var(--on-surface-variant)',
                    background: 'var(--surface-container)',
                    animationDelay: `${300 + i * 60}ms`,
                  }}>{b}</span>
                ))}
              </div>

              <div
                className={`hero-cta-row anim-hidden${mounted ? ' anim-fade-up delay-400' : ''}`}
                style={{ display: 'flex', flexWrap: 'wrap', gap: 16 }}
              >
                <button
                  className="ghost-border pulse-glow"
                  style={{
                    background: 'var(--primary)', color: '#fff',
                    border: 'none', padding: '16px 36px',
                    fontFamily: 'Epilogue, sans-serif', fontWeight: 700,
                    fontSize: 17, cursor: 'pointer',
                    boxShadow: '0 16px 32px rgba(115,92,0,0.25)',
                    transition: 'transform 0.2s cubic-bezier(0.22,1,0.36,1), background 0.2s',
                    display: 'flex', alignItems: 'center', gap: 10,
                  }}
                  onMouseEnter={e => { e.currentTarget.style.transform = 'scale(1.05) translateY(-2px)'; e.currentTarget.style.background = '#5a4700' }}
                  onMouseLeave={e => { e.currentTarget.style.transform = 'scale(1) translateY(0)'; e.currentTarget.style.background = 'var(--primary)' }}
                >
                  <span className="material-symbols-outlined" style={{ fontSize: 20 }}>history_edu</span>
                  Open the Journal
                </button>
                <a href="#faq" style={{ textDecoration: 'none' }}>
                  <button
                    style={{
                      background: 'none', border: 'none', padding: '16px 28px',
                      fontFamily: 'Epilogue, sans-serif', fontWeight: 700,
                      fontSize: 17, cursor: 'pointer', color: 'var(--primary)',
                      borderBottom: '2px solid rgba(115,92,0,0.3)',
                      transition: 'border-color 0.2s, transform 0.2s',
                      display: 'flex', alignItems: 'center', gap: 8,
                    }}
                    onMouseEnter={e => { e.currentTarget.style.borderBottomColor = 'var(--primary)'; e.currentTarget.style.transform = 'translateY(-2px)' }}
                    onMouseLeave={e => { e.currentTarget.style.borderBottomColor = 'rgba(115,92,0,0.3)'; e.currentTarget.style.transform = 'translateY(0)' }}
                  >
                    <span className="material-symbols-outlined" style={{ fontSize: 18 }}>help_outline</span>
                    Consult the Scribes
                  </button>
                </a>
              </div>
            </div>

            {/* ── Hero phone mockup ── */}
            <div className={`hero-image-col anim-hidden${mounted ? ' anim-slide-right delay-200' : ''}`}
              style={{ display: 'flex', justifyContent: 'center', alignItems: 'flex-start', position: 'relative', paddingBottom: 56 }}>

              {/* Phone shell */}
              <div className="float-phone" style={{
                width: 260, height: 540,
                background: '#1c1917', borderRadius: 44,
                border: '7px solid #292524',
                boxShadow: '0 48px 80px rgba(0,0,0,0.35)',
                overflow: 'hidden', position: 'relative', flexShrink: 0,
                zIndex: 2,
              }}>
                {/* Notch */}
                <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 22, background: '#292524', borderRadius: '0 0 14px 14px', zIndex: 20, display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                  <div style={{ width: 72, height: 14, background: '#1c1917', borderRadius: 99 }} />
                </div>
                {/* Screen */}
                <div style={{ background: 'var(--background)', height: '100%', padding: '36px 14px 60px', overflowY: 'hidden' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
                    <span className="material-symbols-outlined" style={{ color: 'var(--primary)', fontSize: 18 }}>menu</span>
                    <span className="font-headline" style={{ fontWeight: 700, fontSize: 12, fontStyle: 'italic' }}>My Ledger</span>
                    <span className="material-symbols-outlined" style={{ color: 'var(--primary)', fontSize: 18 }}>person</span>
                  </div>
                  <p className="font-label" style={{ fontSize: 7, textTransform: 'uppercase', letterSpacing: '0.15em', color: 'var(--on-surface-variant)', marginBottom: 4 }}>CURRENT OBSERVATIONS</p>
                  <p className="font-headline" style={{ fontSize: 24, fontWeight: 900, lineHeight: 1.1, marginBottom: 4 }}>
                    ETB <span style={{ color: 'var(--primary)' }}>24,830</span>
                    <span style={{ fontSize: 11, fontWeight: 400 }}>.00</span>
                  </p>
                  <div style={{ marginBottom: 12, padding: '5px 8px', borderLeft: '2px solid var(--primary-container)' }}>
                    <p style={{ fontSize: 8, fontStyle: 'italic', color: 'var(--on-surface-variant)' }}>"The ledger reflects a prosperous season."</p>
                  </div>
                  {[
                    { icon: 'work',       bg: 'rgba(188,241,161,0.4)',  ic: 'var(--secondary)', label: 'Salary',     amt: '+ETB 8,500', ac: 'var(--secondary)' },
                    { icon: 'restaurant',bg: 'rgba(255,150,143,0.2)',  ic: 'var(--tertiary)',  label: 'Sustenance', amt: '-ETB 320',   ac: 'var(--tertiary)'  },
                    { icon: 'directions_car', bg: 'rgba(255,150,143,0.15)', ic: 'var(--tertiary)', label: 'Carriage', amt: '-ETB 180', ac: 'var(--tertiary)'  },
                  ].map((row, i) => (
                    <div key={i} className="ledger-underline" style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '6px 0' }}>
                      <div style={{ width: 24, height: 24, borderRadius: '50%', background: row.bg, flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <span className="material-symbols-outlined" style={{ fontSize: 12, color: row.ic }}>{row.icon}</span>
                      </div>
                      <p style={{ flex: 1, fontWeight: 700, fontSize: 10 }}>{row.label}</p>
                      <p style={{ fontWeight: 800, fontSize: 10, color: row.ac }}>{row.amt}</p>
                    </div>
                  ))}
                </div>
                {/* Bottom tabs */}
                <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, background: '#1c1917', borderTop: '1px solid #292524', display: 'flex', padding: '5px 0 7px', zIndex: 20 }}>
                  {[['auto_stories','Ledger'],['list_alt','Entries'],['bar_chart','Insights'],['volunteer_activism','Giving'],['account_balance_wallet','Hub']].map(([icon, label], idx) => (
                    <div key={label} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2 }}>
                      <span className="material-symbols-outlined" style={{ fontSize: 14, color: idx === 0 ? '#D4AF37' : '#78716c', fontVariationSettings: idx === 0 ? "'FILL' 1" : "'FILL' 0" }}>{icon}</span>
                      <span style={{ fontSize: 5.5, color: idx === 0 ? '#D4AF37' : '#78716c', fontFamily: 'Space Grotesk' }}>{label}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Floating live entry card */}
              <div
                className="hero-float-card float-card"
                style={{
                  background: 'var(--surface-container-highest)',
                  padding: 20, maxWidth: 270,
                  border: '1px solid var(--outline-variant)',
                  boxShadow: '0 20px 48px rgba(0,0,0,0.14)',
                  transform: 'rotate(-3deg)',
                  zIndex: 3,
                }}
              >
                <p className="font-label" style={{ fontSize: 10, textTransform: 'uppercase', letterSpacing: '0.15em', color: 'var(--primary)', marginBottom: 10 }}>Latest Entry</p>
                {[
                  { icon: 'work', bg: 'rgba(188,241,161,0.4)', ic: 'var(--secondary)', label: 'Salary — CBE Bank', sub: 'Salary · 14 APR 2024', amt: '+ETB 8,500', ac: 'var(--secondary)' },
                  { icon: 'restaurant', bg: 'rgba(255,150,143,0.2)', ic: 'var(--tertiary)', label: 'Sustenance — Telebirr', sub: 'Food · 13 APR 2024', amt: '-ETB 320', ac: 'var(--tertiary)' },
                ].map((row, i) => (
                  <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: i === 0 ? 8 : 0 }}>
                    <div style={{ width: 28, height: 28, borderRadius: '50%', background: row.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                      <span className="material-symbols-outlined" style={{ fontSize: 14, color: row.ic }}>{row.icon}</span>
                    </div>
                    <div style={{ flex: 1 }}>
                      <p style={{ fontWeight: 700, fontSize: 11 }}>{row.label}</p>
                      <p className="font-label" style={{ fontSize: 9, color: 'var(--on-surface-variant)' }}>{row.sub}</p>
                    </div>
                    <p style={{ fontWeight: 800, fontSize: 12, color: row.ac, flexShrink: 0 }}>{row.amt}</p>
                  </div>
                ))}
              </div>
            </div>

          </div>
        </div>
      </section>

      {/* Ticker strip */}
      <Ticker />
    </>
  )
}
