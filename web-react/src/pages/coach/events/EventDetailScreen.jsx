import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { EventService, EventModel } from '../../../core/services/EventService';
import OpenStreetMap from '../../../components/OpenStreetMap';
import './EventManagement.css';

export default function EventDetailScreen() {
    const { id } = useParams();
    const navigate = useNavigate();
    const [event, setEvent] = useState(null);
    const [loading, setLoading] = useState(true);
    const [coordinates, setCoordinates] = useState({ lat: 36.8065, lng: 10.1815 }); // Default to Tunis

    // Function to geocode location if coordinates aren't available
    const geocodeLocation = async (location) => {
        if (!location) return;
        
        try {
            const response = await fetch(
                `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(
                    location
                )}&limit=1&addressdetails=1&countrycodes=tn`
            );
            
            if (response.ok) {
                const data = await response.json();
                if (data.length > 0) {
                    setCoordinates({
                        lat: parseFloat(data[0].lat),
                        lng: parseFloat(data[0].lon)
                    });
                }
            }
        } catch (error) {
            console.error('Error geocoding location:', error);
        }
    };

    useEffect(() => {
        const fetchEvent = async () => {
            try {
                const data = await EventService.getEventById(id);
                setEvent(data);
                
                // Set coordinates if available, otherwise geocode
                if (data.meetingPoint?.coordinates?.lat && data.meetingPoint?.coordinates?.lng) {
                    setCoordinates({
                        lat: data.meetingPoint.coordinates.lat,
                        lng: data.meetingPoint.coordinates.lng
                    });
                } else if (data.location) {
                    // Geocode the location to get coordinates
                    await geocodeLocation(data.location);
                }
            } catch (error) {
                console.error(error);
            } finally {
                setLoading(false);
            }
        };
        fetchEvent();
    }, [id]);

    if (loading) {
        return <div className="detail-loading">Chargement de l'événement...</div>;
    }

    if (!event) {
        return (
            <div className="detail-error">
                <h3>Événement introuvable</h3>
                <button onClick={() => navigate(-1)}>Retour</button>
            </div>
        );
    }

    const groupColor = getGroupColor(event.group);

    return (
        <div className="event-detail-container">
            <header className="detail-header" style={{ backgroundColor: 'var(--group-admin-primary)' }}>
                <button className="back-btn" onClick={() => navigate(-1)}>←</button>
                <h2>Détail de l'événement</h2>
                <div style={{ width: '40px' }}></div>
            </header>

            <main className="detail-content">
                <section className="detail-card main-card" style={{ borderLeft: `6px solid ${groupColor}` }}>
                    <div className="card-top">
                        <span className="badge-group" style={{ backgroundColor: `${groupColor}20`, color: groupColor, border: `1px solid ${groupColor}` }}>
                            {event.groupDisplayName}
                        </span>
                        <span className="badge-type">{event.typeDisplayName}</span>
                    </div>
                    <h1 className="detail-title">{event.title}</h1>
                    <p className="detail-datetime">
                        <span className="icon">📅</span> {event.date.toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' })}
                        <span className="separator">·</span>
                        <span className="icon">🕒</span> {event.time}
                    </p>
                </section>

                <section className="detail-card">
                    <h3 className="section-title">Informations</h3>
                    <div className="info-grid">
                        <InfoItem icon="📍" label="Lieu" value={event.location} />
                        <InfoItem icon="📏" label="Distance" value={event.distanceKm ? `${event.distanceKm} km` : 'N/A'} />
                        {event.weeklySubType && (
                            <InfoItem icon="🏃" label="Sous-type" value={event.weeklySubTypeDisplayName} />
                        )}
                        <InfoItem icon="👥" label="Visibilité" value={event.group ? 'Spécifique au groupe' : 'Tous les membres'} />
                    </div>
                </section>

                {/* Map Section */}
                <section className="detail-card">
                    <h3 className="section-title">📍 Localisation sur la carte</h3>
                    <div style={{ 
                        border: '1px solid #ddd', 
                        borderRadius: '8px', 
                        overflow: 'hidden',
                        boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
                        minHeight: '300px',
                        backgroundColor: '#f9f9f9',
                        position: 'relative'
                    }}>
                        <OpenStreetMap
                            latitude={coordinates.lat}
                            longitude={coordinates.lng}
                            zoom={15}
                            height="300px"
                            markers={[
                                {
                                    lat: coordinates.lat,
                                    lng: coordinates.lng,
                                    popup: event.location || 'Localisation de l\'événement'
                                }
                            ]}
                            className="openstreetmap-container"
                        />
                    </div>
                    {event.location && (
                        <div style={{ 
                            marginTop: '12px', 
                            fontSize: '14px', 
                            color: '#666',
                            padding: '8px',
                            backgroundColor: 'white',
                            borderRadius: '4px',
                            borderLeft: '3px solid #007bff'
                        }}>
                            📍 {event.location}
                        </div>
                    )}
                </section>

                {event.description && (
                    <section className="detail-card">
                        <h3 className="section-title">Description</h3>
                        <div className="description-text">{event.description}</div>
                    </section>
                )}
            </main>
        </div>
    );
}

function InfoItem({ icon, label, value }) {
    return (
        <div className="info-item">
            <span className="info-icon">{icon}</span>
            <div className="info-text">
                <span className="info-label">{label}</span>
                <span className="info-value">{value}</span>
            </div>
        </div>
    );
}

function getGroupColor(group) {
    // Mirroring common group colors
    switch (group) {
        case 'RunningGroup.group1': return '#2e7d32';
        case 'RunningGroup.group2': return '#ef6c00';
        case 'RunningGroup.group3':
        case 'RunningGroup.group4': return '#c62828';
        case 'RunningGroup.group5': return '#1a237e';
        default: return '#0288d1';
    }
}
