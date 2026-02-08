import { useState, useEffect, useMemo } from 'react';
import { auth } from '../../../lib/firebase';
import { GroupService, GroupLevel } from '../../../core/services/GroupService';
import { UserService, UserRole } from '../../../core/services/UserService';
import { appColors } from '../../../core/theme/appColors';
import GroupManagement from './GroupManagement';
import { useNavigate } from 'react-router-dom';
import './GroupAdminDashboard.css';

export default function GroupAdminDashboard({ currentUser }) {
    const navigate = useNavigate();
    const authUser = auth.currentUser;

    const adminId = useMemo(() => {
        return currentUser?.docId || currentUser?.uid || authUser?.uid || null;
    }, [currentUser?.docId, currentUser?.uid, authUser?.uid]);

    const handleSignOut = async () => {
        await auth.signOut();
        navigate('/');
    };

    return (
        <div className="group-admin-layout">
            {/* Standardized App Bar */}
            <header className="app-bar">
                <div className="app-bar-content">
                    <h1 className="app-bar-title">Responsable de Groupe</h1>
                    <div className="app-bar-actions">
                        <button className="icon-button-light" onClick={handleSignOut} title="Déconnexion">
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
                                <polyline points="16 17 21 12 16 7" />
                                <line x1="21" y1="12" x2="9" y2="12" />
                            </svg>
                        </button>
                    </div>
                </div>
            </header>

            {/* Main Content Area */}
            <main className="group-admin-content-container">
                <GroupManagement adminId={adminId} currentUser={currentUser} />
            </main>
        </div>
    );
}
