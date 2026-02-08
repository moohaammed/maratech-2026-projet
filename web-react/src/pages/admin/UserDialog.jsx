import { useState, useEffect } from 'react';
import { UserService, UserRole, RunningGroup } from '../../core/services/UserService';
import './UserDialog.css';

export default function UserDialog({ user, isAdminMode, onClose, onSave }) {
    const [formData, setFormData] = useState({
        fullName: '',
        email: '',
        phone: '',
        cinLastDigits: '',
        role: isAdminMode ? UserRole.COACH_ADMIN : UserRole.MEMBER,
        assignedGroup: RunningGroup.GROUP1,
        password: '',
    });
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const isEditing = !!user;

    useEffect(() => {
        if (user) {
            setFormData({
                fullName: user.fullName || '',
                email: user.email || '',
                phone: user.phone || '',
                cinLastDigits: user.cinLastDigits || '',
                role: user.role || (isAdminMode ? UserRole.COACH_ADMIN : UserRole.MEMBER),
                assignedGroup: user.assignedGroup || RunningGroup.GROUP1,
                password: '',
            });
        }
    }, [user, isAdminMode]);

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({ ...prev, [name]: value }));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setLoading(true);

        try {
            // Basic validation
            if (!formData.fullName || !formData.email || !formData.cinLastDigits) {
                throw new Error("Veuillez remplir les champs obligatoires");
            }

            if (!isEditing && !formData.password) {
                // Auto-generate password if not provided
                const generatedPassword = `000${formData.cinLastDigits}`;
                setFormData(prev => ({ ...prev, password: generatedPassword }));
            }

            const passwordToUse = formData.password || `000${formData.cinLastDigits}`;

            if (isEditing) {
                await UserService.updateUser(user.id, {
                    fullName: formData.fullName,
                    email: formData.email,
                    phone: formData.phone,
                    cinLastDigits: formData.cinLastDigits,
                    role: formData.role,
                    assignedGroup: formData.assignedGroup,
                });
            } else {
                await UserService.createUser({
                    fullName: formData.fullName,
                    email: formData.email,
                    phone: formData.phone,
                    cinLastDigits: formData.cinLastDigits,
                    role: formData.role,
                    assignedGroup: formData.assignedGroup,
                }, passwordToUse);
            }

            onSave();
            onClose();
        } catch (err) {
            console.error("Error submitting form:", err);
            setError(err.message || "Une erreur est survenue");
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="dialog-overlay" onClick={onClose}>
            <div className="dialog-content" onClick={e => e.stopPropagation()}>
                {/* Event-style header */}
                <div className="dialog-header">
                    <h2 className="dialog-title">
                        {isEditing ? 'Modifier' : 'Créer'} {isAdminMode ? 'Administrateur' : 'Utilisateur'}
                    </h2>
                    <button 
                        type="button" 
                        className="dialog-close" 
                        onClick={onClose}
                        aria-label="Fermer"
                    >
                        ✕
                    </button>
                </div>

                <form onSubmit={handleSubmit}>
                    <div className="dialog-body">
                        {error && (
                            <div className="form-error mb-4">
                                {error}
                            </div>
                        )}

                        {/* Icon-wrapped inputs like events */}
                        <div className="form-section">
                            <label>Nom complet *</label>
                            <div className="input-group">
                                <span className="material-icons input-icon">person</span>
                                <input
                                    name="fullName"
                                    value={formData.fullName}
                                    onChange={handleChange}
                                    placeholder="Jean Dupont"
                                    required
                                />
                            </div>
                        </div>

                        <div className="form-section">
                            <label>Email *</label>
                            <div className="input-group">
                                <span className="material-icons input-icon">email</span>
                                <input
                                    type="email"
                                    name="email"
                                    value={formData.email}
                                    onChange={handleChange}
                                    placeholder="jean@example.com"
                                    disabled={isEditing}
                                    required
                                />
                            </div>
                        </div>

                        <div className="form-section">
                            <label>Téléphone</label>
                            <div className="input-group">
                                <span className="material-icons input-icon">phone</span>
                                <input
                                    name="phone"
                                    value={formData.phone}
                                    onChange={handleChange}
                                    placeholder="+216 22 222 222"
                                />
                            </div>
                        </div>

                        <div className="form-section">
                            <label>CIN (3 derniers chiffres) *</label>
                            <div className="input-group">
                                <span className="material-icons input-icon">badge</span>
                                <input
                                    name="cinLastDigits"
                                    value={formData.cinLastDigits}
                                    onChange={handleChange}
                                    maxLength={3}
                                    placeholder="123"
                                    required
                                />
                            </div>
                            <div className="form-help">Mot de passe par défaut : 000 + ces 3 chiffres</div>
                        </div>

                        <div className="form-section">
                            <label>Rôle</label>
                            <div className="input-group">
                                <span className="material-icons input-icon">shield</span>
                                <select name="role" value={formData.role} onChange={handleChange}>
                                    {isAdminMode ? (
                                        <>
                                            <option value={UserRole.GROUP_ADMIN}>Admin Groupe</option>
                                            <option value={UserRole.COACH_ADMIN}>Admin Coach</option>
                                            <option value={UserRole.MAIN_ADMIN}>Admin Principal</option>
                                        </>
                                    ) : (
                                        <>
                                            <option value={UserRole.VISITOR}>Visiteur</option>
                                            <option value={UserRole.MEMBER}>Adhérent</option>
                                        </>
                                    )}
                                </select>
                            </div>
                        </div>

                        {!isAdminMode && (
                            <div className="form-section">
                                <label>Groupe</label>
                                <div className="input-group">
                                    <span className="material-icons input-icon">groups</span>
                                    <select name="assignedGroup" value={formData.assignedGroup || ''} onChange={handleChange}>
                                        <option value={RunningGroup.GROUP1}>Groupe 1</option>
                                        <option value={RunningGroup.GROUP2}>Groupe 2</option>
                                        <option value={RunningGroup.GROUP3}>Groupe 3</option>
                                        <option value={RunningGroup.GROUP4}>Groupe 4</option>
                                        <option value={RunningGroup.GROUP5}>Groupe 5</option>
                                    </select>
                                </div>
                            </div>
                        )}

                        {!isEditing && (
                            <div className="form-section">
                                <label>Mot de passe (Optionnel)</label>
                                <div className="input-group">
                                    <span className="material-icons input-icon">lock</span>
                                    <input
                                        type="password"
                                        name="password"
                                        value={formData.password}
                                        onChange={handleChange}
                                        placeholder="Laisser vide pour défaut (000 + CIN)"
                                    />
                                </div>
                            </div>
                        )}
                    </div>

                    {/* Event-style footer */}
                    <div className="dialog-footer">
                        <button
                            type="button"
                            onClick={onClose}
                            className="btn btn-secondary"
                            disabled={loading}
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
                                    Enregistrement...
                                </>
                            ) : (
                                'Enregistrer'
                            )}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}