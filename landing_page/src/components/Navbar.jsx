import { useState, useEffect } from 'react'
import Drawer from './Drawer'

const NAV_LINKS = [
  { label: 'The Ledger',   href: '#hero'      },
  { label: 'Features',     href: '#features'  },
  { label: 'How It Works', href: '#how'       },
  { label: 'Download',     href: '#download'  },
]

export default function Navbar() {
  const [drawerOpen, setDrawerOpen] = useState(false)
  const [scrolled, setScrolled]     = useState(false)
  const [activeId, setActiveId]     = useState('hero')
  const [progress, setProgress]     = useState(0)

  useEffect(() => {
    const onScroll = () => {
      setScrolled(window.scrollY > 40)
      const docH = document.documentElement.scrollHeight - window.innerHeight
      setProgress(docH > 0 ? Math.min(100, (window.scrollY / docH) * 100) : 0)
    }
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  // Track which section is in view
  useEffect(() => {
    const sectionIds = ['hero', 'features', 'how', 'download']
    const observers = sectionIds.map(id => {
      const el = document.getElementById(id)
      if (!el) return null
      const obs = new IntersectionObserver(
        ([entry]) => { if (entry.isIntersecting) setActiveId(id) },
        { threshold: 0.25, rootMargin: '-60px 0px -40% 0px' }
      )
      obs.observe(el)
      return obs
    })
    return () => observers.forEach(o => o?.disconnect())
  }, [])

  return (
    <>
      <header className={`navbar-glass${scrolled ? ' scrolled' : ''}`}
        style={{ position: 'sticky', top: 0, zIndex: 50 }}>
        {/* Scroll progress bar */}
        <div style={{
          position: 'absolute', top: 0, left: 0, height: 3,
          width: `${progress}%`,
          background: 'linear-gradient(90deg, var(--primary) 0%, var(--primary-container) 100%)',
          transition: 'width 0.1s linear',
          zIndex: 100,
        }} />
        <nav style={{
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          width: '100%', padding: '14px 24px', maxWidth: 1280, margin: '0 auto',
        }}>
          {/* Logo */}
          <a href="#hero" style={{ display: 'flex', alignItems: 'center', gap: 10, textDecoration: 'none' }}>
            <span className="material-symbols-outlined"
              style={{ color: '#D4AF37', fontSize: 28, transition: 'transform 0.3s' }}
              onMouseEnter={e => e.currentTarget.style.transform = 'rotate(-12deg) scale(1.1)'}
              onMouseLeave={e => e.currentTarget.style.transform = 'rotate(0deg) scale(1)'}
            >menu_book</span>
            <span className="font-headline" style={{ fontSize: 20, fontWeight: 700, color: '#1c1917' }}>
              Mystic Ledger
            </span>
          </a>

          {/* Desktop nav */}
          <div className="desktop-nav" style={{ display: 'flex', gap: 28, alignItems: 'center' }}>
            {NAV_LINKS.map(({ label, href }) => {
              const id = href.replace('#', '')
              const isActive = activeId === id
              return (
                <a key={label} href={href} className={`nav-link${isActive ? ' active' : ''}`}>
                  {label}
                </a>
              )
            })}
            <a href="#download" style={{ textDecoration: 'none' }}>
              <button className="ghost-border" style={{
                background: 'var(--primary)', color: '#fff', border: 'none',
                padding: '9px 22px',
                fontFamily: 'Epilogue, sans-serif', fontWeight: 700, fontSize: 13,
                cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 7,
                transition: 'background 0.2s, transform 0.15s',
              }}
                onMouseEnter={e => { e.currentTarget.style.background = '#5a4700'; e.currentTarget.style.transform = 'scale(1.04)' }}
                onMouseLeave={e => { e.currentTarget.style.background = 'var(--primary)'; e.currentTarget.style.transform = 'scale(1)' }}
              >
                <span className="material-symbols-outlined" style={{ fontSize: 15 }}>history_edu</span>
                Open the Journal
              </button>
            </a>
          </div>

          {/* Mobile hamburger */}
          <button onClick={() => setDrawerOpen(true)} className="nav-mobile-btn"
            style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 8 }}>
            <span className="material-symbols-outlined" style={{ fontSize: 28, color: '#1c1917' }}>menu</span>
          </button>
        </nav>
      </header>

      <Drawer open={drawerOpen} onClose={() => setDrawerOpen(false)} activeId={activeId} />

      <style>{`
        .desktop-nav { display: flex; }
        .nav-mobile-btn { display: none; }
        @media (max-width: 768px) {
          .desktop-nav { display: none !important; }
          .nav-mobile-btn { display: block !important; }
        }
      `}</style>
    </>
  )
}
