import { useState } from 'react'
import { useInView } from '../hooks/useInView'

const trustItems = [
  { icon: 'lock',        text: 'Firebase encrypted' },
  { icon: 'wifi_off',    text: 'Works offline' },
  { icon: 'payments',    text: 'ETB currency' },
  { icon: 'no_accounts', text: 'No ads, ever' },
]

function DownloadBtn({ icon, label, sublabel, dark = false, href = '#' }) {
  return (
    <a
      href={href}
      className="ghost-border dl-btn"
      style={{
        display: 'flex', alignItems: 'center', gap: 14,
        padding: '16px 28px',
        background: dark ? '#1c1917' : 'var(--surface-container-highest)',
        color: dark ? '#fff' : 'var(--on-surface)',
        border: dark ? 'none' : '1px solid var(--outline)',
        textDecoration: 'none', minWidth: 210,
      }}
    >
      <span className="material-symbols-outlined" style={{ fontSize: 32, color: dark ? '#D4AF37' : 'var(--primary)' }}>
        {icon}
      </span>
      <div>
        <p className="font-label" style={{ fontSize: 10, textTransform: 'uppercase', letterSpacing: '0.12em', opacity: 0.65, marginBottom: 2 }}>
          {sublabel}
        </p>
        <p className="font-headline" style={{ fontSize: 17, fontWeight: 700 }}>{label}</p>
      </div>
    </a>
  )
}

// Tiny confetti burst — 12 dots that fly outward on success
function Confetti({ active }) {
  if (!active) return null
  const pieces = Array.from({ length: 12 }, (_, i) => {
    const angle = (i / 12) * 360
    const dist = 40 + Math.random() * 30
    const dx = Math.cos((angle * Math.PI) / 180) * dist
    const dy = Math.sin((angle * Math.PI) / 180) * dist
    const colors = ['#D4AF37', '#3c6929', '#ad302f', '#735c00', '#bcf1a1']
    return { dx, dy, color: colors[i % colors.length] }
  })
  return (
    <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none', overflow: 'visible' }}>
      {pieces.map((p, i) => (
        <div key={i} style={{
          position: 'absolute', top: '50%', left: '50%',
          width: 6, height: 6, borderRadius: '50%',
          background: p.color,
          animation: `confetti-fly-${i} 0.6s cubic-bezier(0.22,1,0.36,1) forwards`,
        }} />
      ))}
      <style>{pieces.map((p, i) => `
        @keyframes confetti-fly-${i} {
          0%   { transform: translate(-50%,-50%) translate(0,0) scale(1); opacity: 1; }
          100% { transform: translate(-50%,-50%) translate(${p.dx}px,${p.dy}px) scale(0); opacity: 0; }
        }
      `).join('')}</style>
    </div>
  )
}

function WaitlistForm() {
  const [email, setEmail] = useState('')
  const [status, setStatus] = useState('idle') // idle | loading | success | error
  const [confetti, setConfetti] = useState(false)

  const handleSubmit = (e) => {
    e.preventDefault()
    if (!email.includes('@')) { setStatus('error'); return }
    setStatus('loading')
    // Simulate async submit
    setTimeout(() => {
      setStatus('success')
      setConfetti(true)
      setTimeout(() => setConfetti(false), 700)
    }, 900)
  }

  if (status === 'success') {
    return (
      <div style={{ position: 'relative', display: 'inline-block' }}>
        <Confetti active={confetti} />
        <div style={{
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12,
          padding: '24px 36px',
          background: 'rgba(60,105,41,0.1)',
          border: '1px solid rgba(60,105,41,0.3)',
          animation: 'scaleIn 0.4s cubic-bezier(0.22,1,0.36,1)',
        }}>
          <span className="material-symbols-outlined" style={{
            fontSize: 36, color: 'var(--secondary)',
            fontVariationSettings: "'FILL' 1",
            animation: 'scaleIn 0.5s cubic-bezier(0.34,1.56,0.64,1)',
          }}>check_circle</span>
          <p className="font-headline" style={{ fontWeight: 700, fontSize: 16, color: 'var(--secondary)' }}>
            You are on the list!
          </p>
          <p className="font-label" style={{ fontSize: 11, textTransform: 'uppercase', letterSpacing: '0.12em', color: 'var(--on-surface-variant)' }}>
            We will notify you at {email}
          </p>
        </div>
      </div>
    )
  }

  return (
    <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12, width: '100%', maxWidth: 480, margin: '0 auto' }}>
      <p className="font-label" style={{
        fontSize: 11, textTransform: 'uppercase', letterSpacing: '0.2em',
        color: 'var(--primary)', fontWeight: 700,
      }}>Get notified when iOS launches</p>
      <div style={{ display: 'flex', width: '100%', gap: 0 }}>
        <input
          type="email"
          value={email}
          onChange={e => { setEmail(e.target.value); if (status === 'error') setStatus('idle') }}
          placeholder="your@email.com"
          style={{
            flex: 1, padding: '14px 18px',
            background: 'var(--surface)',
            border: `1px solid ${status === 'error' ? 'var(--tertiary)' : 'var(--outline-variant)'}`,
            borderRight: 'none',
            fontFamily: 'Manrope, sans-serif', fontSize: 14,
            color: 'var(--on-surface)',
            outline: 'none',
            transition: 'border-color 0.2s',
          }}
          onFocus={e => e.target.style.borderColor = 'var(--primary)'}
          onBlur={e => e.target.style.borderColor = status === 'error' ? 'var(--tertiary)' : 'var(--outline-variant)'}
        />
        <button type="submit" disabled={status === 'loading'} style={{
          padding: '14px 24px',
          background: status === 'loading' ? '#a08a00' : 'var(--primary)',
          color: '#fff', border: 'none',
          fontFamily: 'Epilogue, sans-serif', fontWeight: 700, fontSize: 14,
          cursor: status === 'loading' ? 'not-allowed' : 'pointer',
          display: 'flex', alignItems: 'center', gap: 8,
          transition: 'background 0.2s, transform 0.15s',
          whiteSpace: 'nowrap',
        }}
          onMouseEnter={e => { if (status !== 'loading') e.currentTarget.style.background = '#5a4700' }}
          onMouseLeave={e => { if (status !== 'loading') e.currentTarget.style.background = 'var(--primary)' }}
        >
          {status === 'loading' ? (
            <>
              <span className="material-symbols-outlined" style={{ fontSize: 16, animation: 'spinSlow 1s linear infinite' }}>progress_activity</span>
              Noting…
            </>
          ) : (
            <>
              <span className="material-symbols-outlined" style={{ fontSize: 16 }}>history_edu</span>
              Notify Me
            </>
          )}
        </button>
      </div>
      {status === 'error' && (
        <p style={{ fontSize: 12, color: 'var(--tertiary)', marginTop: -4 }}>
          Please enter a valid email address.
        </p>
      )}
    </form>
  )
}

export default function Download() {
  const [ref, visible] = useInView()

  return (
    <section id="download" ref={ref} style={{
      padding: 'clamp(64px, 10vw, 120px) 24px',
      background: '#F5F5DC',
      position: 'relative', overflow: 'hidden',
    }}>
      <div style={{ maxWidth: 860, margin: '0 auto', textAlign: 'center', position: 'relative', zIndex: 10 }}>

        <span className={`font-label anim-hidden${visible ? ' anim-fade-up delay-0' : ''}`} style={{
          color: 'var(--primary)', fontWeight: 700,
          textTransform: 'uppercase', letterSpacing: '0.3em',
          fontSize: 12, display: 'block', marginBottom: 16,
        }}>Begin Your Chronicle</span>

        <h2 className={`font-headline anim-hidden${visible ? ' anim-fade-up delay-100' : ''}`} style={{
          fontSize: 'clamp(32px, 5vw, 56px)',
          fontWeight: 900, marginBottom: 20, lineHeight: 1.1,
        }}>
          Download Mystic Ledger
        </h2>

        <p className={`anim-hidden${visible ? ' anim-fade-up delay-200' : ''}`} style={{
          fontSize: 'clamp(15px, 1.8vw, 18px)',
          color: 'var(--on-surface-variant)',
          maxWidth: 500, margin: '0 auto 20px', lineHeight: 1.75,
        }}>
          Free to begin. Available on Android now, iOS coming soon. Your data stays yours —
          encrypted, synced, and preserved in ink.
        </p>

        {/* Trust row */}
        <div className={`anim-hidden${visible ? ' anim-fade-up delay-300' : ''}`} style={{
          display: 'flex', flexWrap: 'wrap', gap: 20,
          justifyContent: 'center', marginBottom: 40,
        }}>
          {trustItems.map((t) => (
            <div key={t.text} style={{
              display: 'flex', alignItems: 'center', gap: 7,
              padding: '6px 14px',
              border: '1px solid var(--outline-variant)',
              background: 'var(--surface-container)',
              transition: 'border-color 0.2s, transform 0.2s',
              cursor: 'default',
            }}
              onMouseEnter={e => { e.currentTarget.style.borderColor = 'var(--primary-container)'; e.currentTarget.style.transform = 'translateY(-2px)' }}
              onMouseLeave={e => { e.currentTarget.style.borderColor = 'var(--outline-variant)'; e.currentTarget.style.transform = 'translateY(0)' }}
            >
              <span className="material-symbols-outlined" style={{ fontSize: 15, color: 'var(--primary)' }}>{t.icon}</span>
              <span className="font-label" style={{ fontSize: 11, textTransform: 'uppercase', letterSpacing: '0.1em', color: 'var(--on-surface-variant)' }}>
                {t.text}
              </span>
            </div>
          ))}
        </div>

        {/* Download buttons */}
        <div className={`download-btns anim-hidden${visible ? ' anim-scale-in delay-400' : ''}`} style={{ marginBottom: 48 }}>
          <DownloadBtn icon="android"      label="Android (APK)"    sublabel="Download for"     dark href="https://github.com/Mattathiasa/mystic_ledger/releases/download/v1.0.0/app-release.apk" />
          <DownloadBtn icon="phone_iphone" label="iOS — Coming Soon" sublabel="Join the waitlist" href="#waitlist" />
        </div>

        {/* Divider */}
        <div className={`anim-hidden${visible ? ' anim-fade-in delay-400' : ''}`} style={{
          display: 'flex', alignItems: 'center', gap: 16, marginBottom: 36,
        }}>
          <div style={{ flex: 1, height: 1, background: 'var(--outline-variant)' }} />
          <span className="font-label" style={{ fontSize: 10, textTransform: 'uppercase', letterSpacing: '0.2em', color: 'var(--on-surface-variant)', whiteSpace: 'nowrap' }}>
            or join the waitlist
          </span>
          <div style={{ flex: 1, height: 1, background: 'var(--outline-variant)' }} />
        </div>

        {/* Waitlist form */}
        <div id="waitlist" className={`anim-hidden${visible ? ' anim-fade-up delay-500' : ''}`} style={{ display: 'flex', justifyContent: 'center' }}>
          <WaitlistForm />
        </div>

        <p className={`font-label anim-hidden${visible ? ' anim-fade-up delay-600' : ''}`} style={{
          marginTop: 36, fontSize: 11,
          textTransform: 'uppercase', letterSpacing: '0.2em',
          color: 'var(--primary)', fontWeight: 700,
        }}>
          Free to begin. Sacred to maintain.
        </p>
      </div>

      {/* Decorative spinning quill */}
      <div className="quill-deco" style={{
        position: 'absolute', right: -60, bottom: -60,
        opacity: 0.06, pointerEvents: 'none',
      }}>
        <span className="material-symbols-outlined spin-slow" style={{ fontSize: 360 }}>auto_awesome</span>
      </div>
      <div style={{
        position: 'absolute', left: -40, top: -40,
        opacity: 0.05, pointerEvents: 'none', transform: 'rotate(-20deg)',
      }}>
        <span className="material-symbols-outlined" style={{ fontSize: 280 }}>edit</span>
      </div>

      <style>{`@media (max-width: 640px) { .quill-deco { display: none; } }`}</style>
    </section>
  )
}
