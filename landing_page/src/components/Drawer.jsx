export default function Drawer({ open, onClose, activeId = 'hero' }) {
  return (
    <>
      {/* Backdrop */}
      <div
        onClick={onClose}
        style={{
          position: 'fixed', inset: 0, zIndex: 55,
          background: 'rgba(0,0,0,0.3)',
          opacity: open ? 1 : 0,
          pointerEvents: open ? 'auto' : 'none',
          transition: 'opacity 0.3s',
        }}
      />

      {/* Drawer panel */}
      <div style={{
        position: 'fixed', insetY: 0, left: 0, top: 0, bottom: 0,
        zIndex: 60,
        width: 300,
        background: '#F5F5DC',
        boxShadow: '4px 0 24px rgba(0,0,0,0.15)',
        transform: open ? 'translateX(0)' : 'translateX(-100%)',
        transition: 'transform 0.3s ease-in-out',
        display: 'flex',
        flexDirection: 'column',
      }}>
        <div style={{ padding: '24px', borderBottom: '1px solid #d6d3c4', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span className="font-headline" style={{ fontSize: 18, fontWeight: 700 }}>Mystic Ledger</span>
          <button onClick={onClose} style={{ background: 'none', border: 'none', cursor: 'pointer' }}>
            <span className="material-symbols-outlined">close</span>
          </button>
        </div>

        <nav style={{ flex: 1, paddingTop: 8 }}>
          {[
            { icon: 'history_edu', label: 'The Ledger',  href: '#hero',     id: 'hero'     },
            { icon: 'query_stats', label: 'Features',     href: '#features', id: 'features' },
            { icon: 'auto_graph',  label: 'How It Works', href: '#how',      id: 'how'      },
            { icon: 'download',    label: 'Download',     href: '#download', id: 'download' },
          ].map(({ icon, label, href, id }) => {
            const active = activeId === id
            return (
              <a key={label} href={href} onClick={onClose} style={{
                display: 'flex', alignItems: 'center', gap: 16,
                padding: '14px 24px',
                fontFamily: 'Epilogue, sans-serif',
                fontWeight: active ? 700 : 400,
                color: active ? '#D4AF37' : '#57534e',
                background: active ? 'rgba(212,175,55,0.1)' : 'transparent',
                textDecoration: 'none',
                borderRight: active ? '3px solid #D4AF37' : '3px solid transparent',
                transition: 'background 0.2s, color 0.2s',
              }}>
                <span className="material-symbols-outlined" style={{ color: active ? '#D4AF37' : '#78716c', transition: 'color 0.2s' }}>{icon}</span>
                {label}
              </a>
            )
          })}
        </nav>

        <div style={{ padding: 24, borderTop: '1px solid #d6d3c4' }}>
          <button className="ghost-border" style={{
            width: '100%', padding: '12px',
            background: 'var(--primary)', color: '#fff',
            border: 'none', fontFamily: 'Space Grotesk', fontWeight: 700,
            cursor: 'pointer', fontSize: 14,
          }}>Open the Journal</button>
        </div>
      </div>
    </>
  )
}
