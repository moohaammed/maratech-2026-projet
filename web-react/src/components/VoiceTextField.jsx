import { useEffect, useMemo, useRef, useState } from "react";
import { useAccessibility } from "../core/services/AccessibilityContext";
import { appColors } from "../core/theme/appColors";
import "./VoiceTextField.css";

export default function VoiceTextField({
  label,
  hint,
  icon,
  fieldName,
  value,
  onChange,
  obscureText = false,
  keyboardType = "text",
  maxLength,
  isListening = false,
  onStartVoice,
  onStopVoice,
  validator,
  onSubmit,
  suffixIcon,
  autoFocus = false,
  hideVoice = false,
}) {
  const accessibility = useAccessibility();
  const textScale = accessibility?.textScale || 1;
  const boldText = accessibility?.boldText || false;
  const highContrast = accessibility?.highContrast || false;
  const primaryColor = highContrast ? appColors.highContrastPrimary : appColors.primary;
  const surfaceColor = highContrast ? appColors.highContrastSurface : appColors.surface;
  const textColor = highContrast ? "#FFFFFF" : appColors.textPrimary;
  const secondaryTextColor = highContrast ? "rgba(255, 255, 255, 0.7)" : appColors.textSecondary;
  const borderColor = highContrast ? "#FFFFFF" : appColors.divider;

  const inputRef = useRef(null);
  const [touched, setTouched] = useState(false);

  const errorText = useMemo(() => {
    if (!validator) return "";
    return validator(value);
  }, [validator, value]);

  useEffect(() => {
    if (autoFocus && inputRef.current) {
      inputRef.current.focus();
    }
  }, [autoFocus]);

  const inputType = useMemo(() => {
    if (obscureText) return "password";
    if (keyboardType === "number") return "tel";
    return "text";
  }, [obscureText, keyboardType]);

  const handleVoiceToggle = () => {
    if (isListening) {
      onStopVoice?.();
    } else {
      onStartVoice?.();
    }
  };

  const handleKeyDown = (e) => {
    if (e.key === "Enter") {
      onSubmit?.();
    }
  };

  return (
    <div className="voice-text-field" style={{ marginBottom: `${20 * Math.min(textScale, 1.2)}px` }}>
      <label
        htmlFor={fieldName}
        style={{
          display: "block",
          marginBottom: `${8 * Math.min(textScale, 1.2)}px`,
          fontSize: `${14 * textScale}px`,
          color: secondaryTextColor,
          fontWeight: boldText ? "bold" : 600,
        }}
      >
        {label}
      </label>

      <div
        className={`voice-text-field-container ${isListening ? "listening" : ""}`}
        style={{
          display: "flex",
          alignItems: "center",
          gap: 10,
          width: "100%",
          padding: `${12 * Math.min(textScale, 1.2)}px`,
          borderRadius: 14,
          backgroundColor: surfaceColor,
          border: `1px solid ${errorText ? appColors.error : borderColor}`,
        }}
      >
        <div
          aria-hidden="true"
          style={{
            padding: 8,
            borderRadius: 10,
            backgroundColor: highContrast ? `${primaryColor}4D` : `${primaryColor}1A`,
            color: highContrast ? "#000" : primaryColor,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontSize: `${18 * Math.min(textScale, 1.2)}px`,
          }}
        >
          <span>{icon}</span>
        </div>

        <input
          id={fieldName}
          ref={inputRef}
          type={inputType}
          inputMode={keyboardType === "number" ? "numeric" : undefined}
          aria-label={label}
          aria-invalid={!!errorText}
          placeholder={hint}
          value={value}
          onChange={(e) => onChange?.(e.target.value)}
          onBlur={() => setTouched(true)}
          onKeyDown={handleKeyDown}
          maxLength={maxLength}
          style={{
            flex: 1,
            height: `${40 * Math.min(textScale, 1.2)}px`,
            border: "none",
            outline: "none",
            background: "transparent",
            color: textColor,
            fontSize: `${16 * textScale}px`,
            fontWeight: boldText ? "bold" : 500,
          }}
        />

        {suffixIcon && (
          <div style={{ marginRight: '8px' }}>
            {suffixIcon}
          </div>
        )}

        {!hideVoice && (
          <button
            type="button"
            onClick={handleVoiceToggle}
            className={`voice-button ${isListening ? "listening" : ""}`}
            aria-label={isListening ? "Arrêter la dictée" : "Commencer la dictée"}
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: 8,
              padding: "5px 7px",
              borderRadius: 10,
              border: highContrast ? `1px solid ${primaryColor}` : "none",
              backgroundColor: highContrast ? `${primaryColor}4D` : `${primaryColor}1A`,
              color: highContrast ? "#000" : primaryColor,
              cursor: "pointer",
              fontWeight: 700,
              marginRight: '4px',
            }}
          >
            <span style={{ fontSize: `${18 * Math.min(textScale, 1.2)}px` }}>🎤</span>
            {isListening && (
              <span
                className="listening-spinner"
                style={{ width: 16, height: 16 }}
                aria-hidden="true"
              />
            )}
          </button>
        )}
      </div>

      {(touched || errorText) && errorText && (
        <div
          role="alert"
          aria-live="polite"
          style={{
            marginTop: 8,
            display: "flex",
            alignItems: "center",
            gap: 8,
            color: appColors.error,
            fontSize: `${13 * textScale}px`,
            fontWeight: "bold",
          }}
        >
          <span style={{ fontSize: 16 }}>⚠️</span>
          <span>{errorText}</span>
        </div>
      )}
    </div>
  );
}
