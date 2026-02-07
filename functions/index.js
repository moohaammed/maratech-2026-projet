const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Cloud Function qui s'exécute automatiquement quand un nouvel événement est créé
 * Cette fonction envoie une notification push à TOUS les utilisateurs
 * même si leur application est fermée!
 */
exports.sendEventNotification = functions.firestore
    .document('events/{eventId}')
    .onCreate(async (snap, context) => {
        const event = snap.data();
        const eventId = context.params.eventId;

        console.log('📅 Nouvel événement créé:', event.title);

        // Déterminer le type de notification
        const isDaily = event.type === 'daily';
        const icon = isDaily ? '🏃' : '⭐';

        // Créer le message de notification
        const notification = {
            title: `${icon} Nouvel événement: ${event.title}`,
            body: `${event.date} à ${event.time} - ${event.location}`,
        };

        // Données supplémentaires (pour la navigation)
        const data = {
            eventId: eventId,
            type: event.type || 'event',
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
        };

        // Message à envoyer
        const message = {
            notification: notification,
            data: data,
            topic: 'all_events', // Tous les utilisateurs abonnés au topic
            android: {
                priority: 'high',
                notification: {
                    channelId: 'high_importance_channel',
                    priority: 'high',
                    sound: 'default',
                    clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                        badge: 1,
                    },
                },
            },
        };

        try {
            // Envoyer la notification
            const response = await admin.messaging().send(message);
            console.log('✅ Notification envoyée avec succès:', response);
            return response;
        } catch (error) {
            console.error('❌ Erreur lors de l\'envoi de la notification:', error);
            throw error;
        }
    });

/**
 * Cloud Function pour envoyer des rappels automatiques 30 minutes avant l'événement
 * Cette fonction est déclenchée par un scheduler (à configurer)
 */
exports.sendEventReminders = functions.pubsub
    .schedule('every 5 minutes')
    .onRun(async (context) => {
        console.log('🔔 Vérification des rappels à envoyer...');

        const now = admin.firestore.Timestamp.now();
        const in30Minutes = new Date(now.toDate().getTime() + 30 * 60 * 1000);
        const in35Minutes = new Date(now.toDate().getTime() + 35 * 60 * 1000);

        // Récupérer les événements qui commencent dans 30-35 minutes
        const eventsSnapshot = await admin.firestore()
            .collection('events')
            .where('date', '>=', admin.firestore.Timestamp.fromDate(in30Minutes))
            .where('date', '<=', admin.firestore.Timestamp.fromDate(in35Minutes))
            .get();

        if (eventsSnapshot.empty) {
            console.log('Aucun événement à rappeler pour le moment');
            return null;
        }

        const promises = [];

        eventsSnapshot.forEach((doc) => {
            const event = doc.data();
            const eventId = doc.id;

            const message = {
                notification: {
                    title: '⏰ Rappel: Événement dans 30 minutes!',
                    body: `${event.title} à ${event.location}. Soyez prêt!`,
                },
                data: {
                    eventId: eventId,
                    type: 'reminder',
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                },
                topic: 'all_events',
                android: {
                    priority: 'high',
                    notification: {
                        channelId: 'event_reminders',
                        priority: 'high',
                        sound: 'default',
                    },
                },
            };

            promises.push(
                admin.messaging().send(message)
                    .then((response) => {
                        console.log(`✅ Rappel envoyé pour: ${event.title}`, response);
                        return response;
                    })
                    .catch((error) => {
                        console.error(`❌ Erreur rappel pour: ${event.title}`, error);
                        return null;
                    })
            );
        });

        return Promise.all(promises);
    });

/**
 * Cloud Function pour envoyer une notification de test
 * Utilisable depuis l'app pour tester le système
 */
exports.sendTestNotification = functions.https.onCall(async (data, context) => {
    // Vérifier que l'utilisateur est authentifié
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'L\'utilisateur doit être authentifié.'
        );
    }

    const title = data.title || 'Test Push Notification 🔔';
    const body = data.body || 'Cette notification arrive même si l\'app est fermée!';

    const message = {
        notification: {
            title: title,
            body: body,
        },
        data: {
            type: 'test',
            timestamp: Date.now().toString(),
        },
        topic: 'all_events',
        android: {
            priority: 'high',
            notification: {
                channelId: 'high_importance_channel',
                priority: 'high',
                sound: 'default',
            },
        },
    };

    try {
        const response = await admin.messaging().send(message);
        console.log('✅ Notification de test envoyée:', response);
        return { success: true, messageId: response };
    } catch (error) {
        console.error('❌ Erreur envoi notification test:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
