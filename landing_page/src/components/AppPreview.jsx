import { useState } from 'react'
import { useInView } from '../hooks/useInView'

const accounts = [
  { label: 'CBE Bank',  badge: 'Bank',         balance: 'ETB 14,200.00', icon: 'account_balance',        color: 'var(--primary)',   bg: 'rgba(115,92,0,0.1)' },
  { label: 'Telebirr',  badge: 'Mobile Money',  balance: 'ETB 3,150.00',  icon: 'account_balance_wallet', color: 'var(--secondary)', bg: 'rgba(60,105,41,0.1)' },
]

const transactions = [
  { icon: 'work',           iconBg: 'rgba(188,241,161,0.4)',  iconColor: 'var(--secondary)', label: 'Salary',      category: 'Salary',    date: '14 APR 2024', amount: '+ETB 8,500', amountColor: 'var(--secondary)' },
  { icon: 'restaurant',     iconBg: 'rgba(255,150,143,0.2)',  iconColor: 'var(--tertiary)',  label: 'Sustenance',  category: 'Food',      date: '13 APR 2024', amount: '-ETB 320',   amountColor: 'var(--tertiary)' },
  { icon: 'directions_car', iconBg: 'rgba(255,150,143,0.15)', iconColor: 'var(--tertiary)',  label: 'Carriage',    category: 'Transport', date: '12 APR 2024', amount: '-ETB 180',   amountColor: 'var(--tertiary)' },
]

const perks = [
  { num: 'I',   icon: 'account_balance',    title: 'Multi-Account Tracking',        desc: 'Bank, Mobile Money (Telebirr), Cash, and Savings Vault — all in one app. See every balance in a single view.' },
  { num: 'II',  icon: 'volunteer_activism', title: 'Sacred Giving Built In',        desc: 'Auto-calculates your 10% tithe from income. All Time, Monthly, or Weekly (Sunday offering). No spreadsheet needed.' },
  { num: 'III', icon: 'cloud_sync',         title: 'Offline-First, Firebase-Synced', desc: 'Works without internet. Every entry is saved locally and syncs to Firebase the moment you reconnect.' },
]

// ── Screen renderers ───────────────────────────────────────────────────────────

function ScreenLedger() {
  return (
    <div style={{ height: '100%', padding: '36px 14px 14px', overflowY: 'auto' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
        <span className="material-symbols-outlined" style={{ color: 'var(--primary)', fontSize: 20 }}>menu</span>
        <span className="font-headline" style={{ fontWeight: 700, fontSize: 13, fontStyle: 'italic' }}>My Ledger</span>
        <span className="material-symbols-outlined" style={{ color: 'var(--primary)', fontSize: 20 }}>person</span>
      </div>
      <p className="font-label" style={{ fontSize: 8, textTransform: 'uppercase', letterSpacing: '0.15em', color: 'var(--on-surface-variant)', opacity: 0.7, marginBottom: 4 }}>CURRENT OBSERVATIONS</p>
      <div style={{ marginBottom: 16 }}>
        <p className="font-headline" style={{ fontSize: 26, fontWeight: 900, lineHeight: 1.1 }}>
          ETB <span style={{ color: 'var(--primary)' }}>24,830</span>
          <span style={{ fontSize: 13, fontWeight: 400 }}>.00</span>
        </p>
        <div style={{ marginTop: 6, padding: '6px 10px', borderLeft: '2px solid var(--primary-container)' }}>
          <p style={{ fontSize: 9, fontStyle: 'italic', color: 'var(--on-surface-variant)', lineHeight: 1.4 }}>"The ledger reflects a prosperous season."</p>
        </div>
      </div>
      <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
        {accounts.map(a => (
          <div key={a.label} style={{ flex: 1, padding: '10px', background: 'var(--surface-container)', borderRadius: 10, border: '1px solid var(--outline-variant)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 8 }}>
              <div style={{ width: 22, height: 22, borderRadius: 6, background: a.bg, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <span className="material-symbols-outlined" style={{ fontSize: 12, color: a.color }}>{a.icon}</span>
              </div>
              <p className="font-label" style={{ fontSize: 8, letterSpacing: '0.05em', color: 'var(--on-surface-variant)' }}>{a.badge}</p>
            </div>
            <p style={{ fontWeight: 700, fontSize: 10 }}>{a.label}</p>
            <p style={{ fontWeight: 800, fontSize: 11, color: a.color }}>{a.balance}</p>
          </div>
        ))}
      </div>
      <p className="font-headline" style={{ fontSize: 13, fontWeight: 700, fontStyle: 'italic', marginBottom: 8 }}>Recent Entries</p>
      {transactions.map((t) => (
        <div key={t.label} className="ledger-underline" style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '7px 0' }}>
          <div style={{ width: 28, height: 28, borderRadius: '50%', background: t.iconBg, flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <span className="material-symbols-outlined" style={{ fontSize: 13, color: t.iconColor }}>{t.icon}</span>
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <p style={{ fontWeight: 700, fontSize: 10, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{t.label}</p>
            <p className="font-label" style={{ fontSize: 8, color: 'var(--on-surface-variant)' }}>{t.category} · {t.date}</p>
          </div>
          <p style={{ fontWeight: 800, fontSize: 10, color: t.amountColor, flexShrink: 0 }}>{t.amount}</p>
        </div>
      ))}
    </div>
  )
}

function ScreenEntries() {
  const [active, setActive] = useState('All')
  const tabs = ['All', 'Income', 'Expense', 'Transfer']
  return (
    <div style={{ height: '100%', padding: '36px 14px 14px', overflowY: 'auto' }}>
      <p className="font-headline" style={{ fontWeight: 700, fontSize: 14, fontStyle: 'italic', marginBottom: 12, textAlign: 'center' }}>All Entries</p>
      <div style={{ display: 'flex', gap: 5, marginBottom: 14, flexWrap: 'wrap' }}>
        {tabs.map(t => (
          <span key={t} onClick={() => setActive(t)} className="font-label" style={{
            fontSize: 9, textTransform: 'uppercase', letterSpacing: '0.08em',
            padding: '3px 10px', borderRadius: 99, cursor: 'pointer',
            background: active === t ? 'var(--primary)' : 'var(--surface-container)',
            color: active === t ? '#fff' : 'var(--on-surface-variant)',
            transition: 'background 0.2s, color 0.2s',
          }}>{t}</span>
        ))}
      </div>
      {transactions.filter(t => {
        if (active === 'Income') return t.amountColor === 'var(--secondary)'
        if (active === 'Expense') return t.amountColor === 'var(--tertiary)'
        if (active === 'Transfer') return false
        return true
      }).map((t, i) => (
        <div key={i} className="ledger-underline" style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '8px 0' }}>
          <div style={{ width: 28, height: 28, borderRadius: '50%', background: t.iconBg, flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <span className="material-symbols-outlined" style={{ fontSize: 13, color: t.iconColor }}>{t.icon}</span>
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <p style={{ fontWeight: 700, fontSize: 10 }}>{t.label}</p>
            <p className="font-label" style={{ fontSize: 8, color: 'var(--on-surface-variant)' }}>{t.date}</p>
          </div>
          <p style={{ fontWeight: 800, fontSize: 10, color: t.amountColor }}>{t.amount}</p>
        </div>
      ))}
      {active === 'Transfer' && (
        <p style={{ textAlign: 'center', fontSize: 10, color: 'var(--on-surface-variant)', marginTop: 24, fontStyle: 'italic' }}>No transfers yet.</p>
      )}
    </div>
  )
}

function ScreenInsights() {
  const bars = [
    { month: 'Nov', inc: 68, exp: 45 },
    { month: 'Dec', inc: 72, exp: 60 },
    { month: 'Jan', inc: 65, exp: 38 },
    { month: 'Feb', inc: 80, exp: 55 },
    { month: 'Mar', inc: 70, exp: 42 },
    { month: 'Apr', inc: 85, exp: 50 },
  ]
  const cats = [
    { label: 'Food', pct: 35, color: 'var(--tertiary)' },
    { label: 'Transport', pct: 20, color: 'var(--primary)' },
    { label: 'Hearth', pct: 25, color: 'var(--secondary)' },
    { label: 'Other', pct: 20, color: '#a8a29e' },
  ]
  return (
    <div style={{ height: '100%', padding: '36px 14px 14px', overflowY: 'auto' }}>
      <p className="font-headline" style={{ fontWeight: 700, fontSize: 14, fontStyle: 'italic', marginBottom: 12, textAlign: 'center' }}>Insights</p>
      <p className="font-label" style={{ fontSize: 8, textTransform: 'uppercase', letterSpacing: '0.1em', color: 'var(--on-surface-variant)', marginBottom: 8 }}>Last 6 Months</p>
      {/* Bar chart */}
      <div style={{ display: 'flex', gap: 6, alignItems: 'flex-end', height: 70, marginBottom: 6 }}>
        {bars.map(b => (
          <div key={b.month} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2 }}>
            <div style={{ width: '100%', display: 'flex', gap: 1, alignItems: 'flex-end', height: 58 }}>
              <div style={{ flex: 1, background: 'rgba(60,105,41,0.55)', height: `${b.inc}%`, borderRadius: '2px 2px 0 0', transition: 'height 0.6s ease' }} />
              <div style={{ flex: 1, background: 'rgba(173,48,47,0.55)', height: `${b.exp}%`, borderRadius: '2px 2px 0 0', transition: 'height 0.6s ease' }} />
            </div>
            <p style={{ fontSize: 7, color: 'var(--on-surface-variant)' }}>{b.month}</p>
          </div>
        ))}
      </div>
      <div style={{ display: 'flex', gap: 10, marginBottom: 14 }}>
        {[['Income', 'var(--secondary)'], ['Expense', 'var(--tertiary)']].map(([l, c]) => (
          <div key={l} style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
            <div style={{ width: 8, height: 8, background: c, borderRadius: 2 }} />
            <p style={{ fontSize: 8, color: 'var(--on-surface-variant)' }}>{l}</p>
          </div>
        ))}
      </div>
      <p className="font-label" style={{ fontSize: 8, textTransform: 'uppercase', letterSpacing: '0.1em', color: 'var(--on-surface-variant)', marginBottom: 8 }}>Spending by Category</p>
      {cats.map(c => (
        <div key={c.label} style={{ marginBottom: 7 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 2 }}>
            <p style={{ fontSize: 9 }}>{c.label}</p>
            <p style={{ fontSize: 9, color: c.color, fontWeight: 700 }}>{c.pct}%</p>
          </div>
          <div style={{ height: 4, background: 'var(--surface-container)', borderRadius: 99 }}>
            <div style={{ height: '100%', width: `${c.pct}%`, background: c.color, borderRadius: 99, transition: 'width 0.8s ease' }} />
          </div>
        </div>
      ))}
    </div>
  )
}

function ScreenTithe() {
  const [period, setPeriod] = useState('Monthly')
  const periods = ['All Time', 'Monthly', 'Weekly']
  const incomes = { 'All Time': 48500, Monthly: 8500, Weekly: 2125 }
  const tithe = (incomes[period] * 0.1).toFixed(2)
  return (
    <div style={{ height: '100%', padding: '36px 14px 14px', overflowY: 'auto' }}>
      <p className="font-headline" style={{ fontWeight: 700, fontSize: 14, fontStyle: 'italic', marginBottom: 12, textAlign: 'center' }}>Sacred Giving</p>
      <div style={{ display: 'flex', gap: 5, marginBottom: 20 }}>
        {periods.map(p => (
          <span key={p} onClick={() => setPeriod(p)} className="font-label" style={{
            fontSize: 8, textTransform: 'uppercase', letterSpacing: '0.06em',
            padding: '3px 8px', borderRadius: 99, cursor: 'pointer',
            background: period === p ? 'var(--tertiary)' : 'var(--surface-container)',
            color: period === p ? '#fff' : 'var(--on-surface-variant)',
            transition: 'background 0.2s',
          }}>{p}</span>
        ))}
      </div>
      <div style={{ textAlign: 'center', padding: '20px', background: 'rgba(173,48,47,0.06)', border: '1px solid rgba(173,48,47,0.2)', marginBottom: 16 }}>
        <span className="material-symbols-outlined" style={{ fontSize: 32, color: 'var(--tertiary)', marginBottom: 8, display: 'block', fontVariationSettings: "'FILL' 1" }}>volunteer_activism</span>
        <p className="font-label" style={{ fontSize: 8, textTransform: 'uppercase', letterSpacing: '0.12em', color: 'var(--on-surface-variant)', marginBottom: 4 }}>10% Tithe ({period})</p>
        <p className="font-headline" style={{ fontSize: 22, fontWeight: 900, color: 'var(--tertiary)' }}>ETB {(+tithe).toLocaleString()}</p>
        <p style={{ fontSize: 9, color: 'var(--on-surface-variant)', marginTop: 4 }}>from ETB {incomes[period].toLocaleString()}</p>
      </div>
      <div style={{ padding: '10px 14px', background: 'var(--surface-container)', border: '1px solid var(--outline-variant)', display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer' }}>
        <span className="material-symbols-outlined" style={{ fontSize: 14, color: 'var(--tertiary)' }}>send</span>
        <p style={{ fontSize: 10, fontWeight: 700 }}>Initiate Tithe Transfer</p>
      </div>
    </div>
  )
}

function ScreenHub() {
  const tools = [
    { icon: 'swap_horiz',    label: 'Transfer',    color: 'var(--primary)'   },
    { icon: 'savings',       label: 'Vault',       color: 'var(--secondary)' },
    { icon: 'credit_card',   label: 'Debt',        color: 'var(--tertiary)'  },
    { icon: 'bar_chart',     label: 'Budget',      color: 'var(--primary)'   },
    { icon: 'manage_accounts', label: 'Accounts',  color: 'var(--secondary)' },
  ]
  return (
    <div style={{ height: '100%', padding: '36px 14px 14px', overflowY: 'auto' }}>
      <p className="font-headline" style={{ fontWeight: 700, fontSize: 14, fontStyle: 'italic', marginBottom: 16, textAlign: 'center' }}>Finance Hub</p>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
        {tools.map((t) => (
          <div key={t.label} style={{
            padding: '14px 10px', textAlign: 'center',
            background: 'var(--surface-container)',
            border: '1px solid var(--outline-variant)',
            cursor: 'pointer',
            transition: 'background 0.2s, transform 0.2s',
          }}
            onMouseEnter={e => { e.currentTarget.style.background = 'var(--surface-container-high)'; e.currentTarget.style.transform = 'translateY(-2px)' }}
            onMouseLeave={e => { e.currentTarget.style.background = 'var(--surface-container)'; e.currentTarget.style.transform = 'translateY(0)' }}
          >
            <span className="material-symbols-outlined" style={{ fontSize: 22, color: t.color, display: 'block', marginBottom: 6 }}>{t.icon}</span>
            <p style={{ fontSize: 9, fontWeight: 700 }}>{t.label}</p>
          </div>
        ))}
      </div>
      <div style={{ marginTop: 14, padding: '10px', background: 'rgba(60,105,41,0.08)', border: '1px solid rgba(60,105,41,0.2)' }}>
        <p className="font-label" style={{ fontSize: 8, textTransform: 'uppercase', letterSpacing: '0.1em', color: 'var(--secondary)', marginBottom: 4 }}>Savings Vault</p>
        <p className="font-headline" style={{ fontSize: 18, fontWeight: 900, color: 'var(--secondary)' }}>ETB 7,480.00</p>
        <p style={{ fontSize: 8, color: 'var(--on-surface-variant)', marginTop: 2 }}>Goal: ETB 20,000 · 37% reached</p>
        <div style={{ height: 4, background: 'var(--surface-container)', borderRadius: 99, marginTop: 6 }}>
          <div style={{ height: '100%', width: '37%', background: 'var(--secondary)', borderRadius: 99 }} />
        </div>
      </div>
    </div>
  )
}

const TABS = [
  { id: 'ledger',  icon: 'auto_stories',          label: 'My Ledger'   },
  { id: 'entries', icon: 'list_alt',               label: 'Entries'     },
  { id: 'insights',icon: 'bar_chart',              label: 'Insights'    },
  { id: 'tithe',   icon: 'volunteer_activism',     label: 'Giving'      },
  { id: 'hub',     icon: 'account_balance_wallet', label: 'Hub'         },
]

const SCREENS = { ledger: ScreenLedger, entries: ScreenEntries, insights: ScreenInsights, tithe: ScreenTithe, hub: ScreenHub }

function PhoneMockup({ activeTab }) {
  const [prev, setPrev] = useState(activeTab)
  const [animating, setAnimating] = useState(false)
  const [currentTab, setCurrentTab] = useState(activeTab)

  // When activeTab changes, run slide transition
  if (activeTab !== currentTab && !animating) {
    setAnimating(true)
    setTimeout(() => {
      setCurrentTab(activeTab)
      setPrev(activeTab)
      setAnimating(false)
    }, 220)
  }

  const Screen = SCREENS[currentTab] || ScreenLedger

  return (
    <div className="float-phone" style={{
      width: 280, height: 600,
      background: '#1c1917', borderRadius: 44,
      border: '7px solid #292524',
      boxShadow: '0 48px 96px rgba(0,0,0,0.4)',
      overflow: 'hidden', position: 'relative',
      margin: '0 auto', flexShrink: 0,
    }}>
      {/* Notch */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0,
        height: 22, background: '#292524', borderRadius: '0 0 14px 14px',
        zIndex: 20, display: 'flex', justifyContent: 'center', alignItems: 'center',
      }}>
        <div style={{ width: 72, height: 14, background: '#1c1917', borderRadius: 99 }} />
      </div>

      {/* Screen content */}
      <div style={{
        background: 'var(--background)', height: '100%',
        transform: animating ? 'translateX(-18px)' : 'translateX(0)',
        opacity: animating ? 0 : 1,
        transition: 'transform 0.22s ease, opacity 0.22s ease',
      }}>
        <Screen />
      </div>

      {/* Bottom tab bar */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0,
        background: '#1c1917', borderTop: '1px solid #292524',
        display: 'flex', padding: '6px 0 8px',
        zIndex: 20,
      }}>
        {TABS.map(t => (
          <div key={t.id} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2 }}>
            <span className="material-symbols-outlined" style={{
              fontSize: 16,
              color: currentTab === t.id ? '#D4AF37' : '#78716c',
              fontVariationSettings: currentTab === t.id ? "'FILL' 1" : "'FILL' 0",
            }}>{t.icon}</span>
            <span style={{ fontSize: 6, color: currentTab === t.id ? '#D4AF37' : '#78716c', fontFamily: 'Space Grotesk' }}>{t.label}</span>
          </div>
        ))}
      </div>
    </div>
  )
}

export default function AppPreview() {
  const [ref, visible] = useInView()
  const [activeTab, setActiveTab] = useState('ledger')

  return (
    <section ref={ref} style={{ padding: 'clamp(48px, 8vw, 96px) 24px', background: 'var(--surface)' }}>
      <div style={{ maxWidth: 1280, margin: '0 auto' }}>

        <div className={`anim-hidden${visible ? ' anim-fade-up delay-0' : ''}`}
          style={{ textAlign: 'center', marginBottom: 'clamp(28px, 4vw, 48px)' }}>
          <span className="font-label" style={{
            color: 'var(--primary)', fontWeight: 700, fontSize: 11,
            textTransform: 'uppercase', letterSpacing: '0.25em', display: 'block', marginBottom: 10,
          }}>Built for real life</span>
          <h2 className="font-headline" style={{ fontSize: 'clamp(28px, 4vw, 46px)', fontWeight: 700, lineHeight: 1.15 }}>
            The Ledger in Your Pocket
          </h2>
        </div>

        {/* Tab switcher */}
        <div className={`anim-hidden${visible ? ' anim-fade-up delay-100' : ''}`}
          style={{ display: 'flex', justifyContent: 'center', gap: 8, marginBottom: 40, flexWrap: 'wrap' }}>
          {TABS.map(t => (
            <button
              key={t.id}
              onClick={() => setActiveTab(t.id)}
              style={{
                display: 'flex', alignItems: 'center', gap: 7,
                padding: '8px 16px',
                background: activeTab === t.id ? 'var(--primary)' : 'var(--surface-container)',
                color: activeTab === t.id ? '#fff' : 'var(--on-surface-variant)',
                border: activeTab === t.id ? '1px solid var(--primary)' : '1px solid var(--outline-variant)',
                fontFamily: 'Space Grotesk, sans-serif', fontWeight: 700, fontSize: 12,
                cursor: 'pointer',
                transition: 'background 0.2s, color 0.2s, transform 0.2s, border-color 0.2s',
                transform: activeTab === t.id ? 'translateY(-2px)' : 'translateY(0)',
                boxShadow: activeTab === t.id ? '0 6px 20px rgba(115,92,0,0.2)' : 'none',
              }}
              onMouseEnter={e => { if (activeTab !== t.id) { e.currentTarget.style.background = 'var(--surface-container-high)'; e.currentTarget.style.transform = 'translateY(-1px)' } }}
              onMouseLeave={e => { if (activeTab !== t.id) { e.currentTarget.style.background = 'var(--surface-container)'; e.currentTarget.style.transform = 'translateY(0)' } }}
            >
              <span className="material-symbols-outlined" style={{
                fontSize: 15,
                fontVariationSettings: activeTab === t.id ? "'FILL' 1" : "'FILL' 0",
              }}>{t.icon}</span>
              {t.label}
            </button>
          ))}
        </div>

        <div className="preview-grid">
          <div className={`anim-hidden${visible ? ' anim-slide-left delay-200' : ''}`}>
            <PhoneMockup activeTab={activeTab} />
          </div>

          <div className={`preview-perks anim-hidden${visible ? ' anim-slide-right delay-300' : ''}`}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
              {perks.map((p, i) => (
                <div
                  key={p.num}
                  className={`perk-row anim-hidden${visible ? ` anim-fade-up delay-${(i + 4) * 100}` : ''}`}
                  style={{ display: 'flex', gap: 20 }}
                >
                  <div style={{
                    flexShrink: 0, width: 48, height: 48,
                    border: '1px solid var(--outline)',
                    background: 'var(--surface-container)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontFamily: 'Epilogue, sans-serif', fontWeight: 700, fontSize: 16,
                    transition: 'background 0.2s, border-color 0.2s, color 0.2s',
                    cursor: 'default',
                  }}
                    onMouseEnter={e => { e.currentTarget.style.background = 'var(--primary)'; e.currentTarget.style.color = '#fff'; e.currentTarget.style.borderColor = 'var(--primary)' }}
                    onMouseLeave={e => { e.currentTarget.style.background = 'var(--surface-container)'; e.currentTarget.style.color = 'var(--on-surface)'; e.currentTarget.style.borderColor = 'var(--outline)' }}
                  >
                    {p.num}
                  </div>
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
                      <span className="material-symbols-outlined" style={{ fontSize: 18, color: 'var(--primary)' }}>{p.icon}</span>
                      <h4 className="font-headline" style={{ fontSize: 17, fontWeight: 700 }}>{p.title}</h4>
                    </div>
                    <p style={{ color: 'var(--on-surface-variant)', lineHeight: 1.7, fontSize: 14 }}>{p.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
