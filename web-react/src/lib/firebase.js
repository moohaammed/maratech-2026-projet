import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

// Replace with your Firebase web config (from Firebase Console)
const firebaseConfig = {
  apiKey: "AIzaSyAEONm3sxSfmq0Htcz6tFAMh-NZFEkhUgI",
  authDomain: "maratech-impact.firebaseapp.com",
  projectId: "maratech-impact",
  storageBucket: "maratech-impact.firebasestorage.app",
  messagingSenderId: "123219147492",
  appId: "1:123219147492:web:76e548b5bb29d38ff28af1",
  measurementId: "G-W318R1PSDY",
};

const app = initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);
