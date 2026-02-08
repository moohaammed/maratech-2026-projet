import { auth } from '../../lib/firebase';
import { useNavigate } from 'react-router-dom';
import NotificationBadge from '../../components/NotificationBadge';
import { useChatNotifications } from '../../core/services/NotificationService';
import EventListScreen from './events/EventListScreen';

export default function CoachDashboard({ currentUser }) {
    const navigate = useNavigate();
    const authUser = auth.currentUser;

    // Real-time Chat Notifications for Coaches
    useChatNotifications(authUser, currentUser?.assignedGroup || currentUser?.group || currentUser?.groupId);

    const handleLogout = async () => {
        await auth.signOut();
        navigate('/');
    };

    return (
        <div style={{ minHeight: '100vh', backgroundColor: 'var(--color-background)' }}>
            {/* AppBar */}
            <header style={{
                backgroundColor: 'var(--group-admin-primary)',
                color: 'white',
                padding: '16px',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                boxShadow: '0 2px 4px rgba(0,0,0,0.2)'
            }}>
                <div style={{ fontWeight: 'bold', fontSize: '20px' }}>Espace Coach</div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <button
                        className="icon-button-light"
                        onClick={() => navigate('/notifications')}
                        aria-label="Notifications"
                    >
                        <NotificationBadge groupId={currentUser?.assignedGroup || currentUser?.group || currentUser?.groupId}>
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
                                <path d="M13.73 21a2 2 0 0 1-3.46 0" />
                            </svg>
                        </NotificationBadge>
                    </button>
                    <button onClick={handleLogout} className="icon-button-light" title="Déconnexion">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
                            <polyline points="16 17 21 12 16 7" />
                            <line x1="21" y1="12" x2="9" y2="12" />
                        </svg>
                    </button>
                </div>
            </header>

            {/* Content using EventListScreen */}
            <EventListScreen canCreate={true} />

            {/* Note: FAB is inside EventListScreen, handled by canCreate prop if using Flutter pattern, 
                or we can hoist it here. Flutter puts FAB in Scaffold of EventListScreen. 
                I put FAB logic inside EventListScreen check. 
                Wait, I missed the FAB in EventListScreen.jsx implementation! 
                I need to add the FAB there or here. 
                Flutter: EventListScreen has the FAB. 
                Let's stick to that. I will update EventListScreen to include the FAB.
            */}
        </div>
    );
}
