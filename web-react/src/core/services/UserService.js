import {
    collection,
    doc,
    getDocs,
    getDoc,
    setDoc,
    updateDoc,
    deleteDoc,
    query,
    where,
    Timestamp,
    onSnapshot
} from 'firebase/firestore';
import { createUserWithEmailAndPassword } from 'firebase/auth';
import { db, auth } from '../../lib/firebase';

export const UserRole = {
    VISITOR: 'UserRole.visitor',
    MEMBER: 'UserRole.member',
    GROUP_ADMIN: 'UserRole.groupAdmin',
    COACH_ADMIN: 'UserRole.coachAdmin',
    MAIN_ADMIN: 'UserRole.mainAdmin',
};

export const RunningGroup = {
    GROUP1: 'RunningGroup.group1',
    GROUP2: 'RunningGroup.group2',
    GROUP3: 'RunningGroup.group3',
    GROUP4: 'RunningGroup.group4',
    GROUP5: 'RunningGroup.group5',
};

export const UserService = {
    // Collection reference
    get usersCollection() {
        return collection(db, 'users');
    },

    // ----------------------------------------------------------------
    // Data Parsing Helpers (MATCHING FLUTTER LOGIC)
    // ----------------------------------------------------------------

    // Helper: Parse user Role from any string format
    parseUserRole(roleData) {
        if (!roleData) return UserRole.VISITOR;

        const roleStr = roleData.toString().toLowerCase();

        // Direct mapping from Dart logic
        if (roleStr === 'main_admin' || roleStr === 'mainadmin') return UserRole.MAIN_ADMIN;
        if (roleStr === 'coach_admin' || roleStr === 'coachadmin') return UserRole.COACH_ADMIN;
        if (roleStr === 'group_admin' || roleStr === 'groupadmin') return UserRole.GROUP_ADMIN;
        if (roleStr === 'sub_admin' || roleStr === 'subadmin') return UserRole.GROUP_ADMIN; // sub_admin = Group Admin
        if (roleStr === 'member' || roleStr === 'user' || roleStr === 'adherent') return UserRole.MEMBER;
        if (roleStr === 'visitor' || roleStr === 'guest' || roleStr === 'invite') return UserRole.VISITOR;

        // Check if it matches our Enum values (case-insensitive sub-string check)
        // e.g. "UserRole.mainAdmin" (Dart toString) -> ends with "mainadmin"
        if (roleStr.includes('mainadmin')) return UserRole.MAIN_ADMIN;
        if (roleStr.includes('coachadmin')) return UserRole.COACH_ADMIN;
        if (roleStr.includes('groupadmin')) return UserRole.GROUP_ADMIN;
        if (roleStr.includes('member')) return UserRole.MEMBER;
        if (roleStr.includes('visitor')) return UserRole.VISITOR;

        return UserRole.VISITOR; // Default fallback
    },

    // Helper: Parse user from Firestore doc
    fromFirestore(doc) {
        const data = doc.data();
        if (!data) return null;

        const role = this.parseUserRole(data.role);

        return {
            id: doc.id,
            fullName: data.fullName || data.name || '',
            email: data.email || '',
            phone: data.phone || '',
            cinLastDigits: data.cinLastDigits || '',
            role: role,
            assignedGroup: data.assignedGroup || null,
            assignedGroupId: data.assignedGroupId || null,
            createdAt: data.createdAt instanceof Timestamp ? data.createdAt.toDate() : new Date(),
            lastLogin: data.lastLogin instanceof Timestamp ? data.lastLogin.toDate() : null,
            isActive: data.isActive ?? true,
            permissions: data.permissions || this.getDefaultPermissions(role),
        };
    },

    // ----------------------------------------------------------------
    // Core Methods
    // ----------------------------------------------------------------

    // Get all users as a stream
    getAllUsersStream(callback) {
        const q = query(collection(db, 'users'));
        return onSnapshot(q, (snapshot) => {
            const users = snapshot.docs
                .map(doc => this.fromFirestore(doc))
                .sort((a, b) => b.createdAt - a.createdAt);
            callback(users);
        }, (error) => {
            console.error("Error streaming users:", error);
        });
    },

    // Get all users (returns a promise with snapshot)
    async getAllUsers() {
        try {
            const snapshot = await getDocs(this.usersCollection);
            return snapshot.docs
                .map(doc => this.fromFirestore(doc))
                .sort((a, b) => b.createdAt - a.createdAt);
        } catch (error) {
            console.error("Error getting users:", error);
            throw error;
        }
    },

    // Get user by ID
    async getUserById(userId) {
        try {
            const docRef = doc(db, 'users', userId);
            const docSnap = await getDoc(docRef);
            if (docSnap.exists()) {
                return this.fromFirestore(docSnap);
            }
            return null;
        } catch (error) {
            console.error("Error getting user:", error);
            throw error;
        }
    },

    // Create new user (Auth + Firestore)
    // Note: Creating a user in Auth while being logged in will switch the current user.
    // In a real user management app, this should be done via a Cloud Function or a secondary Auth instance.
    // For this prototype, we'll assume we might be logged out or handling it carefully, 
    // BUT the Flutter app seems to do it directly. We might lose session here if we use `auth`.
    // A common workaround in client-side only apps is to warn the admin they might be logged out,
    // or use a secondary app instance. For now, we'll implement it directly and see.
    async createUser(userData, password) {
        try {
            // 1. Create in Firebase Auth
            // WARNING: This signs in the new user immediately in the standard SDK.
            // To avoid this, we would need a secondary Firebase App instance, but that's complex setup.
            // For now, we will proceed, but note that the admin might be logged out.
            // A better approach for client-side admin creation without functions is using a secondary app.

            /* 
               // Secondary App approach (Pseudo-code)
               const secondaryApp = initializeApp(firebaseConfig, "Secondary");
               const secondaryAuth = getAuth(secondaryApp);
               const userCredential = await createUserWithEmailAndPassword(secondaryAuth, userData.email, password);
               await signOut(secondaryAuth);
               deleteApp(secondaryApp);
            */

            // Simplified for this conversion:
            // We'll create the Firestore document. If we need Auth creation to not log us out, 
            // we really need a Cloud Function or secondary app. 
            // Let's try to just create the Firestore doc if the user already exists in Auth (manual entry),
            // OR if we are strictly following Flutter, it likely logs the admin out.
            // Let's USE A SECONDARY APP INSTANCE pattern to be safe if possible, or just accept the logout risk.
            // Actually, let's implement the Firestore part solidly. 
            // Only the `createUserWithEmailAndPassword` is problematic.

            // For now, I'll leave the Auth creation commented out if it risks logging out the admin, 
            // OR better, I will assume the user manually creates them or we accept the session switch.
            // Wait, the Flutter code uses `_auth.createUserWithEmailAndPassword`. 
            // Flutter's FirebaseAuth instance behaves similarly. 
            // Let's Implement it standard and warn if needed.

            const userCredential = await createUserWithEmailAndPassword(auth, userData.email, password);
            const userId = userCredential.user.uid;

            // 2. Prepare Firestore Data
            const firestoreData = {
                fullName: userData.fullName,
                email: userData.email,
                phone: userData.phone,
                cinLastDigits: userData.cinLastDigits,
                role: userData.role.toString(), // Store as string
                assignedGroup: userData.assignedGroup?.toString() || null,
                assignedGroupId: userData.assignedGroupId || null,
                createdAt: Timestamp.now(),
                isActive: true,
                permissions: this.getDefaultPermissions(this.parseUserRole(userData.role)),
            };

            // 3. Create in Firestore
            await setDoc(doc(db, 'users', userId), firestoreData);

            return userId;
        } catch (error) {
            console.error("Error creating user:", error);
            throw error;
        }
    },

    // Update user
    async updateUser(userId, data) {
        try {
            const docRef = doc(db, 'users', userId);
            await updateDoc(docRef, data);
        } catch (error) {
            console.error("Error updating user:", error);
            throw error;
        }
    },

    // Delete user (Firestore only - Auth requires backend)
    async deleteUser(userId) {
        try {
            await deleteDoc(doc(db, 'users', userId));
        } catch (error) {
            console.error("Error deleting user:", error);
            throw error;
        }
    },

    // Toggle user status
    async toggleUserStatus(userId, isActive) {
        try {
            const docRef = doc(db, 'users', userId);
            await updateDoc(docRef, { isActive });
        } catch (error) {
            console.error("Error toggling user status:", error);
            throw error;
        }
    },

    // Get statistics
    async getUserStatistics() {
        try {
            const users = await this.getAllUsers();

            // Using the robust parseUserRole logic via getAllUsers -> fromFirestore
            return {
                total: users.length,
                mainAdmins: users.filter(u => u.role === UserRole.MAIN_ADMIN).length,
                coachAdmins: users.filter(u => u.role === UserRole.COACH_ADMIN).length,
                groupAdmins: users.filter(u => u.role === UserRole.GROUP_ADMIN).length,
                members: users.filter(u => u.role === UserRole.MEMBER).length,
                visitors: users.filter(u => u.role === UserRole.VISITOR).length,
                active: users.filter(u => u.isActive).length,
                inactive: users.filter(u => !u.isActive).length,
            };
        } catch (error) {
            console.error("Error getting statistics:", error);
            throw error;
        }
    },

    // Helper to get default permissions (Matches Flutter exactly)
    getDefaultPermissions(role) {
        // Ensure we are working with a standardized role
        const normalizedRole = this.parseUserRole(role);

        switch (normalizedRole) {
            case UserRole.MAIN_ADMIN:
                return {
                    manageUsers: true,
                    manageAdmins: true,
                    managePermissions: true,
                    createEvents: true,
                    deleteEvents: true,
                    viewHistory: true,
                    sendNotifications: true,
                    manageGroups: true,
                    viewStatistics: true,
                };
            case UserRole.COACH_ADMIN:
                return {
                    manageUsers: false,
                    manageAdmins: false,
                    managePermissions: false,
                    createEvents: true,
                    deleteEvents: false,
                    viewHistory: true,
                    sendNotifications: true,
                    manageGroups: false,
                    viewStatistics: true,
                };
            case UserRole.GROUP_ADMIN:
                return {
                    manageUsers: false,
                    manageAdmins: false,
                    managePermissions: false,
                    createEvents: true,
                    deleteEvents: true,
                    viewHistory: true,
                    sendNotifications: true,
                    manageGroups: true,
                    viewStatistics: false,
                };
            case UserRole.MEMBER:
            case UserRole.VISITOR:
            default:
                return {
                    manageUsers: false,
                    manageAdmins: false,
                    managePermissions: false,
                    createEvents: false,
                    deleteEvents: false,
                    viewHistory: true,
                    sendNotifications: false,
                    manageGroups: false,
                    viewStatistics: false,
                };
        }
    },

    // Keep legacy name for compatibility if needed, but alias to new one
    normalizeRole(role) {
        return this.parseUserRole(role);
    }
};
