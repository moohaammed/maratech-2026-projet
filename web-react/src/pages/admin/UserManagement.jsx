import { useState, useEffect } from 'react';
import { UserService, UserRole } from '../../core/services/UserService';
import UserDialog from './UserDialog';
import './UserManagement.css';

export default function UserManagement() {
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [totalFetched, setTotalFetched] = useState(0);
    const [searchQuery, setSearchQuery] = useState('');
    const [showDialog, setShowDialog] = useState(false);
    const [selectedUser, setSelectedUser] = useState(null);

    useEffect(() => {
        fetchUsers();
        
        // Optional: Set up real-time listener
        const interval = setInterval(fetchUsers, 30000);
        return () => clearInterval(interval);
    }, []);

    const normalizeRole = (role) => {
        if (!role) return null;
        const r = role.toString().trim();
        if (r.startsWith('UserRole.')) return r;
        const key = r.toLowerCase().replace(/[^a-z0-9]+/g, '');
        const map = {
            member: UserRole.MEMBER,
            visitor: UserRole.VISITOR,
            groupadmin: UserRole.GROUP_ADMIN,
            admingroup: UserRole.GROUP_ADMIN,
            subadmin: UserRole.GROUP_ADMIN,
            coachadmin: UserRole.COACH_ADMIN,
            admincoach: UserRole.COACH_ADMIN,
            mainadmin: UserRole.MAIN_ADMIN,
            adminmain: UserRole.MAIN_ADMIN,
        };
        return map[key] || r;
    };

    const fetchUsers = async () => {
        setLoading(true);
        setError('');
        try {
            const allUsers = await UserService.getAllUsers();
            setTotalFetched(allUsers.length);
            const filtered = allUsers.filter(u => {
                const role = normalizeRole(u.role);
                // show everyone except main/coach/group admins
                return ![
                    UserRole.MAIN_ADMIN,
                    UserRole.COACH_ADMIN,
                    UserRole.GROUP_ADMIN
                ].includes(role);
            });
            setUsers(filtered);
        } catch (error) {
            console.error("Error fetching users:", error);
            setError("Impossible de charger les utilisateurs. Vérifiez la connexion et les règles Firestore.");
        } finally {
            setLoading(false);
        }
    };

    const filteredUsers = users.filter(user => {
        const query = searchQuery.toLowerCase();
        return (
            (user.fullName || '').toLowerCase().includes(query) ||
            (user.email || '').toLowerCase().includes(query)
        );
    });

    const handleEdit = (user) => {
        setSelectedUser(user);
        setShowDialog(true);
    };

    const handleDelete = async (user) => {
        if (window.confirm(`Voulez-vous vraiment supprimer ${user.fullName} ?`)) {
            try {
                await UserService.deleteUser(user.id);
                fetchUsers();
            } catch (error) {
                console.error("Error deleting user:", error);
                alert("Erreur lors de la suppression");
            }
        }
    };

    const handleToggleStatus = async (user) => {
        try {
            await UserService.toggleUserStatus(user.id, !user.isActive);
            fetchUsers();
        } catch (error) {
            console.error("Error toggling status:", error);
            alert("Erreur lors du changement de statut");
        }
    };

    const getRoleLabel = (role) => {
        const r = normalizeRole(role);
        if (r === UserRole.MEMBER) return 'Adhérent';
        if (r === UserRole.VISITOR) return 'Visiteur';
        return 'Administrateur';   // fallback for any admin that might still appear
    };

    return (
        <div className="user-management">
            {/* Search Bar & Add Button */}
            <div className="user-management-header">
                <div className="search-container">
                    <svg className="search-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <circle cx="11" cy="11" r="8"/>
                        <path d="m21 21-4.35-4.35"/>
                    </svg>
                    <input
                        type="text"
                        placeholder="Rechercher un utilisateur..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="search-input"
                    />
                    {searchQuery && (
                        <button 
                            className="clear-search"
                            onClick={() => setSearchQuery('')}
                            aria-label="Clear search"
                        >
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                <line x1="18" y1="6" x2="6" y2="18"/>
                                <line x1="6" y1="6" x2="18" y2="18"/>
                            </svg>
                        </button>
                    )}
                </div>
            </div>

            {!loading && !error && (
                <div style={{ fontSize: 12, color: '#777', marginBottom: 12 }}>
                    {`Total: ${totalFetched} · Affichés: ${filteredUsers.length}`}
                </div>
            )}

            {loading ? (
                <div className="loading-container">
                    <div className="spinner"></div>
                    <p>Chargement...</p>
                </div>
            ) : error ? (
                <div className="empty-state" style={{ color: '#c62828' }}>
                    <p>{error}</p>
                </div>
            ) : filteredUsers.length === 0 ? (
                <div className="empty-state">
                    <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                        <circle cx="12" cy="7" r="4"/>
                    </svg>
                    <p>{searchQuery ? 'Aucun utilisateur trouvé' : 'Aucun utilisateur'}</p>
                </div>
            ) : (
                <div className="users-list">
                    {filteredUsers.map(user => (
                        <div key={user.id} className="user-card">
                            <div className="user-avatar">
                                {(user.fullName || '?')[0].toUpperCase()}
                            </div>

                            <div className="user-info">
                                <div className="user-name">{user.fullName}</div>
                                <div className="user-email">{user.email}</div>
                                <div className="user-badges">
                                    <span className="user-role-badge">
                                        {getRoleLabel(user.role)}
                                    </span>
                                    {!user.isActive && (
                                        <span className="user-status-badge inactive">
                                            Inactif
                                        </span>
                                    )}
                                </div>
                            </div>

                            <div className="user-actions">
                                <button
                                    onClick={() => handleEdit(user)}
                                    className="icon-button"
                                    title="Modifier"
                                    aria-label="Modifier"
                                >
                                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                                    </svg>
                                </button>
                                <button
                                    onClick={() => handleToggleStatus(user)}
                                    className="icon-button"
                                    title={user.isActive ? 'Désactiver' : 'Activer'}
                                    aria-label={user.isActive ? 'Désactiver' : 'Activer'}
                                >
                                    {user.isActive ? (
                                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                            <circle cx="12" cy="12" r="10"/>
                                            <line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/>
                                        </svg>
                                    ) : (
                                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
                                            <polyline points="22 4 12 14.01 9 11.01"/>
                                        </svg>
                                    )}
                                </button>
                                <button
                                    onClick={() => handleDelete(user)}
                                    className="icon-button delete-button"
                                    title="Supprimer"
                                    aria-label="Supprimer"
                                >
                                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                        <polyline points="3 6 5 6 21 6"/>
                                        <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
                                        <line x1="10" y1="11" x2="10" y2="17"/>
                                        <line x1="14" y1="11" x2="14" y2="17"/>
                                    </svg>
                                </button>
                            </div>
                        </div>
                    ))}
                </div>
            )}

            {/* Floating Action Button */}
            <button
                onClick={() => { 
                    setSelectedUser(null); 
                    setShowDialog(true); 
                }}
                className="fab"
                title="Ajouter Utilisateur"
                aria-label="Ajouter Utilisateur"
            >
                <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M18 13h-5v5c0 .55-.45 1-1 1s-1-.45-1-1v-5H6c-.55 0-1-.45-1-1s.45-1 1-1h5V6c0-.55.45-1 1-1s1 .45 1 1v5h5c.55 0 1 .45 1 1s-.45 1-1 1z"/>
                </svg>
            </button>

            {showDialog && (
                <UserDialog
                    user={selectedUser}
                    isAdminMode={false}
                    onClose={() => setShowDialog(false)}
                    onSave={fetchUsers}
                />
            )}
        </div>
    );
}
