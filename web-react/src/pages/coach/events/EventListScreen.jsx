import { useState, useEffect } from 'react';
import { EventService, EventModel, EventType, WeeklyEventSubType } from '../../../core/services/EventService';
import { RunningGroup } from '../../../core/services/UserService';
import { useNavigate } from 'react-router-dom';
import CreateEventDialog from './CreateEventDialog';
import EventLocationMap from '../../../components/EventLocationMap';
import './EventManagement.css';

export default function EventListScreen({ canCreate }) {
    const [events, setEvents] = useState([]);
    const [loading, setLoading] = useState(true);
    const [filterFrom, setFilterFrom] = useState(null);
    const [filterTo, setFilterTo] = useState(null);
    const [filterGroup, setFilterGroup] = useState('');
    const [showCreateDialog, setShowCreateDialog] = useState(false);
    const navigate = useNavigate();

    useEffect(() => {
        const unsubscribe = EventService.getEventsStream({
            fromDate: filterFrom,
            toDate: filterTo,
            group: filterGroup || null
        }, (data) => {
            setEvents(data);
            setLoading(false);
        }, (error) => {
            console.error(error);
            setLoading(false);
        });

        return () => unsubscribe();
    }, [filterFrom, filterTo, filterGroup]);

    const handleDateRangeClick = () => {
        const startStr = prompt("Date de début (YYYY-MM-DD):", filterFrom ? filterFrom.toISOString().split('T')[0] : new Date().toISOString().split('T')[0]);
        if (!startStr) return;

        const endStr = prompt("Date de fin (YYYY-MM-DD):", filterTo ? filterTo.toISOString().split('T')[0] : "");

        if (startStr) setFilterFrom(new Date(startStr));
        if (endStr) setFilterTo(new Date(endStr));
        else setFilterTo(null);
    };

    return (
        <div style={{ padding: '16px', width: '100%', margin: 0, minHeight: '100vh', boxSizing: 'border-box' }}>
            {/* Filters */}
            <div style={{
                backgroundColor: 'white',
                padding: '12px',
                borderRadius: '16px',
                marginBottom: '20px',
                display: 'flex', gap: '12px', alignItems: 'center',
                boxShadow: '0 4px 15px rgba(0,0,0,0.05)'
            }}>
                <button
                    onClick={handleDateRangeClick}
                    style={{
                        flex: 1,
                        padding: '10px 16px',
                        border: `1px solid var(--group-admin-primary)`,
                        borderRadius: '10px',
                        backgroundColor: 'white',
                        color: 'var(--group-admin-primary)',
                        fontWeight: '600',
                        cursor: 'pointer',
                        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px'
                    }}
                >
                    <span>📅</span>
                    {filterFrom ? (
                        `${filterFrom.toLocaleDateString()} - ${filterTo ? filterTo.toLocaleDateString() : '...'}`
                    ) : 'Toutes les dates'}
                </button>

                <select
                    value={filterGroup}
                    onChange={(e) => setFilterGroup(e.target.value)}
                    style={{
                        flex: 1,
                        padding: '10px 16px',
                        border: '1px solid #eee',
                        borderRadius: '10px',
                        backgroundColor: '#fafafa',
                        fontWeight: '500',
                        outline: 'none'
                    }}
                >
                    <option value="">Tous les groupes</option>
                    <option value={RunningGroup.GROUP1}>Débutants</option>
                    <option value={RunningGroup.GROUP2}>Intermédiaire</option>
                    <option value={RunningGroup.GROUP3}>Avancé</option>
                    <option value={RunningGroup.GROUP4}>Confirmés</option>
                    <option value={RunningGroup.GROUP5}>Compétition</option>
                </select>
            </div>

            {/* List */}
            {loading ? (
                <div style={{ textAlign: 'center', padding: '60px' }}>Chargement...</div>
            ) : events.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '60px', color: '#888' }}>
                    <div style={{ fontSize: '48px', marginBottom: '16px', opacity: 0.3 }}>🏃‍♂️</div>
                    <h3>Aucun événement trouvé</h3>
                    <p>Modifiez vos filtres ou créez une session.</p>
                </div>
            ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '16px', paddingBottom: '100px' }}>
                    {events.map(event => (
                        <div key={event.id} onClick={() => navigate(`/events/${event.id}`)}>
                            <EventCard event={event} />
                        </div>
                    ))}
                </div>
            )}

            {/* FAB */}
            {canCreate && (
                <button
                    className="group-admin-fab"
                    onClick={() => setShowCreateDialog(true)}
                    title="Créer un événement"
                >
                    <span>+</span> Nouvel Événement
                </button>
            )}

            {showCreateDialog && (
                <CreateEventDialog onClose={() => setShowCreateDialog(false)} />
            )}

        </div >
    );
}

function EventCard({ event }) {
    const groupColor = getGroupColor(event.group);

    const formatDate = (date) => {
        return date.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit' });
    };

    return (
        <div className="group-card" style={{ marginBottom: 0, cursor: 'pointer' }}>
            <div style={{ padding: '16px 20px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '10px' }}>
                    <span style={{
                        backgroundColor: `${groupColor}20`,
                        color: groupColor,
                        padding: '3px 10px',
                        borderRadius: '20px',
                        fontSize: '11px',
                        fontWeight: '800',
                        textTransform: 'uppercase',
                        border: `1px solid ${groupColor}40`
                    }}>
                        {event.groupDisplayName}
                    </span>

                    <span style={{ fontSize: '12px', color: '#777', fontWeight: '500' }}>
                        {event.typeDisplayName}
                    </span>

                    {event.weeklySubType && (
                        <span style={{ fontSize: '11px', color: 'var(--group-admin-primary)', fontWeight: '700' }}>
                            {event.weeklySubTypeDisplayName}
                        </span>
                    )}

                    <div style={{ flex: 1 }} />

                    <div style={{ fontSize: '13px', color: '#555', fontWeight: '600', display: 'flex', alignItems: 'center', gap: '5px' }}>
                        <span>📅</span> {formatDate(event.date)}
                        <span>·</span>
                        <span>🕒</span> {event.time}
                    </div>
                </div>

                <h3 style={{ margin: '0 0 6px 0', fontSize: '18px', color: '#333', fontWeight: '800' }}>
                    {event.title}
                </h3>

                <div style={{ display: 'flex', alignItems: 'center', gap: '15px', color: '#777', fontSize: '13px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                        <span style={{ opacity: 0.7 }}>📍</span> {event.location}
                    </div>
                    {event.distanceKm && (
                        <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                            <span style={{ opacity: 0.7 }}>📏</span> {event.distanceKm} km
                        </div>
                    )}
                </div>

                {/* OpenStreetMap Integration */}
                <EventLocationMap
                    location={event.location}
                    latitude={event.meetingPoint?.coordinates?.lat || 36.8065}
                    longitude={event.meetingPoint?.coordinates?.lng || 10.1815}
                />
            </div>
        </div>
    );
}

function getGroupColor(group) {
    switch (group) {
        case RunningGroup.GROUP1:
        case 'RunningGroup.group1': return '#2e7d32';
        case RunningGroup.GROUP2:
        case 'RunningGroup.group2': return '#ef6c00';
        case RunningGroup.GROUP3:
        case 'RunningGroup.group3':
        case RunningGroup.GROUP4:
        case 'RunningGroup.group4': return '#c62828';
        case RunningGroup.GROUP5:
        case 'RunningGroup.group5': return '#1a237e';
        default: return '#0288d1';
    }
}

