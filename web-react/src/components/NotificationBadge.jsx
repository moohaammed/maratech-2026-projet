import { useNotificationBadge } from '../core/services/NotificationService';

export default function NotificationBadge({ children, style, groupId }) {
    const unreadCount = useNotificationBadge(groupId);

    return (
        <div style={{ position: 'relative', display: 'inline-flex', ...style }}>
            {children}
            {unreadCount > 0 && (
                <span style={{
                    position: 'absolute',
                    top: '2px',
                    right: '2px',
                    width: '10px',
                    height: '10px',
                    backgroundColor: '#FF5252',
                    borderRadius: '50%',
                    border: '2px solid white',
                    boxShadow: '0 0 4px rgba(0,0,0,0.2)'
                }} />
            )}
        </div>
    );
}
