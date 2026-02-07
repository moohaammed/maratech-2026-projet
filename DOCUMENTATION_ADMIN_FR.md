# 🏃‍♂️ Running Club Tunis - Interface Administration

## 📱 Interface d'Administration Principale

Bienvenue ! J'ai créé une **interface complète et moderne** pour l'administrateur principal du Running Club Tunis, conforme à 100% au cahier des charges de votre hackathon.

---

## 🎯 Ce qui a été créé

### 1. **Modèle de Données** (`user_model.dart`)
Gestion complète des utilisateurs avec :
- ✅ 5 types de rôles (Visiteur, Adhérent, Admin Groupe, Admin Coach, Admin Principal)
- ✅ 5 groupes de running (Groupe 1 à 5)
- ✅ 9 permissions granulaires
- ✅ Permissions par défaut selon le rôle
- ✅ Intégration Firebase Firestore

### 2. **Service Firebase** (`user_service.dart`)
Toutes les opérations CRUD :
- ✅ Créer des utilisateurs/admins
- ✅ Modifier les informations
- ✅ Supprimer des comptes
- ✅ Changer les rôles
- ✅ Gérer les permissions
- ✅ Affecter aux groupes
- ✅ Activer/Désactiver les comptes
- ✅ Statistiques en temps réel
- ✅ Recherche d'utilisateurs

### 3. **Dashboard Principal** (`admin_dashboard_screen.dart`)
Interface moderne avec :
- ✅ Header avec gradient bleu élégant
- ✅ 6 cartes de statistiques défilantes
- ✅ Navigation par onglets (Utilisateurs, Admins, Permissions)
- ✅ Rafraîchissement des données
- ✅ Design glassmorphism

### 4. **Gestion des Utilisateurs** (`user_management_screen.dart`)
Fonctionnalités complètes :
- ✅ Recherche en temps réel
- ✅ Filtres (Type : Adhérent/Visiteur, Actifs uniquement)
- ✅ Liste avec cartes utilisateurs
- ✅ Création rapide (bouton +)
- ✅ Modification (clic sur carte)
- ✅ Menu d'actions (modifier, activer/désactiver, supprimer)
- ✅ Confirmations pour actions critiques

### 5. **Gestion des Administrateurs** (`admin_management_screen.dart`)
Interface avancée :
- ✅ Affichage groupé par type d'admin
- ✅ Filtres rapides (Tous, Principaux, Coach, Groupe)
- ✅ Code couleur par rôle
- ✅ Badges de permissions visibles
- ✅ Cartes avec gradient selon le type
- ✅ Création d'admins
- ✅ Modification et suppression

### 6. **Création d'Utilisateurs** (`create_user_dialog.dart`)
Dialogue complet :
- ✅ Formulaire avec validation
- ✅ Champs : Nom, Email, Téléphone, CIN, Mot de passe
- ✅ Sélection de rôle avec icônes
- ✅ Affectation au groupe (optionnel)
- ✅ Mode Admin/Utilisateur différencié
- ✅ Design moderne avec header gradient

### 7. **Modification d'Utilisateurs** (`edit_user_dialog.dart`)
Interface à onglets :
- ✅ **Onglet Informations** : Modifier données personnelles
- ✅ **Onglet Rôle & Groupe** : Changer rôle et groupe
- ✅ **Onglet Permissions** : Contrôle granulaire avec switch
- ✅ Bouton de réinitialisation des permissions
- ✅ Descriptions pour chaque permission

### 8. **Page de Démo** (`admin_demo_page.dart`)
Pour tester facilement :
- ✅ Présentation des fonctionnalités
- ✅ Accès direct au dashboard
- ✅ Design attractif

---

## 🎨 Design & Esthétique

### Palette de Couleurs
- **Bleu Principal** : `#1A237E` → `#0D47A1` (gradient)
- **Admin Principal** : `#FF9800` (Orange)
- **Admin Coach** : `#2196F3` (Bleu)
- **Admin Groupe** : `#9C27B0` (Violet)
- **Adhérent** : `#2196F3` (Bleu)
- **Visiteur** : `#9E9E9E` (Gris)
- **Succès** : `#4CAF50` (Vert)
- **Actif** : `#00BCD4` (Cyan)

### Effets Visuels
- ✨ Gradients modernes
- ✨ Glassmorphism (effets de verre)
- ✨ Ombres subtiles
- ✨ Bordures arrondies
- ✨ Animations de transition
- ✨ Hover effects
- ✨ Snackbars pour feedback

---

## 🔐 Système de Permissions

### Admin Principal (Comité Directeur)
**Accès total** à toutes les fonctionnalités :
```
✅ Gérer utilisateurs
✅ Gérer administrateurs  
✅ Gérer permissions
✅ Créer événements
✅ Supprimer événements
✅ Voir historique
✅ Envoyer notifications
✅ Gérer groupes
✅ Voir statistiques
```

### Admin Coach
**Focus sur les programmes** :
```
❌ Gérer utilisateurs
❌ Gérer administrateurs
❌ Gérer permissions
✅ Créer événements
❌ Supprimer événements
✅ Voir historique
✅ Envoyer notifications
❌ Gérer groupes
✅ Voir statistiques
```

### Admin de Groupe
**Responsable de groupe** :
```
❌ Gérer utilisateurs
❌ Gérer administrateurs
❌ Gérer permissions
✅ Créer événements
✅ Supprimer événements
✅ Voir historique
✅ Envoyer notifications
✅ Gérer groupes
❌ Voir statistiques
```

### Adhérent
**Membre standard** :
```
❌ Gérer utilisateurs
❌ Gérer administrateurs
❌ Gérer permissions
❌ Créer événements
❌ Supprimer événements
✅ Voir historique
❌ Envoyer notifications
❌ Gérer groupes
❌ Voir statistiques
```

### Visiteur
**Accès limité** :
```
❌ Gérer utilisateurs
❌ Gérer administrateurs
❌ Gérer permissions
❌ Créer événements
❌ Supprimer événements
✅ Voir historique
❌ Envoyer notifications
❌ Gérer groupes
❌ Voir statistiques
```

---

## 📂 Structure des Fichiers

```
lib/features/admin/
├── models/
│   └── user_model.dart                 # Modèle de données utilisateur
├── services/
│   └── user_service.dart               # Service Firebase CRUD
└── screens/
    ├── admin_dashboard_screen.dart     # Dashboard principal
    ├── user_management_screen.dart     # Gestion utilisateurs
    ├── admin_management_screen.dart    # Gestion administrateurs
    ├── create_user_dialog.dart         # Dialogue création
    └── edit_user_dialog.dart           # Dialogue modification

lib/features/demo/
└── admin_demo_page.dart                # Page de démonstration

Documentation/
├── INTERFACE_ADMIN_README.md           # Documentation complète
└── GUIDE_VISUEL_ADMIN.txt             # Guide visuel ASCII
```

---

## 🚀 Comment Utiliser

### 1. Navigation vers le Dashboard
```dart
// Depuis n'importe où dans l'app
Navigator.pushNamed(context, '/admin-dashboard');

// Ou directement
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AdminDashboardScreen(),
  ),
);
```

### 2. Depuis la Page de Démo
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AdminDemoPage(),
  ),
);
```

### 3. Tester l'Interface
1. Lancez l'application Flutter
2. Naviguez vers `/admin-dashboard`
3. Explorez les 3 onglets
4. Testez la création, modification et suppression

---

## ✅ Conformité au Cahier des Charges

| Exigence | Statut | Détails |
|----------|--------|---------|
| 3 niveaux d'admins | ✅ | Principal, Coach, Groupe |
| Gestion utilisateurs | ✅ | CRUD complet |
| Gestion admins | ✅ | CRUD complet |
| Gestion permissions | ✅ | 9 permissions granulaires |
| Affectation groupes | ✅ | 5 groupes de running |
| Interface moderne | ✅ | Design premium avec gradient |
| Authentification | ✅ | Firebase Auth intégré |
| Base de données | ✅ | Firestore |
| Mobile Android/iOS | ✅ | Flutter cross-platform |

---

## 🎓 Fonctionnalités Principales

### Dashboard
- 📊 Statistiques en temps réel
- 🔄 Rafraîchissement manuel
- 📑 Navigation par onglets
- 🎨 Design élégant

### Utilisateurs
- 🔍 Recherche instantanée
- 🎯 Filtres multiples
- ➕ Création rapide
- ✏️ Modification complète
- 🗑️ Suppression sécurisée
- ⏸️ Activation/Désactivation

### Administrateurs
- 👥 Vue groupée par type
- 🏷️ Filtres par rôle
- 🎨 Code couleur
- 🔐 Badges de permissions
- ➕ Création d'admins

### Permissions
- 🔐 Contrôle granulaire
- 🎚️ Switch ON/OFF
- ♻️ Réinitialisation
- 📝 Descriptions claires

---

## 💡 Points Forts

1. **Interface Moderne** : Design premium conforme aux standards 2026
2. **Expérience Fluide** : Animations et transitions smoothes
3. **Feedback Utilisateur** : Messages clairs pour chaque action
4. **Sécurité** : Confirmations pour actions critiques
5. **Flexibilité** : Permissions entièrement configurables
6. **Performance** : Streams Firebase pour temps réel
7. **Responsive** : Adaptation iOS et Android
8. **Maintenable** : Code propre et bien structuré

---

## 🔧 Prochaines Étapes (Optionnel)

Pour améliorer encore l'interface :

1. **Photos de profil** : Upload d'avatars
2. **Export de données** : CSV/Excel
3. **Historique d'actions** : Logs d'activité admin
4. **Notifications push** : Intégration FCM
5. **Recherche avancée** : Filtres multiples combinés
6. **Dark mode** : Thème sombre
7. **Multi-langue** : i18n (FR/AR/EN)
8. **Analytics** : Tableaux de bord avancés

---

## 📱 Captures d'Écran (Description)

### Dashboard Principal
- Header bleu avec gradient
- 6 cartes statistiques colorées
- Navigation par onglets claire

### Gestion Utilisateurs
- Barre de recherche élégante
- Filtres rapides
- Cartes utilisateurs avec infos
- Menu d'actions contextuel

### Gestion Admins
- Sections groupées par type
- Cartes avec gradient selon rôle
- Badges de permissions
- Filtres par type d'admin

### Dialogues
- Headers avec gradient
- Formulaires validés
- Sélection visuelle de rôle/groupe
- Onglets pour modification

---

## 🎉 Conclusion

L'interface d'administration principale est **complète, moderne et prête à l'emploi** !

Elle respecte **100% du cahier des charges** et offre une expérience utilisateur exceptionnelle pour gérer les 125 membres du Running Club Tunis.

Tous les écrans, dialogues et fonctionnalités demandés sont implémentés avec un design soigné et professionnel.

**L'interface est prête pour le hackathon ! 🚀**

---

## 📞 Contact

Pour toute question ou assistance :
- **Montassar Mekkaoui** : 93 500 687
- **Fares Chakroun** : 98 773 438 / fares.chakroun@esprit.tn

---

**Créé avec ❤️ pour le Running Club Tunis**
*Maratech 2026 Hackathon*
