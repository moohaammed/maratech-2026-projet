# 🚀 Guide d'Installation - Notifications Push Automatiques

## 📱 Comment ça marche?

Avec ce système, **les notifications arrivent AUTOMATIQUEMENT** sur tous les téléphones:

1. ✅ **Un admin crée un événement** → Notification envoyée instantanément
2. ✅ **30 min avant l'événement** → Rappel automatique envoyé
3. ✅ **Arrive même si l'app est FERMÉE** → C'est ça la magie du PUSH!
4. ✅ **Aucun token ou template manuel** → Tout est automatique!

---

## 🛠️ Installation (À faire UNE SEULE FOIS)

### Étape 1: Installer Node.js
1. Téléchargez Node.js 18 ou supérieur: https://nodejs.org/
2. Vérifiez l'installation:
   ```bash
   node --version
   ```

### Étape 2: Installer Firebase CLI
```bash
npm install -g firebase-tools
```

### Étape 3: Se connecter à Firebase
```bash
firebase login
```
Cela ouvrira votre navigateur pour vous connecter avec votre compte Google.

### Étape 4: Initialiser Firebase Functions (si pas déjà fait)
```bash
cd c:\Users\MSI\Desktop\maratech-2026-projet
firebase init functions
```

**Répondez aux questions:**
- Use existing project → Sélectionnez votre projet
- Language → JavaScript
- ESLint → Yes
- Install dependencies → Yes

### Étape 5: Installer les dépendances
```bash
cd functions
npm install
```

---

## 🚀 Déploiement des Cloud Functions

### Déployer TOUTES les fonctions:
```bash
firebase deploy --only functions
```

### Ou déployer une fonction spécifique:
```bash
firebase deploy --only functions:sendEventNotification
firebase deploy --only functions:sendEventReminders
firebase deploy --only functions:sendTestNotification
```

**Attendez quelques minutes** que le déploiement se termine.

---

## ✅ Vérification du Déploiement

### 1. Vérifier dans Firebase Console
1. Allez sur https://console.firebase.google.com/
2. Sélectionnez votre projet
3. Dans le menu gauche → **Functions**
4. Vous devriez voir 3 fonctions:
   - ✅ `sendEventNotification` - Envoie une notification à chaque nouvel événement
   - ✅ `sendEventReminders` - Envoie des rappels 30 min avant
   - ✅ `sendTestNotification` - Fonction de test appelable depuis l'app

### 2. Vérifier les logs
```bash
firebase functions:log
```

---

## 🧪 Tester le Système

### Test 1: Créer un événement
1. Connectez-vous en tant qu'admin dans l'app
2. Créez un nouvel événement
3. **RÉSULTAT: Tous les utilisateurs reçoivent une notification!**
4. Même si leur app est fermée!

### Test 2: Tester depuis l'app
1. Admin Dashboard → Clic sur 🔔
2. Clic sur "Envoyer une notification de test"
3. Remplissez le formulaire et envoyez
4. **RÉSULTAT: Notification reçue par tous!**

### Test 3: Fermer complètement l'app
1. Fermez l'app (swipe dans le gestionnaire de tâches)
2. Créez un événement depuis un autre appareil OU utilisez Firebase Console
3. **RÉSULTAT: La notification arrive quand même!** 🎉

---

## 🔧 Configuration Avancée

### Activer le Scheduler pour les rappels automatiques

Pour que `sendEventReminders` fonctionne (toutes les 5 minutes):

1. Allez dans Firebase Console → Functions
2. Cliquez sur `sendEventReminders`
3. L'URL du scheduler sera créée automatiquement
4. OU activez Cloud Scheduler dans Google Cloud Console:
   - https://console.cloud.google.com/cloudscheduler
   - Activez l'API si demandé

**Note:** Le plan Blaze (pay-as-you-go) est requis pour le scheduler, mais Firebase offre un quota gratuit généreux.

### Modifier la fréquence des rappels

Dans `functions/index.js`, ligne ~70:
```javascript
.schedule('every 5 minutes')  // Changez ici: 'every 1 hours', etc.
```

---

## 📊 Monitoring

### Voir les logs en temps réel:
```bash
firebase functions:log --only sendEventNotification
```

### Voir tous les logs:
```bash
firebase functions:log
```

### Vérifier les erreurs:
1. Firebase Console → Functions
2. Cliquez sur une fonction
3. Onglet "Logs"

---

## 🎯 Comment ça marche en détail?

### 1. sendEventNotification
**Trigger:** Quand un document est créé dans `events/`
**Action:** Envoie une notification à tous les utilisateurs abonnés au topic `all_events`
**Exemple:**
```
Titre: 🏃 Nouvel événement: Entraînement du matin
Corps: 2026-02-08 à 07:00 - Plage de La Marsa
```

### 2. sendEventReminders
**Trigger:** Toutes les 5 minutes (scheduler)
**Action:** Cherche les événements qui commencent dans 30-35 min et envoie un rappel
**Exemple:**
```
Titre: ⏰ Rappel: Événement dans 30 minutes!
Corps: Entraînement du matin à Plage de La Marsa. Soyez prêt!
```

### 3. sendTestNotification
**Trigger:** Appelée depuis l'app via callable function
**Action:** Envoie une notification personnalisée pour tester
**Utilisation:** Depuis l'écran de test dans l'app admin

---

## 🔒 Sécurité

Les utilisateurs s'abonnent automatiquement au topic `all_events` quand ils ouvrent l'app pour la première fois (voir `NotificationService.init()`).

Pour des notifications ciblées par groupe, modifiez:
```javascript
topic: 'all_events'  // Changez en 'group_1', 'group_2', etc.
```

Et dans l'app, abonnez les utilisateurs dynamiquement:
```dart
await FirebaseMessaging.instance.subscribeToTopic('group_${userGroup}');
```

---

## ❓ Dépannage

### Les notifications n'arrivent pas:
1. ✅ Vérifiez que les fonctions sont déployées: `firebase functions:list`
2. ✅ Vérifiez les logs: `firebase functions:log`
3. ✅ Vérifiez que l'app s'abonne bien au topic (logs de l'app)
4. ✅ Vérifiez les permissions Android dans l'app

### Erreur "Permission denied":
- Assurez-vous que Firebase Admin SDK a les bonnes permissions
- Vérifiez le compte de service dans Firebase Console → Project Settings

### Les rappels ne fonctionnent pas:
- Activez Cloud Scheduler dans Google Cloud Console
- Vérifiez que le plan est Blaze (pas Spark)
- Vérifiez les logs du scheduler

---

## 💰 Coûts

### Plan Gratuit (Spark):
- ❌ Scheduler (sendEventReminders) non disponible
- ✅ sendEventNotification fonctionne
- ✅ sendTestNotification fonctionne

### Plan Blaze (Pay-as-you-go):
- ✅ Tout fonctionne
- Quota généreux gratuit:
  - 2M invocations/mois
  - 125K secondes de calcul/mois
  - 5GB sortie réseau/mois

**Pour une app de running club, vous resterez probablement dans le quota gratuit!**

---

## 🎉 Résultat Final

Une fois déployé:
1. ✅ Création d'événement → Notification instantanée automatique
2. ✅ 30 min avant → Rappel automatique
3. ✅ Arrive même si app fermée
4. ✅ Aucune manipulation manuelle
5. ✅ Fonctionne pour tous les utilisateurs

**C'est ça le vrai PUSH!** 🚀
