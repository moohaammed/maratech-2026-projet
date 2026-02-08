import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { collection, query, where, getDocs, limit } from 'firebase/firestore';
import { auth, db } from '../lib/firebase';
import { useAccessibility } from '../core/services/AccessibilityContext';
import { useSpeechRecognition, useSpeechSynthesis } from '../hooks/useSpeech';
import VoiceTextField from '../components/VoiceTextField';
import { appColors } from '../core/theme/appColors';
import './LoginScreen.css';

export default function LoginScreen() {
    const navigate = useNavigate();
    const [name, setName] = useState('');
    const [pin, setPin] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState('');
    const [obscurePin, setObscurePin] = useState(true);
    const [isListeningForName, setIsListeningForName] = useState(false);
    const [isListeningForPin, setIsListeningForPin] = useState(false);

    const accessibility = useAccessibility();
    const { startListening, stopListening } = useSpeechRecognition();
    const { speak, stop: stopSpeech } = useSpeechSynthesis();

    const nameInputRef = useRef(null);
    const pinInputRef = useRef(null);

    const textScale = accessibility?.textScale || 1;
    const boldText = accessibility?.boldText || false;
    const highContrast = accessibility?.highContrast || false;
    const visualNeeds = accessibility?.visualNeeds || 'normal';
    const isBlind = visualNeeds === 'blind';

    const bgColor = highContrast ? appColors.highContrastBackground : appColors.background;
    const cardColor = highContrast ? appColors.highContrastSurface : appColors.surface;
    const textColor = highContrast ? '#FFFFFF' : appColors.textPrimary;
    const secondaryTextColor = highContrast ? 'rgba(255, 255, 255, 0.7)' : appColors.textSecondary;
    const primaryColor = highContrast ? appColors.highContrastPrimary : appColors.primary;
    const borderColor = highContrast ? '#FFFFFF' : appColors.divider;

    // Speak welcome message for blind users
    useEffect(() => {
        if (isBlind) {
            const timer = setTimeout(() => {
                speak("Écran de connexion. Appuyez sur le micro pour dicter votre nom.");
            }, 500);
            return () => clearTimeout(timer);
        }
    }, [isBlind, speak]);

    // Voice input handlers
    const handleStartVoiceForName = async () => {
        await stopSpeech(); // Stop any ongoing speech
        setIsListeningForName(true);

        await speak("Quel est votre nom ?");
        await new Promise(resolve => setTimeout(resolve, 500));

        startListening(
            (transcript, isFinal) => {
                setName(transcript);
                if (isFinal) {
                    setIsListeningForName(false);
                    if (transcript.trim()) {
                        speak(`Bonjour ${transcript}. Maintenant, dites le code.`);
                        setTimeout(() => handleStartVoiceForPin(), 2000);
                    }
                }
            },
            () => setIsListeningForName(false)
        );
    };

    const handleStopVoiceForName = () => {
        stopListening();
        setIsListeningForName(false);
    };

    const handleStartVoiceForPin = async () => {
        await stopSpeech();
        setIsListeningForPin(true);

        await speak("Dites les 3 chiffres du code");
        await new Promise(resolve => setTimeout(resolve, 500));

        startListening(
            (transcript, isFinal) => {
                // Extract only digits from transcript
                const digits = transcript.replace(/[^0-9]/g, '');
                const truncated = digits.substring(0, 3);
                setPin(truncated);

                if (isFinal) {
                    setIsListeningForPin(false);
                    if (truncated.length === 3) {
                        speak("Code reçu. Connexion en cours...");
                        setTimeout(() => handleLogin(), 1500);
                    }
                }
            },
            () => setIsListeningForPin(false)
        );
    };

    const handleStopVoiceForPin = () => {
        stopListening();
        setIsListeningForPin(false);
    };

    // Login handler
    const handleLogin = async (e) => {
        if (e) e.preventDefault();

        // Validation
        if (!name.trim()) {
            setError('Veuillez entrer votre nom');
            if (isBlind) speak('Veuillez entrer votre nom');
            return;
        }
        if (pin.length !== 3) {
            setError('3 chiffres requis');
            if (isBlind) speak('3 chiffres requis');
            return;
        }

        setIsLoading(true);
        setError('');

        const nameInput = name.trim();
        console.log(`🔐 Attempting login for '${nameInput}' with PIN '***'`);

        try {
            // 1. FAST LOOKUP: Try exact match first
            const usersRef = collection(db, 'users');
            const exactQuery = query(usersRef, where('fullName', '==', nameInput), limit(1));
            let snapshot = await getDocs(exactQuery);

            let userDoc = null;

            if (!snapshot.empty) {
                userDoc = snapshot.docs[0];
                console.log(`✅ Found exact match: ${userDoc.id}`);
            } else {
                // 2. FALLBACK: Case-insensitive scan
                console.log('⚠️ Exact match failed, trying case-insensitive scan...');
                const allUsersSnapshot = await getDocs(usersRef);
                const lowerInput = nameInput.toLowerCase();

                for (const doc of allUsersSnapshot.docs) {
                    const data = doc.data();
                    const docName = (data.fullName || data.name || '').toString().toLowerCase();

                    if (docName === lowerInput || docName.includes(lowerInput)) {
                        userDoc = doc;
                        console.log(`✅ Found fuzzy match: ${doc.id} (${docName})`);
                        break;
                    }
                }
            }

            if (!userDoc) {
                const message = `Utilisateur "${nameInput}" non trouvé.`;
                setError(message);
                if (isBlind) speak(`Je ne trouve pas d'utilisateur au nom de ${nameInput}.`);
                setIsLoading(false);
                return;
            }

            const userData = userDoc.data();
            const email = userData.email;

            if (!email) {
                throw new Error('Email manquant pour cet utilisateur');
            }

            // 2. Construct password from PIN (Flutter convention: "000" + PIN)
            const password = `000${pin}`;

            // 3. Sign in with Firebase Auth
            await signInWithEmailAndPassword(auth, email, password);

            console.log('✅ Login successful');

            if (isBlind) {
                await speak('Connexion réussie! Bienvenue.');
            }

            // Navigation handled by App.jsx via onAuthStateChanged

        } catch (err) {
            console.error('❌ Login error:', err);
            setIsLoading(false);

            let message = 'Erreur de connexion.';
            if (err.code === 'auth/wrong-password' || err.code === 'auth/invalid-credential') {
                message = 'Code PIN incorrect.';
            } else if (err.code === 'auth/user-not-found') {
                message = 'Utilisateur non trouvé.';
            }

            setError(message);
            if (isBlind) speak(message);
        }
    };

    // Validators
    const validateName = (value) => {
        if (!value || value.trim() === '') {
            return 'Veuillez entrer votre nom';
        }
        return '';
    };

    const validatePin = (value) => {
        if (!value || value.length !== 3) {
            return '3 chiffres requis';
        }
        return '';
    };

    // Responsive sizing
    const isSmallScreen = window.innerWidth < 360;
    const isLargeScreen = window.innerWidth >= 600;
    const logoSize = (isSmallScreen ? 80 : isLargeScreen ? 120 : 100) * Math.min(textScale, 1.3);
    const horizontalPadding = 32; // Match Splash screen
    const maxWidth = '100%'; // Full screen width

    return (
        <div
            className="login-screen"
            style={{
                backgroundColor: bgColor,
                minHeight: '100vh',
                background: highContrast
                    ? bgColor
                    : `linear-gradient(to bottom, ${appColors.primary}1A 0%, ${appColors.background} 30%, ${appColors.background} 100%)`,
            }}
        >
            <div
                className="login-content"
                style={{
                    width: '100%',
                    margin: '0 auto',
                    boxSizing: 'border-box',
                    minHeight: '100vh',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    justifyContent: 'center',
                    padding: '32px 16px',
                    gap: '24px'
                }}
            >
                <div style={{
                    width: '100%',
                    maxWidth: '450px',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                }}>
                    {/* Logo */}
                    <div className="logo-container fade-in" style={{ textAlign: isLargeScreen ? 'left' : 'center', marginBottom: `${(isSmallScreen ? 20 : 32) * Math.min(textScale, 1.2)}px` }}>
                        <div
                            className="logo-wrapper"
                            style={{
                                width: logoSize,
                                height: logoSize,
                                margin: '0 auto',
                                borderRadius: '50%',
                                border: `${highContrast ? 3 : 4}px solid ${highContrast ? primaryColor : '#FFFFFF'}`,
                                boxShadow: highContrast ? 'none' : `0 0 30px ${primaryColor}4D`,
                                overflow: 'hidden',
                                backgroundColor: appColors.surface,
                            }}
                        >
                            <img
                                src="/logo.jpg"
                                alt="Running Club Tunis Logo"
                                style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                                onError={(e) => {
                                    e.target.style.display = 'none';
                                    e.target.parentElement.innerHTML = `<div style="width:100%;height:100%;display:flex;align-items:center;justify-content:center;background:${primaryColor};color:white;font-size:${logoSize * 0.5}px">🏃</div>`;
                                }}
                            />
                        </div>
                    </div>

                    {/* Header */}
                    <div className="header slide-up" style={{ textAlign: 'center', width: '100%' }}>
                        <h1
                            style={{
                                fontSize: `${(isSmallScreen ? 24 : 28) * textScale}px`,
                                fontWeight: 'bold',
                                color: highContrast ? primaryColor : appColors.primary,
                                margin: 0,
                                padding: '0 16px',
                            }}
                        >
                            Running Club Tunis
                        </h1>
                        <div
                            style={{
                                display: 'inline-block',
                                marginTop: `${8 * Math.min(textScale, 1.2)}px`,
                                padding: `${6 * Math.min(textScale, 1.2)}px ${16 * Math.min(textScale, 1.2)}px`,
                                backgroundColor: highContrast ? `${primaryColor}4D` : `${primaryColor}1A`,
                                borderRadius: '20px',
                                border: highContrast ? `1px solid ${primaryColor}` : 'none',
                            }}
                        >
                            <span
                                style={{
                                    color: highContrast ? '#FFFFFF' : secondaryTextColor,
                                    fontSize: `${(isSmallScreen ? 12 : 14) * textScale}px`,
                                    fontWeight: boldText ? 'bold' : 500,
                                }}
                            >
                                Espace Membre
                            </span>
                        </div>
                    </div>
                    <br></br>
                    {/* Login Card */}
                    <div
                        className="login-card slide-up"
                        style={{
                            backgroundColor: cardColor,
                            borderRadius: '24px',
                            padding: `${(isSmallScreen ? 20 : 28) * Math.min(textScale, 1.2)}px`,
                            border: highContrast ? `2px solid ${borderColor}` : 'none',
                            width: '100%',
                            boxShadow: highContrast ? 'none' : `0 10px 40px ${appColors.primary}14`,
                        }}
                    >
                        {/* Card Header */}
                        <div style={{ display: 'flex', alignItems: 'center', marginBottom: `${28 * Math.min(textScale, 1.2)}px` }}>
                            <div
                                style={{
                                    padding: `${10 * Math.min(textScale, 1.2)}px`,
                                    backgroundColor: highContrast ? `${primaryColor}4D` : `${primaryColor}1A`,
                                    borderRadius: '12px',
                                    marginRight: `${12 * Math.min(textScale, 1.2)}px`,
                                }}
                            >
                                <span style={{ fontSize: `${24 * Math.min(textScale, 1.3)}px` }}>🔐</span>
                            </div>
                            <div>
                                <h2 style={{ fontSize: `${20 * textScale}px`, fontWeight: 'bold', color: textColor, margin: 0 }}>
                                    Connexion
                                </h2>
                                <p style={{ fontSize: `${13 * textScale}px`, color: secondaryTextColor, margin: 0 }}>
                                    Accédez à votre espace
                                </p>
                            </div>
                        </div>

                        {/* Form */}
                        <form onSubmit={handleLogin}>
                            <VoiceTextField
                                label="Nom complet"
                                hint="Entrez votre nom"
                                icon="👤"
                                fieldName="name"
                                value={name}
                                onChange={setName}
                                isListening={isListeningForName}
                                onStartVoice={handleStartVoiceForName}
                                onStopVoice={handleStopVoiceForName}
                                validator={validateName}
                                onSubmit={() => pinInputRef.current?.focus()}
                                autoFocus={true}
                                hideVoice={true}
                            />

                            <VoiceTextField
                                label="Code PIN (3 chiffres CIN)"
                                hint="• • •"
                                icon="🔒"
                                fieldName="pin"
                                value={pin}
                                onChange={setPin}
                                obscureText={obscurePin}
                                keyboardType="number"
                                maxLength={3}
                                isListening={isListeningForPin}
                                onStartVoice={handleStartVoiceForPin}
                                onStopVoice={handleStopVoiceForPin}
                                validator={validatePin}
                                onSubmit={handleLogin}
                                hideVoice={true}
                            />

                            {/* Error Message */}
                            {error && (
                                <div
                                    role="alert"
                                    aria-live="assertive"
                                    style={{
                                        display: 'flex',
                                        alignItems: 'center',
                                        gap: '12px',
                                        padding: '12px',
                                        backgroundColor: `${appColors.error}1A`,
                                        border: `1px solid ${appColors.error}`,
                                        borderRadius: '12px',
                                        marginBottom: `${20 * Math.min(textScale, 1.2)}px`,
                                    }}
                                >
                                    <span style={{ fontSize: '20px' }}>⚠️</span>
                                    <span style={{ color: appColors.error, fontSize: `${14 * textScale}px`, fontWeight: 'bold' }}>
                                        {error}
                                    </span>
                                </div>
                            )}

                            {/* Login Button */}
                            <button
                                type="submit"
                                disabled={isLoading}
                                className="login-button"
                                style={{
                                    width: '100%',
                                    height: `${56 * Math.min(textScale, 1.3)}px`,
                                    backgroundColor: isLoading ? `${primaryColor}99` : primaryColor,
                                    color: highContrast ? '#000000' : '#FFFFFF',
                                    border: highContrast ? `2px solid ${borderColor}` : 'none',
                                    borderRadius: '16px',
                                    fontSize: `${16 * textScale}px`,
                                    fontWeight: 'bold',
                                    letterSpacing: '1px',
                                    cursor: isLoading ? 'not-allowed' : 'pointer',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    gap: `${8 * Math.min(textScale, 1.2)}px`,
                                    transition: 'all 0.3s ease',
                                }}
                            >
                                {isLoading ? (
                                    <div className="spinner" style={{ width: '24px', height: '24px' }} />
                                ) : (
                                    <>
                                        <span>Se connecter</span>

                                    </>
                                )}
                            </button>
                        </form>
                    </div>

                </div>

                {/* Footer */}
                <div className="footer slide-up" style={{ textAlign: 'center', marginTop: '32px', width: '100%' }}>
                    <div style={{ display: 'flex', alignItems: 'center', marginBottom: `${16 * Math.min(textScale, 1.2)}px` }}>
                        <div style={{ flex: 1, height: highContrast ? '2px' : '1px', backgroundColor: highContrast ? 'rgba(255, 255, 255, 0.54)' : appColors.divider }} />
                        <span style={{ padding: '0 16px', color: secondaryTextColor, fontSize: `${13 * textScale}px` }}>
                            Première fois?
                        </span>
                        <div style={{ flex: 1, height: highContrast ? '2px' : '1px', backgroundColor: highContrast ? 'rgba(255, 255, 255, 0.54)' : appColors.divider }} />
                    </div>
                    <button
                        type="button"
                        onClick={() => {
                            const message = "Contactez l'administrateur";
                            setError(message);
                            if (isBlind) speak(message);
                        }}
                        style={{
                            background: 'none',
                            border: 'none',
                            color: primaryColor,
                            fontSize: `${14 * textScale}px`,
                            cursor: 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '8px',
                            margin: '0 auto 16px auto',
                        }}
                    >
                        <span style={{ fontSize: `${18 * Math.min(textScale, 1.2)}px` }}>❓</span>
                        <span>Besoin d'aide?</span>
                    </button>



                    <button
                        type="button"
                        onClick={() => navigate('/guest')}
                        style={{
                            background: 'none',
                            border: `1px solid ${primaryColor}4D`,
                            color: primaryColor,
                            fontSize: `${15 * textScale}px`,
                            fontWeight: '700',
                            padding: '12px 24px',
                            borderRadius: '16px',
                            cursor: 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '10px',
                            margin: '0 auto',
                            transition: 'all 0.2s',
                        }}
                        onMouseOver={e => {
                            e.currentTarget.style.backgroundColor = `${primaryColor}1A`;
                            e.currentTarget.style.transform = 'translateY(-2px)';
                        }}
                        onMouseOut={e => {
                            e.currentTarget.style.backgroundColor = 'transparent';
                            e.currentTarget.style.transform = 'translateY(0)';
                        }}
                    >
                        <span>🏃‍♂️</span>
                        <span>Continuer en tant qu'invité</span>
                    </button>
                </div>
            </div>
        </div>
    );
}
