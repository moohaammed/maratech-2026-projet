# 🏃 USER (ADHÉRANT) - COMPLETE FEATURE SPECIFICATION
## Running Club Tunis Mobile App

Based on: Fiche de renseignement - Running Club Tunis

---

## 👥 USER TYPES

### **1. VISITEUR (Visitor)** - No Login Required
- Access club history
- View club news/announcements
- See public information
- **Cannot:** Register for events, receive notifications

### **2. ADHÉRANT (Member)** ⭐ MAIN FOCUS
- Full access to app features
- Assigned to a running group
- Login: Name + Last 3 digits of CIN
- **This is the user we're implementing!**

### **3. ADMINS (3 Levels)**
- Admin Principal (Main Admin) - Comité directrice
- Admin Coach - Shares training programs
- Admin de Groupe - Group responsible

---

## 🎯 USER (ADHÉRANT) - COMPLETE JOURNEY

### **PHASE 1: ONBOARDING & SETUP**

#### **Step 1: First Launch** (Accessibility-First!)
```
App Opens
    ↓
Splash Screen (3 languages: FR/EN/AR)
    ↓
Accessibility Wizard
    ├─ Visual needs (text size, contrast, color blind)
    ├─ Audio needs (deaf, hearing loss, vibration)
    └─ Motor needs (limited dexterity, simplified gestures)
    ↓
Settings saved to local + Firebase (when logged in)
```

**User Actions:**
- Select accessibility preferences
- Configure text size (100%-200%)
- Enable high contrast if needed
- Choose notification style (sound/visual/haptic)

---

#### **Step 2: Login**
```
Login Screen
    ↓
Enter: Full Name
Enter: Last 3 digits of CIN (as password)
    ↓
Firebase Authentication
    ↓
Load user profile from Firestore
    ├─ Name
    ├─ Email
    ├─ Phone
    ├─ Group assignment (Débutants/Intermédiaires/Confirmés)
    ├─ Role (adhérant)
    └─ Accessibility settings
    ↓
Navigate to Home Screen
```

**User Data from Firestore:**
```javascript
{
  userId: "user123",
  fullName: "Fares Chakroun",
  email: "fares.chakroun@esprit.tn",
  phone: "98773438",
  cin: "encrypted:12345678",  // Last 3 digits: 678
  pinHash: "hash_of_678",
  role: "user",  // adhérant
  groupId: "intermediate",
  groupName: "Intermédiaires",
  isActive: true,
  memberSince: Timestamp,
  permissions: {
    canCreateEvents: false,  // Only admins
    canViewEvents: true,
    canRegisterForEvents: true,
    canViewHistory: true,
    canReceiveNotifications: true
  }
}
```

---

### **PHASE 2: HOME SCREEN (DAILY USE)**

#### **What User Sees:**

```
┌─────────────────────────────────────┐
│  🏃 Running Club Tunis              │
│  🔔 [Notifications: 2]              │
├─────────────────────────────────────┤
│  👋 Bienvenue, Fares!               │
│  Groupe: Intermédiaires 🟡          │
│  Membre depuis: Avril 2016          │
├─────────────────────────────────────┤
│  🏃 COURSE D'AUJOURD'HUI             │
│  ┌───────────────────────────────┐  │
│  │ Sortie Tempo                  │  │
│  │ 🟡 Intermédiaires             │  │
│  │ 📍 Lac de Tunis - Entrée Sud  │  │
│  │ ⏰ 18:00 (dans 3h)            │  │
│  │ 📏 12 km                      │  │
│  │ 👥 12/40 inscrits             │  │
│  │ [S'INSCRIRE] ✅                │  │
│  └───────────────────────────────┘  │
├─────────────────────────────────────┤
│  ⚡ ACTIONS RAPIDES                 │
│  [📅 Événements] [📜 Historique]   │
│  [📢 Annonces]   [⚙️ Paramètres]   │
├─────────────────────────────────────┤
│  📅 ÉVÉNEMENTS À VENIR              │
│  - Sam 08/02: Sortie Longue (20km) │
│  - Dim 09/02: Course Easy (6km)    │
│  - Mer 12/02: Tempo Run (15km)     │
└─────────────────────────────────────┘
```

**User Can:**
1. ✅ **View today's run** for their group
2. ✅ **Register for events** (one tap)
3. ✅ **See upcoming events** (this week)
4. ✅ **Check notifications**
5. ✅ **Access quick actions**

---

### **PHASE 3: CORE FEATURES**

#### **FEATURE 1: VIEW TODAY'S RUN** 🏃

**User Flow:**
```
Home Screen → Today's Run Card
    ↓
Tap on event
    ↓
Event Details Screen
```

**Event Details Page:**
```
┌─────────────────────────────────────┐
│  ← Sortie Tempo                     │
│                                     │
│  🟡 INTERMÉDIAIRES                  │
│  📅 Vendredi 07 Février 2026        │
│  ⏰ 18:00 - 19:30 (1h30)           │
│                                     │
│  📍 POINT DE RENCONTRE               │
│  Lac de Tunis - Entrée Sud          │
│  [🗺️ Voir sur la carte]            │
│  Parking disponible ✅               │
│  Transport public: Ligne 5          │
│                                     │
│  📏 PARCOURS                         │
│  Distance: 12 km                    │
│  Allure cible: 5:30-6:30 min/km    │
│  Dénivelé: +50m                     │
│  Terrain: Plat, asphalte           │
│  Difficulté: Modérée                │
│                                     │
│  💬 DESCRIPTION                      │
│  Séance de tempo avec 3x3km à      │
│  allure semi-marathon. Échauffement │
│  de 10min + récupération active.    │
│                                     │
│  👥 PARTICIPANTS (12/40)             │
│  [Photos des inscrits]              │
│  • Ahmed B. • Sarah K. • ...        │
│                                     │
│  🔔 RAPPELS                          │
│  ✅ 24h avant (Demain 18:00)        │
│  ✅ 1h avant (Aujourd'hui 17:00)    │
│                                     │
│  [✅ JE PARTICIPE] (Large button)   │
│  ou                                 │
│  [❌ SE DÉSINSCRIRE]                │
└─────────────────────────────────────┘
```

**User Actions:**
- ✅ View full event details
- ✅ See location on map
- ✅ Check who's coming
- ✅ Register for event
- ✅ Unregister if needed
- ✅ Share event with friends

---

#### **FEATURE 2: WEEKLY EVENTS** 📅

**Types of Events:**

**A) Daily Runs (Quotidiens)**
- Created by Admin de Groupe
- Specific to each group
- Usually 18:00-19:00 weekdays
- 6-15 km depending on group

**B) Weekly Events (Hebdomadaires)**
- **Sorties Longues** (Long Runs) - Saturdays
  - All groups together
  - 20-30 km
  - Early morning (07:00)
  
- **Special Events** (Événements spéciaux)
  - National races
  - Club challenges
  - Social events

**Events List Screen:**
```
┌─────────────────────────────────────┐
│  📅 Événements                      │
│  [Tous] [Mon groupe] [Favoris]     │
├─────────────────────────────────────┤
│  AUJOURD'HUI - Ven 07/02            │
│  ┌───────────────────────────────┐  │
│  │ 18:00 | Tempo Run            │  │
│  │ 🟡 Intermédiaires            │  │
│  │ 📍 Lac de Tunis | 12km       │  │
│  │ [INSCRIT ✅]                  │  │
│  └───────────────────────────────┘  │
│                                     │
│  DEMAIN - Sam 08/02                 │
│  ┌───────────────────────────────┐  │
│  │ 07:00 | Sortie Longue        │  │
│  │ 🔵 Tous les groupes          │  │
│  │ 📍 Lac 2 | 25km              │  │
│  │ [S'INSCRIRE]                 │  │
│  └───────────────────────────────┘  │
│                                     │
│  DIMANCHE - Dim 09/02               │
│  ┌───────────────────────────────┐  │
│  │ 08:00 | Course Easy          │  │
│  │ 🟢 Débutants                 │  │
│  │ 📍 Parc Belvédère | 6km      │  │
│  │ (Autre groupe)               │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

**Filters:**
- ✅ All events
- ✅ My group only
- ✅ Events I'm registered for
- ✅ This week / This month
- ✅ Special events only

---

#### **FEATURE 3: NOTIFICATIONS** 🔔

**User Receives:**

**1. Daily Event Notifications**
```
🏃 Course ce soir!
Sortie Tempo à 18:00
Lac de Tunis - 12km
[VOIR DÉTAILS]
```

**2. Reminder Notifications**
```
⏰ Dans 1 heure!
Sortie Tempo commence à 18:00
Point de rencontre: Lac de Tunis
[J'Y VAIS] [ANNULER]
```

**3. Announcement Notifications**
```
📢 Nouvelle annonce!
Coach Ahmed a partagé le programme de la semaine
[LIRE MAINTENANT]
```

**4. Group Updates**
```
👥 Mise à jour du groupe
Votre groupe a un nouveau programme
[CONSULTER]
```

**Notification Settings (User Can Control):**
```
┌─────────────────────────────────────┐
│  🔔 Notifications                   │
├─────────────────────────────────────┤
│  📅 Événements quotidiens      [ON] │
│  📅 Événements hebdomadaires   [ON] │
│  ⏰ Rappels 24h avant          [ON] │
│  ⏰ Rappels 1h avant           [ON] │
│  📢 Annonces du club           [ON] │
│  👥 Changements de groupe     [OFF] │
│  ⚙️ Mises à jour système      [OFF] │
│                                     │
│  🔇 HEURES CALMES                   │
│  De 22:00 à 07:00              [ON] │
│                                     │
│  📳 STYLE DE NOTIFICATION           │
│  • Son + Visuel               [✓]  │
│  • Visuel uniquement          [ ]  │
│  • Vibration uniquement       [ ]  │
│  • Son + Vibration            [ ]  │
└─────────────────────────────────────┘
```

---

#### **FEATURE 4: CLUB PRESENTATION** 🏛️

**Le Club Tab:**
```
┌─────────────────────────────────────┐
│  🏛️ Running Club Tunis              │
├─────────────────────────────────────┤
│  [HISTORIQUE] [GROUPES] [VALEURS]   │
│                                     │
│  📜 HISTORIQUE                       │
│  ┌───────────────────────────────┐  │
│  │ 2016: Fondation du club      │  │
│  │ Le 21 Avril 2016, un groupe  │  │
│  │ de passionnés...             │  │
│  │                              │  │
│  │ 2018: Premier marathon       │  │
│  │ Participation au Marathon    │  │
│  │ de Tunis...                  │  │
│  │                              │  │
│  │ 2023: Expansion              │  │
│  │ 125 membres actifs...        │  │
│  └───────────────────────────────┘  │
│                                     │
│  🏃 NOS GROUPES                      │
│  ┌───────────────────────────────┐  │
│  │ 🟢 DÉBUTANTS                 │  │
│  │ Niveau 1 | 7:00-8:00 min/km │  │
│  │ 3-8 km par sortie           │  │
│  │ 35 membres                   │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ 🟡 INTERMÉDIAIRES ⭐          │  │
│  │ Niveau 2 | 5:30-6:30 min/km │  │
│  │ 8-15 km par sortie          │  │
│  │ 45 membres (Votre groupe)    │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ 🔴 CONFIRMÉS                 │  │
│  │ Niveau 3 | 4:30-5:30 min/km │  │
│  │ 15-25 km par sortie         │  │
│  │ 45 membres                   │  │
│  └───────────────────────────────┘  │
│                                     │
│  💎 NOS VALEURS                      │
│  • Inclusivité                      │
│  • Esprit d'équipe                  │
│  • Progression                      │
│  • Santé                            │
│                                     │
│  🎯 NOS OBJECTIFS                    │
│  • Promouvoir la course à pied      │
│  • Créer une communauté solidaire   │
│  • Participer aux compétitions      │
│  • Améliorer la santé des membres   │
└─────────────────────────────────────┘
```

**User Can:**
- ✅ Read club history (FR/AR)
- ✅ View all running groups
- ✅ See their own group highlighted
- ✅ Understand club values
- ✅ Learn about club objectives

---

#### **FEATURE 5: EVENT HISTORY** 📜

**History Screen:**
```
┌─────────────────────────────────────┐
│  📜 Historique                      │
│  [Tous] [Mes participations]       │
├─────────────────────────────────────┤
│  FÉVRIER 2026                       │
│  ┌───────────────────────────────┐  │
│  │ ✅ Mer 05/02 - Tempo Run      │  │
│  │ 12km | Lac de Tunis          │  │
│  │ Allure: 5:45 min/km          │  │
│  │ 15 participants              │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ ✅ Sam 01/02 - Sortie Longue │  │
│  │ 22km | Lac 2                │  │
│  │ Allure: 6:10 min/km          │  │
│  │ 25 participants              │  │
│  └───────────────────────────────┘  │
│                                     │
│  JANVIER 2026                       │
│  ┌───────────────────────────────┐  │
│  │ ✅ Lun 27/01 - Sortie Tempo  │  │
│  │ 10km | Parc Belvédère       │  │
│  └───────────────────────────────┘  │
│                                     │
│  📊 VOS STATISTIQUES                │
│  • Total courses: 42                │
│  • Distance totale: 487 km          │
│  • Mois actif: Février 2026         │
└─────────────────────────────────────┘
```

**User Can:**
- ✅ View all past events
- ✅ Filter by their participations
- ✅ See event details (who participated, route, etc.)
- ✅ View personal statistics

---

#### **FEATURE 6: ANNOUNCEMENTS** 📢

**Announcements Screen:**
```
┌─────────────────────────────────────┐
│  📢 Annonces                        │
│  [Toutes] [Épinglées] [Mon groupe] │
├─────────────────────────────────────┤
│  📌 ÉPINGLÉ                          │
│  ┌───────────────────────────────┐  │
│  │ ⚠️ Changement d'horaire       │  │
│  │ Admin Principal • Il y a 2h   │  │
│  │                              │  │
│  │ Suite aux conditions météo,  │  │
│  │ la sortie de demain est      │  │
│  │ avancée à 17:00.             │  │
│  │                              │  │
│  │ 👥 Pour tous les groupes     │  │
│  │ [LIRE PLUS]                  │  │
│  └───────────────────────────────┘  │
│                                     │
│  AUJOURD'HUI                         │
│  ┌───────────────────────────────┐  │
│  │ 💪 Programme de la semaine   │  │
│  │ Coach Ahmed • Il y a 5h      │  │
│  │                              │  │
│  │ Voici le programme d'entraî- │  │
│  │ nement pour les Intermé-     │  │
│  │ diaires cette semaine...     │  │
│  │                              │  │
│  │ 🟡 Intermédiaires            │  │
│  │ 📎 Fichier joint: programme  │  │
│  │ [TÉLÉCHARGER]                │  │
│  └───────────────────────────────┘  │
│                                     │
│  HIER                                │
│  ┌───────────────────────────────┐  │
│  │ 🎉 Félicitations!            │  │
│  │ Admin de Groupe • Hier 20:00 │  │
│  │                              │  │
│  │ Bravo aux 18 participants    │  │
│  │ d'hier! Record de présence!  │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

**Announcement Types:**
- 📢 General announcements (all members)
- 🟡 Group-specific (only your group)
- 📌 Pinned (urgent/important)
- 💪 Training programs from coaches
- 🎉 Celebrations/achievements
- ⚠️ Schedule changes

**User Can:**
- ✅ Read all announcements
- ✅ Filter by their group
- ✅ Download attached files
- ✅ Mark as read
- ✅ See priority (low/normal/high/urgent)

---

#### **FEATURE 7: PROFILE & SETTINGS** ⚙️

**Profile Screen:**
```
┌─────────────────────────────────────┐
│  👤 Profil                          │
├─────────────────────────────────────┤
│  [Photo de profil]                  │
│                                     │
│  Fares Chakroun                     │
│  fares.chakroun@esprit.tn           │
│  📞 98 773 438                      │
│                                     │
│  🟡 INTERMÉDIAIRES                  │
│  Membre depuis: Avril 2016          │
│                                     │
│  📊 STATISTIQUES                     │
│  • 42 courses participées           │
│  • 487 km parcourus                 │
│  • Allure moyenne: 5:52 min/km      │
│                                     │
│  ⚙️ PARAMÈTRES                       │
│  ┌───────────────────────────────┐  │
│  │ 👁️ Accessibilité              │  │
│  │ [CONFIGURER]                 │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ 🔔 Notifications             │  │
│  │ [GÉRER]                      │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ 🌐 Langue                    │  │
│  │ Français [FR] ▼              │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ 🎨 Thème                     │  │
│  │ Clair / Sombre / Auto        │  │
│  └───────────────────────────────┘  │
│                                     │
│  ℹ️ À PROPOS                         │
│  • Version: 1.0.0                   │
│  • [Politique de confidentialité]  │
│  • [Conditions d'utilisation]      │
│  • [Nous contacter]                │
│                                     │
│  [🚪 DÉCONNEXION]                   │
└─────────────────────────────────────┘
```

**User Can:**
- ✅ View/edit profile information
- ✅ See running statistics
- ✅ Configure accessibility settings
- ✅ Manage notifications
- ✅ Change language (FR/EN/AR)
- ✅ Choose theme (light/dark/auto)
- ✅ Log out

---

## 🔔 NOTIFICATION FLOW

### **Scenario 1: Daily Event Notification**

```
Admin creates event "Tempo Run - Intermédiaires"
Event date: Friday 07/02 at 18:00
    ↓
System sends notification to ALL Intermédiaires members
    ↓
User receives: "🏃 Nouvelle course demain!"
Time: Thursday 06/02 at 18:00 (24h before)
    ↓
Notification shows:
- Event title
- Date & time
- Location
- [S'INSCRIRE] button
    ↓
User taps notification → Opens event details
User taps [S'INSCRIRE] → Registered!
    ↓
System adds user to participants list
System sends confirmation: "✅ Vous êtes inscrit!"
```

### **Scenario 2: Event Reminder**

```
User registered for event at 18:00
    ↓
System sends 1h reminder at 17:00
    ↓
Notification: "⏰ Dans 1 heure!"
"Tempo Run commence à 18:00"
"📍 Lac de Tunis - Entrée Sud"
[J'Y VAIS] [JE NE PEUX PLUS]
    ↓
User can confirm or cancel participation
```

### **Scenario 3: Announcement Notification**

```
Coach posts training program
Target: Intermédiaires group
    ↓
System sends to all Intermédiaires
    ↓
User receives: "📢 Nouveau programme!"
"Coach Ahmed a partagé le programme"
[LIRE]
    ↓
User taps → Opens announcement
User downloads attached file
```

---

## 📱 SCREEN FLOW SUMMARY

```
Splash Screen
    ↓
Accessibility Wizard (first launch)
    ↓
Login Screen
    ↓
Home Screen (Main Hub)
    ├─ Today's Run → Event Details → Register
    ├─ Events Tab → Event List → Event Details
    ├─ Club Tab → History / Groups / Values
    ├─ Announcements Tab → Read announcements
    └─ Profile Tab → Settings / Statistics / Logout
```

---

## 🎯 KEY USER ACTIONS (Priority Order)

### **MUST HAVE (MVP)**
1. ✅ Login with name + CIN
2. ✅ View today's run for their group
3. ✅ Register for events
4. ✅ Receive notifications
5. ✅ View event details
6. ✅ View club information

### **SHOULD HAVE**
7. ✅ View event history
8. ✅ Read announcements
9. ✅ Configure accessibility settings
10. ✅ View personal statistics
11. ✅ Manage notification preferences
12. ✅ View map for meeting points

### **NICE TO HAVE**
13. ✅ Share events with friends
14. ✅ Add events to calendar
15. ✅ Download training programs
16. ✅ View who's coming to events
17. ✅ Multi-language support (FR/EN/AR)

---

## 📊 USER DATA STRUCTURE

```javascript
// Firestore: users/{userId}
{
  // Identity
  userId: "user123",
  fullName: "Fares Chakroun",
  email: "fares.chakroun@esprit.tn",
  phone: "98773438",
  cin: "encrypted:12345678",
  pinHash: "hash_of_678",
  
  // Role & Permissions
  role: "user",  // adhérant
  permissions: {
    canCreateEvents: false,
    canViewEvents: true,
    canRegisterForEvents: true,
    canViewHistory: true,
    canReceiveNotifications: true
  },
  
  // Group Assignment
  groupId: "intermediate",
  groupName: "Intermédiaires",
  groupColor: "#FFC107",
  groupHistory: [
    {
      groupId: "beginner",
      assignedBy: "admin123",
      startDate: Timestamp(2016-04-21),
      endDate: Timestamp(2017-06-15),
      reason: "Progression"
    },
    {
      groupId: "intermediate",
      assignedBy: "admin123",
      startDate: Timestamp(2017-06-16),
      endDate: null,
      reason: "Niveau atteint"
    }
  ],
  
  // Status
  isActive: true,
  accountStatus: "active",
  memberSince: Timestamp(2016-04-21),
  
  // Preferences
  notificationPreferences: {
    dailyEvents: true,
    weeklyEvents: true,
    announcements: true,
    reminders24h: true,
    reminders1h: true,
    quietHoursEnabled: true,
    quietHoursStart: "22:00",
    quietHoursEnd: "07:00"
  },
  
  // Statistics
  stats: {
    totalEventsJoined: 42,
    totalDistance: 487,  // km
    averagePace: 352,    // seconds per km (5:52)
    lastEventDate: Timestamp,
    consecutiveWeeks: 8
  },
  
  // FCM Token for notifications
  fcmToken: "device-token-here",
  
  // Timestamps
  createdAt: Timestamp,
  updatedAt: Timestamp,
  lastLogin: Timestamp
}
```

---

This is the complete specification for what a regular USER (Adhérant) does in your app!

Would you like me to:
1. Create the actual Flutter screens for these features?
2. Build the event registration system?
3. Implement the notification system?
4. Create the Firebase security rules for user permissions?

Let me know what you want to implement next! 🚀
