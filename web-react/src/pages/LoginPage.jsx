import { useMemo, useState } from "react";
import { signInWithEmailAndPassword } from "firebase/auth";
import { auth } from "../lib/firebase";

function withTimeout(promise, ms, message) {
  let timer;
  const timeout = new Promise((_, reject) => {
    timer = setTimeout(() => reject(new Error(message)), ms);
  });
  return Promise.race([promise, timeout]).finally(() => clearTimeout(timer));
}

function mapFirebaseAuthError(err) {
  const code = err?.code || "";

  if (code === "auth/user-not-found") return "Utilisateur non trouvé. Vérifiez l'email.";
  if (code === "auth/wrong-password") return "Mot de passe incorrect.";
  if (code === "auth/invalid-email") return "Format d'email invalide.";
  if (code === "auth/invalid-credential") return "Email ou mot de passe incorrect.";
  if (code === "auth/too-many-requests") return "Trop de tentatives. Réessayez plus tard.";

  // fallback
  return `Erreur: ${err?.message || "Impossible de se connecter."}`;
}

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const [errorMessage, setErrorMessage] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  const canSubmit = useMemo(() => {
    return email.trim().length > 0 && password.trim().length > 0 && !isLoading;
  }, [email, password, isLoading]);

  const login = async (e) => {
    e.preventDefault();
    setErrorMessage("");
    setIsLoading(true);

    const eTrim = email.trim();
    const pTrim = password.trim();

    // Debug logs like Flutter prints
    console.log("=== LOGIN ATTEMPT ===");
    console.log("Time:", new Date().toISOString());
    console.log("Email:", eTrim);
    console.log("Attempting Firebase signIn...");

    try {
      const cred = await withTimeout(
        signInWithEmailAndPassword(auth, eTrim, pTrim),
        30000,
        "Timeout: La connexion a pris trop de temps. Vérifiez votre connexion internet."
      );

      console.log("=== LOGIN SUCCESS ===");
      console.log("User:", cred.user?.email);
      console.log("UID:", cred.user?.uid);
      // onAuthStateChanged will redirect to HomePage automatically
    } catch (err) {
      console.log("=== LOGIN ERROR ===");
      console.log("Full error:", err);
      setErrorMessage(mapFirebaseAuthError(err));
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <main style={{ minHeight: "100vh", display: "grid", placeItems: "center", padding: 16 }}>
      <section
        style={{
          width: "min(480px, 100%)",
          background: "white",
          border: "1px solid #ddd",
          borderRadius: 12,
          padding: 24,
        }}
        aria-label="Connexion"
      >
        <div style={{ textAlign: "center", marginBottom: 20 }}>
          <div
            aria-hidden="true"
            style={{ fontSize: 48, lineHeight: 1, marginBottom: 12 }}
          >
            🏃
          </div>
          <h1 style={{ margin: 0, fontSize: 28 }}>Connexion</h1>
          <p style={{ marginTop: 8, color: "#444", fontSize: 18 }}>
            Connectez-vous avec votre compte Firebase
          </p>
        </div>

        <form onSubmit={login} aria-label="Formulaire de connexion">
          <label htmlFor="email" style={{ display: "block", fontSize: 18, marginBottom: 6 }}>
            Email
          </label>
          <div style={{ display: "flex", gap: 8, alignItems: "center", marginBottom: 16 }}>
            <span aria-hidden="true">📧</span>
            <input
              id="email"
              type="email"
              inputMode="email"
              autoComplete="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              style={{ flex: 1, padding: 12, fontSize: 18 }}
              aria-describedby="email-help"
            />
          </div>
          <div id="email-help" style={{ marginTop: -10, marginBottom: 16, color: "#555" }}>
            Exemple: nom@exemple.com
          </div>

          <label htmlFor="password" style={{ display: "block", fontSize: 18, marginBottom: 6 }}>
            Mot de passe
          </label>
          <div style={{ display: "flex", gap: 8, alignItems: "center", marginBottom: 20 }}>
            <span aria-hidden="true">🔒</span>
            <input
              id="password"
              type="password"
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              style={{ flex: 1, padding: 12, fontSize: 18 }}
            />
          </div>

          <button
            type="submit"
            disabled={!canSubmit}
            style={{
              width: "100%",
              height: 56,
              fontSize: 20,
              fontWeight: 700,
              background: canSubmit ? "#0b4dbb" : "#8aa7df",
              color: "white",
              border: "none",
              borderRadius: 10,
              cursor: canSubmit ? "pointer" : "not-allowed",
            }}
            aria-busy={isLoading ? "true" : "false"}
          >
            {isLoading ? "Connexion…" : "SE CONNECTER"}
          </button>

          {errorMessage && (
            <p
              role="alert"
              aria-live="assertive"
              style={{
                marginTop: 16,
                color: "crimson",
                fontSize: 18,
                fontWeight: 700,
                textAlign: "center",
              }}
            >
              {errorMessage}
            </p>
          )}
        </form>
      </section>
    </main>
  );
}
