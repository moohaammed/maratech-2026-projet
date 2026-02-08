import { auth } from '../../lib/firebase';
import { useNavigate } from 'react-router-dom';
import EventListScreen from './events/EventListScreen';

export default function CoachDashboard() {
    const navigate = useNavigate();

    const handleLogout = async () => {
        await auth.signOut();
        navigate('/');
    };

    return (
        <div style={{ minHeight: '100vh', backgroundColor: '#f8f9fa' }}>
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
                <button onClick={handleLogout} className="icon-button-light" title="Déconnexion">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
                        <polyline points="16 17 21 12 16 7" />
                        <line x1="21" y1="12" x2="9" y2="12" />
                    </svg>
                </button>
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
