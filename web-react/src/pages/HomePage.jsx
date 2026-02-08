import { signOut } from "firebase/auth";
import { auth } from "../lib/firebase";
import "./HomePage.css";

export default function HomePage({ user }) {
  const logout = async () => {
    await signOut(auth);
  };

  return (
    <main className="home">
      <section className="home-card" aria-label="Accueil">
        <div aria-hidden="true" className="home-emoji">✅</div>
        <h1 className="home-title">Connexion réussie !</h1>
        <p className="home-subtitle">Bienvenue</p>
        <p className="home-identity">{user?.email || "Utilisateur"}</p>
        <div className="home-actions">
          <button onClick={logout} className="home-logout">Se déconnecter</button>
        </div>
      </section>
    </main>
  );
}
