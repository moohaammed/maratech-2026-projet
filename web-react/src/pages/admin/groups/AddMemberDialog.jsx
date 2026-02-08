import { useState, useEffect } from 'react';
import { UserService, UserRole } from '../../../core/services/UserService';
import { GroupService } from '../../../core/services/GroupService';
import { appColors } from '../../../core/theme/appColors';

export default function AddMemberDialog({ group, onClose, onAdded }) {
    const [search, setSearch] = useState('');
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [addingMap, setAddingMap] = useState({}); // Track adding state per user

    useEffect(() => {
        fetchUsers();
    }, []);

    const fetchUsers = async () => {
        try {
            // Fetch all users
            // Optimally, we'd query for users without a group, but for now fetch all and filter client-side 
            // to match the Flutter logic and keep it simple
            const allUsers = await UserService.getAllUsers();

            // Filter: 
            // 1. Role is member
            // 2. Not already in THIS group (assignedGroupId !== group.id)
            // Note: Users in OTHER groups are shown with a label, based on Flutter code
            const eligible = allUsers.filter(u => u.role === UserRole.MEMBER && u.assignedGroupId !== group.id);
            setUsers(eligible);
        } catch (error) {
            console.error("Error fetching users:", error);
        } finally {
            setLoading(false);
        }
    };

    const handleAdd = async (user) => {
        setAddingMap(prev => ({ ...prev, [user.id]: true }));
        try {
            await GroupService.addMemberToGroup(group.id, user.id);
            onAdded?.();
            onClose(); // Close after adding one? Flutter code pops, so yes.
        } catch (error) {
            console.error("Error adding member:", error);
            alert("Erreur lors de l'ajout");
            setAddingMap(prev => ({ ...prev, [user.id]: false }));
        }
    };

    const filteredUsers = users.filter(u =>
        u.fullName.toLowerCase().includes(search.toLowerCase()) ||
        (u.email && u.email.toLowerCase().includes(search.toLowerCase()))
    );

    return (
        <div style={{
            position: 'fixed',
            top: 0, left: 0, right: 0, bottom: 0,
            backgroundColor: 'rgba(0,0,0,0.5)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            zIndex: 1000
        }}>
            <div style={{
                backgroundColor: 'white',
                borderRadius: '16px',
                padding: '24px',
                width: '100%',
                maxWidth: '450px',
                height: '80vh',
                display: 'flex',
                flexDirection: 'column',
                boxShadow: '0 4px 20px rgba(0,0,0,0.15)'
            }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                    <h3 style={{ margin: 0 }}>Ajouter un Membre</h3>
                    <button onClick={onClose} style={{ background: 'none', border: 'none', fontSize: '24px', cursor: 'pointer' }}>×</button>
                </div>

                <div style={{ marginBottom: '16px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', border: '1px solid #ddd', borderRadius: '8px', padding: '8px 12px' }}>
                        <span style={{ marginRight: '8px' }}>🔍</span>
                        <input
                            type="text"
                            value={search}
                            onChange={(e) => setSearch(e.target.value)}
                            placeholder="Rechercher par nom ou email"
                            style={{ border: 'none', outline: 'none', width: '100%', fontSize: '16px' }}
                            autoFocus
                        />
                    </div>
                </div>

                <div style={{ flex: 1, overflowY: 'auto' }}>
                    {loading ? (
                        <div style={{ textAlign: 'center', padding: '20px' }}>Chargement...</div>
                    ) : filteredUsers.length === 0 ? (
                        <div style={{ textAlign: 'center', padding: '20px', color: '#888' }}>Aucun adhérent trouvé.</div>
                    ) : (
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                            {filteredUsers.map(user => (
                                <div key={user.id} style={{
                                    display: 'flex',
                                    alignItems: 'center',
                                    padding: '12px',
                                    border: '1px solid #eee',
                                    borderRadius: '12px',
                                    backgroundColor: user.assignedGroupId ? '#fff8e1' : 'white' // Highlight if already in another group
                                }}>
                                    <div style={{
                                        width: '40px', height: '40px',
                                        borderRadius: '50%',
                                        backgroundColor: `${appColors.primary}20`,
                                        color: appColors.primary,
                                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                                        fontWeight: 'bold',
                                        marginRight: '12px'
                                    }}>
                                        {user.fullName ? user.fullName[0].toUpperCase() : '?'}
                                    </div>
                                    <div style={{ flex: 1 }}>
                                        <div style={{ fontWeight: 'bold' }}>{user.fullName}</div>
                                        <div style={{ fontSize: '12px', color: '#666' }}>
                                            {user.assignedGroupId ? 'Déjà dans un autre groupe' : 'Sans groupe'}
                                        </div>
                                    </div>
                                    <button
                                        onClick={() => handleAdd(user)}
                                        disabled={addingMap[user.id]}
                                        style={{
                                            background: 'none',
                                            border: 'none',
                                            cursor: 'pointer',
                                            color: appColors.primary,
                                            padding: '8px'
                                        }}
                                        title="Ajouter"
                                    >
                                        {addingMap[user.id] ? '...' : <span style={{ fontSize: '24px' }}>➕</span>}
                                    </button>
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}
