# 📱 Guide de Test des Notifications Push FCM

## 🎯 Objectif
Vérifier que les notifications **Push** arrivent même quand l'application est **complètement fermée**.

## 📋 Étapes pour tester

### 1️⃣ Récupérer le Token FCM
1. Lancez l'application sur votre appareil
2. Connectez-vous en tant qu'administrateur
3. Dans le dashboard admin, cliquez sur l'icône 🔔 (notifications) en haut à droite
4. Vous verrez l'écran "Test FCM Push Notifications"
5. **Copiez le FCM Token** (bouton "Copier le token")

### 2️⃣ Ouvrir Firebase Console
1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet
3. Dans le menu de gauche, cliquez sur **"Cloud Messaging"** (sous "Engage")
4. Cliquez sur **"Send your first message"** ou **"New notification"**

### 3️⃣ Créer la notification de test

#### Configuration du message:
- **Notification title**: "Test Push Notification 🔔"
- **Notification text**: "Cette notification arrive même quand l'app est fermée!"
- **Notification image** (optionnel): Laissez vide

#### Ciblage:
1. Sélectionnez **"Send test message"** (en haut à droite)
2. **Collez le FCM Token** que vous avez copié à l'étape 1
3. Cliquez sur **"Test"**

### 4️⃣ Tester les 3 scénarios

#### Scénario 1: Application au premier plan (ouverte) 🟢
- **État**: Gardez l'app ouverte sur l'écran de test FCM
- **Action**: Envoyez la notification depuis Firebase Console
- **Résultat attendu**: 
  - Le message apparaît dans la section "Messages reçus" avec "🟢 FOREGROUND"
  - Une notification locale s'affiche aussi

#### Scénario 2: Application en arrière-plan (minimisée) 🟡
- **État**: Minimisez l'application (bouton Home)
- **Action**: Envoyez une nouvelle notification depuis Firebase Console
- **Résultat attendu**:
  - Une notification s'affiche dans la barre de notifications Android
  - Quand vous cliquez dessus, l'app s'ouvre et le message apparaît avec "🟡 OPENED APP"

#### Scénario 3: Application fermée (terminée) 🔴 **← LE PLUS IMPORTANT!**
- **État**: Fermez complètement l'application
  - Ouvrez le gestionnaire de tâches (bouton carré)
  - Balayez l'application pour la fermer
  - OU allez dans Paramètres → Apps → Impact → "Force Stop"
- **Action**: Envoyez une nouvelle notification depuis Firebase Console
- **Résultat attendu**:
  - ✅ **Une notification arrive dans la barre de notifications Android**
  - ✅ **Quand vous cliquez dessus, l'app se lance et affiche l'événement associé**

## ✅ Critères de réussite

Pour que les notifications Push soient correctement configurées:

1. ✅ Token FCM visible et copiable dans l'app
2. ✅ Notification reçue quand l'app est **ouverte**
3. ✅ Notification reçue quand l'app est **minimisée**
4. ✅ **Notification reçue quand l'app est FERMÉE** ← le plus critique!
5. ✅ Cliquer sur la notification ouvre l'écran correspondant

## 🔍 Vérification des permissions

Si les notifications n'arrivent pas:

### Android:
1. Paramètres → Apps → Impact → Notifications
2. Vérifiez que les notifications sont **activées**
3. Vérifiez que "Push notifications" est activé

### Logs de debug:
- Recherchez "FCM Token:" dans les logs Flutter
- Recherchez "Message reçu" dans les logs
- Vérifiez qu'il n'y a pas d'erreurs Firebase

## 📝 Notes importantes

### Différence Push vs Local:
- **Notifications Locales**: Programmées sur l'appareil, fonctionnent même sans internet mais nécessitent que l'app soit installée
- **Notifications Push (FCM)**: Envoyées depuis Firebase, arrivent via internet **même si l'app est fermée**

### Pour envoyer des notifications Push en production:
1. Depuis votre backend, utilisez l'API Firebase Cloud Messaging
2. Ou configurez des Cloud Functions Firebase avec triggers (nouveaux événements, rappels, etc.)
3. Ou utilisez l'interface Firebase Console pour des campagnes manuelles

## 🐛 Dépannage

### Token FCM null ou vide:
- Vérifiez que google-services.json est dans android/app/
- Vérifiez les permissions dans AndroidManifest.xml
- Redémarrez l'application

### Notifications n'arrivent pas quand l'app est fermée:
- Vérifiez que "Battery optimization" n'est pas activée pour l'app
- Paramètres → Apps → Impact → Battery → "Don't optimize"
- Certains fabricants (Xiaomi, Huawei) bloquent les notifications en arrière-plan

### Cliquer sur la notification ne fait rien:
- Vérifiez que le payload contient `eventId`
- Vérifiez les logs pour voir si `onMessageOpenedApp` est appelé
- Vérifiez que la route `/event-details` existe

## 🎓 Test réussi si:

1. ✅ Vous fermez complètement l'application
2. ✅ Vous envoyez une notification depuis Firebase Console
3. ✅ La notification apparaît dans votre barre de notifications Android
4. ✅ En cliquant dessus, l'application se lance
5. ✅ Vous êtes redirigé vers l'écran de détails de l'événement

**C'est ça la vraie puissance des notifications PUSH!** 🚀
