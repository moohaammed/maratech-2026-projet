import { useState, useEffect } from 'react';
import { signOut } from 'firebase/auth';
import { auth } from '../../lib/firebase';
import { UserService } from '../../core/services/UserService';
import UserManagement from './UserManagement';
import AdminManagement from './AdminManagement';
import './AdminDashboard.css';

export default function AdminDashboard() {
    const [activeTab, setActiveTab] = useState(0);
    const [stats, setStats] = useState({ total: 0, active: 0, admins: 0 });
    const [loadingStats, setLoadingStats] = useState(true);
    const [currentUser, setCurrentUser] = useState(null);
    const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

    useEffect(() => {
        fetchCurrentUser();
        fetchStats();
        const interval = setInterval(fetchStats, 30000);
        return () => clearInterval(interval);
    }, []);

    const fetchCurrentUser = async () => {
        try {
            const firebaseUser = auth.currentUser;
            if (firebaseUser) {
                const userModel = await UserService.getUserById(firebaseUser.uid);
                setCurrentUser(userModel);
            }
        } catch (error) {
            console.error("Error fetching current user:", error);
        }
    };

    const fetchStats = async () => {
        try {
            const data = await UserService.getUserStatistics();
            setStats({
                total: data.members + data.visitors,   // users without admins
                active: data.active,
                admins: data.mainAdmins + data.coachAdmins + data.groupAdmins
            });
        } catch (error) {
            console.error("Error fetching stats:", error);
        } finally {
            setLoadingStats(false);
        }
    };

    const handleLogout = async () => {
        await signOut(auth);
    };

    const toggleMobileMenu = () => {
        setIsMobileMenuOpen(!isMobileMenuOpen);
    };

    // Close mobile menu when tab changes
    const handleTabChange = (tabIndex) => {
        setActiveTab(tabIndex);
        setIsMobileMenuOpen(false);
    };

    return (
        <div className="admin-layout">
            {/* App Bar */}
            <header className="app-bar">
                <div className="app-bar-content">
                    <h1 className="app-bar-title">Admin Dashboard</h1>
                    <div className="app-bar-actions">
                        <button className="icon-button-light" title="Notifications">
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
                                <path d="M13.73 21a2 2 0 0 1-3.46 0" />
                            </svg>
                        </button>
                        <button onClick={handleLogout} className="icon-button-light" title="Déconnexion">
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
                                <polyline points="16 17 21 12 16 7" />
                                <line x1="21" y1="12" x2="9" y2="12" />
                            </svg>
                        </button>
                    </div>
                </div>

                {/* Tabs */}
                <div className="app-bar-tabs">
                    <button
                        className={`tab-item ${activeTab === 0 ? 'active' : ''}`}
                        onClick={() => setActiveTab(0)}
                    >
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" style={{ marginRight: 8 }}>
                            <path d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z" />
                        </svg>
                        Utilisateurs
                    </button>
                    <button
                        className={`tab-item ${activeTab === 1 ? 'active' : ''}`}
                        onClick={() => setActiveTab(1)}
                    >
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" style={{ marginRight: 8 }}>
                            <path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4zm0 10.99h7c-.53 4.12-3.28 7.79-7 8.94V12H5V6.3l7-3.11v8.8z" />
                        </svg>
                        Administrateurs
                    </button>
                </div>
            </header>
            <br className="stats-header"></br>
            {/* Statistics Header */}
            <div className="stats-header">
                <div className="stats-grid">
                    <div className="stat-box">
                        <div className="stat-icon-small">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                                <path d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z" />
                            </svg>
                        </div>
                        <div className="stat-content">
                            <span className="stat-value-small">{loadingStats ? '-' : stats.total}</span>
                            <span className="stat-label-small">Total</span>
                        </div>
                    </div>

                    <div className="stat-box">
                        <div className="stat-icon-small">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                                <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z" />
                            </svg>
                        </div>
                        <div className="stat-content">
                            <span className="stat-value-small">{loadingStats ? '-' : stats.active}</span>
                            <span className="stat-label-small">Actifs</span>
                        </div>
                    </div>

                    <div className="stat-box">
                        <div className="stat-icon-small">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                                <path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4zm0 10.99h7c-.53 4.12-3.28 7.79-7 8.94V12H5V6.3l7-3.11v8.8z" />
                            </svg>
                        </div>
                        <div className="stat-content">
                            <span className="stat-value-small">{loadingStats ? '-' : stats.admins}</span>
                            <span className="stat-label-small">Admins</span>
                        </div>
                    </div>
                </div>
            </div>

            {/* Main Content */}
            <main className="content-container">
                {activeTab === 0 && <UserManagement />}
                {activeTab === 1 && <AdminManagement />}
            </main>
        </div>
    );
}
