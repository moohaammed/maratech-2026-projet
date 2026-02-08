import React, { useState, useEffect } from 'react';
import './SplashScreen.css';
import { useAccessibility } from '../core/services/AccessibilityContext';
import { useSpeechSynthesis } from '../hooks/useSpeech';
import image1 from '../assets/image1.jpg';
import image2 from '../assets/image2.jpg';
import image3 from '../assets/image3.jpg';
import logo from '../assets/logo.jpg';

/**
 * Splash Screen - First screen users see with images carousel
 */
const SplashScreen = ({ onComplete }) => {
    const [currentImageIndex, setCurrentImageIndex] = useState(0);
    const [fadeIn, setFadeIn] = useState(false);
    const accessibility = useAccessibility();
    const visualNeeds = accessibility?.visualNeeds || 'normal';
    const { speak } = useSpeechSynthesis();

    // Images from assets
    const images = [image1, image2, image3];

    useEffect(() => {
        // Start fade-in animation
        setFadeIn(true);

        // Image carousel - change every 1.5 seconds
        const carouselInterval = setInterval(() => {
            setCurrentImageIndex((prevIndex) => {
                if (prevIndex < images.length - 1) {
                    return prevIndex + 1;
                }
                return prevIndex;
            });
        }, 1500);

        return () => clearInterval(carouselInterval);
    }, [images.length]);

    // TTS effect - only run once or when visualNeeds changes
    useEffect(() => {
        console.log('SplashScreen TTS Effect: initializing welcome...');
        const welcome = async () => {
            // First time users won't have visualNeeds set to 'blind' yet
            // So we speak a short generic intro to confirm the app is working for blind users
            speak('Running Club Tunis. Chargement en cours. Loading. جار التحميل.');
        };
        welcome();
    }, [speak]);

    // Navigation effect - only run once
    useEffect(() => {
        const timer = setTimeout(() => {
            console.log('SplashScreen: Timer complete, calling onComplete');
            if (onComplete) {
                onComplete();
            }
        }, 4500);

        return () => {
            console.log('SplashScreen: Cleaning up timer');
            clearTimeout(timer);
        };
    }, [onComplete]);

    return (
        <div
            className="splash-screen"
            role="main"
            aria-label="Écran de chargement. Running Club Tunis. Welcome. مرحبا."
        >
            {/* Background image carousel with fade animation */}
            <div className="splash-background">
                {images.map((image, index) => (
                    <div
                        key={index}
                        className={`splash-image ${currentImageIndex === index ? 'active' : ''} ${currentImageIndex > index ? 'exited' : ''
                            }`}
                        style={{
                            backgroundImage: `url(${image})`,
                        }}
                    />
                ))}

                {/* Fallback gradient if images fail */}
                <div className="splash-gradient-fallback" />
            </div>

            {/* Dark overlay for text readability */}
            <div className="splash-overlay" />

            {/* Content */}
            <div className={`splash-content ${fadeIn ? 'fade-in' : ''}`}>
                <div className="splash-spacer-top" />

                {/* Logo */}
                <div className="splash-logo-container">
                    <img
                        src={logo}
                        alt="Running Club Tunis Logo"
                        className="splash-logo"
                        onError={(e) => {
                            // Fallback icon if logo fails to load
                            e.target.style.display = 'none';
                            e.target.nextSibling.style.display = 'flex';
                        }}
                    />
                    <div className="splash-logo-fallback" style={{ display: 'none' }}>
                        <svg
                            width="60"
                            height="60"
                            viewBox="0 0 24 24"
                            fill="currentColor"
                            className="splash-icon"
                        >
                            <path d="M13.49 5.48c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm-3.6 13.9l1-4.4 2.1 2v6h2v-7.5l-2.1-2 .6-3c1.3 1.5 3.3 2.5 5.5 2.5v-2c-1.9 0-3.5-1-4.3-2.4l-1-1.6c-.4-.6-1-1-1.7-1-.3 0-.5.1-.8.1l-5.2 2.2v4.7h2v-3.4l1.8-.7-1.6 8.1-4.9-1-.4 2 7 1.4z" />
                        </svg>
                    </div>
                </div>

                {/* App Name */}
                <div className="splash-title">
                    <h1 className="splash-title-main">Running Club</h1>
                    <h2 className="splash-title-sub">TUNIS</h2>
                </div>

                <div className="splash-spacer-mid" />

                {/* Welcome messages in 3 languages */}
                <div className="splash-welcome-box">
                    <p className="splash-welcome-text">🇫🇷 Bienvenue!</p>
                    <p className="splash-welcome-text">🇬🇧 Welcome!</p>
                    <p className="splash-welcome-text splash-welcome-arabic">🇹🇳 مرحبا!</p>
                </div>

                <div className="splash-spacer-bottom" />

                {/* Image indicator dots */}
                <div className="splash-indicators">
                    {images.map((_, index) => (
                        <div
                            key={index}
                            className={`splash-dot ${currentImageIndex === index ? 'active' : ''}`}
                        />
                    ))}
                </div>

                {/* Loading indicator */}
                <div className="splash-loading">
                    <div className="splash-spinner" role="status" aria-live="polite">
                        <span className="sr-only">Loading...</span>
                    </div>
                    <p className="splash-loading-text">
                        Chargement... Loading... جار التحميل...
                    </p>
                </div>
            </div>
        </div>
    );
};

export default SplashScreen;
