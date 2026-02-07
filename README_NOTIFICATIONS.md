# 📱 Comment ça marche - Notifications AUTOMATIQUES

## 🎯 Ce qui a été créé

Votre application envoie maintenant des **notifications PUSH automatiques** qui arrivent sur tous les téléphones, même si l'app est fermée!

## ✅ Ce qui fonctionne DÉJÀ (sans Cloud Functions)

1. **Rappels locaux programmés** - 30 minutes avant chaque événement
   - ✅ Fonctionne si l'app est installée
   - ✅ Notification locale Android
   - ⚠️ L'app doit être installée

2. **Navigation depuis les notifications**
   - ✅ Cliquer sur une notification ouvre les détails de l'événement
   - ✅ Fonctionne même si l'app était fermée

## 🚀 Ce qui nécessite Cloud Functions (pour le VRAI PUSH)

Pour que les notifications arrivent **même si l'app est fermée** ET **sans que l'app soit ouverte**, vous devez déployer les Cloud Functions.

### Qu'est-ce que ça fait?

1. **Notification automatique à la création d'événement**
   - Admin crée un événement → Notification envoyée à TOUS immédiatement
   - Arrive même si l'app n'est jamais ouverte sur ce téléphone

2. **Rappels automatiques**
   - 30 minutes avant chaque événement
   - Envoyé à TOUS via le cloud
   - Arrive même si l'app est fermée

3. **Test depuis l'app**
   - Bouton "Envoyer notification de test" dans l'app admin
   - Envoie une vraie notification push à tous

## 📋 Installation des Cloud Functions (15 minutes)

### 1. Installer Node.js
- Téléchargez: https://nodejs.org/ (version 18+)
- Installez et redémarrez votre PC

### 2. Installer Firebase CLI
Ouvrez PowerShell et exécutez:
```powershell
npm install -g firebase-tools
```

### 3. Se connecter à Firebase
```powershell
firebase login
```

### 4. Aller dans le dossier du projet
```powershell
cd C:\Users\MSI\Desktop\maratech-2026-projet
```

### 5. Installer les dépendances functions
```powershell
cd functions
npm install
cd ..
```

### 6. Déployer les Cloud Functions
```powershell
firebase deploy --only functions
```

Attendez quelques minutes. Vous verrez:
```
✔  Deploy complete!
   functions[sendEventNotification(...)]
   functions[sendEventReminders(...)]
   functions[sendTestNotification(...)]
```

**C'est tout!** Les notifications automatiques fonctionnent maintenant! 🎉

## 🧪 Tester

### Test rapide:
1. Dans l'app admin, cliquez sur 🔔 (en haut à droite)
2. Cliquez sur le bouton vert "Envoyer une notification de test"
3. Cliquez sur "Envoyer à tous les utilisateurs"
4. **Fermez complètement l'app**
5. Depuis un autre appareil, envoyez une autre notification
6. La notification apparaît! 🎉

### Test complet:
1. Créez un nouvel événement depuis l'app admin
2. TOUS les utilisateurs reçoivent une notification immédiatement
3. Même ceux qui ont fermé l'app!

## ❓ Si ça ne marche pas

### "Cloud Function not found"
➡️ Les functions ne sont pas déployées. Exécutez: `firebase deploy --only functions`

### "Permission denied"
➡️ Exécutez: `firebase login` et reconnectez-vous

### Les notifications n'arrivent pas
1. Vérifiez que les functions sont déployées: `firebase functions:list`
2. Vérifiez les logs: `firebase functions:log`
3. Vérifiez que l'app s'est abonnée au topic (logs de l'app au démarrage)

## 💰 Coûts

- **Plan Spark (gratuit)**: sendEventNotification et sendTestNotification fonctionnent
- **Plan Blaze (pay-as-you-go)**: Tout fonctionne, mais quota gratuit très généreux
  - Pour un club de running, vous resterez probablement gratuit

## 📝 Résumé

**AVANT Cloud Functions:**
- ✅ Rappels locaux (app installée nécessaire)
- ✅ Navigation depuis notifications

**APRÈS Cloud Functions:**
- ✅ Notifications arrivent VRAIMENT même si app fermée
- ✅ Envoi automatique à la création d'événement
- ✅ Rappels cloud 30 min avant
- ✅ Test depuis l'app

**Pour déployer:** `firebase deploy --only functions`

C'est ça le vrai PUSH! 🚀
