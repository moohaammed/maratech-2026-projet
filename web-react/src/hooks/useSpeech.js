import { useState, useEffect, useCallback, useRef } from 'react';

/**
 * Custom hook for Web Speech API - Speech Recognition (Speech-to-Text)
 * @returns {Object} Speech recognition interface
 */
export function useSpeechRecognition() {
    const [isListening, setIsListening] = useState(false);
    const [transcript, setTranscript] = useState('');
    const [isAvailable, setIsAvailable] = useState(false);
    const [error, setError] = useState(null);
    const recognitionRef = useRef(null);
    const commandsRef = useRef({});
    const isContinuousRef = useRef(false);
    const isListeningRef = useRef(false);
    const onResultCallbackRef = useRef(null);
    const onEndCallbackRef = useRef(null);
    const lastCommandAtRef = useRef(0);
    const lastCommandKeyRef = useRef('');

    useEffect(() => {
        const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;

        if (SpeechRecognition) {
            setIsAvailable(true);
            recognitionRef.current = new SpeechRecognition();
            recognitionRef.current.continuous = false;
            recognitionRef.current.interimResults = true;
            recognitionRef.current.lang = 'fr-FR';
            recognitionRef.current.maxAlternatives = 1;

            recognitionRef.current.onresult = (event) => {
                const current = event.resultIndex;
                const transcriptText = event.results[current][0].transcript.toLowerCase().trim();
                const isFinal = !!event.results[current].isFinal;
                setTranscript(transcriptText);

                if (isFinal) {
                    const now = Date.now();
                    const cooldownMs = 1200;

                    // Check for registered commands (final results only)
                    Object.keys(commandsRef.current).forEach(command => {
                        const normalizedCommand = command.toLowerCase();
                        const hit = transcriptText.includes(normalizedCommand);
                        if (!hit) return;

                        const cmdKey = `${normalizedCommand}|${transcriptText}`;
                        if (now - lastCommandAtRef.current < cooldownMs && lastCommandKeyRef.current === cmdKey) {
                            return;
                        }

                        lastCommandAtRef.current = now;
                        lastCommandKeyRef.current = cmdKey;

                        console.log(`Voice Command Detected: "${command}" in "${transcriptText}"`);
                        commandsRef.current[command]();
                    });
                }

                if (onResultCallbackRef.current) {
                    onResultCallbackRef.current(transcriptText, isFinal);
                }
            };

            recognitionRef.current.onend = () => {
                console.log('Speech recognition service disconnected');
                // Auto-restart if in continuous mode
                if (isContinuousRef.current && isListeningRef.current) {
                    try {
                        recognitionRef.current.start();
                        console.log('Speech recognition auto-restarted');
                    } catch (e) {
                        console.error('Failed to auto-restart speech recognition:', e);
                        isListeningRef.current = false;
                        setIsListening(false);
                    }
                } else {
                    isListeningRef.current = false;
                    setIsListening(false);
                }

                if (onEndCallbackRef.current) onEndCallbackRef.current();
            };

            recognitionRef.current.onerror = (event) => {
                console.error('Speech recognition error:', event.error);
                setError(event.error || 'unknown');
                isListeningRef.current = false;
                setIsListening(false);
            };
        } else {
            setIsAvailable(false);
        }

        return () => {
            if (recognitionRef.current) {
                isContinuousRef.current = false;
                isListeningRef.current = false;
                recognitionRef.current.stop();
            }
        };
    }, []);

    const startListening = useCallback((arg1 = {}, arg2, arg3) => {
        if (!recognitionRef.current || !isAvailable) return;

        const legacySignature = typeof arg1 === 'function';
        const options = legacySignature ? (arg3 || {}) : (arg1 || {});
        const onResult = legacySignature ? arg1 : options.onResult;
        const onEnd = legacySignature ? arg2 : options.onEnd;
        const { lang = 'fr-FR', continuous = false } = options;

        recognitionRef.current.lang = lang;
        recognitionRef.current.continuous = continuous;
        isContinuousRef.current = continuous;
        onResultCallbackRef.current = onResult || null;
        onEndCallbackRef.current = onEnd || null;
        setError(null);

        try {
            isListeningRef.current = true;
            recognitionRef.current.start();
            setIsListening(true);
            console.log(`Speech recognition started (lang=${lang}, continuous=${continuous})`);
        } catch (error) {
            if (error.name === 'InvalidStateError') {
                // Already started, ignore
            } else {
                console.error('Failed to start speech recognition:', error);
                setError(error.name || 'start_failed');
                isListeningRef.current = false;
                setIsListening(false);
            }
        }
    }, [isAvailable]);

    const stopListening = useCallback(() => {
        if (recognitionRef.current) {
            isContinuousRef.current = false;
            isListeningRef.current = false;
            recognitionRef.current.stop();
            setIsListening(false);
        }
    }, []);

    const registerCommand = useCallback((command, callback) => {
        commandsRef.current[command] = callback;
    }, []);

    const clearCommands = useCallback(() => {
        commandsRef.current = {};
    }, []);

    return {
        isListening,
        transcript,
        isAvailable,
        error,
        startListening,
        stopListening,
        registerCommand,
        clearCommands
    };
}

/**
 * Custom hook for Web Speech API - Speech Synthesis (Text-to-Speech)
 * @returns {Object} Speech synthesis interface
 */
export function useSpeechSynthesis() {
    const [isSpeaking, setIsSpeaking] = useState(false);
    const [isAvailable, setIsAvailable] = useState(false);
    const [voices, setVoices] = useState([]);

    useEffect(() => {
        if ('speechSynthesis' in window) {
            setIsAvailable(true);

            const updateVoices = () => {
                const availableVoices = window.speechSynthesis.getVoices();
                setVoices(availableVoices);
            };

            updateVoices();
            window.speechSynthesis.onvoiceschanged = updateVoices;

            return () => {
                window.speechSynthesis.onvoiceschanged = null;
            };
        } else {
            console.warn('Speech Synthesis not supported in this browser');
            setIsAvailable(false);
        }
    }, []);

    const getBestVoice = useCallback((lang = 'fr-FR') => {
        if (!voices.length) {
            console.warn('getBestVoice: No voices loaded yet');
            return null;
        }

        // Try to find an EXACT match first
        let voice = voices.find(v => v.lang === lang && !v.localService); // Prefer remote high-quality
        if (!voice) {
            voice = voices.find(v => v.lang === lang);
        }

        // If not found, try a fuzzy match (e.g., 'fr' in 'fr-FR')
        if (!voice) {
            const shortLang = lang.split('-')[0];
            voice = voices.find(v => v.lang.startsWith(shortLang));
        }

        if (voice) {
            console.log(`getBestVoice: Selected ${voice.name} (${voice.lang}) for ${lang}`);
        } else {
            console.warn(`getBestVoice: No matching voice found for ${lang}`);
        }

        return voice;
    }, [voices]);

    const speak = useCallback((text, options = {}) => {
        console.log(`useSpeechSynthesis.speak: "${text}"`, options);

        if (!isAvailable) {
            console.error('Speech synthesis not available in this browser');
            return Promise.resolve();
        }

        // Stop any ongoing speech
        window.speechSynthesis.cancel();

        return new Promise((resolve, reject) => {
            // Tiny delay to ensure cancel finished and voices are ready if just loaded
            setTimeout(() => {
                const utterance = new SpeechSynthesisUtterance(text);
                const lang = options.lang || 'fr-FR';

                utterance.lang = lang;
                utterance.rate = options.rate || 1.0;
                utterance.pitch = options.pitch || 1;
                utterance.volume = options.volume || 1;

                // Attempt to pick a good voice
                const voice = getBestVoice(lang);
                if (voice) {
                    utterance.voice = voice;
                } else {
                    console.log('Using browser default voice (no match found or voices still loading)');
                }

                utterance.onstart = () => {
                    console.log('Speech started');
                    setIsSpeaking(true);
                };

                utterance.onend = () => {
                    console.log('Speech ended successfully');
                    setIsSpeaking(false);
                    resolve();
                };

                utterance.onerror = (event) => {
                    console.error('Speech synthesis error:', event);
                    setIsSpeaking(false);
                    reject(event);
                };

                try {
                    window.speechSynthesis.speak(utterance);
                    console.log('window.speechSynthesis.speak() called');
                } catch (error) {
                    console.error('Failed to execute speak():', error);
                    setIsSpeaking(false);
                    reject(error);
                }
            }, 100); // Small buffer for stability
        });
    }, [isAvailable, getBestVoice]);

    const stop = useCallback(() => {
        if (isAvailable) {
            window.speechSynthesis.cancel();
            setIsSpeaking(false);
        }
    }, [isAvailable]);

    return {
        speak,
        stop,
        isSpeaking,
        isAvailable,
        voices
    };
}
