import { signOut } from "firebase/auth";
import { auth } from "../lib/firebase";

export default function HomePage({ user }) {
  const logout = async () => {
    await signOut(auth);
  };

  return (
    <main style={{ minHeight: "100vh", display: "grid", placeItems: "center", padding: 16 }}>
      <section
        style={{
          width: "min(560px, 100%)",
          background: "white",
          border: "1px solid #ddd",
          borderRadius: 12,
          padding: 24,
          textAlign: "center",
        }}
        aria-label="Accueil"
      >
        <div aria-hidden="true" style={{ fontSize: 56, marginBottom: 10 }}>
          ✅
        </div>

        <h1 style={{ margin: 0, fontSize: 30 }}>Connexion réussie !</h1>

        <p style={{ fontSize: 20, color: "#555", marginTop: 16 }}>Bienvenue</p>

        <p style={{ fontSize: 24, fontWeight: 600, color: "#0b4dbb", marginTop: 6 }}>
          {user?.email || "Utilisateur"}
        </p>

        <button
          onClick={logout}
          style={{
            marginTop: 24,
            padding: "14px 20px",
            fontSize: 18,
            borderRadius: 10,
            border: "1px solid #bbb",
            background: "white",
            cursor: "pointer",
          }}
        >
          Se déconnecter
        </button>
      </section>
    </main>
  );
}
