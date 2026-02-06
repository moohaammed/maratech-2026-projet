import { useEffect, useState } from "react";
import { onAuthStateChanged } from "firebase/auth";
import { auth } from "./lib/firebase";
import LoginPage from "./pages/LoginPage";
import HomePage from "./pages/HomePage";

export default function App() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    return onAuthStateChanged(auth, (u) => {
      setUser(u);
      setLoading(false);
    });
  }, []);

  if (loading) return <p style={{ padding: 16 }}>Chargement…</p>;
  return user ? <HomePage user={user} /> : <LoginPage />;
}
