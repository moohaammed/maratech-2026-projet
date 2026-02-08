import { useState, useEffect } from 'react';
import { collection, query, where, onSnapshot, Timestamp, orderBy, limit } from 'firebase/firestore';
import { db } from '../../lib/firebase';

const STORAGE_KEY = 'maratech_notifications_last_checked';

export const NotificationService = {
    markAsRead: () => {
        try {
            localStorage.setItem(STORAGE_KEY, Date.now().toString());
            window.dispatchEvent(new Event('storage'));
        } catch (e) {
            console.warn("Storage write failed", e);
        }
    },

    getLastChecked: () => {
        try {
            const val = localStorage.getItem(STORAGE_KEY);
            return val ? parseInt(val, 10) : 0;
        } catch (e) {
            return 0;
        }
    },

    requestDesktopPermission: async () => {
        if (!("Notification" in window)) return false;
        if (Notification.permission === "granted") return true;

        if (Notification.permission !== "denied") {
            const permission = await Notification.requestPermission();
            return permission === "granted";
        }
        return false;
    },

    sendDesktopNotification: (title, body) => {
        if (!("Notification" in window) || Notification.permission !== "granted") return;

        try {
            // Play a subtle sound
            const audio = new Audio('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3');
            audio.play().catch(e => console.warn("Audio play blocked", e));

            const n = new Notification(title, {
                body: body,
                icon: '/pwa-512x512.png',
                tag: 'maratech-notif',
                renotify: true
            });

            n.onclick = () => {
                window.focus();
                n.close();
            };
        } catch (e) {
            console.warn("Desktop notification error", e);
        }
    }
};

export function useNotificationBadge(groupId) {
    const [unreadEvents, setUnreadEvents] = useState(0);
    const [unreadMessages, setUnreadMessages] = useState(0);

    useEffect(() => {
        let isInitialLoad = true;
        const lastChecked = NotificationService.getLastChecked();
        const lastCheckedDate = new Date(lastChecked);

        // 1. Listen for new events
        const eventsRef = collection(db, 'events');
        const qEvents = query(
            eventsRef,
            where('createdAt', '>', Timestamp.fromDate(lastCheckedDate))
        );

        const unsubEvents = onSnapshot(qEvents, (snapshot) => {
            setUnreadEvents(snapshot.size);

            if (!isInitialLoad) {
                snapshot.docChanges().forEach((change) => {
                    if (change.type === "added") {
                        const eventData = change.doc.data();
                        if (Notification.permission === "granted") {
                            NotificationService.sendDesktopNotification(
                                `Maratech: ${eventData.title || 'Nouvel événement'}`,
                                `Un nouvel événement a été créé pour le ${eventData.date?.toDate ? eventData.date.toDate().toLocaleDateString() : 'bientôt'}.`
                            );
                        }
                    }
                });
            }
            isInitialLoad = false;
        }, (error) => {
            console.warn("Error counting unread events:", error);
        });

        // 2. Listen for new messages in group (if provided)
        let unsubChat = () => { };
        if (groupId) {
            const messagesRef = collection(db, 'groupChats', groupId, 'messages');
            const qMessages = query(
                messagesRef,
                where('createdAt', '>', Timestamp.fromDate(lastCheckedDate))
            );

            unsubChat = onSnapshot(qMessages, (snapshot) => {
                setUnreadMessages(snapshot.size);
            }, (error) => {
                console.warn("Error counting unread messages:", error);
            });
        }

        const handleStorage = () => {
            setUnreadEvents(0);
            setUnreadMessages(0);
        };
        window.addEventListener('storage', handleStorage);

        return () => {
            unsubEvents();
            unsubChat();
            window.removeEventListener('storage', handleStorage);
        };
    }, [groupId]);

    return unreadEvents + unreadMessages;
}

export function useChatNotifications(currentUser, groupId) {
    useEffect(() => {
        if (!groupId || !currentUser) return;

        console.log(`useChatNotifications started for group: ${groupId}`);
        let isInitialLoad = true;

        const messagesRef = collection(db, 'groupChats', groupId, 'messages');
        const q = query(
            messagesRef,
            orderBy('createdAt', 'desc'),
            limit(1)
        );

        const unsubscribe = onSnapshot(q, (snapshot) => {
            if (isInitialLoad) {
                isInitialLoad = false;
                return;
            }

            snapshot.docChanges().forEach((change) => {
                if (change.type === "added") {
                    const msg = change.doc.data();
                    // Only notify if message is from someone else
                    if (msg.senderId !== currentUser.uid) {
                        console.log("New chat message for notification:", msg.text);
                        NotificationService.sendDesktopNotification(
                            `Message de ${msg.senderName || 'Groupe'}`,
                            msg.text || 'Nouveau message reçu.'
                        );
                    }
                }
            });
        }, (error) => {
            console.warn("Chat notification error:", error);
        });

        return () => unsubscribe();
    }, [currentUser?.uid, groupId]);
}
