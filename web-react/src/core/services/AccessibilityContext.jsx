import { createContext, useContext, useState, useCallback, useEffect } from "react";

const STORAGE_KEYS = {
  highContrast: "accessibility_highContrast",
  textScale: "accessibility_textScale",
  boldText: "accessibility_boldText",
  visualNeeds: "accessibility_visualNeeds",
  audioNeeds: "accessibility_audioNeeds",
  motorNeeds: "accessibility_motorNeeds",
  languageCode: "accessibility_languageCode",
  profile: "accessibility_profile_json",
  wizardCompleted: "onboarding_wizard_completed",
};

const AccessibilityContext = createContext(null);

export function AccessibilityProvider({ children }) {
  const [highContrast, setHighContrastState] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEYS.highContrast) || "false");
    } catch {
      return false;
    }
  });
  const [textScale, setTextScaleState] = useState(() => {
    try {
      const v = parseFloat(localStorage.getItem(STORAGE_KEYS.textScale) || "1");
      return Number.isFinite(v) ? Math.max(0.8, Math.min(2, v)) : 1;
    } catch {
      return 1;
    }
  });
  const [boldText, setBoldTextState] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEYS.boldText) || "false");
    } catch {
      return false;
    }
  });

  useEffect(() => {
    document.documentElement.dataset.theme = highContrast ? "highContrast" : "";
  }, [highContrast]);

  const setHighContrast = useCallback((value) => {
    const v = !!value;
    setHighContrastState(v);
    try {
      localStorage.setItem(STORAGE_KEYS.highContrast, JSON.stringify(v));
    } catch (_) {}
  }, []);

  const setTextScale = useCallback((value) => {
    const v = Math.max(0.8, Math.min(2, Number(value) || 1));
    setTextScaleState(v);
    try {
      localStorage.setItem(STORAGE_KEYS.textScale, String(v));
    } catch (_) {}
  }, []);

  const setBoldText = useCallback((value) => {
    const v = !!value;
    setBoldTextState(v);
    try {
      localStorage.setItem(STORAGE_KEYS.boldText, JSON.stringify(v));
    } catch (_) {}
  }, []);

  const value = {
    highContrast,
    textScale,
    boldText,
    setHighContrast,
    setTextScale,
    setBoldText,
    STORAGE_KEYS,
  };

  return (
    <AccessibilityContext.Provider value={value}>
      <div
        style={{
          fontSize: `${textScale * 100}%`,
          fontWeight: boldText ? "bold" : undefined,
        }}
      >
        {children}
      </div>
    </AccessibilityContext.Provider>
  );
}

export function useAccessibility() {
  const ctx = useContext(AccessibilityContext);
  if (!ctx) return null;
  return ctx;
}

export function getWizardCompleted() {
  try {
    return JSON.parse(localStorage.getItem(STORAGE_KEYS.wizardCompleted) || "false");
  } catch {
    return false;
  }
}

export function setWizardCompleted(value) {
  try {
    localStorage.setItem(STORAGE_KEYS.wizardCompleted, JSON.stringify(!!value));
  } catch (_) {}
}

export function saveAccessibilityProfile(profile) {
  try {
    localStorage.setItem(STORAGE_KEYS.profile, JSON.stringify(profile));
  } catch (_) {}
}
