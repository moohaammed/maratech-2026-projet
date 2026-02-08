import { useState } from 'react';
import { auth } from '../../../lib/firebase';
import { GroupService, GroupLevel } from '../../../core/services/GroupService';

export default function CreateGroupDialog({ currentUser, onClose, onCreated }) {
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
            const adminId = currentUser?.uid || auth.currentUser?.uid || currentUser?.docId;
            await GroupService.createGroup(name, level, adminId);
            onCreated?.();
            onClose();
        } catch (err) {
            console.error(err);
            setError("Erreur lors de la création du groupe");
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="dialog-overlay" onClick={onClose}>
            <div className="dialog-content" onClick={e => e.stopPropagation()}>
                <div className="dialog-header">
                    <h2 className="dialog-title">Créer un Nouveau Groupe</h2>
                    <button 
                        type="button" 
                        className="dialog-close" 
                        onClick={onClose}
                        aria-label="Fermer"
                    >
                        ✕
                    </button>
                </div>

                <div className="dialog-body">
                    {error && (
                        <div className="form-error mb-4">
                            {error}
                        </div>
                    )}

                    <form onSubmit={handleSubmit}>
                        <div className="form-group">
                            <label className="form-label" htmlFor="group-name">
                                Nom du groupe
                            </label>
                            <div className="flex items-center gap-3">
                                <span className="text-xl">👥</span>
                                <input
                                    id="group-name"
                                    type="text"
                                    value={name}
                                    onChange={(e) => setName(e.target.value)}
                                    placeholder="Ex: Groupe A"
                                    className="form-input"
                                    required
                                />
                            </div>
                        </div>

                        <div className="form-group mb-6">
                            <label className="form-label" htmlFor="group-level">
                                Niveau (Level)
                            </label>
                            <div className="flex items-center gap-3">
                                <span className="text-xl">📊</span>
                                <select
                                    id="group-level"
                                    value={level}
                                    onChange={(e) => setLevel(e.target.value)}
                                    className="form-input"
                                >
                                    <option value={GroupLevel.BEGINNER || 'beginner'}>Débutant</option>
                                    <option value={GroupLevel.INTERMEDIATE || 'intermediate'}>Intermédiaire</option>
                                    <option value={GroupLevel.ADVANCED || 'advanced'}>Avancé</option>
                                </select>
                            </div>
                        </div>

                        <div className="dialog-footer">
                            <button
                                type="button"
                                onClick={onClose}
                                className="btn btn-secondary"
                            >
                                Annuler
                            </button>
                            <button
                                type="submit"
                                disabled={loading}
                                className="btn btn-primary"
                            >
                                {loading ? (
                                    <>
                                        <span className="loading"></span>
                                        Création...
                                    </>
                                ) : (
                                    'Créer le Groupe'
                                )}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    );
}
