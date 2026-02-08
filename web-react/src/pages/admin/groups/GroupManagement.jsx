import { useState, useEffect } from 'react';
import { GroupService, GroupLevel } from '../../../core/services/GroupService';
import { appColors } from '../../../core/theme/appColors';
import AddMemberDialog from './AddMemberDialog';

export default function GroupManagement({ adminId, currentUser }) {
    const [groups, setGroups] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showAddMemberDialog, setShowAddMemberDialog] = useState(false);
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
                // Determine memberIds either from group object or by fetching
                // Flutter code used group.memberIds. Our service expects it.
                // If memberIds is missing, we might need to fetch members first, but let's assume it's there or empty
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
        <div style={{ padding: '16px', maxWidth: '800px', margin: '0 auto', width: '100%' }}>

            {/* Header */}
            <div style={{ marginBottom: '24px' }}>
                <h2 style={{ margin: 0, color: appColors.textPrimary }}>Gestion des Groupes</h2>
            </div>

            {loading ? (
                <div style={{ textAlign: 'center', padding: '40px' }}>Chargement...</div>
            ) : groups.length === 0 ? (
                <div style={{ textAlign: 'center', color: '#888', marginTop: '40px' }}>
                    Aucun groupe créé pour le moment.
                </div>
            ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '16px', paddingBottom: '80px' }}>
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

            {showAddMemberDialog && selectedGroup && (
                <AddMemberDialog
                    group={selectedGroup}
                    onClose={() => {
                        setShowAddMemberDialog(false);
                        setSelectedGroup(null);
                    }}
                    onAdded={() => {/* Stream updates automatically */ }}
                />
            )}
        </div>
    );
}

function GroupCard({ group, onDelete, onAddMember }) {
    const [expanded, setExpanded] = useState(false);
    const [members, setMembers] = useState([]);
    const [loadingMembers, setLoadingMembers] = useState(false);

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

    return (
        <div style={{
            backgroundColor: 'white',
            borderRadius: '16px',
            boxShadow: '0 2px 8px rgba(0,0,0,0.08)',
            overflow: 'hidden'
        }}>
            {/* Header (Always Visible) */}
            <div
                onClick={() => setExpanded(!expanded)}
                style={{
                    padding: '16px',
                    cursor: 'pointer',
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    backgroundColor: expanded ? '#f9f9f9' : 'white'
                }}
            >
                <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '4px' }}>
                        <h3 style={{ margin: 0, fontSize: '18px' }}>{group.name}</h3>
                        <LevelBadge level={group.level} />
                    </div>
                    <div style={{ color: appColors.textSecondary, fontSize: '14px' }}>
                        {group.memberIds?.length || 0} membres
                    </div>
                </div>
                <div style={{ transform: expanded ? 'rotate(180deg)' : 'rotate(0deg)', transition: 'transform 0.3s' }}>
                    ▼
                </div>
            </div>

            {/* Expanded Content */}
            {expanded && (
                <div style={{ borderTop: '1px solid #eee' }}>
                    {loadingMembers ? (
                        <div style={{ padding: '20px', textAlign: 'center' }}>Chargement des membres...</div>
                    ) : (
                        <div style={{ padding: '0' }}>
                            {members.length === 0 ? (
                                <div style={{ padding: '16px', textAlign: 'center', color: '#888', fontStyle: 'italic' }}>
                                    Aucun membre dans ce groupe.
                                </div>
                            ) : (
                                members.map(member => (
                                    <div key={member.id} style={{
                                        padding: '12px 16px',
                                        display: 'flex',
                                        alignItems: 'center',
                                        borderBottom: '1px solid #f0f0f0'
                                    }}>
                                        <div style={{
                                            width: '32px', height: '32px',
                                            borderRadius: '50%',
                                            backgroundColor: `${appColors.primary}15`,
                                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                                            marginRight: '12px',
                                            fontWeight: 'bold',
                                            color: appColors.primary
                                        }}>
                                            {member.fullName ? member.fullName[0] : '?'}
                                        </div>
                                        <div style={{ flex: 1 }}>
                                            <div style={{ fontWeight: 500 }}>{member.fullName}</div>
                                            <div style={{ fontSize: '12px', color: '#888' }}>{member.email}</div>
                                        </div>
                                        <button
                                            onClick={(e) => {
                                                e.stopPropagation();
                                                if (window.confirm(`Retirer ${member.fullName} du groupe ?`)) {
                                                    GroupService.removeMemberFromGroup(group.id, member.id);
                                                }
                                            }}
                                            style={{
                                                background: 'none', border: 'none', cursor: 'pointer',
                                                color: '#d32f2f', fontSize: '20px'
                                            }}
                                            title="Retirer"
                                        >
                                            ⛔
                                        </button>
                                    </div>
                                ))
                            )}

                            {/* Actions Footer */}
                            <div style={{ padding: '16px', display: 'flex', justifyContent: 'space-between', backgroundColor: '#fafafa' }}>
                                <button
                                    onClick={(e) => {
                                        e.stopPropagation();
                                        onDelete();
                                    }}
                                    style={{
                                        color: '#d32f2f',
                                        background: 'none',
                                        border: 'none',
                                        cursor: 'pointer',
                                        display: 'flex', alignItems: 'center', gap: '8px',
                                        fontWeight: 500
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
                                        backgroundColor: `${appColors.primary}15`,
                                        color: appColors.primary,
                                        border: 'none',
                                        borderRadius: '8px',
                                        padding: '8px 16px',
                                        cursor: 'pointer',
                                        display: 'flex', alignItems: 'center', gap: '8px',
                                        fontWeight: 'bold'
                                    }}
                                >
                                    👤+ Ajouter un membre
                                </button>
                            </div>
                        </div>
                    )}
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
            padding: '2px 8px',
            borderRadius: '4px',
            fontSize: '12px',
            fontWeight: 'bold',
            textTransform: 'uppercase'
        }}>
            {label}
        </span>
    );
}
