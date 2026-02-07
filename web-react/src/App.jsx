import { useEffect, useState } from "react";
import { onAuthStateChanged } from "firebase/auth";
import { auth } from "./lib/firebase";
import { AccessibilityProvider, getWizardCompleted } from "./core/services/AccessibilityContext";
import AccessibilityWizardPage from "./pages/AccessibilityWizardPage";
import LoginPage from "./pages/LoginPage";
import HomePage from "./pages/HomePage";

export default function App() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [showWizard, setShowWizard] = useState(() => !getWizardCompleted());

  useEffect(() => {
    return onAuthStateChanged(auth, (u) => {
      setUser(u);
      setLoading(false);
    });
  }, []);

  const handleWizardFinish = () => setShowWizard(false);
  const handleWizardSkip = () => setShowWizard(false);

  if (loading) {
    return (
      <div style={{ minHeight: "100vh", display: "grid", placeItems: "center", background: "#F5F5F5" }}>
        <p style={{ padding: 16 }}>Chargement…</p>
      </div>
    );
  }

  if (showWizard) {
    return (
      <AccessibilityProvider>
        <AccessibilityWizardPage onFinish={handleWizardFinish} onSkip={handleWizardSkip} />
      </AccessibilityProvider>
    );
  }

  return (
    <AccessibilityProvider>
      {user ? <HomePage user={user} /> : <LoginPage />}
    </AccessibilityProvider>
  );
}
