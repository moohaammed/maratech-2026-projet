# 🔔 Comment recevoir les notifications d'événements

## ✅ Ce qui vient d'être corrigé

**Problème:** Quand un coach crée un événement, les users ne reçoivent pas de notification.

**Solution:** Le système envoie maintenant **2 types de notifications locales**:

1. **Notification immédiate** quand un événement est créé (NOUVEAU!)
2. **Rappel 30 minutes** avant l'événement (déjà existant)

---

## 📱 Comment ça marche maintenant

### Pour les USERS:

1. **Ouvrez l'application** (important!)
2. L'app détecte automatiquement les nouveaux événements
3. **Vous recevez une notification immédiatement**: "🏃 Nouvel événement: [Titre]"
4. **30 min avant l'événement**: Rappel automatique

### Pour les ADMINS/COACHES:

1. Créez un événement normalement
2. Tous les users qui ont l'app **ouverte** reçoivent la notification immédiatement
3. Les autres la recevront **quand ils ouvriront l'app**

---

## ⚠️ Important à comprendre

### Notifications LOCALES (ce qui fonctionne maintenant):
- ✅ Fonctionnent sans internet
- ✅ Notifications immédiates quand événement créé
- ✅ Rappels 30 min avant
- ⚠️ **L'app doit être ouverte AU MOINS UNE FOIS** pour détecter les nouveaux événements

### Notifications PUSH (nécessitent Cloud Functions):
- ✅ Arrivent même si l'app n'est jamais ouverte
- ✅ Envoi automatique instantané
- ❌ Nécessitent déploiement des Cloud Functions

---

## 🧪 Test rapide

### Scénario 1: User avec app ouverte
1. **User:** Ouvrez l'app
2. **Coach:** Créez un événement
3. **User:** Reçoit la notification immédiatement! ✅

### Scénario 2: User avec app fermée
1. **Coach:** Créez un événement
2. **User:** Ouvre l'app
3. **User:** Reçoit la notification au moment de l'ouverture! ✅

### Scénario 3: Rappel automatique
1. Un événement est prévu dans 30 minutes
2. **Tous les users** reçoivent un rappel automatique
3. Même si l'app est fermée! ✅ (car déjà programmé)

---

##  🚀 Pour aller plus loin (Notifications PUSH vraies)

Si vous voulez que les notifications arrivent **même sans jamais ouvrir l'app**, déployez les Cloud Functions:

```powershell
# 1. Installer Firebase CLI
npm install -g firebase-tools

# 2. Se connecter
firebase login

# 3. Déployer
cd C:\Users\MSI\Desktop\maratech-2026-projet
firebase deploy --only functions
```

Avec les Cloud Functions:
- ✅ Notification arrive INSTANTANÉMENT
- ✅ Même si user n'a jamais ouvert l'app
- ✅ Vrai système PUSH

---

## 💡 Résumé

**MAINTENANT (Notifications Locales):**
- Créer événement → Users avec app ouverte reçoivent notification
- Users ouvrent l'app → Reçoivent notifications des nouveaux événements
- 30 min avant → Tous reçoivent le rappel

**APRÈS Cloud Functions (Notifications Push):**
- Créer événement → TOUS reçoivent immédiatement
- Même app fermée
- Même jamais ouverte

---

## ✅ Test maintenant!

1. **User:** Ouvrez l'application
2. **Coach:** Créez un nouvel événement
3. **User:** Vérifiez que vous recevez la notification! 🎉

Si ça fonctionne, le système local marche parfaitement!
Si vous voulez le PUSH instantané, déployez les Cloud Functions.
