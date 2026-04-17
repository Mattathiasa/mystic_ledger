import Navbar from './components/Navbar'
import Hero from './components/Hero'
import Stats from './components/Stats'
import Features from './components/Features'
import Testimonials from './components/Testimonials'
import AppPreview from './components/AppPreview'
import HowItWorks from './components/HowItWorks'
import FAQ from './components/FAQ'
import Download from './components/Download'
import Footer from './components/Footer'

export default function App() {
  return (
    <>
      <Navbar />
      <main>
        <Hero />
        <Stats />
        <Features />
        <AppPreview />
        <Testimonials />
        <HowItWorks />
        <FAQ />
        <Download />
      </main>
      <Footer />
    </>
  )
}
