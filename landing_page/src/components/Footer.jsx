import { useInView } from '../hooks/useInView'

const footerCols = [
  {
    heading: 'Mystic Ledger',
    links: [
      { label: 'My Ledger',     href: '#' },
      { label: 'All Entries',   href: '#' },
      { label: 'Sacred Giving', href: '#' },
      { label: 'Insights',      href: '#' },
      { label: 'Finance Hub',   href: '#' },
    ],
  },
  {
    heading: 'Legal',
    links: [
      { label: 'Privacy Policy', href: '#' },
      { label: 'Terms of Use',   href: '#' },
      { label: 'Contact',        href: '#' },
    ],
  },
]

export default function Footer() {
  const [ref, visible] = useInView()

  return (
    <footer ref={ref} style={{ background: '#F5F5DC', borderTop: '2px solid #d6d3c4' }}>
      <div className="footer-inner" style={{ maxWidth: 1280, margin: '0 auto', padding: '52px 32px' }}>

        {/* Brand */}
        <div className={`anim-hidden${visible ? ' anim-fade-up delay-0' : ''}`}
          style={{ display: 'flex', flexDirection: 'column', gap: 16, maxWidth: 300 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <span className="material-symbols-outlined" style={{
              color: 'var(--primary)', fontSize: 26,
              transition: 'transform 0.3s cubic-bezier(0.34,1.56,0.64,1)',
            }}
              onMouseEnter={e => e.currentTarget.style.transform = 'rotate(-15deg) scale(1.15)'}
              onMouseLeave={e => e.currentTarget.style.transform = 'rotate(0deg) scale(1)'}
            >menu_book</span>
            <span className="font-headline" style={{ fontWeight: 700, fontSize: 18, color: '#1c1917' }}>
              Mystic Ledger
            </span>
          </div>
          <p style={{ fontSize: 13, color: '#78716c', lineHeight: 1.7 }}>
            A personal finance app built for those who treat money like a story.
            Track, give, save, and grow — one entry at a time.
          </p>
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginTop: 4 }}>
            {['ETB', 'Firebase', 'Offline-First'].map(b => (
              <span key={b} className="font-label" style={{
                fontSize: 9, textTransform: 'uppercase', letterSpacing: '0.1em',
                padding: '3px 8px',
                border: '1px solid var(--outline-variant)',
                color: 'var(--on-surface-variant)',
                transition: 'border-color 0.2s, color 0.2s',
                cursor: 'default',
              }}
                onMouseEnter={e => { e.currentTarget.style.borderColor = 'var(--primary-container)'; e.currentTarget.style.color = 'var(--primary)' }}
                onMouseLeave={e => { e.currentTarget.style.borderColor = 'var(--outline-variant)'; e.currentTarget.style.color = 'var(--on-surface-variant)' }}
              >{b}</span>
            ))}
          </div>
        </div>

        {/* Link columns */}
        <div className={`footer-links anim-hidden${visible ? ' anim-fade-up delay-200' : ''}`}>
          {footerCols.map(col => (
            <div key={col.heading} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <h4 className="font-label" style={{
                fontSize: 11, textTransform: 'uppercase',
                letterSpacing: '0.15em', fontWeight: 700, color: 'var(--primary)',
              }}>{col.heading}</h4>
              {col.links.map(link => (
                <a key={link.label} href={link.href} style={{
                  fontFamily: 'Space Grotesk, sans-serif',
                  fontSize: 13, color: '#78716c',
                  textDecoration: 'none', transition: 'color 0.2s, transform 0.2s',
                  display: 'inline-block',
                }}
                  onMouseEnter={e => { e.currentTarget.style.color = '#D4AF37'; e.currentTarget.style.transform = 'translateX(4px)' }}
                  onMouseLeave={e => { e.currentTarget.style.color = '#78716c'; e.currentTarget.style.transform = 'translateX(0)' }}
                >{link.label}</a>
              ))}
            </div>
          ))}

          {/* Manifesto */}
          <div className={`anim-hidden${visible ? ' anim-fade-up delay-300' : ''}`}
            style={{ display: 'flex', flexDirection: 'column', gap: 14, maxWidth: 220 }}>
            <h4 className="font-label" style={{
              fontSize: 11, textTransform: 'uppercase',
              letterSpacing: '0.15em', fontWeight: 700, color: 'var(--primary)',
            }}>Manifesto</h4>
            <p style={{ fontSize: 13, color: '#a8a29e', fontStyle: 'italic', lineHeight: 1.7 }}>
              "Wealth is not in the having, but in the knowing of how it was gathered."
            </p>
            <div style={{ display: 'flex', gap: 10, marginTop: 4 }}>
              {['android', 'phone_iphone'].map(icon => (
                <a key={icon} href="#download" style={{
                  width: 36, height: 36,
                  border: '1px solid var(--outline-variant)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  color: 'var(--primary)', textDecoration: 'none',
                  transition: 'background 0.2s, border-color 0.2s, transform 0.2s',
                }}
                  onMouseEnter={e => { e.currentTarget.style.background = 'var(--primary)'; e.currentTarget.style.borderColor = 'var(--primary)'; e.currentTarget.style.color = '#fff'; e.currentTarget.style.transform = 'translateY(-3px)' }}
                  onMouseLeave={e => { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.borderColor = 'var(--outline-variant)'; e.currentTarget.style.color = 'var(--primary)'; e.currentTarget.style.transform = 'translateY(0)' }}
                >
                  <span className="material-symbols-outlined" style={{ fontSize: 18 }}>{icon}</span>
                </a>
              ))}
            </div>
          </div>
        </div>

      </div>

      {/* Bottom bar */}
      <div style={{
        borderTop: '1px solid #d6d3c4', padding: '20px 32px',
        display: 'flex', flexWrap: 'wrap', justifyContent: 'space-between', alignItems: 'center', gap: 12,
      }}>
        <p className="font-label" style={{ fontSize: 11, textTransform: 'uppercase', letterSpacing: '0.15em', color: '#78716c' }}>
          © 2024 Mystic Ledger. All data preserved in ink.
        </p>
        <p className="font-label" style={{ fontSize: 11, textTransform: 'uppercase', letterSpacing: '0.1em', color: 'var(--primary)' }}>
          Free to begin. Sacred to maintain.
        </p>
      </div>
    </footer>
  )
}
