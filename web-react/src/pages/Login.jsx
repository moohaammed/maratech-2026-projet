import { useState } from "react";
import { signInWithEmailAndPassword } from "firebase/auth";
import { auth } from "../lib/firebase";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [err, setErr] = useState("");

  const submit = async (e) => {
    e.preventDefault();
    setErr("");
    try {
      await signInWithEmailAndPassword(auth, email, password);
    } catch (e) {
      setErr(e.message);
    }
  };

  return (
    <main style={{ maxWidth: 420, margin: "40px auto", padding: 16 }}>
      <h1>Login</h1>
      <form onSubmit={submit} aria-label="Login form">
        <label>
          Email
          <input
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            type="email"
            autoComplete="email"
            required
            style={{ width: "100%", padding: 10, marginTop: 6, marginBottom: 12 }}
          />
        </label>

        <label>
          Password
          <input
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            type="password"
            autoComplete="current-password"
            required
            style={{ width: "100%", padding: 10, marginTop: 6, marginBottom: 12 }}
          />
        </label>

        {err && <p role="alert" style={{ color: "crimson" }}>{err}</p>}

        <button type="submit" style={{ padding: 10, width: "100%" }}>
          Sign in
        </button>
      </form>
    </main>
  );
}
