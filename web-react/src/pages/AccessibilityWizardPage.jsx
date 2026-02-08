import { useState, useEffect, useCallback, useRef } from "react";
import { appColors } from "../core/theme/appColors";
import { useSpeechSynthesis, useSpeechRecognition } from "../hooks/useSpeech";
import {
  useAccessibility,
  setWizardCompleted,
  saveAccessibilityProfile,
} from "../core/services/AccessibilityContext";

const LANGUAGES = [
  { code: "fr", name: "French", nativeName: "Français", flag: "🇫🇷" },
  { code: "ar", name: "Arabic", nativeName: "العربية", flag: "🇹🇳" },
  { code: "en", name: "English", nativeName: "English", flag: "🇬🇧" },
];

function T(selectedCode, fr, en, ar) {
  switch (selectedCode) {
    case "en":
      return en;
    case "ar":
      return ar;
    default:
      return fr;
  }
}

function OptionCard({
  title,
  subtitle,
  voiceHint,
  isSelected,
  onTap,
  useHighContrast,
  textColor,
  ts,
}) {
  return (
    <button
      type="button"
      onClick={onTap}
      style={{
        width: "100%",
        padding: `${20 * Math.min(ts, 1.2)}px`,
        marginBottom: 12,
        textAlign: "left",
        border: `2px solid ${isSelected ? (useHighContrast ? "#fff" : appColors.primary) : useHighContrast ? "#444" : "#ddd"}`,
        borderRadius: 16,
        background: isSelected
          ? useHighContrast ? "rgba(255,255,255,0.15)" : `${appColors.primary}26`
          : useHighContrast ? "#1a1a1a" : "#fff",
        cursor: "pointer",
      }}
    >
      <div style={{ display: "flex", alignItems: "flex-start", gap: 12 }}>
        <div style={{ flex: 1 }}>
          <div
            style={{
              fontSize: 18 * ts,
              fontWeight: "bold",
              color: isSelected ? (useHighContrast ? "#fff" : appColors.primary) : textColor,
            }}
          >
            {title}
          </div>
          <div style={{ fontSize: 14 * ts, color: `${textColor}99`, marginTop: 4 }}>{subtitle}</div>
          <div style={{ fontSize: 12 * ts, fontStyle: "italic", color: "#888", marginTop: 4 }}>
            {voiceHint}
          </div>
        </div>
        {isSelected && (
          <span style={{ fontSize: 24, color: useHighContrast ? "#fff" : appColors.primary }}>✓</span>
        )}
      </div>
    </button>
  );
}

export default function AccessibilityWizardPage({ onFinish, onSkip }) {
  const accessibility = useAccessibility();
  const [currentStep, setCurrentStep] = useState(0);
  const [isInitialized, setIsInitialized] = useState(false);
  const [useVoiceMode, setUseVoiceMode] = useState(true);
  const [userHasTouched, setUserHasTouched] = useState(false);
  const isSecureOrLocalhost =
    typeof window !== "undefined" &&
    (window.isSecureContext || window.location.hostname === "localhost" || window.location.hostname === "127.0.0.1");

  const { speak, stop: stopSpeech, isAvailable: isTtsAvailable } = useSpeechSynthesis();
  const { startListening, stopListening, isListening, isAvailable: isSttAvailable, error: sttError, registerCommand, clearCommands } = useSpeechRecognition();

  const [selectedLanguage, setSelectedLanguage] = useState(LANGUAGES[0]);
  const [visualNeeds, setVisualNeeds] = useState("normal");
  const [audioNeeds, setAudioNeeds] = useState("normal");
  const [motorNeeds, setMotorNeeds] = useState("normal");
  const [textScale, setTextScale] = useState(1.0);
  const [highContrast, setHighContrast] = useState(false);
  const [boldText, setBoldText] = useState(false);

  const useHighContrast = highContrast || visualNeeds === "blind";
  const bgColor = useHighContrast ? "#000" : appColors.background;
  const textColor = useHighContrast ? "#fff" : appColors.textPrimary;
  const ts = Math.min(Math.max(textScale, 1), 1.3);

  const goToLogin = useCallback(() => {
    const profile = {
      isProfileComplete: true,
      completedAt: new Date().toISOString(),
      lastUpdated: new Date().toISOString(),
      visual: {
        needsCategory: visualNeeds,
        textSize: Math.round(textScale * 100),
        fontWeight: boldText ? "bold" : "normal",
        contrastMode: highContrast ? "high_contrast" : "standard",
        boldText,
      },
      audio: { needsCategory: audioNeeds },
      motor: { needsCategory: motorNeeds },
      theme: { mode: "system" },
      version: 1,
    };
    saveAccessibilityProfile(profile);
    setWizardCompleted(true);
    onFinish?.();
  }, [visualNeeds, audioNeeds, motorNeeds, textScale, highContrast, boldText, onFinish]);

  const handleSkip = useCallback(() => {
    setWizardCompleted(true);
    onSkip?.();
  }, [onSkip]);

  const nextStep = useCallback(() => {
    if (currentStep < 4) {
      setCurrentStep(s => s + 1);
    } else {
      goToLogin();
    }
  }, [currentStep, goToLogin]);

  const previousStep = useCallback(() => {
    if (currentStep > 0) {
      setCurrentStep(s => s - 1);
    }
  }, [currentStep]);

  // User touched screen - disable voice guidance loop
  const onUserTouch = useCallback(() => {
    if (!userHasTouched) {
      console.log("👆 User touched screen - disabling voice guidance loop");
      setUserHasTouched(true);
      setUseVoiceMode(false);
      stopSpeech();
      stopListening();
    }
  }, [userHasTouched, stopSpeech, stopListening]);

  // Command registration logic
  const registerStepCommands = useCallback((step) => {
    clearCommands();

    // Global commands
    registerCommand("passer", handleSkip);
    registerCommand("skip", handleSkip);
    registerCommand("retour", previousStep);
    registerCommand("back", previousStep);
    registerCommand("continuer", nextStep);
    registerCommand("continue", nextStep);
    registerCommand("suivant", nextStep);
    registerCommand("next", nextStep);

    if (step === 0) {
      registerCommand("français", () => selectLanguage(LANGUAGES[0]));
      registerCommand("arabe", () => selectLanguage(LANGUAGES[1]));
      registerCommand("anglais", () => selectLanguage(LANGUAGES[2]));
      registerCommand("french", () => selectLanguage(LANGUAGES[0]));
      registerCommand("arabic", () => selectLanguage(LANGUAGES[1]));
      registerCommand("english", () => selectLanguage(LANGUAGES[2]));
    } else if (step === 1) {
      registerCommand("oui", () => selectVisual("low_vision"));
      registerCommand("yes", () => selectVisual("low_vision"));
      registerCommand("non", () => selectVisual("normal"));
      registerCommand("no", () => selectVisual("normal"));
      registerCommand("نعم", () => selectVisual("low_vision"));
      registerCommand("لا", () => selectVisual("normal"));
      registerCommand("normal", () => selectVisual("normal"));
      registerCommand("agrandi", () => selectVisual("low_vision"));
      registerCommand("plus grand", () => selectVisual("low_vision"));
      registerCommand("plus grande", () => selectVisual("low_vision"));
      registerCommand("aveugle", () => selectVisual("blind"));
      registerCommand("blind", () => selectVisual("blind"));
      registerCommand("larger", () => selectVisual("low_vision"));
    } else if (step === 2) {
      registerCommand("oui", () => selectAudio("hearing_loss"));
      registerCommand("yes", () => selectAudio("hearing_loss"));
      registerCommand("non", () => selectAudio("normal"));
      registerCommand("no", () => selectAudio("normal"));
      registerCommand("نعم", () => selectAudio("hearing_loss"));
      registerCommand("لا", () => selectAudio("normal"));
      registerCommand("entends", () => selectAudio("normal"));
      registerCommand("hear", () => selectAudio("normal"));
      registerCommand("vibration", () => selectAudio("hearing_loss"));
      registerCommand("sourd", () => selectAudio("deaf"));
      registerCommand("deaf", () => selectAudio("deaf"));
    } else if (step === 3) {
      registerCommand("oui", () => selectMotor("limited_dexterity"));
      registerCommand("yes", () => selectMotor("limited_dexterity"));
      registerCommand("non", () => selectMotor("normal"));
      registerCommand("no", () => selectMotor("normal"));
      registerCommand("نعم", () => selectMotor("limited_dexterity"));
      registerCommand("لا", () => selectMotor("normal"));
      registerCommand("normal", () => selectMotor("normal"));
      registerCommand("difficultés", () => selectMotor("limited_dexterity"));
      registerCommand("motor", () => selectMotor("limited_dexterity"));
      registerCommand("vocale", () => selectMotor("limited_dexterity"));
      registerCommand("voice", () => selectMotor("limited_dexterity"));
    } else if (step === 4) {
      registerCommand("commencer", goToLogin);
      registerCommand("start", goToLogin);
    }
  }, [clearCommands, registerCommand, handleSkip, previousStep, nextStep, goToLogin]);

  const startListeningForStep = useCallback((step, langCode) => {
    if (!useVoiceMode || userHasTouched) return;
    registerStepCommands(step);
    startListening({ continuous: true, lang: langCode });
  }, [useVoiceMode, userHasTouched, registerStepCommands, startListening]);

  // Start sequence
  useEffect(() => {
    const startWizard = async () => {
      if (!isTtsAvailable) return;

      console.log("🎙️ Starting Accessibility Wizard Guidance Loop");

      // Start welcome sequence but don't await the whole thing before showing UI
      const welcomeSequence = async () => {
        await speak("Bienvenue dans Running Club Tunis! Dites Français, Arabe, ou Anglais.", { lang: 'fr-FR' });
        await speak("مرحبا! قل عربي، فرنسي، أو إنجليزي.", { lang: 'ar-SA' });
        await speak("Welcome! Say English, French, or Arabic.", { lang: 'en-GB' });

        if (useVoiceMode && !userHasTouched) {
          startListeningForStep(0, 'fr-FR');
        }
      };

      welcomeSequence();
      setIsInitialized(true);
    };

    startWizard();
    return () => {
      stopSpeech();
      stopListening();
    };
  }, [isTtsAvailable]); // Only run once on mount (when TTS is ready)

  // Announce step change
  useEffect(() => {
    if (isInitialized && useVoiceMode && !userHasTouched) {
      const announce = async () => {
        let msg = "";
        switch (currentStep) {
          case 1: msg = T(selectedLanguage.code, "Question 1 sur 3. Avez-vous des difficultés visuelles? Dites oui, non, ou agrandi.", "Question 1 of 3. Do you have any visual difficulties? Say yes, no, or larger.", "السؤال 1 من 3. هل لديك صعوبات في الرؤية؟ قل نعم أو لا."); break;
          case 2: msg = T(selectedLanguage.code, "Question 2 sur 3. Avez-vous des difficultés auditives? Dites oui ou non.", "Question 2 of 3. Do you have any hearing difficulties? Say yes or no.", "السؤال 2 من 3. هل لديك صعوبات في السمع؟ قل نعم أو لا."); break;
          case 3: msg = T(selectedLanguage.code, "Question 3 sur 3. Avez-vous des difficultés à utiliser vos mains? Dites oui ou non.", "Question 3 of 3. Do you have difficulty using your hands? Say yes or no.", "السؤال 3 من 3. هل لديك صعوبات في استخدام يديك؟ قل نعم أو لا."); break;
          case 4: msg = T(selectedLanguage.code, "Configuration terminée! Dites commencer.", "Setup complete! Say start.", "اكتمل الإعداد! قل ابدأ."); break;
        }
        if (msg) {
          await speak(msg, { lang: selectedLanguage.code === 'fr' ? 'fr-FR' : selectedLanguage.code === 'ar' ? 'ar-SA' : 'en-GB' });
          startListeningForStep(
            currentStep,
            selectedLanguage.code === 'fr' ? 'fr-FR' : selectedLanguage.code === 'ar' ? 'ar-SA' : 'en-GB'
          );
        }
      };
      announce();
    }
  }, [currentStep, isInitialized, selectedLanguage, useVoiceMode, userHasTouched]);

  const selectLanguage = useCallback((lang) => {
    stopListening();
    setSelectedLanguage(lang);
    speak(T(lang.code, "Français sélectionné. Dites continuer.", "English selected. Say continue.", "تم اختيار العربية. قل متابعة."));
    if (useVoiceMode) setTimeout(() => nextStep(), 2000);
  }, [useVoiceMode, speak, nextStep, stopListening]);

  const selectVisual = useCallback((value) => {
    stopListening();
    setVisualNeeds(value);
    if (value === "low_vision") {
      setTextScale(1.5); setHighContrast(true); setBoldText(true);
      speak("Mode texte agrandi sélectionné");
    } else if (value === "blind") {
      setHighContrast(true);
      speak("Mode aveugle sélectionné. Tout sera lu à voix haute.");
    } else {
      speak("Mode standard sélectionné");
    }
    if (useVoiceMode) setTimeout(() => nextStep(), 2000);
  }, [useVoiceMode, speak, nextStep, stopListening]);

  const selectAudio = useCallback((value) => {
    stopListening();
    setAudioNeeds(value);
    if (value === "deaf" || value === "hearing_loss") {
      stopSpeech();
      setUseVoiceMode(false);
      return;
    }
    speak("Mode audition standard sélectionné");
    if (useVoiceMode) setTimeout(() => nextStep(), 2000);
  }, [useVoiceMode, speak, nextStep, stopListening, stopSpeech]);

  const selectMotor = useCallback((value) => {
    stopListening();
    setMotorNeeds(value);
    if (value === "limited_dexterity") speak("Mode commandes vocales sélectionné");
    else speak("Mode interaction standard sélectionné");
    if (useVoiceMode) setTimeout(() => nextStep(), 2000);
  }, [useVoiceMode, speak, nextStep, stopListening]);

  useEffect(() => {
    if (accessibility) {
      accessibility.setTextScale(textScale);
      accessibility.setHighContrast(highContrast);
      accessibility.setBoldText(boldText);
    }
  }, [textScale, highContrast, boldText, accessibility]);

  const isLast = currentStep === 4;
  const buttonText = isLast ? T(selectedLanguage.code, "Commencer", "Start", "ابدأ") : T(selectedLanguage.code, "Continuer", "Continue", "متابعة");

  return (
    <div
      style={{
        position: "fixed",
        top: 0,
        left: 0,
        width: "100vw",
        height: "100vh",
        overflow: "auto",
        background: bgColor,
        color: textColor,
      }}
    >
      {/* AppBar */}
      <header
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          padding: "12px 16px",
          borderBottom: useHighContrast ? "1px solid #333" : "1px solid #eee",
        }}
      >
        <div style={{ width: 48 }}>
          {currentStep > 0 ? (
            <button
              type="button"
              onClick={() => { onUserTouch(); previousStep(); }}
              style={{
                background: "none",
                border: "none",
                color: textColor,
                cursor: "pointer",
                fontSize: 24,
                padding: 4,
              }}
              aria-label={T(selectedLanguage.code, "Retour", "Back", "رجوع")}
            >
              ←
            </button>
          ) : null}
        </div>
        <span style={{ fontSize: 18 * ts, fontWeight: 600 }}>
          {currentStep === 0 ? "" : T(selectedLanguage.code, `Étape ${currentStep} / 4`, `Step ${currentStep} / 4`, `الخطوة ${currentStep} / 4`)}
        </span>
        <button
          type="button"
          onClick={() => { onUserTouch(); handleSkip(); }}
          style={{
            background: "none",
            border: "none",
            color: useHighContrast ? "#aaa" : appColors.primary,
            cursor: "pointer",
            fontSize: 16,
            fontWeight: "bold",
            padding: "8px 12px",
          }}
        >
          {T(selectedLanguage.code, "Passer", "Skip", "تخطي")}
        </button>
      </header>

      {/* Progress */}
      {currentStep > 0 && (
        <div style={{ padding: "16px 24px 0" }}>
          <div
            style={{
              height: 8,
              borderRadius: 4,
              background: useHighContrast ? "#333" : "#e0e0e0",
              overflow: "hidden",
            }}
          >
            <div
              style={{
                height: "100%",
                width: `${(currentStep / 4) * 100}%`,
                background: useHighContrast ? "#fff" : appColors.primary,
                borderRadius: 4,
              }}
            />
          </div>
        </div>
      )}

      <div style={{ maxWidth: 450, margin: "0 auto", padding: `24px ${24 * ts}px` }}>
        <div style={{ minHeight: 320 }}>{renderStep()}</div>

        {/* Main button */}
        <div style={{ marginTop: 24 }}>
          <button
            type="button"
            onClick={() => {
              onUserTouch();
              if (isLast) goToLogin();
              else nextStep();
            }}
            style={{
              width: "100%",
              height: 64 * Math.min(ts, 1.3),
              fontSize: 20 * ts,
              fontWeight: "bold",
              borderRadius: 16,
              border: useHighContrast ? "3px solid #fff" : "none",
              background: useHighContrast ? "#fff" : appColors.primary,
              color: useHighContrast ? "#000" : "#fff",
              cursor: "pointer",
              boxShadow: useHighContrast ? "none" : `0 4px 12px ${appColors.primary}80`,
            }}
          >
            {buttonText}
          </button>
        </div>

        {/* Listening Indicator */}
        {useVoiceMode && isListening && (
          <div style={{
            marginTop: 20,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 12,
            color: appColors.primary,
            fontWeight: "bold"
          }}>
            <span style={{
              width: 12,
              height: 12,
              background: appColors.primary,
              borderRadius: "50%",
              animation: "pulse 1.5s infinite"
            }} />
            <span>{T(selectedLanguage.code, "Je vous écoute...", "I'm listening...", "أنا أستمع...")}</span>
          </div>
        )}

        {useVoiceMode && !userHasTouched && (!isSttAvailable || sttError) && (
          <div style={{
            marginTop: 16,
            padding: 12,
            borderRadius: 12,
            border: `1px solid ${useHighContrast ? '#666' : '#ddd'}`,
            background: useHighContrast ? '#111' : '#fff',
            color: textColor,
            textAlign: 'center'
          }}>
            {!isSecureOrLocalhost && (
              <div style={{ fontSize: 12 * ts, marginBottom: 10, color: `${textColor}cc` }}>
                {T(
                  selectedLanguage.code,
                  "Pour activer le micro, ouvrez l'app sur http://localhost:5173 (ou en HTTPS). Sur une adresse IP en http, le navigateur peut bloquer le micro.",
                  "To enable the mic, open the app on http://localhost:5173 (or HTTPS). On an IP address over http, the browser may block the mic.",
                  "لتفعيل الميكروفون، افتح التطبيق على http://localhost:5173 (أو عبر HTTPS). على عنوان IP عبر http قد يمنع المتصفح الميكروفون."
                )}
              </div>
            )}
            <div style={{ fontSize: 14 * ts, marginBottom: 10 }}>
              {T(
                selectedLanguage.code,
                "Le micro n'est pas actif. Cliquez pour l'activer.",
                "Microphone is not active. Click to enable.",
                "الميكروفون غير نشط. اضغط للتفعيل."
              )}
            </div>
            <button
              type="button"
              onClick={() => {
                const lang = selectedLanguage.code === 'fr' ? 'fr-FR' : selectedLanguage.code === 'ar' ? 'ar-SA' : 'en-GB';
                startListeningForStep(currentStep, lang);
              }}
              style={{
                padding: '12px 16px',
                borderRadius: 12,
                border: useHighContrast ? '2px solid #fff' : '1px solid #ddd',
                background: useHighContrast ? '#fff' : appColors.primary,
                color: useHighContrast ? '#000' : '#fff',
                cursor: 'pointer',
                fontWeight: 'bold'
              }}
            >
              {T(selectedLanguage.code, "Activer le micro", "Enable mic", "تفعيل الميكروفون")}
            </button>
          </div>
        )}
      </div>
      <style>{`
        @keyframes pulse {
          0% { transform: scale(1); opacity: 1; }
          50% { transform: scale(1.5); opacity: 0.5; }
          100% { transform: scale(1); opacity: 1; }
        }
      `}</style>
    </div>
  );

  function renderStep() {
    switch (currentStep) {
      case 0:
        return (
          <>
            <div style={{ textAlign: "center", marginBottom: 32 }}>
              <div
                style={{
                  width: 80,
                  height: 80,
                  borderRadius: "50%",
                  background: "#fff",
                  margin: "0 auto 16px",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  fontSize: 40,
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
              <h2 style={{ margin: 0, fontSize: 22 * ts, fontWeight: "bold", color: textColor }}>
                {T(selectedLanguage.code, "Choisissez votre langue", "Choose your language", "اختر لغتك")}
              </h2>
            </div>
            {LANGUAGES.map((lang) => (
              <button
                key={lang.code}
                type="button"
                onClick={() => selectLanguage(lang)}
                style={{
                  width: "100%",
                  display: "flex",
                  alignItems: "center",
                  gap: 16,
                  padding: "12px 16px",
                  marginBottom: 12,
                  border: `2px solid ${selectedLanguage.code === lang.code ? appColors.primary : "transparent"}`,
                  borderRadius: 12,
                  background: useHighContrast ? "#1a1a1a" : "#fff",
                  cursor: "pointer",
                  boxShadow: useHighContrast ? "none" : "0 1px 4px rgba(0,0,0,0.1)",
                  textAlign: "left",
                }}
              >
                <span style={{ fontSize: 32 }}>{lang.flag}</span>
                <div style={{ flex: 1 }}>
                  <div
                    style={{
                      fontSize: 18 * ts,
                      fontWeight: "bold",
                      color: selectedLanguage.code === lang.code ? appColors.primary : textColor,
                    }}
                  >
                    {lang.nativeName}
                  </div>
                  <div style={{ fontSize: 14, color: `${textColor}99` }}>{lang.name}</div>
                </div>
                {selectedLanguage.code === lang.code && (
                  <span style={{ color: appColors.primary, fontSize: 20 }}>✓</span>
                )}
              </button>
            ))}
            <p
              style={{
                textAlign: "center",
                fontSize: 14,
                fontStyle: "italic",
                color: `${textColor}99`,
                marginTop: 16,
              }}
            >
              {T(selectedLanguage.code, "Ou dites simplement le nom de la langue", "Or just say the language name", "أو قل اسم اللغة ببساطة")}
            </p>
          </>
        );
      case 1:
        return (
          <>
            <div style={{ marginBottom: 24 }}>
              <span style={{ fontSize: 48 * ts, color: useHighContrast ? "#fff" : appColors.primary }}>👁️</span>
              <h2 style={{ margin: "16px 0 0", fontSize: 28 * ts, fontWeight: "bold", color: textColor }}>
                {T(selectedLanguage.code, "Vision", "Vision", "الرؤية")}
              </h2>
            </div>
            <OptionCard
              title={T(selectedLanguage.code, "Je vois bien", "I see well", "أرى جيدًا")}
              subtitle={T(selectedLanguage.code, "Mode standard", "Standard mode", "الوضع العادي")}
              voiceHint={T(selectedLanguage.code, 'Dites "normal"', 'Say "normal"', 'قل "عادي"')}
              isSelected={visualNeeds === "normal"}
              onTap={() => selectVisual("normal")}
              useHighContrast={useHighContrast}
              textColor={textColor}
              ts={ts}
            />
            <OptionCard
              title={T(selectedLanguage.code, "Texte plus grand", "Larger text", "نص أكبر")}
              subtitle={T(selectedLanguage.code, "Texte agrandi + contraste", "Enlarged + contrast", "مكبّر + تباين")}
              voiceHint={T(selectedLanguage.code, 'Dites "agrandi"', 'Say "larger"', 'قل "أكبر"')}
              isSelected={visualNeeds === "low_vision"}
              onTap={() => selectVisual("low_vision")}
              useHighContrast={useHighContrast}
              textColor={textColor}
              ts={ts}
            />
            <OptionCard
              title={T(selectedLanguage.code, "Je suis aveugle", "I am blind", "أنا كفيف")}
              subtitle={T(selectedLanguage.code, "Tout sera lu à voix haute", "Everything read aloud", "كل شيء يُقرأ بصوت عالٍ")}
              voiceHint={T(selectedLanguage.code, 'Dites "aveugle"', 'Say "blind"', 'قل "كفيف"')}
              isSelected={visualNeeds === "blind"}
              onTap={() => { onUserTouch(); selectVisual("blind"); }}
              useHighContrast={useHighContrast}
              textColor={textColor}
              ts={ts}
            />
            {visualNeeds !== "blind" && (
              <>
                <div style={{ marginTop: 32, marginBottom: 8 }}>
                  <span style={{ fontSize: 18 * ts, fontWeight: 600, color: textColor }}>
                    {T(selectedLanguage.code, "Taille du texte", "Text size", "حجم النص")}
                  </span>
                </div>
                <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                  <span style={{ fontSize: 14, color: textColor }}>A</span>
                  <input
                    type="range"
                    min="1"
                    max="2"
                    step="0.2"
                    value={textScale}
                    onChange={(e) => setTextScale(parseFloat(e.target.value))}
                    style={{ flex: 1, accentColor: appColors.primary }}
                  />
                  <span style={{ fontSize: 28, fontWeight: "bold", color: textColor }}>A</span>
                </div>
                <div
                  style={{
                    marginTop: 12,
                    padding: 16 * ts,
                    borderRadius: 12,
                    background: useHighContrast ? "#1a1a1a" : "#f0f0f0",
                  }}
                >
                  <span
                    style={{
                      fontSize: 16 * textScale,
                      fontWeight: boldText ? "bold" : "normal",
                      color: textColor,
                    }}
                  >
                    {T(selectedLanguage.code, "Aperçu du texte", "Text preview", "معاينة النص")}
                  </span>
                </div>
              </>
            )}
          </>
        );
      case 2:
        return (
          <>
            <div style={{ marginBottom: 24 }}>
              <span style={{ fontSize: 48 * ts, color: useHighContrast ? "#fff" : appColors.primary }}>👂</span>
              <h2 style={{ margin: "16px 0 0", fontSize: 28 * ts, fontWeight: "bold", color: textColor }}>
                {T(selectedLanguage.code, "Audition", "Hearing", "السمع")}
              </h2>
            </div>
            <OptionCard
              title={T(selectedLanguage.code, "J'entends bien", "I hear well", "أسمع جيدًا")}
              subtitle={T(selectedLanguage.code, "Notifications sonores", "Sound notifications", "إشعارات صوتية")}
              voiceHint={T(selectedLanguage.code, 'Dites "entends"', 'Say "hear"', 'قل "أسمع"')}
              isSelected={audioNeeds === "normal"}
              onTap={() => selectAudio("normal")}
              useHighContrast={useHighContrast}
              textColor={textColor}
              ts={ts}
            />
            <OptionCard
              title={T(selectedLanguage.code, "Vibrations renforcées", "Enhanced vibrations", "اهتزازات معززة")}
              subtitle={T(selectedLanguage.code, "Vibrations fortes", "Strong vibrations", "اهتزازات قوية")}
              voiceHint={T(selectedLanguage.code, 'Dites "vibration"', 'Say "vibration"', 'قل "اهتزاز"')}
              isSelected={audioNeeds === "hearing_loss"}
              onTap={() => selectAudio("hearing_loss")}
              useHighContrast={useHighContrast}
              textColor={textColor}
              ts={ts}
            />
            <OptionCard
              title={T(selectedLanguage.code, "Je suis sourd", "I am deaf", "أنا أصم")}
              subtitle={T(selectedLanguage.code, "Notifications visuelles", "Visual notifications", "إشعارات مرئية")}
              voiceHint={T(selectedLanguage.code, 'Dites "sourd"', 'Say "deaf"', 'قل "أصم"')}
              isSelected={audioNeeds === "deaf"}
              onTap={() => selectAudio("deaf")}
              useHighContrast={useHighContrast}
              textColor={textColor}
              ts={ts}
            />
          </>
        );
      case 3:
        return (
          <>
            <div style={{ marginBottom: 24 }}>
              <span style={{ fontSize: 48 * ts, color: useHighContrast ? "#fff" : appColors.primary }}>✋</span>
              <h2 style={{ margin: "16px 0 0", fontSize: 28 * ts, fontWeight: "bold", color: textColor }}>
                {T(selectedLanguage.code, "Interaction", "Interaction", "التفاعل")}
              </h2>
            </div>
            <OptionCard
              title={T(selectedLanguage.code, "Oui, sans problème", "Yes, no problem", "نعم، بدون مشكلة")}
              subtitle={T(selectedLanguage.code, "Écran tactile standard", "Standard touch", "لمس عادي")}
              voiceHint={T(selectedLanguage.code, 'Dites "normal"', 'Say "normal"', 'قل "عادي"')}
              isSelected={motorNeeds === "normal"}
              onTap={() => selectMotor("normal")}
              useHighContrast={useHighContrast}
              textColor={textColor}
              ts={ts}
            />
            <OptionCard
              title={T(selectedLanguage.code, "Difficultés motrices", "Motor difficulties", "صعوبات حركية")}
              subtitle={T(selectedLanguage.code, "Commandes vocales activées", "Voice commands enabled", "أوامر صوتية مفعّلة")}
              voiceHint={T(selectedLanguage.code, 'Dites "vocale"', 'Say "voice"', 'قل "صوت"')}
              isSelected={motorNeeds === "limited_dexterity"}
              onTap={() => selectMotor("limited_dexterity")}
              useHighContrast={useHighContrast}
              textColor={textColor}
              ts={ts}
            />
            {motorNeeds === "limited_dexterity" && (
              <div
                style={{
                  marginTop: 24,
                  padding: 16 * ts,
                  borderRadius: 12,
                  border: "2px solid #4CAF50",
                  background: "rgba(76, 175, 80, 0.2)",
                  display: "flex",
                  alignItems: "center",
                  gap: 12,
                }}
              >
                <span style={{ fontSize: 32 }}>🎤</span>
                <span style={{ fontSize: 14 * ts, fontWeight: 600, color: textColor }}>
                  {T(
                    selectedLanguage.code,
                    "✅ Commandes vocales activées! Dites le nom du bouton.",
                    "✅ Voice commands enabled! Say the button name.",
                    "✅ الأوامر الصوتية مفعّلة! قل اسم الزر."
                  )}
                </span>
              </div>
            )}
          </>
        );
      case 4:
        return (
          <>
            <div style={{ textAlign: "center", marginBottom: 24 }}>
              <span style={{ fontSize: 80 * Math.min(ts, 1.2), color: appColors.success }}>✅</span>
              <h2 style={{ margin: "24px 0 0", fontSize: 28 * ts, fontWeight: "bold", color: textColor }}>
                ✅ {T(selectedLanguage.code, "Configuration terminée!", "Setup complete!", "اكتمل الإعداد!")}
              </h2>
            </div>
            <div
              style={{
                padding: 20 * ts,
                borderRadius: 16,
                border: `2px solid ${useHighContrast ? "#fff" : appColors.primary}`,
                background: useHighContrast ? "#111" : `${appColors.primary}1A`,
              }}
            >
              <SummaryRow
                label={`🌍 ${T(selectedLanguage.code, "Langue", "Language", "اللغة")}`}
                value={selectedLanguage.nativeName}
                textColor={textColor}
                ts={ts}
              />
              <SummaryRow
                label={`👁️ ${T(selectedLanguage.code, "Vision", "Vision", "الرؤية")}`}
                value={getVisualSummary()}
                textColor={textColor}
                ts={ts}
              />
              <SummaryRow
                label={`👂 ${T(selectedLanguage.code, "Audition", "Hearing", "السمع")}`}
                value={getAudioSummary()}
                textColor={textColor}
                ts={ts}
              />
              <SummaryRow
                label={`✋ ${T(selectedLanguage.code, "Interaction", "Interaction", "التفاعل")}`}
                value={getMotorSummary()}
                textColor={textColor}
                ts={ts}
              />
            </div>
            <p
              style={{
                marginTop: 24,
                fontSize: 16 * ts,
                fontStyle: "italic",
                color: `${textColor}99`,
                textAlign: "center",
              }}
            >
              {T(selectedLanguage.code, 'Dites "Commencer" pour continuer', 'Say "Start" to continue', 'قل "ابدأ" للمتابعة')}
            </p>
          </>
        );
      default:
        return null;
    }
  }

  function SummaryRow({ label, value, textColor, ts }) {
    return (
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: 12,
        }}
      >
        <span style={{ fontSize: 16 * ts, fontWeight: 500, color: textColor }}>{label}</span>
        <span style={{ fontSize: 16 * ts, fontWeight: "bold", color: `${textColor}cc` }}>{value}</span>
      </div>
    );
  }

  function getVisualSummary() {
    switch (visualNeeds) {
      case "low_vision":
        return T(selectedLanguage.code, "Texte agrandi", "Enlarged text", "نص مكبّر");
      case "blind":
        return T(selectedLanguage.code, "Lecture vocale", "Voice reading", "قراءة صوتية");
      default:
        return T(selectedLanguage.code, "Standard", "Standard", "عادي");
    }
  }

  function getAudioSummary() {
    switch (audioNeeds) {
      case "hearing_loss":
        return T(selectedLanguage.code, "Vibrations", "Vibrations", "اهتزازات");
      case "deaf":
        return T(selectedLanguage.code, "Mode visuel", "Visual mode", "وضع مرئي");
      default:
        return T(selectedLanguage.code, "Standard", "Standard", "عادي");
    }
  }

  function getMotorSummary() {
    return motorNeeds === "limited_dexterity"
      ? T(selectedLanguage.code, "Commandes vocales", "Voice commands", "أوامر صوتية")
      : T(selectedLanguage.code, "Standard", "Standard", "عادي");
  }
}
