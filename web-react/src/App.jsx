import { useEffect, useState, useCallback } from "react";
import { onAuthStateChanged } from "firebase/auth";
import { query, where, getDocs, limit } from "firebase/firestore";
import { auth } from "./lib/firebase";
import { AccessibilityProvider, getWizardCompleted } from "./core/services/AccessibilityContext";
import { UserService, UserRole } from "./core/services/UserService";
import { Routes, Route, Navigate, Link, useLocation } from "react-router-dom";
import SplashScreen from "./pages/SplashScreen";
import AccessibilityWizardPage from "./pages/AccessibilityWizardPage";
import LoginScreen from "./pages/LoginScreen";
import HomePage from "./pages/HomePage";
import AdminDashboard from "./pages/admin/AdminDashboard";
import GroupAdminDashboard from "./pages/admin/groups/GroupAdminDashboard";
import CoachDashboard from "./pages/coach/CoachDashboard";
import EventDetailScreen from "./pages/coach/events/EventDetailScreen";
import GuestHomeScreen from "./pages/guest/GuestHomeScreen";
import MemberHomeScreen from './pages/member/MemberHomeScreen';
import NotificationScreen from "./pages/NotificationScreen";
import "./styles/layout.css";

function Navigation({ user, normalizeRole }) {
  const location = useLocation();

  const handleLogout = () => {
    auth.signOut();
  };

  const isRole = (userRole, targetRole) => {
    if (!userRole) return false;
    const normalized = normalizeRole(userRole);
    return normalized === targetRole || normalized === targetRole.replace('UserRole.', '');
  };

  const getUserDisplayName = () => {
    return user.displayName || user.email?.split('@')[0] || 'Utilisateur';
  };

  const getUserRoleLabel = () => {
    if (isRole(user.role, UserRole.MAIN_ADMIN)) return 'Admin Principal';
    if (isRole(user.role, UserRole.COACH_ADMIN)) return 'Admin Coach';
    if (isRole(user.role, UserRole.GROUP_ADMIN)) return 'Admin Groupe';
    if (isRole(user.role, UserRole.MEMBER)) return 'Adhérent';
    if (isRole(user.role, UserRole.VISITOR)) return 'Visiteur';
    return 'Utilisateur';
  };

}

function AppLayout({ children, user, normalizeRole }) {
  const location = useLocation();
  const isCoach =
    user && user.role &&
    (normalizeRole(user.role) === UserRole.COACH_ADMIN ||
      normalizeRole(user.role) === 'UserRole.COACH_ADMIN');
  const hideHeader = isCoach && (location.pathname === '/' || location.pathname === '/coach');
  return (
    <div className="app-layout">
      {!hideHeader && (
        <header className="app-header">
          <div className="app-header-content">
            <Navigation user={user} normalizeRole={normalizeRole} />
          </div>
        </header>
      )}

      <main className="app-main">
        {children}
      </main>

      <footer className="app-footer">
        <p>© 2024 Maratech - Tous droits réservés</p>
      </footer>
    </div>
  );
}

export default function App() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [showSplash, setShowSplash] = useState(true);
  const [showWizard, setShowWizard] = useState(true); // Always show wizard for testing

  const normalizeRole = useCallback((role) => {
    if (!role) return null;
    const r = role.toString();
    if (r.startsWith('UserRole.')) return r;

    const map = {
      groupadmin: UserRole.GROUP_ADMIN,
      group_admin: UserRole.GROUP_ADMIN,
      admin_group: UserRole.GROUP_ADMIN,
      subadmin: UserRole.GROUP_ADMIN,
      sub_admin: UserRole.GROUP_ADMIN,
      coachadmin: UserRole.COACH_ADMIN,
      coach_admin: UserRole.COACH_ADMIN,
      admin_coach: UserRole.COACH_ADMIN,
      mainadmin: UserRole.MAIN_ADMIN,
      main_admin: UserRole.MAIN_ADMIN,
      admin_main: UserRole.MAIN_ADMIN,
      member: UserRole.MEMBER,
      visitor: UserRole.VISITOR,
    };

    const key = r.toLowerCase().replace(/\s+/g, '');
    return map[key] || r;
  }, []);

  useEffect(() => {
    return onAuthStateChanged(auth, async (u) => {
      console.log("Auth state changed:", u ? u.uid : "No user");
      if (u) {
        try {
          // 1. Try lookup by UID (standard)
          let userDoc = await UserService.getUserById(u.uid);

          // 2. Fallback: If UID lookup fails, try matching by email
          if (!userDoc && u.email) {
            console.warn(`User doc not found by UID ${u.uid}, trying email fallback...`);
            const usersRef = UserService.usersCollection;
            const q = query(usersRef, where('email', '==', u.email), limit(1));
            const snapshot = await getDocs(q);
            if (!snapshot.empty) {
              const doc = snapshot.docs[0];
              userDoc = { id: doc.id, ...doc.data() };
              console.log("Matched user by email fallback:", userDoc);
            }
          }

          console.log("Resolved user doc:", userDoc);

          if (userDoc) {
            // Flexible check function to handle formats like 'UserRole.groupAdmin' OR 'groupAdmin'
            const hasRole = (role, target) => {
              if (!role) return false;
              const normalized = normalizeRole(role);
              return normalized === target || normalized === target.replace('UserRole.', '');
            };

            const isAdmin =
              hasRole(userDoc.role, UserRole.MAIN_ADMIN) ||
              hasRole(userDoc.role, UserRole.COACH_ADMIN) ||
              hasRole(userDoc.role, UserRole.GROUP_ADMIN);

            // Clone to ensure new object reference for React
            const enhancedUser = Object.assign(Object.create(Object.getPrototypeOf(u)), u);
            enhancedUser.isAdmin = isAdmin;
            enhancedUser.role = normalizeRole(userDoc.role);
            enhancedUser.docId = userDoc.id; // Store Firestore ID just in case
            enhancedUser.assignedGroup = userDoc.assignedGroup;
            enhancedUser.assignedGroupId = userDoc.assignedGroupId;

            console.log("User Access Level:", { role: enhancedUser.role, isAdmin: enhancedUser.isAdmin });
            setUser(enhancedUser);
          } else {
            console.error("No Firestore document found for user even with email fallback.");
            setUser(u);
          }
        } catch (error) {
          console.error("Error fetching user role:", error);
          setUser(u);
        }
      } else {
        setUser(null);
      }
      setLoading(false);
    });
  }, []);

  useEffect(() => {
    if (user) {
      setTimeout(() => {
        import("./core/services/NotificationService").then(({ NotificationService }) => {
          NotificationService.requestDesktopPermission();
        });
      }, 2000); // Delay slightly to not interrupt splash/wizard
    }
  }, [user]);

  const handleSplashComplete = useCallback(() => setShowSplash(false), []);
  const handleWizardFinish = useCallback(() => setShowWizard(false), []);
  // Separate handler for skip to ensure we don't get stuck if wizard logic changes
  const handleWizardSkip = useCallback(() => setShowWizard(false), []);

  // Helper for flexible role checks in render
  const isRole = (userRole, targetRole) => {
    if (!userRole) return false;
    const normalized = normalizeRole(userRole);
    return normalized === targetRole || normalized === targetRole.replace('UserRole.', '');
  };

  return (
    <AccessibilityProvider>
      {showSplash ? (
        <SplashScreen onComplete={handleSplashComplete} />
      ) : loading ? (
        <div style={{ minHeight: "100vh", display: "grid", placeItems: "center", background: "#F5F5F5" }}>
          <p style={{ padding: 16 }}>Chargement...</p>
        </div>
      ) : showWizard ? (
        <AccessibilityWizardPage onFinish={handleWizardFinish} onSkip={handleWizardSkip} />
      ) : user ? (
        <AppLayout user={user} normalizeRole={normalizeRole}>
          <Routes>
            <Route
              path="/admin/groups"
              element={
                isRole(user.role, UserRole.GROUP_ADMIN) ? (
                  <GroupAdminDashboard currentUser={user} />
                ) : (
                  <Navigate to="/" replace />
                )
              }
            />
            <Route path="/" element={
              isRole(user.role, UserRole.GROUP_ADMIN) ? (
                <GroupAdminDashboard currentUser={user} />
              ) : isRole(user.role, UserRole.COACH_ADMIN) ? (
                <CoachDashboard currentUser={user} />
              ) : user.isAdmin ? (
                <AdminDashboard />
              ) : (
                <MemberHomeScreen user={user} />
              )
            } />
            <Route path="/events/:id" element={<EventDetailScreen />} />
            <Route path="/notifications" element={<NotificationScreen />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </AppLayout>
      ) : (
        <Routes>
          <Route path="/" element={<LoginScreen />} />
          <Route path="/guest" element={<GuestHomeScreen />} />
          <Route path="/events/:id" element={<EventDetailScreen />} />
          <Route path="/notifications" element={<NotificationScreen />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      )}
    </AccessibilityProvider>
  );
}
