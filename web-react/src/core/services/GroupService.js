import { db } from "../../lib/firebase";
import {
    collection,
    addDoc,
    updateDoc,
    deleteDoc,
    doc,
    query,
    where,
    getDocs,
    onSnapshot,
    serverTimestamp,
    arrayUnion,
    arrayRemove,
    or
} from "firebase/firestore";

export const GroupLevel = {
    BEGINNER: 'beginner',
    INTERMEDIATE: 'intermediate',
    ADVANCED: 'advanced'
};

export const GroupService = {
    // Create a new group
    createGroup: async (name, level, adminId) => {
        try {
            const groupData = {
                name,
                level,
                adminId,
                memberIds: [],
                createdAt: serverTimestamp()
            };
            const docRef = await addDoc(collection(db, "groups"), groupData);
            return docRef.id;
        } catch (error) {
            console.error("Error creating group:", error);
            throw error;
        }
    },

    // Get all groups as a stream (callback)
    getGroupsStream: (callback) => {
        const q = query(collection(db, "groups"));
        return onSnapshot(q, (snapshot) => {
            const groups = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));
            callback(groups);
        });
    },

    // Get groups managed by a specific admin
    getGroupsByAdminStream: (adminId, callback) => {
        const q = query(collection(db, "groups"), where("adminId", "==", adminId));
        return onSnapshot(q, (snapshot) => {
            const groups = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));
            callback(groups);
        });
    },

    // Delete a group and remove references from members
    deleteGroup: async (groupId, memberIds = []) => {
        try {
            await deleteDoc(doc(db, "groups", groupId));

            // Remove assignedGroupId from all members
            // Note: Batching would be better for large groups, but doing individually for now
            // mirroring existing Flutter logic which implies some cleanup
            if (memberIds && memberIds.length > 0) {
                const batchPromises = memberIds.map(memberId =>
                    updateDoc(doc(db, "users", memberId), {
                        assignedGroupId: null
                    })
                );
                await Promise.all(batchPromises);
            }
        } catch (error) {
            console.error("Error deleting group:", error);
            throw error;
        }
    },

    // Add a member to a group
    addMemberToGroup: async (groupId, userId) => {
        try {
            // Add user ID to group's memberIds array
            await updateDoc(doc(db, "groups", groupId), {
                memberIds: arrayUnion(userId)
            });

            // Update user's assignedGroupId
            await updateDoc(doc(db, "users", userId), {
                assignedGroupId: groupId
            });
        } catch (error) {
            console.error("Error adding member to group:", error);
            throw error;
        }
    },

    // Remove a member from a group
    removeMemberFromGroup: async (groupId, userId) => {
        try {
            // Remove user ID from group's memberIds array
            await updateDoc(doc(db, "groups", groupId), {
                memberIds: arrayRemove(userId)
            });

            // Update user's assignedGroupId to null
            await updateDoc(doc(db, "users", userId), {
                assignedGroupId: null
            });
        } catch (error) {
            console.error("Error removing member from group:", error);
            throw error;
        }
    },

    // Get members of a specific group
    getGroupMembersStream: (groupId, callback) => {
        // Query users collection checking all possible group ID fields
        const q = query(
            collection(db, "users"),
            or(
                where("assignedGroupId", "==", groupId),
                where("groupId", "==", groupId),
                where("group", "==", groupId)
            )
        );
        return onSnapshot(q, (snapshot) => {
            const users = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));
            callback(users);
        });
    }
};
