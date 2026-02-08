import { useState } from 'react';
import { auth } from '../../../lib/firebase';
import { EventService, EventModel, EventType, WeeklyEventSubType } from '../../../core/services/EventService';
import { RunningGroup } from '../../../core/services/UserService';
import LocationPicker from '../../../components/LocationPicker';
import './EventManagement.css';

export default function CreateEventDialog({ onClose, onCreated }) {
    const [title, setTitle] = useState('');
    const [titleAr, setTitleAr] = useState('');
    const [description, setDescription] = useState('');
    const [descriptionAr, setDescriptionAr] = useState('');
    const [location, setLocation] = useState('');
    const [coordinates, setCoordinates] = useState({ lat: 36.8065, lng: 10.1815 });
    const [meetingPointAddress, setMeetingPointAddress] = useState('');
    const [date, setDate] = useState(new Date().toISOString().split('T')[0]);
    const [time, setTime] = useState('09:00');
    const [distanceKm, setDistanceKm] = useState('');
    const [targetPace, setTargetPace] = useState('');
    const [maxParticipants, setMaxParticipants] = useState('40');
    const [publicTransport, setPublicTransport] = useState('');
    const [eventType, setEventType] = useState(EventType.DAILY);
    const [weeklySubType, setWeeklySubType] = useState(WeeklyEventSubType.LONG_RUN);
    const [selectedGroup, setSelectedGroup] = useState(RunningGroup.GROUP1);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const DEFAULT_DURATION_MIN = 90;

    const languageCode = (() => {
        try {
            return localStorage.getItem('accessibility_languageCode') || 'fr';
        } catch {
            return 'fr';
        }
    })();
    const isArabic = languageCode === 'ar';

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!title.trim() || !location.trim()) {
            setError('Le titre et le lieu sont requis');
            return;
        }

        // Add error boundary for LocationPicker
        try {
            // Validate coordinates
            if (!coordinates || !coordinates.lat || !coordinates.lng) {
                setError('Les coordonnées de localisation sont requises');
                return;
            }
        } catch (err) {
            console.error('Location validation error:', err);
            setError('Erreur de validation de la localisation');
            return;
        }

        setLoading(true);
        setError('');

        try {
            const dateOnly = new Date(date);
            const [hh, mm] = (time || '09:00').split(':').map(v => parseInt(v, 10));
            const startDateTime = new Date(
                dateOnly.getFullYear(),
                dateOnly.getMonth(),
                dateOnly.getDate(),
                Number.isFinite(hh) ? hh : 9,
                Number.isFinite(mm) ? mm : 0,
                0,
                0
            );
            const endDateTime = new Date(startDateTime.getTime() + DEFAULT_DURATION_MIN * 60 * 1000);

            const formatHHMM = (d) => {
                const h = d.getHours().toString().padStart(2, '0');
                const m = d.getMinutes().toString().padStart(2, '0');
                return `${h}:${m}`;
            };

            const event = new EventModel({
                id: '',
                title: title.trim(),
                titleAr: isArabic ? (titleAr.trim() || null) : null,
                description: description.trim() || null,
                descriptionAr: isArabic ? (descriptionAr.trim() || null) : null,
                type: eventType,
                weeklySubType: eventType === EventType.WEEKLY ? weeklySubType : null,
                group: eventType === EventType.DAILY ? selectedGroup : null,
                date: new Date(date),
                time: time || '09:00',
                startTime: formatHHMM(startDateTime),
                endTime: formatHHMM(endDateTime),
                duration: DEFAULT_DURATION_MIN,
                location: location.trim(),
                distanceKm: distanceKm ? parseFloat(distanceKm.replace(',', '.')) : null,
                targetPace: targetPace.trim() || null,

                // Static / default fields saved to Firestore (not exposed in the form)
                accessibility: {
                    audioGuidanceAvailable: true,
                    buddySystemAvailable: true,
                    signLanguageSupport: false,
                    visualGuidanceAvailable: true,
                    wheelchairAccessible: false,
                },
                category: 'tempo',
                intensity: 'high',
                status: 'upcoming',
                isAllGroups: false,
                isCancelled: false,
                isFeatured: true,
                isPinned: false,
                maxParticipants: Number.isFinite(parseInt(maxParticipants, 10)) ? parseInt(maxParticipants, 10) : 40,
                participants: [],
                participantCount: 0,
                waitlist: [],
                parkingAvailable: true,
                publicTransport: publicTransport
                    ? publicTransport
                        .split(',')
                        .map(s => s.trim())
                        .filter(Boolean)
                    : [],
                meetingPoint: {
                    address: (meetingPointAddress || location).trim(),
                    coordinates: coordinates,
                    name: (meetingPointAddress || location).trim(),
                    nameAr: null,
                },
                route: {
                    difficulty: 'moderate',
                    distance: distanceKm ? parseFloat(distanceKm.replace(',', '.')) : null,
                    elevation: null,
                    routeDescription: null,
                    routeDescriptionAr: null,
                    terrain: null,
                },
                groupId: null,
                groupName: null,
                groupColor: null,
                createdAt: new Date(),
                createdBy: auth.currentUser?.uid,
                creatorName: auth.currentUser?.displayName || null,
                creatorRole: null,
                publishedAt: new Date(),
                updatedAt: new Date(),
            });

            await EventService.createEvent(event);
            onCreated?.();
            onClose();
        } catch (err) {
            console.error(err);
            setError("Erreur lors de la création de l'événement");
        } finally {
            setLoading(false);
        }
    };

    console.log('CreateEventDialog: Rendering dialog, location:', location, 'coordinates:', coordinates);

    return (
        <div className="admin-dialog-overlay" onClick={onClose}>
            <div className="admin-dialog-content event-dialog" onClick={e => e.stopPropagation()}>
                <header className="event-dialog-header">
                    <h2>Créer un événement</h2>
                    <button className="close-btn" onClick={onClose}>&times;</button>
                </header>

                <form onSubmit={handleSubmit} className="event-form">
                    <div className="event-dialog-body">
                        <div className="form-section">
                            <label>Titre *</label>
                            <div className="input-group">
                                <span className="input-icon">Title</span>
                                <input
                                    type="text"
                                    value={title}
                                    onChange={(e) => setTitle(e.target.value)}
                                    placeholder="Entrez le titre"
                                    required
                                />
                            </div>
                        </div>

                        {isArabic && (
                            <div className="form-section">
                                <label>Titre (Arabe)</label>
                                <div className="input-group">
                                    <span className="input-icon">AR</span>
                                    <input
                                        type="text"
                                        value={titleAr}
                                        onChange={(e) => setTitleAr(e.target.value)}
                                        placeholder="عنوان بالعربية (اختياري)"
                                    />
                                </div>
                            </div>
                        )}

                        <div className="form-section">
                            <label>Description</label>
                            <textarea
                                value={description}
                                onChange={(e) => setDescription(e.target.value)}
                                placeholder="Description optionnelle"
                                rows="2"
                            />
                        </div>

                        {isArabic && (
                            <div className="form-section">
                                <label>Description (Arabe)</label>
                                <textarea
                                    value={descriptionAr}
                                    onChange={(e) => setDescriptionAr(e.target.value)}
                                    placeholder="وصف بالعربية (اختياري)"
                                    rows="2"
                                />
                            </div>
                        )}

                        <div className="form-row">
                            <div className="form-section flex-1">
                                <label>Type *</label>
                                <select value={eventType} onChange={(e) => setEventType(e.target.value)}>
                                    <option value={EventType.DAILY}>Quotidien (par groupe)</option>
                                    <option value={EventType.WEEKLY}>Hebdomadaire</option>
                                </select>
                            </div>

                            {eventType === EventType.WEEKLY ? (
                                <div className="form-section flex-1">
                                    <label>Sous-type *</label>
                                    <select value={weeklySubType} onChange={(e) => setWeeklySubType(e.target.value)}>
                                        <option value={WeeklyEventSubType.LONG_RUN}>Sortie longue</option>
                                        <option value={WeeklyEventSubType.SPECIAL_EVENT}>Course officielle</option>
                                    </select>
                                </div>
                            ) : (
                                <div className="form-section flex-1">
                                    <label>Groupe *</label>
                                    <select value={selectedGroup} onChange={(e) => setSelectedGroup(e.target.value)}>
                                        <option value={RunningGroup.GROUP1}>Débutants</option>
                                        <option value={RunningGroup.GROUP2}>Intermédiaire</option>
                                        <option value={RunningGroup.GROUP3}>Avancé</option>
                                        <option value={RunningGroup.GROUP4}>Confirmés</option>
                                        <option value={RunningGroup.GROUP5}>Compétition</option>
                                    </select>
                                </div>
                            )}
                        </div>

                        <div className="form-row">
                            <div className="form-section flex-1">
                                <label>Date *</label>
                                <input type="date" value={date} onChange={(e) => setDate(e.target.value)} required />
                            </div>
                            <div className="form-section flex-1">
                                <label>Heure *</label>
                                <input type="time" value={time} onChange={(e) => setTime(e.target.value)} required />
                            </div>
                        </div>

                        <div className="form-section">
                            <label>Lieu *</label>
                            <div style={{ border: '1px solid #ddd', borderRadius: '8px', padding: '8px' }}>
                                <LocationPicker
                                    value={location}
                                    onChange={setLocation}
                                    onCoordinatesChange={setCoordinates}
                                    placeholder="Recherchez ou cliquez sur la carte pour sélectionner le lieu"
                                />
                            </div>
                        </div>

                        <div className="form-row">
                            <div className="form-section flex-1">
                                <label>Distance (km)</label>
                                <input type="text" value={distanceKm} onChange={(e) => setDistanceKm(e.target.value)} placeholder="0.0" />
                            </div>
                            <div className="form-section flex-1">
                                <label>Adresse du rendez-vous</label>
                                <input
                                    type="text"
                                    value={meetingPointAddress}
                                    onChange={(e) => setMeetingPointAddress(e.target.value)}
                                    placeholder="Ex: Avenue de la Ligue Arabe, Tunis"
                                />
                            </div>
                        </div>

                        <div className="form-row">
                            <div className="form-section flex-1">
                                <label>Allure cible</label>
                                <input
                                    type="text"
                                    value={targetPace}
                                    onChange={(e) => setTargetPace(e.target.value)}
                                    placeholder="Ex: 5:45"
                                />
                            </div>
                            <div className="form-section flex-1">
                                <label>Max participants</label>
                                <input
                                    type="number"
                                    value={maxParticipants}
                                    onChange={(e) => setMaxParticipants(e.target.value)}
                                    min="1"
                                    step="1"
                                />
                            </div>
                        </div>

                        <div className="form-section">
                            <label>Transport public (séparé par des virgules)</label>
                            <input
                                type="text"
                                value={publicTransport}
                                onChange={(e) => setPublicTransport(e.target.value)}
                                placeholder="Ex: Bus 20, Metro Ligne 5"
                            />
                        </div>

                        {error && <div className="error-message">{error}</div>}
                    </div>

                    <div className="dialog-actions">
                        <button type="button" className="cancel-btn" onClick={onClose}>Annuler</button>
                        <button type="submit" className="submit-btn" disabled={loading}>
                            {loading ? 'Création...' : 'Créer l\'événement'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}
