import { useInView } from '../hooks/useInView'

const steps = [
  {
    num: 'I', icon: 'account_balance_wallet', color: 'var(--primary)',
    title: 'Add Your Vessels',
    desc: 'Create your accounts — Bank, Mobile Money (Telebirr), Cash, or Savings Vault. Each one becomes a named vessel inside Mystic Ledger.',
    detail: 'Bank · Telebirr · Cash · Savings Vault',
  },
  {
    num: 'II', icon: 'edit_note', color: 'var(--secondary)',
    title: 'Record Every Flow',
    desc: 'Log income and expenses with real categories: Sustenance, Carriage, The Hearth, Vices & Joy, Tithe, Salary, Freelance, and Miscellany.',
    detail: 'Income · Expense · Transfer',
  },
  {
    num: 'III', icon: 'auto_graph', color: 'var(--tertiary)',
    title: 'Observe the Essence',
    desc: 'Watch your monthly bar charts, category donut, tithe calculations, and debt overview update in real time. Your financial story writes itself.',
    detail: 'Charts · Tithe · Budgets · Debts',
  },
]

export default function HowItWorks() {
  const [ref, visible] = useInView()

  return (
    <section id="how" ref={ref} style={{
      padding: 'clamp(48px, 8vw, 96px) 24px',
      background: 'var(--surface-container-high)',
      borderTop: '2px solid var(--outline-variant)',
      borderBottom: '2px solid var(--outline-variant)',
      overflow: 'hidden',
    }}>
      <div style={{ maxWidth: 1280, margin: '0 auto' }}>

        <div className={`anim-hidden${visible ? ' anim-fade-up delay-0' : ''}`}
          style={{ textAlign: 'center', marginBottom: 'clamp(40px, 6vw, 72px)' }}>
          <span className="font-label" style={{
            color: 'var(--primary)', fontWeight: 700, fontSize: 11,
            textTransform: 'uppercase', letterSpacing: '0.25em', display: 'block', marginBottom: 10,
          }}>Three movements</span>
          <h2 className="font-headline" style={{ fontSize: 'clamp(28px, 4vw, 40px)', fontWeight: 700, marginBottom: 12 }}>
            The Ritual of Record
          </h2>
          <p style={{ color: 'var(--on-surface-variant)', maxWidth: 440, margin: '0 auto' }}>
            From first account to full financial clarity — here is how Mystic Ledger works.
          </p>
        </div>

        <div style={{ position: 'relative' }}>
          <div className="connector-line" />
          <div className="steps-grid">
            {steps.map((step, i) => (
              <div
                key={step.title}
                className={`step-card ghost-border anim-hidden${visible ? ` anim-fade-up delay-${(i + 1) * 200}` : ''}`}
                style={{
                  background: 'var(--surface)',
                  padding: 'clamp(24px, 4vw, 40px)',
                  border: '1px solid var(--outline-variant)',
                  textAlign: 'center',
                  display: 'flex', flexDirection: 'column', alignItems: 'center',
                }}
              >
                <div
                  className="step-icon-ring"
                  style={{
                    width: 64, height: 64,
                    background: step.color, color: '#fff',
                    borderRadius: '50%',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    marginBottom: 24,
                    boxShadow: '0 8px 24px rgba(0,0,0,0.15)',
                  }}
                >
                  <span className="material-symbols-outlined" style={{ fontSize: 28 }}>{step.icon}</span>
                </div>
                <h3 className="font-headline" style={{ fontSize: 21, fontWeight: 700, marginBottom: 12 }}>{step.title}</h3>
                <p style={{ color: 'var(--on-surface-variant)', fontSize: 14, lineHeight: 1.7, marginBottom: 20 }}>{step.desc}</p>
                <div style={{
                  marginTop: 'auto', padding: '6px 14px',
                  background: 'var(--surface-container)',
                  border: '1px solid var(--outline-variant)',
                }}>
                  <p className="font-label" style={{ fontSize: 10, textTransform: 'uppercase', letterSpacing: '0.1em', color: step.color }}>
                    {step.detail}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>

      </div>
    </section>
  )
}
