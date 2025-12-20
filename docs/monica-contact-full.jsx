import React, { useState } from 'react';

// Complete Monica v4 contact data model
const sampleContact = {
  // Core fields
  id: 1,
  hash_id: "h:Y5LOkAdWNDqgVomKPv",
  first_name: "Sarah",
  last_name: "Chen",
  nickname: "Sare",
  complete_name: "Sarah Chen (Sare)",
  initials: "SC",
  gender: "Woman",
  gender_type: "F",
  is_starred: true,
  is_partial: false,
  is_active: true,
  is_dead: false,
  is_me: false,
  description: "Met at a tech conference. Super sharp product thinker.",
  
  // Activity tracking
  last_called: "2024-11-28T14:30:00Z",
  last_activity_together: "2024-12-01T10:00:00Z",
  stay_in_touch_frequency: 14, // days
  stay_in_touch_trigger_date: "2024-12-15T00:00:00Z",
  
  // Information object
  information: {
    dates: {
      birthdate: {
        is_age_based: false,
        is_year_unknown: false,
        date: "1992-03-15T00:00:00Z"
      },
      deceased_date: {
        is_age_based: null,
        is_year_unknown: null,
        date: null
      }
    },
    career: {
      job: "Senior Product Designer",
      company: "Stripe"
    },
    avatar: {
      url: null,
      source: "default",
      default_avatar_color: "#FF6B9D"
    },
    food_preferences: "Vegetarian. Loves Thai food, especially pad see ew. Allergic to shellfish.",
    how_you_met: {
      general_information: "We met at Config 2023 in San Francisco. She was presenting on design systems.",
      first_met_date: {
        is_age_based: false,
        is_year_unknown: false,
        date: "2023-06-08T00:00:00Z"
      },
      first_met_through_contact: {
        id: 42,
        first_name: "Mike",
        last_name: "Torres"
      }
    },
    relationships: {
      love: {
        total: 1,
        contacts: [
          {
            relationship: { id: 1, name: "partner" },
            contact: { id: 15, first_name: "David", last_name: "Park", is_partial: true }
          }
        ]
      },
      family: {
        total: 2,
        contacts: [
          {
            relationship: { id: 2, name: "mother" },
            contact: { id: 16, first_name: "Linda", last_name: "Chen", is_partial: true }
          },
          {
            relationship: { id: 3, name: "brother" },
            contact: { id: 17, first_name: "Kevin", last_name: "Chen", is_partial: false }
          }
        ]
      },
      friend: { total: 0, contacts: [] },
      work: {
        total: 1,
        contacts: [
          {
            relationship: { id: 4, name: "colleague" },
            contact: { id: 18, first_name: "Emma", last_name: "Liu", is_partial: false }
          }
        ]
      }
    }
  },
  
  // Addresses
  addresses: [
    {
      id: 1,
      name: "Home",
      street: "742 Hayes Street",
      city: "San Francisco",
      province: "CA",
      postal_code: "94102",
      country: { id: "US", name: "United States", iso: "US" },
      latitude: 37.7749,
      longitude: -122.4194
    },
    {
      id: 2,
      name: "Work",
      street: "354 Oyster Point Blvd",
      city: "South San Francisco",
      province: "CA",
      postal_code: "94080",
      country: { id: "US", name: "United States", iso: "US" }
    }
  ],
  
  // Tags
  tags: [
    { id: 1, name: "SF Friends", name_slug: "sf-friends" },
    { id: 2, name: "Design", name_slug: "design" },
    { id: 3, name: "Conference", name_slug: "conference" },
    { id: 4, name: "Close Friends", name_slug: "close-friends" }
  ],
  
  // Contact Fields (phone, email, social, etc.)
  contactFields: [
    {
      id: 1,
      content: "sarah.chen@gmail.com",
      contact_field_type: { id: 1, name: "Email", type: "email", fontawesome_icon: "fa fa-envelope" }
    },
    {
      id: 2,
      content: "+1 (415) 555-0142",
      contact_field_type: { id: 2, name: "Phone", type: "phone", fontawesome_icon: "fa fa-phone" }
    },
    {
      id: 3,
      content: "sarahchen",
      contact_field_type: { id: 3, name: "Twitter", type: null, fontawesome_icon: "fa fa-twitter" }
    },
    {
      id: 4,
      content: "linkedin.com/in/sarahchen",
      contact_field_type: { id: 4, name: "LinkedIn", type: null, fontawesome_icon: "fa fa-linkedin" }
    }
  ],
  
  // Statistics
  statistics: {
    number_of_calls: 12,
    number_of_notes: 8,
    number_of_activities: 15,
    number_of_reminders: 2,
    number_of_tasks: 1,
    number_of_gifts: 3,
    number_of_debts: 0
  },
  
  // Notes (from API when using ?with=contactfields)
  notes: [
    {
      id: 1,
      body: "Loves hiking and outdoor photography. Ask about her Joshua Tree trip.",
      is_favorited: true,
      favorited_at: "2024-11-28T00:00:00Z",
      created_at: "2024-11-28T00:00:00Z"
    },
    {
      id: 2,
      body: "Recently adopted a rescue dog named Mochi - a golden retriever mix.",
      is_favorited: false,
      created_at: "2024-11-15T00:00:00Z"
    },
    {
      id: 3,
      body: "Mentioned she's thinking about leaving Stripe for a startup opportunity. Follow up on this.",
      is_favorited: true,
      favorited_at: "2024-12-01T00:00:00Z",
      created_at: "2024-12-01T00:00:00Z"
    }
  ],
  
  // Activities (fetched separately via /activities?contact_id=X)
  activities: [
    {
      id: 1,
      activity_type: { id: 1, name: "Coffee" },
      summary: "Coffee catch-up at Sightglass",
      description: "Talked about her new role and potential startup move. She seems excited but nervous.",
      happened_at: "2024-12-01T10:00:00Z"
    },
    {
      id: 2,
      activity_type: { id: 2, name: "Dinner" },
      summary: "Birthday dinner at Nopa",
      happened_at: "2024-03-15T19:00:00Z"
    }
  ],
  
  // Calls (fetched separately via /calls)
  calls: [
    {
      id: 1,
      called_at: "2024-11-28T14:30:00Z",
      content: "Quick call to finalize dinner plans for next week."
    }
  ],
  
  // Reminders (fetched separately via /reminders)
  reminders: [
    {
      id: 1,
      title: "Sarah's birthday",
      initial_date: "2025-03-15T00:00:00Z",
      frequency_type: "year",
      frequency_number: 1
    },
    {
      id: 2,
      title: "Follow up on startup decision",
      initial_date: "2024-12-20T00:00:00Z",
      frequency_type: "one_time"
    }
  ],
  
  // Tasks (fetched separately via /tasks)
  tasks: [
    {
      id: 1,
      title: "Send article about product-led growth",
      description: "She mentioned wanting to learn more about PLG strategies",
      completed: false
    }
  ],
  
  // Gifts (fetched separately via /gifts)
  gifts: [
    {
      id: 1,
      name: "Patagonia Nano Puff Jacket",
      comment: "Birthday 2024 - she loved it",
      is_an_idea: false,
      has_been_offered: true,
      value: 199.00
    },
    {
      id: 2,
      name: "Ceramic pour-over coffee set",
      comment: "For her new apartment",
      is_an_idea: true,
      has_been_offered: false,
      value: 85.00
    }
  ],
  
  // Debts (fetched separately via /debts)
  debts: [],
  
  // Conversations (fetched separately via /conversations)
  conversations: [
    {
      id: 1,
      happened_at: "2024-11-25T00:00:00Z",
      contact_field_type: { name: "iMessage" },
      messages: [
        { written_by_me: false, content: "Hey! Are you free for coffee this weekend?" },
        { written_by_me: true, content: "Yes! Saturday works great. Sightglass?" }
      ]
    }
  ],
  
  // Documents/Photos
  documents: [],
  photos: [
    { id: 1, filename: "config-2023.jpg" }
  ],

  created_at: "2023-06-10T00:00:00Z",
  updated_at: "2024-12-01T10:30:00Z"
};

// Helper functions
const formatDate = (dateStr) => {
  if (!dateStr) return null;
  const date = new Date(dateStr);
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
};

const formatRelativeDate = (dateStr) => {
  if (!dateStr) return null;
  const date = new Date(dateStr);
  const now = new Date();
  const diffDays = Math.floor((now - date) / (1000 * 60 * 60 * 24));
  if (diffDays === 0) return 'Today';
  if (diffDays === 1) return 'Yesterday';
  if (diffDays < 7) return `${diffDays} days ago`;
  if (diffDays < 30) return `${Math.floor(diffDays / 7)} weeks ago`;
  return formatDate(dateStr);
};

const getAge = (birthdate) => {
  if (!birthdate) return null;
  const birth = new Date(birthdate);
  const now = new Date();
  let age = now.getFullYear() - birth.getFullYear();
  const m = now.getMonth() - birth.getMonth();
  if (m < 0 || (m === 0 && now.getDate() < birth.getDate())) age--;
  return age;
};

const getInitials = (contact) => {
  return `${contact.first_name?.[0] || ''}${contact.last_name?.[0] || ''}`;
};

// Section Component
const Section = ({ title, icon, children, action, collapsed = false }) => {
  const [isCollapsed, setIsCollapsed] = useState(collapsed);
  
  return (
    <div style={{
      background: 'white',
      borderRadius: '16px',
      marginBottom: '12px',
      overflow: 'hidden',
      boxShadow: '0 1px 3px rgba(0,0,0,0.04)',
    }}>
      <button
        onClick={() => setIsCollapsed(!isCollapsed)}
        style={{
          width: '100%',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '14px 16px',
          background: 'none',
          border: 'none',
          cursor: 'pointer',
          borderBottom: isCollapsed ? 'none' : '1px solid #F2F2F7',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <span style={{ fontSize: '18px' }}>{icon}</span>
          <span style={{
            fontSize: '13px',
            fontWeight: '600',
            color: '#1a1a1a',
            textTransform: 'uppercase',
            letterSpacing: '0.5px',
          }}>{title}</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          {action}
          <span style={{
            color: '#C7C7CC',
            fontSize: '14px',
            transform: isCollapsed ? 'rotate(-90deg)' : 'rotate(0deg)',
            transition: 'transform 0.2s',
          }}>▼</span>
        </div>
      </button>
      {!isCollapsed && (
        <div style={{ padding: '12px 16px 16px' }}>
          {children}
        </div>
      )}
    </div>
  );
};

// Info Row Component
const InfoRow = ({ icon, label, value, action }) => (
  <div style={{
    display: 'flex',
    alignItems: 'flex-start',
    padding: '10px 0',
    borderBottom: '1px solid #F8F8F8',
  }}>
    <span style={{ fontSize: '16px', width: '28px', flexShrink: 0 }}>{icon}</span>
    <div style={{ flex: 1, minWidth: 0 }}>
      <p style={{
        margin: 0,
        fontSize: '11px',
        color: '#8E8E93',
        textTransform: 'uppercase',
        letterSpacing: '0.5px',
      }}>{label}</p>
      <p style={{
        margin: '2px 0 0',
        fontSize: '15px',
        color: '#1a1a1a',
        lineHeight: '1.4',
      }}>{value}</p>
    </div>
    {action}
  </div>
);

// Main Component
export default function MonicaContactFull() {
  const contact = sampleContact;
  const [activeTab, setActiveTab] = useState('overview');
  
  const tabs = [
    { id: 'overview', label: 'Overview' },
    { id: 'activities', label: 'Activities' },
    { id: 'notes', label: 'Notes' },
    { id: 'gifts', label: 'Gifts' },
  ];
  
  return (
    <div style={{
      fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", system-ui, sans-serif',
      background: '#F2F2F7',
      minHeight: '100vh',
      maxWidth: '390px',
      margin: '0 auto',
      position: 'relative',
    }}>
      {/* Status Bar */}
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: '12px 24px 8px',
        background: 'linear-gradient(180deg, #5a67d8 0%, #4c51bf 100%)',
        color: 'white',
        fontSize: '14px',
        fontWeight: '600',
      }}>
        <span>9:41</span>
        <div style={{ display: 'flex', gap: '6px', alignItems: 'center' }}>
          <span style={{ fontSize: '12px' }}>●●●●○</span>
          <span>🔋</span>
        </div>
      </div>
      
      {/* Header */}
      <div style={{
        background: 'linear-gradient(180deg, #4c51bf 0%, #434190 50%, #F2F2F7 100%)',
        padding: '8px 16px 50px',
      }}>
        {/* Nav */}
        <div style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: '20px',
        }}>
          <button style={{
            background: 'none',
            border: 'none',
            color: 'white',
            fontSize: '17px',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '4px',
            padding: 0,
          }}>
            <span style={{ fontSize: '22px' }}>‹</span> Contacts
          </button>
          <div style={{ display: 'flex', gap: '12px' }}>
            <button style={{
              background: 'rgba(255,255,255,0.2)',
              border: 'none',
              color: 'white',
              fontSize: '18px',
              width: '36px',
              height: '36px',
              borderRadius: '18px',
              cursor: 'pointer',
            }}>
              {contact.is_starred ? '⭐' : '☆'}
            </button>
            <button style={{
              background: 'rgba(255,255,255,0.2)',
              border: 'none',
              color: 'white',
              fontSize: '14px',
              padding: '8px 16px',
              borderRadius: '18px',
              cursor: 'pointer',
            }}>
              Edit
            </button>
          </div>
        </div>
        
        {/* Profile */}
        <div style={{ textAlign: 'center' }}>
          <div style={{
            width: '100px',
            height: '100px',
            borderRadius: '50%',
            background: contact.information.avatar.default_avatar_color,
            margin: '0 auto 12px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: '36px',
            fontWeight: '500',
            color: 'white',
            boxShadow: '0 8px 32px rgba(0,0,0,0.2)',
          }}>
            {getInitials(contact)}
          </div>
          <h1 style={{
            fontSize: '26px',
            fontWeight: '700',
            color: 'white',
            margin: '0 0 2px',
          }}>
            {contact.first_name} {contact.last_name}
          </h1>
          {contact.nickname && (
            <p style={{ fontSize: '14px', color: 'rgba(255,255,255,0.8)', margin: '0 0 4px' }}>
              "{contact.nickname}"
            </p>
          )}
          <p style={{ fontSize: '14px', color: 'rgba(255,255,255,0.9)', margin: 0 }}>
            {contact.information.career.job} at {contact.information.career.company}
          </p>
        </div>
      </div>
      
      {/* Quick Actions */}
      <div style={{
        display: 'flex',
        justifyContent: 'center',
        gap: '10px',
        marginTop: '-28px',
        marginBottom: '16px',
        padding: '0 16px',
      }}>
        {[
          { icon: '💬', label: 'Message' },
          { icon: '📞', label: 'Call' },
          { icon: '📧', label: 'Email' },
          { icon: '📍', label: 'Map' },
        ].map((action, i) => (
          <button key={i} style={{
            flex: 1,
            background: 'white',
            border: 'none',
            borderRadius: '14px',
            padding: '12px 8px',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: '4px',
            cursor: 'pointer',
            boxShadow: '0 2px 12px rgba(0,0,0,0.08)',
          }}>
            <span style={{ fontSize: '20px' }}>{action.icon}</span>
            <span style={{ fontSize: '11px', color: '#5a67d8', fontWeight: '500' }}>{action.label}</span>
          </button>
        ))}
      </div>
      
      {/* Tabs */}
      <div style={{
        display: 'flex',
        padding: '0 16px',
        marginBottom: '12px',
        gap: '4px',
      }}>
        {tabs.map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            style={{
              flex: 1,
              padding: '10px 12px',
              background: activeTab === tab.id ? '#5a67d8' : 'white',
              color: activeTab === tab.id ? 'white' : '#666',
              border: 'none',
              borderRadius: '10px',
              fontSize: '13px',
              fontWeight: '600',
              cursor: 'pointer',
            }}
          >
            {tab.label}
          </button>
        ))}
      </div>
      
      {/* Content */}
      <div style={{ padding: '0 16px 120px' }}>
        {activeTab === 'overview' && (
          <>
            {/* Stay in Touch Alert */}
            {contact.stay_in_touch_frequency && (
              <div style={{
                background: 'linear-gradient(135deg, #FEF3C7 0%, #FDE68A 100%)',
                borderRadius: '14px',
                padding: '14px 16px',
                marginBottom: '12px',
                display: 'flex',
                alignItems: 'center',
                gap: '12px',
              }}>
                <span style={{ fontSize: '24px' }}>🔔</span>
                <div style={{ flex: 1 }}>
                  <p style={{ margin: 0, fontSize: '14px', fontWeight: '600', color: '#92400E' }}>
                    Stay in touch every {contact.stay_in_touch_frequency} days
                  </p>
                  <p style={{ margin: '2px 0 0', fontSize: '12px', color: '#B45309' }}>
                    Next reminder: {formatDate(contact.stay_in_touch_trigger_date)}
                  </p>
                </div>
              </div>
            )}
            
            {/* Last Activity */}
            <div style={{
              background: 'white',
              borderRadius: '14px',
              padding: '14px 16px',
              marginBottom: '12px',
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              boxShadow: '0 1px 3px rgba(0,0,0,0.04)',
            }}>
              <span style={{ fontSize: '28px' }}>☕️</span>
              <div style={{ flex: 1 }}>
                <p style={{ margin: 0, fontSize: '15px', fontWeight: '600', color: '#1a1a1a' }}>
                  {contact.activities[0]?.summary}
                </p>
                <p style={{ margin: '2px 0 0', fontSize: '13px', color: '#8E8E93' }}>
                  {formatRelativeDate(contact.last_activity_together)}
                </p>
              </div>
              <button style={{
                background: '#EEF2FF',
                border: 'none',
                borderRadius: '10px',
                padding: '8px 12px',
                fontSize: '12px',
                fontWeight: '600',
                color: '#5a67d8',
                cursor: 'pointer',
              }}>
                + Log
              </button>
            </div>
            
            {/* Contact Info Section */}
            <Section title="Contact Info" icon="📇">
              {contact.contactFields.map(field => (
                <InfoRow
                  key={field.id}
                  icon={field.contact_field_type.name === 'Email' ? '✉️' :
                        field.contact_field_type.name === 'Phone' ? '📱' :
                        field.contact_field_type.name === 'Twitter' ? '🐦' : '🔗'}
                  label={field.contact_field_type.name}
                  value={field.content}
                />
              ))}
              {contact.addresses.map(addr => (
                <InfoRow
                  key={addr.id}
                  icon="📍"
                  label={addr.name}
                  value={`${addr.street}, ${addr.city}, ${addr.province} ${addr.postal_code}`}
                />
              ))}
            </Section>
            
            {/* Important Dates */}
            <Section title="Important Dates" icon="📅">
              {contact.information.dates.birthdate.date && (
                <InfoRow
                  icon="🎂"
                  label="Birthday"
                  value={`${formatDate(contact.information.dates.birthdate.date)} (${getAge(contact.information.dates.birthdate.date)} years old)`}
                />
              )}
              {contact.information.how_you_met.first_met_date.date && (
                <InfoRow
                  icon="🤝"
                  label="First Met"
                  value={formatDate(contact.information.how_you_met.first_met_date.date)}
                />
              )}
              {contact.reminders.map(reminder => (
                <InfoRow
                  key={reminder.id}
                  icon="⏰"
                  label={reminder.frequency_type === 'year' ? 'Yearly' : 'One-time'}
                  value={`${reminder.title} - ${formatDate(reminder.initial_date)}`}
                />
              ))}
            </Section>
            
            {/* How We Met */}
            <Section title="How We Met" icon="🤝">
              <p style={{ margin: '0 0 10px', fontSize: '15px', color: '#1a1a1a', lineHeight: '1.5' }}>
                {contact.information.how_you_met.general_information}
              </p>
              {contact.information.how_you_met.first_met_through_contact && (
                <div style={{
                  background: '#F8F8FA',
                  borderRadius: '10px',
                  padding: '10px 12px',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '10px',
                }}>
                  <span style={{ fontSize: '14px' }}>👤</span>
                  <span style={{ fontSize: '14px', color: '#5a67d8' }}>
                    Met through {contact.information.how_you_met.first_met_through_contact.first_name} {contact.information.how_you_met.first_met_through_contact.last_name}
                  </span>
                </div>
              )}
            </Section>
            
            {/* Relationships */}
            <Section title="Relationships" icon="👥">
              {Object.entries(contact.information.relationships).map(([type, data]) => (
                data.contacts.map(rel => (
                  <div key={rel.contact.id} style={{
                    display: 'flex',
                    alignItems: 'center',
                    padding: '10px 0',
                    borderBottom: '1px solid #F8F8F8',
                    gap: '12px',
                  }}>
                    <div style={{
                      width: '40px',
                      height: '40px',
                      borderRadius: '20px',
                      background: '#E8EAFF',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: '14px',
                      color: '#5a67d8',
                      fontWeight: '600',
                    }}>
                      {rel.contact.first_name[0]}{rel.contact.last_name?.[0] || ''}
                    </div>
                    <div style={{ flex: 1 }}>
                      <p style={{ margin: 0, fontSize: '15px', fontWeight: '500', color: '#1a1a1a' }}>
                        {rel.contact.first_name} {rel.contact.last_name}
                      </p>
                      <p style={{ margin: '2px 0 0', fontSize: '12px', color: '#8E8E93', textTransform: 'capitalize' }}>
                        {rel.relationship.name}
                      </p>
                    </div>
                    {!rel.contact.is_partial && (
                      <span style={{ color: '#C7C7CC', fontSize: '18px' }}>›</span>
                    )}
                  </div>
                ))
              ))}
            </Section>
            
            {/* Food Preferences */}
            {contact.information.food_preferences && (
              <Section title="Food Preferences" icon="🍽️">
                <p style={{ margin: 0, fontSize: '15px', color: '#1a1a1a', lineHeight: '1.5' }}>
                  {contact.information.food_preferences}
                </p>
              </Section>
            )}
            
            {/* Tags */}
            <Section title="Tags" icon="🏷️">
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
                {contact.tags.map(tag => (
                  <span key={tag.id} style={{
                    background: '#EEF2FF',
                    color: '#5a67d8',
                    fontSize: '13px',
                    fontWeight: '500',
                    padding: '6px 12px',
                    borderRadius: '16px',
                  }}>
                    {tag.name}
                  </span>
                ))}
                <button style={{
                  background: 'transparent',
                  border: '1.5px dashed #C7C7CC',
                  color: '#8E8E93',
                  fontSize: '13px',
                  padding: '6px 12px',
                  borderRadius: '16px',
                  cursor: 'pointer',
                }}>
                  + Add
                </button>
              </div>
            </Section>
            
            {/* Tasks */}
            {contact.tasks.length > 0 && (
              <Section title="Tasks" icon="✅">
                {contact.tasks.map(task => (
                  <div key={task.id} style={{
                    display: 'flex',
                    alignItems: 'flex-start',
                    gap: '10px',
                    padding: '8px 0',
                  }}>
                    <div style={{
                      width: '20px',
                      height: '20px',
                      borderRadius: '10px',
                      border: '2px solid #C7C7CC',
                      flexShrink: 0,
                      marginTop: '2px',
                    }} />
                    <div>
                      <p style={{ margin: 0, fontSize: '15px', color: '#1a1a1a' }}>{task.title}</p>
                      {task.description && (
                        <p style={{ margin: '4px 0 0', fontSize: '13px', color: '#8E8E93' }}>{task.description}</p>
                      )}
                    </div>
                  </div>
                ))}
              </Section>
            )}
            
            {/* Stats Footer */}
            <div style={{
              background: 'white',
              borderRadius: '14px',
              padding: '16px',
              marginTop: '8px',
              boxShadow: '0 1px 3px rgba(0,0,0,0.04)',
            }}>
              <div style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(4, 1fr)',
                gap: '8px',
                textAlign: 'center',
              }}>
                {[
                  { value: contact.statistics.number_of_activities, label: 'Activities' },
                  { value: contact.statistics.number_of_notes, label: 'Notes' },
                  { value: contact.statistics.number_of_calls, label: 'Calls' },
                  { value: contact.statistics.number_of_gifts, label: 'Gifts' },
                ].map((stat, i) => (
                  <div key={i}>
                    <p style={{ margin: 0, fontSize: '20px', fontWeight: '700', color: '#5a67d8' }}>{stat.value}</p>
                    <p style={{ margin: '2px 0 0', fontSize: '10px', color: '#8E8E93', textTransform: 'uppercase' }}>{stat.label}</p>
                  </div>
                ))}
              </div>
            </div>
          </>
        )}
        
        {activeTab === 'activities' && (
          <>
            <button style={{
              width: '100%',
              background: '#5a67d8',
              color: 'white',
              border: 'none',
              borderRadius: '12px',
              padding: '14px',
              fontSize: '15px',
              fontWeight: '600',
              marginBottom: '16px',
              cursor: 'pointer',
            }}>
              + Log New Activity
            </button>
            
            {contact.activities.map(activity => (
              <div key={activity.id} style={{
                background: 'white',
                borderRadius: '14px',
                padding: '16px',
                marginBottom: '10px',
                boxShadow: '0 1px 3px rgba(0,0,0,0.04)',
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '8px' }}>
                  <span style={{ fontSize: '20px' }}>
                    {activity.activity_type.name === 'Coffee' ? '☕️' : '🍽️'}
                  </span>
                  <span style={{
                    background: '#EEF2FF',
                    color: '#5a67d8',
                    fontSize: '12px',
                    fontWeight: '500',
                    padding: '4px 10px',
                    borderRadius: '12px',
                  }}>
                    {activity.activity_type.name}
                  </span>
                  <span style={{ marginLeft: 'auto', fontSize: '12px', color: '#8E8E93' }}>
                    {formatDate(activity.happened_at)}
                  </span>
                </div>
                <h3 style={{ margin: '0 0 6px', fontSize: '16px', fontWeight: '600', color: '#1a1a1a' }}>
                  {activity.summary}
                </h3>
                {activity.description && (
                  <p style={{ margin: 0, fontSize: '14px', color: '#666', lineHeight: '1.4' }}>
                    {activity.description}
                  </p>
                )}
              </div>
            ))}
            
            {/* Calls */}
            <h4 style={{
              fontSize: '12px',
              color: '#8E8E93',
              textTransform: 'uppercase',
              letterSpacing: '0.5px',
              margin: '20px 0 10px 4px',
            }}>Recent Calls</h4>
            
            {contact.calls.map(call => (
              <div key={call.id} style={{
                background: 'white',
                borderRadius: '14px',
                padding: '14px 16px',
                marginBottom: '10px',
                display: 'flex',
                alignItems: 'center',
                gap: '12px',
                boxShadow: '0 1px 3px rgba(0,0,0,0.04)',
              }}>
                <span style={{ fontSize: '20px' }}>📞</span>
                <div style={{ flex: 1 }}>
                  <p style={{ margin: 0, fontSize: '14px', color: '#1a1a1a' }}>{call.content}</p>
                  <p style={{ margin: '4px 0 0', fontSize: '12px', color: '#8E8E93' }}>
                    {formatRelativeDate(call.called_at)}
                  </p>
                </div>
              </div>
            ))}
          </>
        )}
        
        {activeTab === 'notes' && (
          <>
            <button style={{
              width: '100%',
              background: '#5a67d8',
              color: 'white',
              border: 'none',
              borderRadius: '12px',
              padding: '14px',
              fontSize: '15px',
              fontWeight: '600',
              marginBottom: '16px',
              cursor: 'pointer',
            }}>
              + Add Note
            </button>
            
            {contact.notes.map(note => (
              <div key={note.id} style={{
                background: note.is_favorited ? '#FFFEF5' : 'white',
                borderRadius: '14px',
                padding: '14px 16px',
                marginBottom: '10px',
                borderLeft: note.is_favorited ? '3px solid #F59E0B' : 'none',
                boxShadow: '0 1px 3px rgba(0,0,0,0.04)',
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <p style={{ margin: '0 0 8px', fontSize: '15px', color: '#1a1a1a', lineHeight: '1.5', flex: 1 }}>
                    {note.body}
                  </p>
                  <button style={{
                    background: 'none',
                    border: 'none',
                    fontSize: '18px',
                    cursor: 'pointer',
                    padding: '0 0 0 8px',
                  }}>
                    {note.is_favorited ? '⭐' : '☆'}
                  </button>
                </div>
                <p style={{ margin: 0, fontSize: '12px', color: '#8E8E93' }}>
                  {formatDate(note.created_at)}
                </p>
              </div>
            ))}
          </>
        )}
        
        {activeTab === 'gifts' && (
          <>
            <button style={{
              width: '100%',
              background: '#5a67d8',
              color: 'white',
              border: 'none',
              borderRadius: '12px',
              padding: '14px',
              fontSize: '15px',
              fontWeight: '600',
              marginBottom: '16px',
              cursor: 'pointer',
            }}>
              + Add Gift Idea
            </button>
            
            <h4 style={{
              fontSize: '12px',
              color: '#8E8E93',
              textTransform: 'uppercase',
              letterSpacing: '0.5px',
              margin: '0 0 10px 4px',
            }}>Gift Ideas</h4>
            
            {contact.gifts.filter(g => g.is_an_idea && !g.has_been_offered).map(gift => (
              <div key={gift.id} style={{
                background: 'white',
                borderRadius: '14px',
                padding: '14px 16px',
                marginBottom: '10px',
                boxShadow: '0 1px 3px rgba(0,0,0,0.04)',
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                  <span style={{ fontSize: '24px' }}>💡</span>
                  <div style={{ flex: 1 }}>
                    <p style={{ margin: 0, fontSize: '15px', fontWeight: '500', color: '#1a1a1a' }}>
                      {gift.name}
                    </p>
                    {gift.comment && (
                      <p style={{ margin: '4px 0 0', fontSize: '13px', color: '#8E8E93' }}>{gift.comment}</p>
                    )}
                  </div>
                  {gift.value && (
                    <span style={{ fontSize: '14px', fontWeight: '600', color: '#5a67d8' }}>
                      ${gift.value}
                    </span>
                  )}
                </div>
              </div>
            ))}
            
            <h4 style={{
              fontSize: '12px',
              color: '#8E8E93',
              textTransform: 'uppercase',
              letterSpacing: '0.5px',
              margin: '20px 0 10px 4px',
            }}>Given Gifts</h4>
            
            {contact.gifts.filter(g => g.has_been_offered).map(gift => (
              <div key={gift.id} style={{
                background: 'white',
                borderRadius: '14px',
                padding: '14px 16px',
                marginBottom: '10px',
                boxShadow: '0 1px 3px rgba(0,0,0,0.04)',
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                  <span style={{ fontSize: '24px' }}>🎁</span>
                  <div style={{ flex: 1 }}>
                    <p style={{ margin: 0, fontSize: '15px', fontWeight: '500', color: '#1a1a1a' }}>
                      {gift.name}
                    </p>
                    {gift.comment && (
                      <p style={{ margin: '4px 0 0', fontSize: '13px', color: '#8E8E93' }}>{gift.comment}</p>
                    )}
                  </div>
                  {gift.value && (
                    <span style={{ fontSize: '14px', fontWeight: '600', color: '#10B981' }}>
                      ${gift.value}
                    </span>
                  )}
                </div>
              </div>
            ))}
          </>
        )}
      </div>
      
      {/* Tab Bar */}
      <div style={{
        position: 'fixed',
        bottom: 0,
        left: '50%',
        transform: 'translateX(-50%)',
        width: '390px',
        background: 'rgba(255,255,255,0.95)',
        backdropFilter: 'blur(20px)',
        borderTop: '1px solid rgba(0,0,0,0.1)',
        display: 'flex',
        justifyContent: 'space-around',
        padding: '10px 0 28px',
      }}>
        {[
          { icon: '👥', label: 'Contacts', active: true },
          { icon: '📅', label: 'Activities' },
          { icon: '🔔', label: 'Reminders' },
          { icon: '📓', label: 'Journal' },
          { icon: '⚙️', label: 'Settings' },
        ].map((tab, i) => (
          <button key={i} style={{
            background: 'none',
            border: 'none',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: '4px',
            cursor: 'pointer',
          }}>
            <span style={{ fontSize: '20px', opacity: tab.active ? 1 : 0.5 }}>{tab.icon}</span>
            <span style={{
              fontSize: '10px',
              fontWeight: '500',
              color: tab.active ? '#5a67d8' : '#8E8E93',
            }}>{tab.label}</span>
          </button>
        ))}
      </div>
    </div>
  );
}
