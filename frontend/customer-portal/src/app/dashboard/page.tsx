'use client';

import { useState, useEffect } from 'react';
import { ShoppingCart, FileText, Calendar, Mail, Share2, Sparkles, Check, Plus } from 'lucide-react';

interface Service {
  key: string;
  name: string;
  description: string;
  price: number;
  status: 'available' | 'active' | 'provisioning';
  url?: string;
}

export default function DashboardPage() {
  const [tenant, setTenant] = useState({ subdomain: 'acmecorp', company_name: 'Acme Corp' });
  const [services, setServices] = useState<Service[]>([
    { key: 'crm', name: 'CRM Suite', description: 'Customer relationship management', price: 49, status: 'available' },
    { key: 'docs', name: 'Document Management', description: 'Paperless documents', price: 29, status: 'active', url: '/docs' },
    { key: 'calendar', name: 'Calendar & Scheduling', description: 'Appointment scheduling', price: 19, status: 'available' },
    { key: 'email', name: 'Email Marketing', description: 'Email campaigns', price: 29, status: 'active', url: '/email' },
    { key: 'social', name: 'Social Media Manager', description: 'Multi-platform scheduling', price: 39, status: 'available' },
    { key: 'content', name: 'Content Creation Suite', description: 'AI content generation', price: 59, status: 'available' },
  ]);

  const handleSubscribe = async (serviceKey: string) => {
    // Update UI to show provisioning
    setServices(services.map(s =>
      s.key === serviceKey ? { ...s, status: 'provisioning' as const } : s
    ));

    try {
      // Call n8n webhook to deploy service
      const response = await fetch('https://n8n.aiqso.io/webhook/deploy-service', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          tenant_id: tenant.subdomain, // Would be actual UUID in production
          service_key: serviceKey
        })
      });

      if (response.ok) {
        const data = await response.json();
        setServices(services.map(s =>
          s.key === serviceKey ? { ...s, status: 'active' as const, url: data.url } : s
        ));
      }
    } catch (error) {
      console.error('Failed to deploy service:', error);
      setServices(services.map(s =>
        s.key === serviceKey ? { ...s, status: 'available' as const } : s
      ));
    }
  };

  const getIcon = (key: string) => {
    const icons: Record<string, any> = {
      crm: ShoppingCart,
      docs: FileText,
      calendar: Calendar,
      email: Mail,
      social: Share2,
      content: Sparkles
    };
    return icons[key] || FileText;
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 py-6 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">{tenant.company_name}</h1>
              <p className="text-sm text-gray-500 mt-1">
                <a href={`https://${tenant.subdomain}.aiqso.io`} className="text-indigo-600 hover:text-indigo-800">
                  {tenant.subdomain}.aiqso.io
                </a>
              </p>
            </div>
            <div className="flex items-center space-x-4">
              <button className="text-gray-700 hover:text-gray-900">Settings</button>
              <button className="text-gray-700 hover:text-gray-900">Billing</button>
              <button className="text-gray-700 hover:text-gray-900">Logout</button>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div className="bg-white rounded-lg shadow p-6">
            <div className="text-sm text-gray-500 mb-1">Active Services</div>
            <div className="text-3xl font-bold text-gray-900">
              {services.filter(s => s.status === 'active').length}
            </div>
          </div>
          <div className="bg-white rounded-lg shadow p-6">
            <div className="text-sm text-gray-500 mb-1">Monthly Cost</div>
            <div className="text-3xl font-bold text-gray-900">
              ${services.filter(s => s.status === 'active').reduce((sum, s) => sum + s.price, 0)}
            </div>
          </div>
          <div className="bg-white rounded-lg shadow p-6">
            <div className="text-sm text-gray-500 mb-1">Storage Used</div>
            <div className="text-3xl font-bold text-gray-900">12.4 GB</div>
          </div>
          <div className="bg-white rounded-lg shadow p-6">
            <div className="text-sm text-gray-500 mb-1">Trial Days Left</div>
            <div className="text-3xl font-bold text-gray-900">7</div>
          </div>
        </div>

        {/* Services Section */}
        <h2 className="text-2xl font-bold text-gray-900 mb-6">Your Services</h2>

        {/* Active Services */}
        <div className="mb-8">
          <h3 className="text-lg font-semibold text-gray-700 mb-4">Active</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {services.filter(s => s.status === 'active').map((service) => {
              const Icon = getIcon(service.key);
              return (
                <div key={service.key} className="bg-white rounded-lg shadow-lg p-6 border-2 border-green-200">
                  <div className="flex items-center justify-between mb-4">
                    <div className="bg-green-100 p-3 rounded-lg">
                      <Icon className="w-6 h-6 text-green-600" />
                    </div>
                    <Check className="w-6 h-6 text-green-600" />
                  </div>
                  <h4 className="text-xl font-bold text-gray-900 mb-2">{service.name}</h4>
                  <p className="text-gray-600 mb-4">{service.description}</p>
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-gray-500">${service.price}/mo</span>
                    <a
                      href={service.url}
                      className="bg-indigo-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-indigo-700"
                    >
                      Open Service
                    </a>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Available Services */}
        <div>
          <h3 className="text-lg font-semibold text-gray-700 mb-4">Available Services</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {services.filter(s => s.status === 'available' || s.status === 'provisioning').map((service) => {
              const Icon = getIcon(service.key);
              return (
                <div key={service.key} className="bg-white rounded-lg shadow p-6">
                  <div className="flex items-center mb-4">
                    <div className="bg-gray-100 p-3 rounded-lg">
                      <Icon className="w-6 h-6 text-gray-600" />
                    </div>
                  </div>
                  <h4 className="text-xl font-bold text-gray-900 mb-2">{service.name}</h4>
                  <p className="text-gray-600 mb-4">{service.description}</p>
                  <div className="flex justify-between items-center">
                    <span className="text-xl font-bold text-indigo-600">${service.price}<span className="text-sm text-gray-500">/mo</span></span>
                    <button
                      onClick={() => handleSubscribe(service.key)}
                      disabled={service.status === 'provisioning'}
                      className={`flex items-center px-4 py-2 rounded-lg text-sm font-semibold ${
                        service.status === 'provisioning'
                          ? 'bg-gray-300 text-gray-600 cursor-not-allowed'
                          : 'bg-indigo-600 text-white hover:bg-indigo-700'
                      }`}
                    >
                      {service.status === 'provisioning' ? (
                        <>Deploying...</>
                      ) : (
                        <>
                          <Plus className="w-4 h-4 mr-1" />
                          Subscribe
                        </>
                      )}
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </main>
    </div>
  );
}