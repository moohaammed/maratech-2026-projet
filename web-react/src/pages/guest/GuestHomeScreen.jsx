import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useSpeechSynthesis } from '../../hooks/useSpeech';
import { useAccessibility } from '../../core/services/AccessibilityContext';
import { appColors } from '../../core/theme/appColors';
import EventListScreen from '../coach/events/EventListScreen';
import './GuestHomeScreen.css';

export default function GuestHomeScreen() {
    const [activeTab, setActiveTab] = useState('club');
    const navigate = useNavigate();
    const { speak, stop: stopSpeech } = useSpeechSynthesis();
    const accessibility = useAccessibility();
    // Get accessibility context
    const textScale = accessibility?.textScale || 1;
    const highContrast = accessibility?.highContrast || false;
    const isBlind = accessibility?.visualNeeds === 'blind';
    const primaryColor = highContrast ? appColors.highContrastPrimary : appColors.primary;
    const borderColor = highContrast ? '#FFFFFF' : appColors.divider;

    useEffect(() => {
        if (isBlind) {
            speak('Mode invité activé. Vous pouvez consulter l\'histoire du club, nos valeurs, la liste des événements et nos réseaux sociaux. Utilisez les onglets en haut de l\'écran pour naviguer.');
        }
        return () => stopSpeech();
    }, [isBlind, speak, stopSpeech]);

    return (
        <div className="page-container guest-full-page">
            {/* Page Header */}
            <div className="page-header">
                <div className="page-header-content">
                    <div className="page-title-section">
                        <h1 className="page-title">Running Club Tunis</h1>
                        <p className="page-subtitle">Bienvenue dans notre communauté de coureurs</p>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <button
                            onClick={() => navigate('/')}
                            className="login-button"
                            style={{
                                height: `${44 * Math.min(textScale, 1.2)}px`,
                                backgroundColor: primaryColor,
                                color: highContrast ? '#000000' : '#FFFFFF',
                                border: highContrast ? `2px solid ${borderColor}` : 'none',
                                borderRadius: '12px',
                                padding: `0 ${20 * Math.min(textScale, 1.2)}px`,
                                fontSize: `${14 * textScale}px`,
                                fontWeight: 'bold',
                                cursor: 'pointer',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                gap: '8px',
                                transition: 'all 0.2s ease',
                                boxShadow: highContrast ? 'none' : `0 4px 12px ${appColors.primary}33`,
                            }}
                            title="Se connecter"
                        >
                            <span>→</span>
                            <span>Se connecter</span>
                        </button>
                    </div>
                </div>
            </div>

            {/* Navigation Tabs */}
            <div className="tabs-container">
                <div className="tabs">
                    <button
                        className={`tab ${activeTab === 'club' ? 'active' : ''}`}
                        onClick={() => setActiveTab('club')}
                        aria-label="Histoire du Club"
                    >
                        <span>🏛️</span>
                        Le Club
                    </button>
                    <button
                        className={`tab ${activeTab === 'values' ? 'active' : ''}`}
                        onClick={() => setActiveTab('values')}
                        aria-label="Valeurs et Charte"
                    >
                        <span>💎</span>
                        Nos Valeurs
                    </button>
                    <button
                        className={`tab ${activeTab === 'events' ? 'active' : ''}`}
                        onClick={() => setActiveTab('events')}
                        aria-label="Événements"
                    >
                        <span>📅</span>
                        Événements
                    </button>
                    <button
                        className={`tab ${activeTab === 'social' ? 'active' : ''}`}
                        onClick={() => setActiveTab('social')}
                        aria-label="Réseaux Sociaux"
                    >
                        <span>📱</span>
                        Réseaux Sociaux
                    </button>
                </div>
            </div>

            {/* Tab Content */}
            <div className="content-container">
                <div className="content-card">
                    {activeTab === 'club' && <HistoryTab />}
                    {activeTab === 'values' && <ValuesTab />}
                    {activeTab === 'events' && <EventListScreen canCreate={false} />}
                    {activeTab === 'social' && <SocialTab />}
                </div>
            </div>
        </div>
    );
}

function HistoryTab() {
    return (
        <div className="content-section">
            <div className="content-header">
                <h2 className="content-title">Notre Histoire</h2>
                <p className="content-description">Découvrez l'histoire passionnante de notre club</p>
            </div>

            <div className="card-grid">
                <div className="info-card">
                    <div className="info-card-icon">🏛️</div>
                    <div className="info-card-content">
                        <h3 className="info-card-title">Origines du Club</h3>
                        <p className="info-card-text">
                            Fondé en <strong>2015</strong> par un petit groupe d’amis joggeurs, le Running Club Tunis est vite devenu
                            la référence running de la capitale. Aujourd’hui nous comptons <strong>plus de 250 membres</strong>
                            répartis en 5 groupes d’entraînement, du débutant au semi-pro.
                        </p>
                        <p className="info-card-text" style={{ marginTop: 12 }}>
                            📈 <strong>5 000 km</strong> cumulés chaque semaine<br />
                            🏅 <strong>80 compétitions</strong> par saison<br />
                            🌍 Runners de <strong>22 nationalités</strong>
                        </p>
                        <div style={{ marginTop: 16 }}>
                            <span className="badge" style={{ background: '#e8f5e9', color: '#2e7d32', padding: '4px 8px', borderRadius: 4, fontSize: 12 }}>
                                Rejoignez-nous →
                            </span>
                        </div>
                    </div>
                </div>

                <div className="info-card">
                    <div className="info-card-icon">🗺️</div>
                    <div className="info-card-content">
                        <h3 className="info-card-title">Nos Parcours</h3>
                        <p className="info-card-text">
                            Du 5 km débutant au marathon 42,195 km, nous proposons <strong>7 parcours permanents</strong>
                            balisés GPS et 3 sorties hebdomadaires encadrées vers Carthage, Sidi Bou Saïd, le lac ou la forêt de la Manouba.
                        </p>
                        <p className="info-card-text" style={{ marginTop: 12 }}>
                            🏃‍♂️ <strong>3 séances collectives</strong> / semaine (lun-mer-ven 6h30 & 18h)<br />
                            📏 Distances : 5 km • 10 km • 15 km • semi • marathon<br />
                            📸 <strong>Galerie photos</strong> de chaque sortie sur nos réseaux
                        </p>
                        <div style={{ marginTop: 16 }}>
                            <span className="badge" style={{ background: '#e3f2fd', color: '#1565c0', padding: '4px 8px', borderRadius: 4, fontSize: 12 }}>
                                Télécharger nos parcours GPX →
                            </span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}

function ValuesTab() {
    return (
        <div className="content-section">
            <div className="content-header">
                <h2 className="content-title">Nos Valeurs et Objectifs</h2>
                <p className="content-description">Les principes qui nous guident chaque jour</p>
            </div>

            <div className="values-grid">
                <ValueItem
                    icon="🤝"
                    title="Inclusivité"
                    desc="Accueillir tous les coureurs, du débutant à l'athlète confirmé, dans un esprit de partage et de respect mutuel."
                />
                <ValueItem
                    icon="📈"
                    title="Dépassement"
                    desc="Encourager chacun à atteindre ses objectifs personnels et à repousser ses limites de manière progressive."
                />
                <ValueItem
                    icon="❤️"
                    title="Solidarité"
                    desc="Courir ensemble, s'entraider et ne laisser personne derrière, quels que soient le niveau ou les capacités."
                />
            </div>

            <div className="content-header">
                <h2 className="content-title">Charte du Club</h2>
                <p className="content-description">Les règles fondamentales de notre communauté</p>
            </div>

            <div className="info-card">
                <div className="info-card-icon">📜</div>
                <div className="info-card-content">
                    <h3 className="info-card-title">Nos Engagements</h3>
                    <ul className="info-list">
                        <li>Respect des autres coureurs et des piétons lors des entraînements collectifs</li>
                        <li>Ponctualité et assiduité aux séances d'entraînement organisées</li>
                        <li>Port des couleurs du club lors des compétitions officielles et événements</li>
                        <li>Entraide technique et morale entre les membres de tous niveaux</li>
                        <li>Responsabilité individuelle et collective lors des sorties groupées</li>
                    </ul>
                </div>
            </div>

            <div className="content-header">
                <h2 className="content-title">Organisation</h2>
                <p className="content-description">Notre structure pour une meilleure organisation</p>
            </div>

            <div className="info-card">
                <div className="info-card-icon">👥</div>
                <div className="info-card-content">
                    <h3 className="info-card-title">Groupes d'Entraînement</h3>
                    <p className="info-card-text">
                        L'organisation s'appuie sur des responsables de groupe (Group Admins) qui encadrent les séances :
                    </p>
                    <div className="groups-list">
                        <div className="group-item">
                            <span className="group-badge">1-2</span>
                            <span className="group-description">Débutants - Prise en main progressive</span>
                        </div>
                        <div className="group-item">
                            <span className="group-badge">3</span>
                            <span className="group-description">Intermédiaire - Amélioration des performances</span>
                        </div>
                        <div className="group-item">
                            <span className="group-badge">4-5</span>
                            <span className="group-description">Avancé - Entraînements intensifs et compétitions</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}

function SocialTab() {
    const { speak, stop: stopSpeech } = useSpeechSynthesis();
    const accessibility = useAccessibility();
    const isBlind = accessibility?.visualNeeds === 'blind';

    useEffect(() => {
        if (isBlind) {
            speak('Réseaux sociaux. Découvrez nos comptes Instagram, Facebook et notre adresse email.');
        }
        return () => stopSpeech();
    }, [isBlind, speak, stopSpeech]);

    return (
        <div className="content-section">
            <div className="content-header">
                <h2 className="content-title">Nos Réseaux Sociaux</h2>
                <p className="content-description">Restez connectés avec nous</p>
            </div>

            <div className="info-card">
                <div className="info-card-icon">📱</div>
                <div className="info-card-content">
                    <h3 className="info-card-title">Suivez-nous</h3>
                    <div className="social-links">
                        <a
                            href="https://instagram.com/running_club_tunis"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="social-link"
                            style={{ color: '#E4405F' }}
                        >
                            <span className="material-icons" style={{ fontSize: 24, verticalAlign: 'middle', marginRight: 8 }}>photo_camera</span>
                            Instagram: @running_club_tunis
                        </a>
                        <br />
                        <a
                            href="https://www.facebook.com/rctunis/"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="social-link"
                            style={{ color: '#1877F2' }}
                        >
                            <span className="material-icons" style={{ fontSize: 24, verticalAlign: 'middle', marginRight: 8 }}>facebook</span>
                            Facebook: Running Club Tunis
                        </a>
                        <br />
                        <a
                            href="mailto:runningclubtunis@gmail.com"
                            className="social-link"
                            style={{ color: '#D44638' }}
                        >
                            <span className="material-icons" style={{ fontSize: 24, verticalAlign: 'middle', marginRight: 8 }}>mail</span>
                            Email: runningclubtunis@gmail.com
                        </a>
                    </div>
                </div>
            </div>
        </div>
    );
}

function ValueItem({ icon, title, desc }) {
    return (
        <div className="value-card">
            <div className="value-icon">{icon}</div>
            <div className="value-content">
                <h3 className="value-title">{title}</h3>
                <p className="value-description">{desc}</p>
            </div>
        </div>
    );
}