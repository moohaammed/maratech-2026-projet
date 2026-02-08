import { useState, useEffect } from 'react';
import { GroupService, GroupLevel } from '../../../core/services/GroupService';
import { appColors } from '../../../core/theme/appColors';
import AddMemberDialog from './AddMemberDialog';
import CreateGroupDialog from './CreateGroupDialog';

export default function GroupManagement({ adminId, currentUser }) {
    const [groups, setGroups] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showAddMemberDialog, setShowAddMemberDialog] = useState(false);
    const [showCreateDialog, setShowCreateDialog] = useState(false);
    const [selectedGroup, setSelectedGroup] = useState(null);

    useEffect(() => {
        // Stream groups
        const unsubscribe = adminId
            ? GroupService.getGroupsByAdminStream(adminId, (data) => {
                setGroups(data);
                setLoading(false);
            })
            : GroupService.getGroupsStream((data) => {
                setGroups(data);
                setLoading(false);
            });

        return () => unsubscribe();
    }, [adminId]);

    const handleDeleteGroup = async (group) => {
        if (window.confirm(`Voulez-vous vraiment supprimer le groupe "${group.name}" ? Les membres seront retirés du groupe.`)) {
            try {
                await GroupService.deleteGroup(group.id, group.memberIds || []);
            } catch (error) {
                console.error("Error deleting group:", error);
                alert("Erreur lors de la suppression");
            }
        }
    };

    const handleAddMemberClick = (group) => {
        setSelectedGroup(group);
        setShowAddMemberDialog(true);
    };

    return (
        <div style={{ padding: '24px', maxWidth: '900px', margin: '0 auto', width: '100%', boxSizing: 'border-box' }}>

            {/* Header Section */}
            <div style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                marginBottom: '32px',
                flexWrap: 'wrap',
                gap: '16px'
            }}>
                <div>
                    <h2 style={{ margin: 0, color: appColors.textPrimary, fontSize: '24px', fontWeight: '800' }}>Gestion des Groupes</h2>
                    <p style={{ margin: '4px 0 0 0', color: appColors.textSecondary, fontSize: '14px' }}>
                        Gérez vos équipes et suivez les membres en temps réel.
                    </p>
                </div>
                <button
                    onClick={() => setShowCreateDialog(true)}
                    style={{
                        backgroundColor: appColors.primary,
                        color: 'white',
                        border: 'none',
                        borderRadius: '12px',
                        padding: '12px 20px',
                        fontSize: '15px',
                        fontWeight: 'bold',
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '8px',
                        boxShadow: `0 4px 12px ${appColors.primary}4D`,
                        transition: 'all 0.2s ease'
                    }}
                >
                    <span style={{ fontSize: '20px' }}>+</span>
                    Nouveau Groupe
                </button>
            </div>

            {loading ? (
                <div style={{ textAlign: 'center', padding: '60px', color: '#888' }}>
                    <div className="spinner"></div>
                    <p>Chargement des groupes...</p>
                </div>
            ) : groups.length === 0 ? (
                <div style={{
                    textAlign: 'center',
                    padding: '60px 20px',
                    color: '#888',
                    backgroundColor: 'white',
                    borderRadius: '24px',
                    border: '2px dashed #eee'
                }}>
                    <div style={{ fontSize: '48px', marginBottom: '16px' }}>👥</div>
                    <h3 style={{ margin: 0, color: '#444' }}>Aucun groupe</h3>
                    <p>Commencez par créer votre premier groupe d'entraînement.</p>
                </div>
            ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '20px', paddingBottom: '80px' }}>
                    {groups.map(group => (
                        <GroupCard
                            key={group.id}
                            group={group}
                            onDelete={() => handleDeleteGroup(group)}
                            onAddMember={() => handleAddMemberClick(group)}
                        />
                    ))}
                </div>
            )}

            {showCreateDialog && (
                <CreateGroupDialog
                    adminId={adminId}
                    onClose={() => setShowCreateDialog(false)}
                />
            )}

            {showAddMemberDialog && selectedGroup && (
                <AddMemberDialog
                    group={selectedGroup}
                    onClose={() => {
                        setShowAddMemberDialog(false);
                        setSelectedGroup(null);
                    }}
                />
            )}
        </div>
    );
}

function GroupCard({ group, onDelete, onAddMember }) {
    const [expanded, setExpanded] = useState(false);
    const [members, setMembers] = useState([]);
    const [loadingMembers, setLoadingMembers] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');

    useEffect(() => {
        if (expanded) {
            setLoadingMembers(true);
            const unsubscribe = GroupService.getGroupMembersStream(group.id, (data) => {
                setMembers(data);
                setLoadingMembers(false);
            });
            return () => unsubscribe();
        }
    }, [expanded, group.id]);

    const filteredMembers = members.filter(m =>
        m.fullName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        m.email.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <div style={{
            backgroundColor: 'white',
            borderRadius: '24px',
            boxShadow: expanded ? '0 12px 30px rgba(0,0,0,0.1)' : '0 4px 12px rgba(0,0,0,0.05)',
            overflow: 'hidden',
            transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
            border: expanded ? `1px solid ${appColors.primary}33` : '1px solid #f0f0f0',
            transform: expanded ? 'translateY(-2px)' : 'translateY(0)'
        }}>
            {/* Header Area */}
            <div
                onClick={() => setExpanded(!expanded)}
                style={{
                    padding: '20px 24px',
                    cursor: 'pointer',
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    backgroundColor: expanded ? '#fafafa' : 'white'
                }}
            >
                <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
                    <div style={{
                        width: '48px',
                        height: '48px',
                        borderRadius: '14px',
                        backgroundColor: `${appColors.primary}10`,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontSize: '24px'
                    }}>
                        {group.level === GroupLevel.ADVANCED ? '⚡' : group.level === GroupLevel.INTERMEDIATE ? '🏃' : '🐢'}
                    </div>
                    <div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '4px' }}>
                            <h3 style={{ margin: 0, fontSize: '18px', fontWeight: '700', color: appColors.textPrimary }}>{group.name}</h3>
                            <LevelBadge level={group.level} />
                        </div>
                        <div style={{ color: appColors.textSecondary, fontSize: '14px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                            <span style={{ display: 'inline-block', width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#4CAF50' }}></span>
                            {members.length > 0 ? members.length : (group.memberIds?.length || 0)} membre(s)
                        </div>
                    </div>
                </div>
                <div style={{
                    width: '32px',
                    height: '32px',
                    borderRadius: '50%',
                    backgroundColor: expanded ? appColors.primary : '#f5f5f5',
                    color: expanded ? 'white' : '#999',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    transform: expanded ? 'rotate(180deg)' : 'rotate(0deg)',
                    transition: 'all 0.3s ease'
                }}>
                    ▼
                </div>
            </div>

            {/* Expanded Content */}
            {expanded && (
                <div style={{ backgroundColor: 'white' }}>
                    {/* Search Bar within Group */}
                    <div style={{ padding: '0 24px 16px 24px' }}>
                        <div style={{
                            display: 'flex',
                            alignItems: 'center',
                            backgroundColor: '#f8f9fa',
                            borderRadius: '12px',
                            padding: '8px 16px',
                            border: '1px solid #eee'
                        }}>
                            <span style={{ marginRight: '10px', opacity: 0.5 }}>🔍</span>
                            <input
                                type="text"
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                                onClick={(e) => e.stopPropagation()}
                                placeholder="Rechercher un membre dans ce groupe..."
                                style={{
                                    border: 'none',
                                    background: 'none',
                                    outline: 'none',
                                    width: '100%',
                                    fontSize: '14px',
                                    color: '#444'
                                }}
                            />
                        </div>
                    </div>

                    <div style={{ maxHeight: '400px', overflowY: 'auto' }}>
                        {loadingMembers ? (
                            <div style={{ padding: '40px', textAlign: 'center', color: '#888' }}>
                                <div className="spinner-small"></div>
                                <p style={{ marginTop: '12px' }}>Récupération des membres...</p>
                            </div>
                        ) : (
                            <div>
                                {filteredMembers.length === 0 ? (
                                    <div style={{ padding: '40px 24px', textAlign: 'center', color: '#999' }}>
                                        {searchTerm ? 'Aucun membre ne correspond à votre recherche.' : 'Ce groupe est vide.'}
                                    </div>
                                ) : (
                                    filteredMembers.map((member, index) => (
                                        <div key={member.id} style={{
                                            padding: '16px 24px',
                                            display: 'flex',
                                            alignItems: 'center',
                                            borderBottom: index === filteredMembers.length - 1 ? 'none' : '1px solid #f8f9fa',
                                            transition: 'background-color 0.2s',
                                            cursor: 'default'
                                        }}>
                                            <div style={{
                                                width: '44px', height: '44px',
                                                borderRadius: '12px',
                                                backgroundColor: `${appColors.primary}${index % 2 === 0 ? '15' : '10'}`,
                                                display: 'flex', alignItems: 'center', justifyContent: 'center',
                                                marginRight: '16px',
                                                fontWeight: '700',
                                                color: appColors.primary,
                                                fontSize: '16px'
                                            }}>
                                                {member.fullName ? member.fullName[0].toUpperCase() : '?'}
                                            </div>
                                            <div style={{ flex: 1 }}>
                                                <div style={{ fontWeight: 600, color: '#333', fontSize: '15px' }}>{member.fullName}</div>
                                                <div style={{ fontSize: '13px', color: '#999' }}>{member.email}</div>
                                            </div>
                                            <button
                                                onClick={(e) => {
                                                    e.stopPropagation();
                                                    if (window.confirm(`Retirer ${member.fullName} du groupe ?`)) {
                                                        GroupService.removeMemberFromGroup(group.id, member.id);
                                                    }
                                                }}
                                                style={{
                                                    width: '36px', height: '36px',
                                                    borderRadius: '10px',
                                                    backgroundColor: '#FFF5F5',
                                                    border: 'none', cursor: 'pointer',
                                                    color: '#FF5252',
                                                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                                                    transition: 'all 0.2s'
                                                }}
                                                title="Retirer"
                                                className="hover-danger"
                                            >
                                                ✕
                                            </button>
                                        </div>
                                    ))
                                )}
                            </div>
                        )}
                    </div>

                    {/* Actions Footer */}
                    <div style={{
                        padding: '20px 24px',
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                        backgroundColor: '#fafafa',
                        borderTop: '1px solid #f0f0f0'
                    }}>
                        <button
                            onClick={(e) => {
                                e.stopPropagation();
                                onDelete();
                            }}
                            style={{
                                color: '#FF5252',
                                background: 'none',
                                border: 'none',
                                cursor: 'pointer',
                                display: 'flex', alignItems: 'center', gap: '6px',
                                fontWeight: '600',
                                fontSize: '14px',
                                padding: '8px 0'
                            }}
                        >
                            🗑️ Supprimer le groupe
                        </button>

                        <button
                            onClick={(e) => {
                                e.stopPropagation();
                                onAddMember();
                            }}
                            style={{
                                backgroundColor: appColors.primary,
                                color: 'white',
                                border: 'none',
                                borderRadius: '10px',
                                padding: '10px 18px',
                                cursor: 'pointer',
                                display: 'flex', alignItems: 'center', gap: '8px',
                                fontWeight: 'bold',
                                fontSize: '14px',
                                boxShadow: `0 4px 10px ${appColors.primary}33`
                            }}
                        >
                            👤+ Ajouter
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
}

function LevelBadge({ level }) {
    let color = '#757575';
    let label = 'Inconnu';
    let bg = '#eeeeee';

    switch (level) {
        case GroupLevel.BEGINNER:
            color = '#2e7d32'; // Green
            label = 'Débutant';
            bg = '#e8f5e9';
            break;
        case GroupLevel.INTERMEDIATE:
            color = '#ef6c00'; // Orange
            label = 'Intermédiaire';
            bg = '#fff3e0';
            break;
        case GroupLevel.ADVANCED:
            color = '#c62828'; // Red
            label = 'Avancé';
            bg = '#ffebee';
            break;
        default:
            break;
    }

    return (
        <span style={{
            backgroundColor: bg,
            color: color,
            padding: '4px 10px',
            borderRadius: '8px',
            fontSize: '11px',
            fontWeight: '800',
            textTransform: 'uppercase',
            letterSpacing: '0.5px'
        }}>
            {label}
        </span>
    );
}
