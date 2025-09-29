import Link from 'next/link';
import { ShoppingCart, FileText, Calendar, Mail, Share2, Sparkles } from 'lucide-react';

export default function HomePage() {
  const services = [
    {
      key: 'crm',
      name: 'CRM Suite',
      description: 'Customer relationship management powered by EspoCRM',
      icon: ShoppingCart,
      price: 49,
      features: ['Contact Management', 'Sales Pipeline', 'Email Integration', 'Reporting']
    },
    {
      key: 'docs',
      name: 'Document Management',
      description: 'Paperless document management with OCR',
      icon: FileText,
      price: 29,
      features: ['OCR Processing', 'Full-Text Search', 'Tagging System', 'Mobile App']
    },
    {
      key: 'calendar',
      name: 'Calendar & Scheduling',
      description: 'Appointment scheduling with CalCom',
      icon: Calendar,
      price: 19,
      features: ['Online Booking', 'Calendar Sync', 'Reminders', 'Team Scheduling']
    },
    {
      key: 'email',
      name: 'Email Marketing',
      description: 'Email campaign management with Listmonk',
      icon: Mail,
      price: 29,
      features: ['Campaign Builder', 'Subscriber Management', 'Analytics', 'Templates']
    },
    {
      key: 'social',
      name: 'Social Media Manager',
      description: 'Multi-platform scheduling with AI captions',
      icon: Share2,
      price: 39,
      features: ['Multi-Platform', 'AI Captions', 'Content Calendar', 'Analytics']
    },
    {
      key: 'content',
      name: 'Content Creation Suite',
      description: 'AI-powered blog and content generation',
      icon: Sparkles,
      price: 59,
      features: ['AI Writing', 'SEO Optimization', 'Content Calendar', 'Image Suggestions']
    }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      {/* Header */}
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 py-6 sm:px-6 lg:px-8 flex justify-between items-center">
          <h1 className="text-3xl font-bold text-gray-900">AIQSO Platform</h1>
          <div className="space-x-4">
            <Link href="/login" className="text-gray-700 hover:text-gray-900">Login</Link>
            <Link href="/signup" className="bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700">
              Get Started
            </Link>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="max-w-7xl mx-auto px-4 py-16 sm:px-6 lg:px-8 text-center">
        <h2 className="text-5xl font-extrabold text-gray-900 mb-6">
          Your Business, Your Services, Your Domain
        </h2>
        <p className="text-xl text-gray-600 mb-8 max-w-3xl mx-auto">
          Choose the services you need. Get your own isolated environment at your-company.aiqso.io.
          No vendor lock-in. Open-source. Self-hosted.
        </p>
        <Link
          href="/signup"
          className="inline-block bg-indigo-600 text-white px-8 py-4 rounded-lg text-lg font-semibold hover:bg-indigo-700 transition"
        >
          Start Your 14-Day Free Trial
        </Link>
      </section>

      {/* Services Grid */}
      <section className="max-w-7xl mx-auto px-4 py-16 sm:px-6 lg:px-8">
        <h3 className="text-3xl font-bold text-gray-900 mb-12 text-center">
          Modular Services for Your Business
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {services.map((service) => {
            const Icon = service.icon;
            return (
              <div
                key={service.key}
                className="bg-white rounded-xl shadow-lg p-6 hover:shadow-xl transition"
              >
                <div className="flex items-center mb-4">
                  <div className="bg-indigo-100 p-3 rounded-lg">
                    <Icon className="w-6 h-6 text-indigo-600" />
                  </div>
                  <div className="ml-4">
                    <h4 className="text-xl font-bold text-gray-900">{service.name}</h4>
                    <p className="text-2xl font-bold text-indigo-600">${service.price}<span className="text-sm text-gray-500">/mo</span></p>
                  </div>
                </div>
                <p className="text-gray-600 mb-4">{service.description}</p>
                <ul className="space-y-2">
                  {service.features.map((feature) => (
                    <li key={feature} className="flex items-center text-sm text-gray-700">
                      <svg className="w-4 h-4 text-green-500 mr-2" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                      </svg>
                      {feature}
                    </li>
                  ))}
                </ul>
              </div>
            );
          })}
        </div>
      </section>

      {/* Features Section */}
      <section className="bg-white py-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <h3 className="text-3xl font-bold text-gray-900 mb-12 text-center">
            Why Choose AIQSO?
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="text-center">
              <div className="bg-indigo-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4">
                <svg className="w-8 h-8 text-indigo-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
              </div>
              <h4 className="text-xl font-bold mb-2">Isolated & Secure</h4>
              <p className="text-gray-600">Your data in your own environment. Complete isolation from other customers.</p>
            </div>
            <div className="text-center">
              <div className="bg-indigo-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4">
                <svg className="w-8 h-8 text-indigo-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
              </div>
              <h4 className="text-xl font-bold mb-2">Instant Provisioning</h4>
              <p className="text-gray-600">Services deployed in minutes. Start using immediately after signup.</p>
            </div>
            <div className="text-center">
              <div className="bg-indigo-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4">
                <svg className="w-8 h-8 text-indigo-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                </svg>
              </div>
              <h4 className="text-xl font-bold mb-2">AI-Powered</h4>
              <p className="text-gray-600">Built-in AI for content creation, captions, and automation.</p>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="bg-indigo-600 py-16">
        <div className="max-w-4xl mx-auto text-center px-4">
          <h3 className="text-3xl font-bold text-white mb-4">
            Ready to get started?
          </h3>
          <p className="text-xl text-indigo-100 mb-8">
            Start your 14-day free trial. No credit card required.
          </p>
          <Link
            href="/signup"
            className="inline-block bg-white text-indigo-600 px-8 py-4 rounded-lg text-lg font-semibold hover:bg-gray-100 transition"
          >
            Create Your Account
          </Link>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-900 text-gray-300 py-8">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <p>&copy; 2025 AIQSO Platform. Open-source, self-hosted SaaS.</p>
        </div>
      </footer>
    </div>
  );
}