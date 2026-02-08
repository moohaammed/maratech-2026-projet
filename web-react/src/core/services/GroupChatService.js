import {
  collection,
  addDoc,
  query,
  orderBy,
  limit,
  serverTimestamp,
  onSnapshot
} from 'firebase/firestore';
import { db } from '../../lib/firebase';

const COLLECTION = 'groupChats';

export const GroupChatService = {
  /**
   * Subscribe to messages for a given group (real-time)
   * @param {string} groupId
   * @param {(msgs: Array) => void} callback
   * @returns {() => void} unsubscribe function
   */
  subscribe(groupId, callback) {
    const q = query(
      collection(db, COLLECTION, groupId, 'messages'),
      orderBy('createdAt', 'asc'),
      limit(500)
    );

    return onSnapshot(q, (snap) => {
      const msgs = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      callback(msgs);
    });
  },

  /**
   * Send a message
   * @param {string} groupId
   * @param {string} senderId
   * @param {string} senderName
   * @param {string} text
   */
  async sendMessage(groupId, senderId, senderName, text) {
    if (!text?.trim()) return;
    await addDoc(collection(db, COLLECTION, groupId, 'messages'), {
      senderId,
      senderName,
      text: text.trim(),
      createdAt: serverTimestamp()
    });
  }
};