import { useState, useRef } from 'react'
import { useInView } from '../hooks/useInView'

const FAQS = [
  {
    q: 'Is Mystic Ledger free to use?',
    a: 'Yes — completely free to begin. Every core feature (accounts, entries, tithe, insights, and finance hub) is available at no cost. There are no ads, no paywalls, and no hidden charges.',
  },
  {
    q: 'Does it work without an internet connection?',
    a: 'Absolutely. Mystic Ledger is offline-first. All your data is stored locally on your device. When you reconnect, everything syncs automatically to Firebase in the background — no action needed from you.',
  },
  {
    q: 'What currencies does the app support?',
    a: 'The app is built around Ethiopian Birr (ETB) as the primary currency, with native formatting and display throughout. Support for additional currencies is on the roadmap.',
  },
  {
    q: 'How does the tithe calculator work?',
    a: 'Sacred Giving automatically totals all your income entries and calculates 10%. You can switch between All Time, Monthly, or Weekly (Sunday offering) views. One tap initiates the transfer to your chosen account.',
  },
  {
    q: 'Is my financial data secure?',
    a: 'Your data is encrypted both locally and in Firebase. We never sell your data or share it with third parties. You own your ledger — always.',
  },
  {
    q: 'When is the iOS version available?',
    a: 'The Android APK is available now. The iOS App Store release is actively in development. Drop your email in the waitlist below and we will notify you the moment it lands.',
  },
  {
    q: 'Can I track debts and money I am owed?',
    a: 'Yes. The Finance Hub includes a dedicated Debt tracker with two sides: "I Owe" and "Owed to Me". Each entry shows the person, amount, and date — so you never lose track of an obligation.',
  },
]

function AccordionItem({ faq, open, onToggle, delay, visible }) {
  const bodyRef = useRef(null)

  return (
    <div
      className={`anim-hidden${visible ? ` anim-fade-up ${delay}` : ''}`}
      style={{
        borderBottom: '1px solid var(--outline-variant)',
        background: open ? 'var(--surface-container)' : 'var(--surface)',
        transition: 'background 0.3s',
      }}
    >
      <button
        onClick={onToggle}
        style={{
          width: '100%', textAlign: 'left', padding: '22px 24px',
          background: 'none', border: 'none', cursor: 'pointer',
          display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 16,
        }}
      >
        <span className="font-headline" style={{
          fontSize: 'clamp(15px, 1.8vw, 17px)', fontWeight: 700,
          color: open ? 'var(--primary)' : 'var(--on-surface)',
          transition: 'color 0.2s',
        }}>
          {faq.q}
        </span>
        <span className="material-symbols-outlined" style={{
          fontSize: 22, color: open ? 'var(--primary)' : 'var(--on-surface-variant)',
          transform: open ? 'rotate(45deg)' : 'rotate(0deg)',
          transition: 'transform 0.3s cubic-bezier(0.22,1,0.36,1), color 0.2s',
          flexShrink: 0,
        }}>add</span>
      </button>

      {/* Animated body */}
      <div style={{
        display: 'grid',
        gridTemplateRows: open ? '1fr' : '0fr',
        transition: 'grid-template-rows 0.35s cubic-bezier(0.22,1,0.36,1)',
      }}>
        <div style={{ overflow: 'hidden' }}>
          <p style={{
            padding: '0 24px 22px',
            color: 'var(--on-surface-variant)',
            lineHeight: 1.8, fontSize: 14,
          }}>
            {faq.a}
          </p>
        </div>
      </div>
    </div>
  )
}

export default function FAQ() {
  const [ref, visible] = useInView()
  const [openIndex, setOpenIndex] = useState(0)

  return (
    <section id="faq" ref={ref} style={{
      padding: 'clamp(48px, 8vw, 96px) 24px',
      background: 'var(--surface-container-low)',
      borderTop: '1px solid var(--outline-variant)',
    }}>
      <div style={{ maxWidth: 860, margin: '0 auto' }}>

        <div className={`anim-hidden${visible ? ' anim-fade-up delay-0' : ''}`}
          style={{ textAlign: 'center', marginBottom: 'clamp(32px, 5vw, 56px)' }}>
          <span className="font-label" style={{
            color: 'var(--primary)', fontWeight: 700, fontSize: 11,
            textTransform: 'uppercase', letterSpacing: '0.25em', display: 'block', marginBottom: 10,
          }}>Questions & Answers</span>
          <h2 className="font-headline" style={{ fontSize: 'clamp(26px, 4vw, 38px)', fontWeight: 700, marginBottom: 12 }}>
            Frequently Asked
          </h2>
          <p style={{ color: 'var(--on-surface-variant)', maxWidth: 480, margin: '0 auto', lineHeight: 1.7 }}>
            Everything you need to know before opening your first entry.
          </p>
        </div>

        <div style={{ border: '1px solid var(--outline-variant)' }}>
          {FAQS.map((faq, i) => (
            <AccordionItem
              key={faq.q}
              faq={faq}
              open={openIndex === i}
              onToggle={() => setOpenIndex(openIndex === i ? -1 : i)}
              delay={`delay-${Math.min(i * 80, 500)}`}
              visible={visible}
            />
          ))}
        </div>

        <div className={`anim-hidden${visible ? ' anim-fade-up delay-500' : ''}`}
          style={{ textAlign: 'center', marginTop: 40 }}>
          <p style={{ color: 'var(--on-surface-variant)', fontSize: 14, marginBottom: 12 }}>
            Still have questions?
          </p>
          <a href="mailto:mattathiasabraham@gmail.com" style={{
            display: 'inline-flex', alignItems: 'center', gap: 8,
            color: 'var(--primary)', fontWeight: 700, fontFamily: 'Epilogue, sans-serif',
            textDecoration: 'none', fontSize: 14,
            borderBottom: '1px solid rgba(115,92,0,0.3)',
            paddingBottom: 2,
            transition: 'border-color 0.2s',
          }}
            onMouseEnter={e => e.currentTarget.style.borderColor = 'var(--primary)'}
            onMouseLeave={e => e.currentTarget.style.borderColor = 'rgba(115,92,0,0.3)'}
          >
            <span className="material-symbols-outlined" style={{ fontSize: 16 }}>mail</span>
            Consult the Scribes
          </a>
        </div>

      </div>
    </section>
  )
}
