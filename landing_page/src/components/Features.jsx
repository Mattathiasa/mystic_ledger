import { useInView } from '../hooks/useInView'

const features = [
  {
    icon: 'auto_stories', title: 'My Ledger',
    desc: 'Your financial dashboard. Total ETB balance across all accounts, per-account cards (Bank, Telebirr, Cash, Savings Vault), and your 5 most recent entries.',
    bg: 'var(--surface-container-highest)', iconColor: 'var(--primary)', tag: null,
    image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDUdBFZXblYx6dZv932zRFzoSD5SSRoFBO_mu1oEUaWFj0AkHe6LKnTxJmgIARxN2JS79iVYHUgvIz6svQIHfOR0_y1kt8ueiBDPftkmlCuvBXNsqOUzwOiOUuQDenlSb11NzpNYsU84Zx1t-fhrseSK2stzAyPbRWeOBTmS4qjqpovBWyNiAU-XyzG4bgTMZXlud0drlRYW4Eh07LLJyllLa_-zrhAEYlKjltvDFYuRW2xrOFKzrjAHNkMiUppJ9bA8dhJVopi3BM',
  },
  {
    icon: 'list_alt', title: 'All Entries',
    desc: 'Complete transaction archive. Filter by All, Income, Expense, or Transfer. Paginated 20 at a time. Swipe to delete with confirmation.',
    bg: 'rgba(188,241,161,0.18)', iconColor: 'var(--secondary)',
    tag: { label: 'Archive', color: 'var(--secondary)' },
  },
  {
    icon: 'volunteer_activism', title: 'Sacred Giving',
    desc: 'Auto-calculates your 10% tithe from income. Toggle All Time, Monthly, or Weekly (Sunday offering). One tap to initiate the transfer.',
    bg: 'rgba(255,150,143,0.13)', iconColor: 'var(--tertiary)', tag: null,
  },
  {
    icon: 'bar_chart', title: 'Insights',
    desc: 'Monthly income vs expense bar chart (last 6 months), spending-by-category donut, and top 5 expenditure breakdown with progress bars.',
    bg: 'var(--surface-container)', iconColor: 'var(--primary)', tag: null,
  },
  {
    icon: 'account_balance_wallet', title: 'Finance Hub',
    desc: 'Transfers between accounts, Savings Vault deposits, Debt tracking (I Owe / Owed to Me), Budget limits per category, and account management.',
    bg: 'var(--surface-container-high)', iconColor: 'var(--secondary)',
    tag: { label: '5 Tools', color: 'var(--primary)' },
  },
]

function SmallCard({ f, delay, visible }) {
  return (
    <div
      className={`feature-card anim-hidden${visible ? ` anim-scale-in ${delay}` : ''}`}
      style={{
        background: f.bg, padding: 28,
        border: '1px solid var(--outline-variant)',
        display: 'flex', flexDirection: 'column',
      }}
    >
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 16 }}>
        <span className="material-symbols-outlined" style={{
          fontSize: 34, color: f.iconColor,
          transition: 'transform 0.3s cubic-bezier(0.34,1.56,0.64,1)',
        }}
          onMouseEnter={e => e.currentTarget.style.transform = 'scale(1.2) rotate(-8deg)'}
          onMouseLeave={e => e.currentTarget.style.transform = 'scale(1) rotate(0deg)'}
        >{f.icon}</span>
        {f.tag && (
          <span className="font-label" style={{
            background: f.tag.color, color: '#fff',
            padding: '2px 10px', fontSize: 10,
            textTransform: 'uppercase', letterSpacing: '0.1em',
          }}>{f.tag.label}</span>
        )}
      </div>
      <h3 className="font-headline" style={{ fontSize: 19, fontWeight: 700, marginBottom: 8 }}>{f.title}</h3>
      <p style={{ color: 'var(--on-surface-variant)', fontSize: 13, lineHeight: 1.65 }}>{f.desc}</p>
    </div>
  )
}

export default function Features() {
  const [ref, visible] = useInView()
  const [hero, ...rest] = features

  return (
    <section id="features" ref={ref} style={{ padding: 'clamp(48px, 8vw, 96px) 24px', background: 'var(--surface-container-low)' }}>
      <div style={{ maxWidth: 1280, margin: '0 auto' }}>

        <div className={`anim-hidden${visible ? ' anim-fade-up delay-0' : ''}`} style={{ marginBottom: 'clamp(32px, 5vw, 56px)' }}>
          <span className="font-label" style={{
            color: 'var(--primary)', fontWeight: 700, fontSize: 11,
            textTransform: 'uppercase', letterSpacing: '0.25em', display: 'block', marginBottom: 10,
          }}>Five Tabs. One App.</span>
          <h2 className="font-headline" style={{ fontSize: 'clamp(28px, 4vw, 40px)', fontWeight: 700, marginBottom: 10 }}>
            Core Arcana
          </h2>
          <p style={{ color: 'var(--on-surface-variant)', maxWidth: 480 }}>
            Every screen in Mystic Ledger is purpose-built. Here is what lives inside.
          </p>
        </div>

        <div className="features-grid">

          {/* My Ledger — large hero card */}
          <div
            className={`feature-card feature-large anim-hidden${visible ? ' anim-slide-left delay-100' : ''}`}
            style={{
              background: hero.bg, padding: 32,
              border: '1px solid var(--outline-variant)',
              display: 'flex', flexDirection: 'column', justifyContent: 'flex-end',
              position: 'relative', overflow: 'hidden', minHeight: 300,
            }}
          >
            <img src={hero.image} alt="" aria-hidden="true" style={{
              position: 'absolute', top: 0, right: 0,
              width: 200, opacity: 0.08, pointerEvents: 'none',
              transition: 'opacity 0.4s, transform 0.4s',
            }} />
            {/* Mini balance chip */}
            <div style={{
              position: 'absolute', top: 24, right: 24,
              background: 'var(--surface-container-low)',
              border: '1px solid var(--outline-variant)',
              padding: '10px 16px', transform: 'rotate(1deg)',
              boxShadow: '0 4px 16px rgba(0,0,0,0.06)',
            }}>
              <p className="font-label" style={{ fontSize: 9, textTransform: 'uppercase', color: 'var(--on-surface-variant)', marginBottom: 2 }}>Total Balance</p>
              <p className="font-headline" style={{ fontSize: 20, fontWeight: 900, color: 'var(--primary)' }}>ETB 24,830.00</p>
            </div>
            <span className="material-symbols-outlined" style={{
              fontSize: 52, color: hero.iconColor, marginBottom: 18,
              transition: 'transform 0.3s cubic-bezier(0.34,1.56,0.64,1)',
            }}
              onMouseEnter={e => e.currentTarget.style.transform = 'scale(1.15) rotate(-5deg)'}
              onMouseLeave={e => e.currentTarget.style.transform = 'scale(1) rotate(0deg)'}
            >{hero.icon}</span>
            <h3 className="font-headline" style={{ fontSize: 28, fontWeight: 700, marginBottom: 12 }}>{hero.title}</h3>
            <p style={{ color: 'var(--on-surface-variant)', maxWidth: 340, lineHeight: 1.65, fontSize: 14 }}>{hero.desc}</p>
          </div>

          {/* All Entries — wide */}
          <div
            className={`feature-card feature-wide anim-hidden${visible ? ' anim-fade-up delay-200' : ''}`}
            style={{
              background: rest[0].bg, padding: 28,
              border: '1px solid var(--outline-variant)',
              display: 'flex', flexDirection: 'column',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 16 }}>
              <span className="material-symbols-outlined" style={{ fontSize: 34, color: rest[0].iconColor }}>{rest[0].icon}</span>
              <span className="font-label" style={{
                background: rest[0].tag.color, color: '#fff',
                padding: '2px 10px', fontSize: 10, textTransform: 'uppercase', letterSpacing: '0.1em',
              }}>{rest[0].tag.label}</span>
            </div>
            <div style={{ display: 'flex', gap: 6, marginBottom: 14, flexWrap: 'wrap' }}>
              {['All', 'Income', 'Expense', 'Transfer'].map((f, i) => (
                <span key={f} className="font-label" style={{
                  fontSize: 9, textTransform: 'uppercase', letterSpacing: '0.08em',
                  padding: '3px 10px',
                  background: i === 0 ? 'var(--primary)' : 'var(--surface-container)',
                  color: i === 0 ? '#fff' : 'var(--on-surface-variant)',
                  borderRadius: 99,
                  transition: 'background 0.2s, color 0.2s',
                  cursor: 'default',
                }}
                  onMouseEnter={e => { if (i !== 0) { e.currentTarget.style.background = 'var(--primary)'; e.currentTarget.style.color = '#fff' } }}
                  onMouseLeave={e => { if (i !== 0) { e.currentTarget.style.background = 'var(--surface-container)'; e.currentTarget.style.color = 'var(--on-surface-variant)' } }}
                >{f}</span>
              ))}
            </div>
            <h3 className="font-headline" style={{ fontSize: 19, fontWeight: 700, marginBottom: 8 }}>{rest[0].title}</h3>
            <p style={{ color: 'var(--on-surface-variant)', fontSize: 13, lineHeight: 1.65 }}>{rest[0].desc}</p>
          </div>

          <SmallCard f={rest[1]} delay="delay-300" visible={visible} />
          <SmallCard f={rest[2]} delay="delay-400" visible={visible} />
          <SmallCard f={rest[3]} delay="delay-500" visible={visible} />

        </div>
      </div>
    </section>
  )
}
