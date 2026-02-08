import { useState, useEffect, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { collection, query, where, orderBy, limit, onSnapshot, Timestamp } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { EventModel } from '../core/services/EventService';
import { useAccessibility } from '../core/services/AccessibilityContext';
import { useSpeechSynthesis } from '../hooks/useSpeech';
import { appColors } from '../core/theme/appColors';
import { NotificationService } from '../core/services/NotificationService';
import './NotificationScreen.css';

export default function NotificationScreen() {
    const navigate = useNavigate();
    const accessibility = useAccessibility();
    const { speak, stop: stopSpeech } = useSpeechSynthesis();

    const [events, setEvents] = useState([]);
    const [loading, setLoading] = useState(true);
    const [permissionStatus, setPermissionStatus] = useState(
        (typeof window !== 'undefined' && window.Notification) ? window.Notification.permission : 'default'
    );
    const [isSecureContext] = useState(typeof window !== 'undefined' ? window.isSecureContext : false);

    useEffect(() => {
        NotificationService.markAsRead();
    }, []);

    const isBlind = accessibility?.visualNeeds === 'blind';
    const highContrast = !!accessibility?.highContrast;
    const textScale = accessibility?.textScale || 1.0;

    const theme = useMemo(() => {
        const primary = highContrast ? '#00E676' : appColors.primary;
        const background = highContrast ? '#000000' : appColors.background;
        const surface = highContrast ? '#121212' : '#FFFFFF';
        const textPrimary = highContrast ? '#FFFFFF' : appColors.textPrimary;
        const textSecondary = highContrast ? 'rgba(255,255,255,0.7)' : appColors.textSecondary;
        return { primary, background, surface, textPrimary, textSecondary };
    }, [highContrast]);

    useEffect(() => {
        const eventsRef = collection(db, 'events');
        const q = query(
            eventsRef,
            where('date', '>=', Timestamp.now()),
            orderBy('date', 'asc'),
            limit(20)
        );

        const unsubscribe = onSnapshot(q, (snapshot) => {
            const fetchedEvents = snapshot.docs.map(doc => EventModel.fromFirestore(doc));
            setEvents(fetchedEvents);
            setLoading(false);

            if (isBlind && fetchedEvents.length > 0) {
                speak(`Vous avez ${fetchedEvents.length} nouvelles notifications d'événements.`);
            }
        }, (error) => {
            console.error("Error fetching notifications:", error);
            setLoading(false);
        });

        return () => {
            unsubscribe();
            stopSpeech();
        };
    }, [isBlind, speak, stopSpeech]);

    const formatTime = (date) => {
        if (!date) return '';
        try {
            const d = date instanceof Date ? date : (date.toDate ? date.toDate() : new Date(date));
            return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        } catch (e) {
            return '';
        }
    };

    const formatDate = (date) => {
        if (!date) return '';
        try {
            const d = date instanceof Date ? date : (date.toDate ? date.toDate() : new Date(date));
            return d.toLocaleDateString('fr-FR', { day: 'numeric', month: 'short', year: 'numeric' });
        } catch (e) {
            return '';
        }
    };

    const handleRequestPermission = async () => {
        const granted = await NotificationService.requestDesktopPermission();
        setPermissionStatus(Notification.permission);
        if (granted) {
            NotificationService.sendDesktopNotification("Succès !", "Les notifications sont maintenant activées sur votre PC.");
        }
    };

    const handleSendTest = () => {
        NotificationService.sendDesktopNotification("Test Maratech", "Ceci est une notification de test.");
    };

    const getBody = (event) => {
        const type = event.type || 'daily';
        const location = event.location || 'Tunis';
        if (type === 'daily') {
            return `Entraînement quotidien à ${location}.`;
        }
        return `Événement spécial : ${location}. Préparez-vous !`;
    };

    return (
        <div className="notification-page" style={{ background: theme.background, color: theme.textPrimary }}>
            <header className="notification-appbar" style={{ background: highContrast ? theme.surface : theme.primary }}>
                <div className="notification-appbar-content">
                    <button className="back-button" onClick={() => navigate(-1)} aria-label="Retour">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                            <path d="M15 18l-6-6 6-6" />
                        </svg>
                    </button>
                    <h1>Notifications</h1>
                    <div style={{ width: 40 }}></div>
                </div>
            </header>

            <main className="notification-container" style={{ padding: 16 }}>
                {loading ? (
                    <div className="notification-loader">Chargement...</div>
                ) : events.length === 0 ? (
                    <div className="notification-empty">
                        <div className="empty-icon" style={{ color: theme.textSecondary }}>🔔</div>
                        <h3>Aucune nouvelle notification</h3>
                        <p style={{ color: theme.textSecondary }}>Revenez plus tard pour voir les nouveaux événements.</p>
                    </div>
                ) : (
                    <div className="notification-list">
                        {events.map((event) => (
                            <div
                                key={event.id}
                                className="notification-card"
                                onClick={() => navigate(`/events/${event.id}`)}
                                style={{
                                    background: theme.surface,
                                    borderColor: highContrast ? 'rgba(255,255,255,0.2)' : 'rgba(0,0,0,0.05)',
                                    fontSize: `${16 * textScale}px`
                                }}
                            >
                                <div className="notification-card-icon" style={{ background: event.type === 'weekly' ? 'rgba(41, 121, 255, 0.1)' : 'rgba(229, 57, 53, 0.1)' }}>
                                    <span style={{ color: event.type === 'weekly' ? '#2979FF' : theme.primary }}>
                                        {event.type === 'weekly' ? '⭐' : '🏃'}
                                    </span>
                                </div>
                                <div className="notification-card-content">
                                    <div className="notification-card-header">
                                        <h4 style={{ color: theme.textPrimary }}>{event.title || 'Nouveau message'}</h4>
                                        <span className="notification-time" style={{ color: theme.textSecondary }}>
                                            {formatTime(event.date)}
                                        </span>
                                    </div>
                                    <p className="notification-body" style={{ color: theme.textSecondary }}>
                                        {getBody(event)}
                                    </p>
                                    <span className="notification-date" style={{ color: event.type === 'weekly' ? '#2979FF' : theme.primary }}>
                                        {formatDate(event.date)}
                                    </span>
                                </div>
                            </div>
                        ))}
                    </div>
                )}

                {/* Always visible debug box */}
                <div style={{
                    marginTop: 40,
                    padding: '24px 20px',
                    borderRadius: 16,
                    background: theme.surface,
                    border: `1px solid ${highContrast ? '#fff' : '#eee'}`,
                    textAlign: 'left',
                    boxShadow: '0 4px 12px rgba(0,0,0,0.05)'
                }}>
                    <h4 style={{ margin: '0 0 12px 0', fontSize: 18 }}>🛠️ Diagnostic Notifications</h4>

                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 20 }}>
                        <div style={{ padding: 12, borderRadius: 10, background: theme.background }}>
                            <div style={{ fontSize: 11, opacity: 0.6, textTransform: 'uppercase' }}>Autorisation</div>
                            <div style={{ fontWeight: '700', fontSize: 14 }}>
                                {permissionStatus === 'granted' ? '✅ Accordée' :
                                    permissionStatus === 'denied' ? '❌ Bloquée' : '⏳ En attente'}
                            </div>
                        </div>
                        <div style={{ padding: 12, borderRadius: 10, background: theme.background }}>
                            <div style={{ fontSize: 11, opacity: 0.6, textTransform: 'uppercase' }}>Connexion</div>
                            <div style={{ fontWeight: '700', fontSize: 14 }}>
                                {isSecureContext ? '🔒 Sécurisée' : '⚠️ Non Sécurisée'}
                            </div>
                        </div>
                    </div>

                    {!isSecureContext && (
                        <div style={{
                            padding: 12, borderRadius: 10, background: 'rgba(229, 57, 53, 0.1)',
                            color: '#E53935', fontSize: 13, marginBottom: 20, lineHeight: 1.4
                        }}>
                            <strong>Problème détecté :</strong> Votre navigateur bloque les notifications car le site n'est pas en HTTPS (ou localhost).
                        </div>
                    )}

                    <div style={{ display: 'flex', gap: 12 }}>
                        <button
                            onClick={handleRequestPermission}
                            style={{
                                flex: 1, padding: '12px', borderRadius: 12, border: 'none',
                                background: theme.primary, color: '#fff', fontSize: 14, fontWeight: '700', cursor: 'pointer'
                            }}
                        >
                            Activer maintenant
                        </button>
                        {permissionStatus === 'granted' && (
                            <button
                                onClick={handleSendTest}
                                style={{
                                    flex: 1, padding: '12px', borderRadius: 12, border: `2px solid ${theme.primary}`,
                                    background: 'none', color: theme.primary, fontSize: 14, fontWeight: '700', cursor: 'pointer'
                                }}
                            >
                                Envoyer un test
                            </button>
                        )}
                    </div>
                </div>
            </main>
        </div>
    );
}
