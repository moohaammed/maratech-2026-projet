import { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { signOut } from 'firebase/auth';
import { auth } from '../../lib/firebase';
import { UserService, RunningGroup } from '../../core/services/UserService';
import NotificationBadge from '../../components/NotificationBadge';
import { useChatNotifications } from '../../core/services/NotificationService';
import { useAccessibility } from '../../core/services/AccessibilityContext';
import { useSpeechSynthesis } from '../../hooks/useSpeech';
import { appColors } from '../../core/theme/appColors';
import EventListScreen from '../coach/events/EventListScreen';
import GroupChat from '../../components/GroupChat';
import './MemberHomeScreen.css';

const TABS = {
  HOME: 'home',
  EVENTS: 'events',
  CLUB: 'club',
  PROFILE: 'profile',
};

export default function MemberHomeScreen({ user }) {
  const navigate = useNavigate();
  const accessibility = useAccessibility();
  const { speak, stop: stopSpeech } = useSpeechSynthesis();

  const [activeTab, setActiveTab] = useState(TABS.HOME);
  const [userDoc, setUserDoc] = useState(null);
  const [loadingUserDoc, setLoadingUserDoc] = useState(true);

  const isBlind = accessibility?.visualNeeds === 'blind';
  const highContrast = !!accessibility?.highContrast;

  // Real-time Chat Notifications
  useChatNotifications(auth.currentUser, userDoc?.assignedGroup || userDoc?.group || userDoc?.groupId);

  const theme = useMemo(() => {
    const primary = highContrast ? appColors.highContrastPrimary : appColors.primary;
    const background = highContrast ? appColors.highContrastBackground : appColors.background;
    const surface = highContrast ? appColors.highContrastSurface : appColors.surface;
    const textPrimary = highContrast ? '#FFFFFF' : appColors.textPrimary;
    const textSecondary = highContrast ? 'rgba(255,255,255,0.72)' : appColors.textSecondary;

    return { primary, background, surface, textPrimary, textSecondary };
  }, [highContrast]);

  useEffect(() => {
    let mounted = true;

    const load = async () => {
      setLoadingUserDoc(true);
      try {
        const uid = user?.uid;
        if (!uid) {
          if (mounted) setUserDoc(null);
          return;
        }
        const doc = await UserService.getUserById(uid);
        if (mounted) setUserDoc(doc);
      } catch (e) {
        console.error('Error loading member profile:', e);
        if (mounted) setUserDoc(null);
      } finally {
        if (mounted) setLoadingUserDoc(false);
      }
    };

    load();
    return () => {
      mounted = false;
    };
  }, [user?.uid]);

  useEffect(() => {
    if (!isBlind) return;
    const label = getTabLabel(activeTab);
    speak(`Onglet ${label} sélectionné`);
    return () => stopSpeech();
  }, [activeTab, isBlind, speak, stopSpeech]);

  const onSelectTab = (tab) => setActiveTab(tab);

  const handleLogout = async () => {
    await signOut(auth);
  };

  return (
    <div className="member-shell" style={{ background: theme.background, color: theme.textPrimary }}>
      <div className="member-body">
        {activeTab === TABS.HOME && (
          <MemberHomeTab
            theme={theme}
            isBlind={isBlind}
            speak={speak}
            stopSpeech={stopSpeech}
            loadingUserDoc={loadingUserDoc}
            userDoc={userDoc}
            navigate={navigate}
          />
        )}
        {activeTab === TABS.EVENTS && (
          <div className="member-tab-fill" style={{ background: theme.background }}>
            <div className="member-appbar" style={{ background: theme.primary, color: highContrast ? theme.primary : '#fff' }}>
              <div className="member-appbar-title">Tous les événements</div>
              <button
                className="icon-button-light"
                onClick={() => navigate('/notifications')}
                aria-label="Notifications"
                style={{ width: 44, height: 44, padding: 8, display: 'flex', alignItems: 'center', justifyContent: 'center' }}
              >
                <NotificationBadge groupId={userDoc?.assignedGroup || userDoc?.group || userDoc?.groupId}>
                  <span className="material-icons" style={{ fontSize: 24 }}>notifications</span>
                </NotificationBadge>
              </button>
            </div>
            <div className="member-tab-content">
              <EventListScreen canCreate={false} />
            </div>
          </div>
        )}
        {activeTab === TABS.CLUB && (
          <MemberClubTab theme={theme} isBlind={isBlind} speak={speak} />
        )}
        {activeTab === TABS.CHAT && (
          <MemberChatTab theme={theme} isBlind={isBlind} speak={speak} userDoc={userDoc} navigate={navigate} />
        )}
        {activeTab === TABS.PROFILE && (
          <MemberProfileTab
            theme={theme}
            loadingUserDoc={loadingUserDoc}
            userDoc={userDoc}
            onLogout={handleLogout}
            navigate={navigate}
          />
        )}

        <AICoachButton theme={theme} onSelectTab={setActiveTab} />
      </div>

      <MemberBottomNav
        activeTab={activeTab}
        onSelectTab={onSelectTab}
        theme={theme}
        highContrast={highContrast}
        isBlind={isBlind}
        speak={speak}
      />
    </div>
  );
}

function MemberChatTab({ theme, isBlind, speak, userDoc, navigate }) {
  useEffect(() => {
    if (!isBlind) return;
    const groupLabel = getGroupName(userDoc?.assignedGroup || userDoc?.group || userDoc?.groupId);
    speak(`Chat du groupe ${groupLabel}`);
    return () => speak.stop?.();
  }, [isBlind, speak, userDoc]);

  const groupId = userDoc?.assignedGroup || userDoc?.group || userDoc?.groupId;

  return (
    <div className="member-tab-fill" style={{ background: theme.background }}>
      <div className="member-appbar" style={{ background: theme.primary, color: '#fff' }}>
        <div className="member-appbar-title">Chat du groupe</div>
        <button
          className="icon-button-light"
          onClick={() => navigate('/notifications')}
          aria-label="Notifications"
          style={{ width: 44, height: 44, padding: 8, display: 'flex', alignItems: 'center', justifyContent: 'center' }}
        >
          <NotificationBadge>
            <span className="material-icons" style={{ fontSize: 24 }}>notifications</span>
          </NotificationBadge>
        </button>
      </div>
      <div className="member-tab-content">
        <GroupChat user={auth.currentUser} groupId={groupId} />
      </div>
    </div>
  );
}

function MemberBottomNav({ activeTab, onSelectTab, theme, highContrast, isBlind, speak }) {
  const items = [
    { key: TABS.HOME, label: 'Accueil', icon: 'home' },
    { key: TABS.EVENTS, label: 'Événements', icon: 'calendar' },
    { key: TABS.CLUB, label: 'Le Club', icon: 'group' },
    //{ key: TABS.CHAT, label: 'Chat', icon: 'chat' },
    { key: TABS.PROFILE, label: 'Profil', icon: 'person' },
  ];

  return (
    <nav
      className="member-nav"
      style={{
        background: highContrast ? theme.surface : '#FFFFFF',
        borderTopColor: highContrast ? 'rgba(255,255,255,0.16)' : appColors.divider,
      }}
    >
      {items.map((item) => {
        const selected = activeTab === item.key;
        const color = selected ? theme.primary : theme.textSecondary;

        return (
          <button
            key={item.key}
            className={`member-nav-item ${selected ? 'is-selected' : ''}`}
            onClick={() => {
              onSelectTab(item.key);
              if (isBlind) speak(`Onglet ${item.label} sélectionné`);
            }}
            aria-label={item.label}
            type="button"
          >
            <span className="member-nav-icon" style={{ color }} aria-hidden="true">
              {renderNavIcon(item.icon)}
            </span>
            <span className="member-nav-label" style={{ color }}>{item.label}</span>
          </button>
        );
      })}
    </nav>
  );
}

function MemberHomeTab({ theme, isBlind, speak, stopSpeech, loadingUserDoc, userDoc, navigate }) {
  useEffect(() => {
    if (!isBlind) return;
    if (loadingUserDoc) return;

    const name = userDoc?.fullName || userDoc?.name || 'Membre';
    const groupLabel = getGroupName(userDoc?.assignedGroup || userDoc?.group || userDoc?.groupId);

    speak(`Bienvenue sur l'écran d'accueil, ${name}. Vous êtes dans le groupe ${groupLabel}.`);
    return () => stopSpeech();
  }, [isBlind, loadingUserDoc, userDoc, speak, stopSpeech]);

  const name = userDoc?.fullName || userDoc?.name || 'Membre';
  const firstName = String(name).split(' ')[0] || 'Membre';
  const groupLabel = getGroupName(userDoc?.assignedGroup || userDoc?.group || userDoc?.groupId);
  const groupColor = getGroupColor(userDoc?.assignedGroup || userDoc?.group || userDoc?.groupId);

  return (
    <div className="member-tab-fill" style={{ background: theme.background }}>
      <div className="member-appbar" style={{ background: theme.primary, color: '#fff' }}>
        <div className="member-appbar-title">Running Club Tunis</div>
        <button
          className="icon-button-light"
          onClick={() => navigate('/notifications')}
          aria-label="Notifications"
          style={{ width: 44, height: 44, padding: 8, display: 'flex', alignItems: 'center', justifyContent: 'center' }}
        >
          <NotificationBadge>
            <span className="material-icons" style={{ fontSize: 24 }}>notifications</span>
          </NotificationBadge>
        </button>
      </div>

      <div className="member-tab-content">
        <div className="member-card member-welcome" style={{ background: theme.primary, color: '#fff' }}>
          <div className="member-welcome-row">
            <div className="member-avatar" aria-hidden="true">{firstName[0]?.toUpperCase() || 'M'}</div>
            <div className="member-welcome-text">
              <div className="member-welcome-hello">Bonjour,</div>
              <div className="member-welcome-name">{firstName}</div>
            </div>
          </div>

          <div className="member-welcome-badges">
            <span className="member-badge" style={{ borderColor: 'rgba(255,255,255,0.35)', background: 'rgba(255,255,255,0.16)' }}>
              <span className="member-badge-dot" style={{ background: groupColor }} aria-hidden="true" />
              {groupLabel}
            </span>
          </div>
        </div>

        <div className="member-card" style={{ background: theme.surface, color: theme.textPrimary }}>
          <div className="member-section-title">Actions rapides</div>
          <div className="member-quick-grid">
            <QuickAction title="Événements" subtitle="Voir les entraînements" theme={theme} onClick={() => { }} />
            <QuickAction title="Historique" subtitle="Mes séances" theme={theme} onClick={() => { }} />
            <QuickAction title="Annonces" subtitle="Infos du club" theme={theme} onClick={() => { }} />
          </div>
        </div>

        <div className="member-card" style={{ background: theme.surface, color: theme.textPrimary }}>
          <div className="member-section-title">À venir</div>
          <div style={{ color: theme.textSecondary }}>
            Consultez l’onglet Événements pour voir toutes les sessions.
          </div>
        </div>
      </div>
    </div>
  );
}

function QuickAction({ title, subtitle, theme, onClick }) {
  return (
    <button
      type="button"
      className="member-quick"
      onClick={onClick}
      style={{ borderColor: theme.primary, color: theme.textPrimary }}
    >
      <div className="member-quick-title" style={{ color: theme.primary }}>{title}</div>
      <div className="member-quick-subtitle" style={{ color: theme.textSecondary }}>{subtitle}</div>
    </button>
  );
}

function MemberClubTab({ theme, isBlind, speak }) {
  useEffect(() => {
    if (!isBlind) return;
    speak("Le Club. Découvrez l'histoire et les valeurs du Running Club Tunis.");
  }, [isBlind, speak]);

  return (
    <div className="member-tab-fill" style={{ background: theme.background }}>
      <div className="member-appbar" style={{ background: theme.primary, color: '#fff' }}>
        <div className="member-appbar-title">Le Club</div>
      </div>

      <div className="member-tab-content">
        <div className="member-card" style={{ background: theme.surface, color: theme.textPrimary }}>
          <div className="member-section-title">Notre Histoire</div>
          <p className="member-paragraph" style={{ color: theme.textSecondary }}>
            Fondé en 2015 par un groupe de passionnés de course à pied, le Running Club Tunis a commencé avec seulement 10 membres.
            Aujourd'hui, nous sommes fiers de compter une grande communauté de coureurs.
          </p>
        </div>

        <div className="member-card" style={{ background: theme.surface, color: theme.textPrimary }}>
          <div className="member-section-title">Nos Valeurs</div>
          <div className="member-values">
            <ValueItem title="Inclusivité" desc="Ouvert à tous, quel que soit le niveau ou l'âge." theme={theme} />
            <ValueItem title="Dépassement" desc="Atteindre ses objectifs personnels, progressivement." theme={theme} />
            <ValueItem title="Solidarité" desc="On court ensemble, on ne laisse personne derrière." theme={theme} />
          </div>
        </div>
      </div>
    </div>
  );
}

function ValueItem({ title, desc, theme }) {
  return (
    <div className="member-value">
      <div className="member-value-title" style={{ color: theme.textPrimary }}>{title}</div>
      <div className="member-value-desc" style={{ color: theme.textSecondary }}>{desc}</div>
    </div>
  );
}

function MemberProfileTab({ theme, loadingUserDoc, userDoc, onLogout, navigate }) {
  const name = userDoc?.fullName || userDoc?.name || '';
  const email = userDoc?.email || auth.currentUser?.email || '';
  const groupLabel = getGroupName(userDoc?.assignedGroup || userDoc?.group || userDoc?.groupId);

  return (
    <div className="member-tab-fill" style={{ background: theme.background }}>
      <div className="member-appbar" style={{ background: theme.primary, color: '#fff', display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingRight: '8px' }}>
        <div className="member-appbar-title">Profil</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
          <button
            className="icon-button-light"
            onClick={() => navigate('/notifications')}
            aria-label="Notifications"
          >
            <NotificationBadge>
              <span className="material-icons" style={{ fontSize: 24 }}>notifications</span>
            </NotificationBadge>
          </button>
          <button className="icon-button-light" onClick={onLogout} title="Déconnexion">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
              <polyline points="16 17 21 12 16 7" />
              <line x1="21" y1="12" x2="9" y2="12" />
            </svg>
          </button>
        </div>
      </div>

      <div className="member-tab-content">
        <div className="member-card" style={{ background: theme.surface, color: theme.textPrimary }}>
          {loadingUserDoc ? (
            <div style={{ color: theme.textSecondary }}>Chargement...</div>
          ) : (
            <>
              <div className="member-section-title">Informations</div>
              <div className="member-kv">
                <div className="member-k">Nom</div>
                <div className="member-v">{name || '—'}</div>
              </div>
              <div className="member-kv">
                <div className="member-k">Email</div>
                <div className="member-v">{email || '—'}</div>
              </div>
              <div className="member-kv">
                <div className="member-k">Groupe</div>
                <div className="member-v">{groupLabel}</div>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}

function AICoachButton({ theme, onSelectTab }) {
  const [open, setOpen] = useState(false);

  return (
    <>
      {/* Floating chat bubble */}
      <button
        type="button"
        className="member-chat-bubble"
        onClick={() => onSelectTab(TABS.CHAT)}
        style={{ background: theme.primary, color: '#fff' }}
        aria-label="Chat du groupe"
        title="Chat du groupe"
      >
        <span className="material-icons" style={{ fontSize: 24 }}>chat</span>
      </button>

      <button
        type="button"
        className="member-ai"
        onClick={() => setOpen(true)}
        style={{ background: theme.primary, color: '#fff' }}
        aria-label="AI Coach"
        title="AI Coach"
      >
        AI
      </button>

      {open && (
        <div className="member-dialog-overlay" onClick={() => setOpen(false)}>
          <div className="member-dialog" onClick={(e) => e.stopPropagation()} style={{ background: theme.surface, color: theme.textPrimary }}>
            <div className="member-dialog-title">AI Coach</div>
            <div className="member-dialog-body" style={{ color: theme.textSecondary }}>
              Cette fonctionnalité sera disponible bientôt.
            </div>
            <div className="member-dialog-actions">
              <button type="button" className="member-dialog-btn" onClick={() => setOpen(false)} style={{ background: theme.primary, color: '#fff' }}>
                Fermer
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}

function renderNavIcon(name) {
  switch (name) {
    case 'home':
      return '⌂';
    case 'calendar':
      return '📅';
    case 'group':
      return '👥';
    case 'person':
      return '👤';
    default:
      return '•';
  }
}

function getTabLabel(tab) {
  switch (tab) {
    case TABS.HOME:
      return 'Accueil';
    case TABS.EVENTS:
      return 'Événements';
    case TABS.CLUB:
      return 'Le Club';
    case TABS.PROFILE:
      return 'Profil';
    default:
      return 'Accueil';
  }
}

function getGroupName(group) {
  const g = (group || '').toString().trim();
  const normalized = g.toLowerCase();

  if (normalized.includes('group1') || normalized === '1' || normalized === 'beginner' || normalized.includes('début')) return 'Débutants';
  if (normalized.includes('group2') || normalized === '2') return 'Intermédiaire';
  if (normalized.includes('group3') || normalized === '3' || normalized.includes('inter')) return 'Avancé';
  if (normalized.includes('group4') || normalized === '4' || normalized.includes('group5') || normalized === '5' || normalized.includes('adv') || normalized.includes('confirm')) return 'Confirmés';

  return 'Non assigné';
}

function getGroupColor(group) {
  const g = (group || '').toString();
  switch (g) {
    case RunningGroup.GROUP1:
      return appColors.beginner;
    case RunningGroup.GROUP2:
      return '#ef6c00';
    case RunningGroup.GROUP3:
      return appColors.intermediate;
    case RunningGroup.GROUP4:
    case RunningGroup.GROUP5:
      return appColors.advanced;
    default:
      return appColors.primary;
  }
}
