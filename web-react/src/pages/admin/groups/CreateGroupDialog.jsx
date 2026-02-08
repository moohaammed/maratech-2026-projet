import { useState } from 'react';
import { GroupService, GroupLevel } from '../../../core/services/GroupService';
import { appColors } from '../../../core/theme/appColors';

export default function CreateGroupDialog({ adminId, onClose, onCreated }) {
    const [name, setName] = useState('');
    const [level, setLevel] = useState(GroupLevel.BEGINNER);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!name.trim()) return;

        setLoading(true);
        setError('');

        try {
            await GroupService.createGroup(name.trim(), level, adminId);
            onCreated?.();
            onClose();
        } catch (err) {
            console.error(err);
            setError('Erreur lors de la création du groupe.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div style={{
            position: 'fixed',
            top: 0, left: 0, right: 0, bottom: 0,
            backgroundColor: 'rgba(0,0,0,0.5)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            zIndex: 1000,
            padding: '20px'
        }}>
            <div style={{
                backgroundColor: 'white',
                borderRadius: '20px',
                width: '100%',
                maxWidth: '400px',
                overflow: 'hidden',
                boxShadow: '0 10px 40px rgba(0,0,0,0.2)'
            }}>
                <div style={{
                    backgroundColor: appColors.primary,
                    color: 'white',
                    padding: '20px',
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center'
                }}>
                    <h2 style={{ margin: 0, fontSize: '18px' }}>Nouveau Groupe</h2>
                    <button onClick={onClose} style={{ background: 'none', border: 'none', color: 'white', fontSize: '24px', cursor: 'pointer' }}>×</button>
                </div>

                <form onSubmit={handleSubmit} style={{ padding: '24px', display: 'flex', flexDirection: 'column', gap: '20px' }}>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                        <label style={{ fontSize: '12px', fontWeight: 'bold', color: '#666', textTransform: 'uppercase' }}>Nom du Groupe</label>
                        <input
                            type="text"
                            value={name}
                            onChange={(e) => setName(e.target.value)}
                            placeholder="ex: Les Gazelles, Groupe Matinal..."
                            required
                            autoFocus
                            style={{
                                padding: '12px',
                                borderRadius: '10px',
                                border: '1px solid #ddd',
                                fontSize: '16px',
                                outline: 'none'
                            }}
                        />
                    </div>

                    <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                        <label style={{ fontSize: '12px', fontWeight: 'bold', color: '#666', textTransform: 'uppercase' }}>Niveau de Course</label>
                        <select
                            value={level}
                            onChange={(e) => setLevel(e.target.value)}
                            style={{
                                padding: '12px',
                                borderRadius: '10px',
                                border: '1px solid #ddd',
                                fontSize: '16px',
                                outline: 'none',
                                backgroundColor: '#fcfcfc'
                            }}
                        >
                            <option value={GroupLevel.BEGINNER}>Débutant 🐢</option>
                            <option value={GroupLevel.INTERMEDIATE}>Intermédiaire 🏃</option>
                            <option value={GroupLevel.ADVANCED}>Avancé ⚡</option>
                        </select>
                    </div>

                    {error && <div style={{ color: '#d32f2f', fontSize: '14px', textAlign: 'center' }}>{error}</div>}

                    <div style={{ display: 'flex', gap: '12px', marginTop: '10px' }}>
                        <button
                            type="button"
                            onClick={onClose}
                            style={{
                                flex: 1,
                                padding: '12px',
                                borderRadius: '10px',
                                border: 'None',
                                backgroundColor: '#f5f5f5',
                                color: '#666',
                                fontWeight: 'bold',
                                cursor: 'pointer'
                            }}
                        >
                            Annuler
                        </button>
                        <button
                            type="submit"
                            disabled={loading}
                            style={{
                                flex: 2,
                                padding: '12px',
                                borderRadius: '10px',
                                border: 'none',
                                backgroundColor: appColors.primary,
                                color: 'white',
                                fontWeight: 'bold',
                                cursor: 'pointer',
                                opacity: loading ? 0.7 : 1
                            }}
                        >
                            {loading ? 'Création...' : 'Créer le groupe'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}
