import { useState, useEffect } from 'react';
import { UserService, UserRole } from '../../core/services/UserService';
import UserDialog from './UserDialog';

export default function AdminManagement() {
    const [admins, setAdmins] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [showDialog, setShowDialog] = useState(false);
    const [selectedAdmin, setSelectedAdmin] = useState(null);

    useEffect(() => {
        fetchAdmins();
    }, []);

    const fetchAdmins = async () => {
        setLoading(true);
        setError('');
        try {
            const allUsers = await UserService.getAllUsers();
            // Filter only admins
            const filtered = allUsers.filter(u =>
                u.role === UserRole.MAIN_ADMIN ||
                u.role === UserRole.COACH_ADMIN ||
                u.role === UserRole.GROUP_ADMIN
            );
            setAdmins(filtered);
        } catch (error) {
            console.error("Error fetching admins:", error);
            setError("Impossible de charger les administrateurs. Vérifiez la connexion et les règles Firestore.");
        } finally {
            setLoading(false);
        }
    };

    const handleEdit = (admin) => {
        setSelectedAdmin(admin);
        setShowDialog(true);
    };

    const handleDelete = async (admin) => {
        if (window.confirm(`Voulez-vous vraiment supprimer l'admin ${admin.fullName} ?`)) {
            await UserService.deleteUser(admin.id);
            fetchAdmins();
        }
    };

    const getRoleLabel = (role) => {
        switch (role) {
            case UserRole.MAIN_ADMIN: return 'Admin Principal';
            case UserRole.COACH_ADMIN: return 'Admin Coach';
            case UserRole.GROUP_ADMIN: return 'Admin Groupe';
            default: return 'Admin';
        }
    };

    const getRoleColor = (role) => {
        switch (role) {
            case UserRole.MAIN_ADMIN: return '#D32F2F'; // Red
            case UserRole.COACH_ADMIN: return '#E53935'; // Primary Red
            case UserRole.GROUP_ADMIN: return '#1976D2'; // Blue
            default: return '#757575';
        }
    };

    return (
        <div style={{ paddingTop: 12 }}>
            {loading ? (
                <div style={{ textAlign: 'center', padding: 40, color: '#666' }}>Chargement...</div>
            ) : error ? (
                <div style={{ textAlign: 'center', color: '#c62828', padding: 40 }}>{error}</div>
            ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                    {admins.length === 0 ? (
                        <div style={{ textAlign: 'center', color: '#888', padding: 40 }}>
                            Aucun administrateur trouvé
                        </div>
                    ) : (
                        admins.map(admin => (
                            <div
                                key={admin.id}
                                style={{
                                    background: 'white',
                                    padding: '12px 16px',
                                    borderRadius: 12,
                                    border: '1px solid #E0E0E0',
                                    display: 'flex',
                                    alignItems: 'center',
                                    gap: 16,
                                    boxShadow: '0 1px 2px rgba(0,0,0,0.05)'
                                }}
                            >
                                <div
                                    style={{
                                        width: 40,
                                        height: 40,
                                        borderRadius: '50%',
                                        backgroundColor: `${getRoleColor(admin.role)}1A`,
                                        color: getRoleColor(admin.role),
                                        display: 'flex',
                                        alignItems: 'center',
                                        justifyContent: 'center',
                                    }}
                                >
                                    <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                                        <path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4zm0 10.99h7c-.53 4.12-3.28 7.79-7 8.94V12H5V6.3l7-3.11v8.8z" />
                                    </svg>
                                </div>

                                <div style={{ flex: 1 }}>
                                    <div style={{ fontWeight: '700', fontSize: 16, color: '#333' }}>
                                        {admin.fullName}
                                    </div>
                                    <div style={{ fontSize: 13, color: '#666', marginTop: 2 }}>
                                        {getRoleLabel(admin.role)}
                                    </div>
                                </div>

                                <div style={{ display: 'flex' }}>
                                    <button
                                        onClick={() => handleEdit(admin)}
                                        style={{
                                            background: 'none',
                                            border: 'none',
                                            cursor: 'pointer',
                                            padding: 8,
                                            color: '#757575'
                                        }}
                                        title="Modifier"
                                    >
                                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                            <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
                                            <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
                                        </svg>
                                    </button>
                                    <button
                                        onClick={() => handleDelete(admin)}
                                        style={{
                                            background: 'none',
                                            border: 'none',
                                            cursor: 'pointer',
                                            padding: 8,
                                            color: '#D32F2F'
                                        }}
                                        title="Supprimer"
                                    >
                                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                            <polyline points="3 6 5 6 21 6" />
                                            <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
                                            <line x1="10" y1="11" x2="10" y2="17" />
                                            <line x1="14" y1="11" x2="14" y2="17" />
                                        </svg>
                                    </button>
                                </div>
                            </div>
                        ))
                    )}
                </div>
            )}

            {/* FAB for Add Admin */}
            <button
                onClick={() => { setSelectedAdmin(null); setShowDialog(true); }}
                style={{
                    position: 'fixed',
                    bottom: 24,
                    right: 24,
                    width: 56,
                    height: 56,
                    borderRadius: '50%',
                    backgroundColor: '#E53935',
                    color: 'white',
                    border: 'none',
                    boxShadow: '0 4px 12px rgba(229, 57, 53, 0.4)',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    zIndex: 100
                }}
                title="Ajouter Administrateur"
            >
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <line x1="12" y1="5" x2="12" y2="19"></line>
                    <line x1="5" y1="12" x2="19" y2="12"></line>
                </svg>
            </button>

            {showDialog && (
                <UserDialog
                    user={selectedAdmin}
                    isAdminMode={true}
                    onClose={() => setShowDialog(false)}
                    onSave={fetchAdmins}
                />
            )}
        </div>
    );
}

