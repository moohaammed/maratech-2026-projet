# 🎯 QUICK REFERENCE - USER (ADHÉRANT) FEATURES
## Running Club Tunis - What Can Members Do?

---

## 📱 **5 MAIN SCREENS**

### **1. HOME SCREEN** 🏠
**Purpose:** Daily dashboard

**User sees:**
- Today's run for their group
- Upcoming events (this week)
- Quick action buttons
- Notification badge

**User can:**
- Register for today's run (1 tap)
- View event details
- Access other sections

---

### **2. EVENTS SCREEN** 📅
**Purpose:** Browse all running events

**User sees:**
- All events (daily + weekly)
- Calendar view
- Filters (my group, all groups, registered)

**Types:**
- **Daily runs** (18:00, each group)
- **Long runs** (Saturdays, all groups)
- **Special events** (races, challenges)

**User can:**
- View event details
- Register/unregister
- Filter by group/date
- Add to calendar

---

### **3. CLUB INFO SCREEN** 🏛️
**Purpose:** Learn about Running Club Tunis

**User sees:**
- Club history (2016-present)
- Running groups (Débutants/Intermédiaires/Confirmés)
- Club values & objectives
- Contact information

**User can:**
- Read club story
- Understand group levels
- See their group highlighted

---

### **4. ANNOUNCEMENTS SCREEN** 📢
**Purpose:** Stay informed

**User sees:**
- Announcements from admins
- Training programs from coaches
- Schedule changes
- Achievements & celebrations

**Types:**
- General (all members)
- Group-specific
- Pinned (urgent)
- With attachments (PDFs, images)

**User can:**
- Read announcements
- Download files
- Filter by group
- Mark as read

---

### **5. PROFILE SCREEN** 👤
**Purpose:** Manage account & settings

**User sees:**
- Personal information
- Group assignment
- Running statistics
- Settings options

**User can:**
- View stats (distance, events, pace)
- Configure accessibility
- Manage notifications
- Change language/theme
- Log out

---

## 🔔 **NOTIFICATIONS**

### **What User Receives:**

1. **Event Created** (24h before)
   ```
   🏃 Nouvelle course demain!
   Tempo Run - Intermédiaires
   18:00 à Lac de Tunis
   [S'INSCRIRE]
   ```

2. **Event Reminder** (1h before)
   ```
   ⏰ Dans 1 heure!
   Tempo Run commence à 18:00
   📍 Lac de Tunis
   [J'Y VAIS]
   ```

3. **Announcement**
   ```
   📢 Nouveau programme!
   Coach Ahmed a partagé le programme
   [LIRE]
   ```

4. **Event Update**
   ```
   ⚠️ Changement d'horaire
   La course de demain est avancée
   [VOIR DÉTAILS]
   ```

### **User Can Control:**
- ✅ Enable/disable per type
- ✅ Set quiet hours (22:00-07:00)
- ✅ Choose style (sound/visual/vibration)
- ✅ Reminder timing (24h, 1h)

---

## 🏃 **EVENT REGISTRATION FLOW**

### **Simple Registration:**
```
1. User sees event on home screen
2. Taps event card
3. Reviews details (location, time, distance)
4. Taps [S'INSCRIRE] button
5. System adds to participants
6. User receives confirmation
7. User gets reminders (24h, 1h before)
```

### **Unregister:**
```
1. User opens registered event
2. Taps [SE DÉSINSCRIRE]
3. System removes from participants
4. Notifications canceled
```

---

## 👥 **GROUP SYSTEM**

### **3 Groups:**

**🟢 DÉBUTANTS (Beginners)**
- Level 1
- Pace: 7:00-8:00 min/km
- Distance: 3-8 km
- ~35 members

**🟡 INTERMÉDIAIRES (Intermediate)**
- Level 2
- Pace: 5:30-6:30 min/km
- Distance: 8-15 km
- ~45 members

**🔴 CONFIRMÉS (Advanced)**
- Level 3
- Pace: 4:30-5:30 min/km
- Distance: 15-25 km
- ~45 members

### **User's Group:**
- Assigned by Admin Principal
- Shown on profile & home screen
- Determines which events they see first
- Can be changed by admins

---

## 📊 **USER STATISTICS**

**Tracked Automatically:**
- Total events participated
- Total distance (km)
- Average pace (min/km)
- Consecutive weeks active
- Member since date

**Displayed:**
- On profile screen
- In event history
- Personal dashboard

---

## 🌐 **MULTI-LANGUAGE**

**Supported:**
- 🇫🇷 Français (default)
- 🇬🇧 English
- 🇹🇳 العربية (Arabic)

**Where:**
- All UI text
- Announcements
- Event descriptions
- Notifications

**User Can:**
- Switch language in settings
- See content in preferred language
- App RTL support for Arabic

---

## ♿ **ACCESSIBILITY**

**Visual:**
- Text size: 100%-200%
- High contrast mode
- Bold text option
- Color blind friendly

**Audio:**
- Visual notifications (no sound)
- Vibration patterns
- Flash alerts
- Captions

**Motor:**
- Large touch targets (48dp+)
- Simplified gestures
- Voice control ready
- One-handed mode

**Settings:**
- Configured in wizard (first launch)
- Can be changed anytime
- Saves to Firebase
- Applies everywhere

---

## 🔐 **LOGIN SYSTEM**

**Credentials:**
- Username: Full name
- Password: Last 3 digits of CIN

**Example:**
```
Name: Fares Chakroun
CIN: 12345678
Password: 678
```

**Security:**
- CIN encrypted in database
- Password hashed (SHA-256)
- Firebase Authentication
- Secure session

**First Login:**
1. Admin creates account
2. Admin assigns to group
3. User receives credentials
4. User completes accessibility wizard
5. User can start using app

---

## 📍 **EVENT LOCATIONS**

**Common Meeting Points:**
- Lac de Tunis (multiple entrées)
- Parc du Belvédère
- Lac 2 (Ennahli)
- Centre Urbain Nord
- Carthage

**Each Location Has:**
- Name (FR/AR)
- Address
- GPS coordinates
- Map link
- Parking info
- Public transport info

**User Can:**
- View on map
- Get directions
- See landmarks
- Share location

---

## 🎯 **USER PERMISSIONS**

**What User CAN Do:**
- ✅ View events for their group
- ✅ View events for all groups
- ✅ Register for any event
- ✅ Unregister from events
- ✅ Read announcements
- ✅ Download attachments
- ✅ View club information
- ✅ View event history
- ✅ See statistics
- ✅ Configure settings
- ✅ Receive notifications

**What User CANNOT Do:**
- ❌ Create events
- ❌ Edit events
- ❌ Delete events
- ❌ Post announcements
- ❌ Manage other users
- ❌ Change group assignments
- ❌ Access admin panel

---

## 📱 **OFFLINE FEATURES**

**Works Without Internet:**
- ✅ View downloaded events
- ✅ Read cached announcements
- ✅ View club information
- ✅ Access profile data
- ✅ View statistics

**Requires Internet:**
- ❌ Register for events
- ❌ Receive notifications
- ❌ See new announcements
- ❌ Update profile
- ❌ Sync with cloud

**Auto-Sync:**
- When internet returns
- On app open
- Every 30 minutes (background)

---

## 🚀 **MVP FEATURES (PRIORITY)**

### **MUST HAVE (Phase 1):**
1. ✅ Login
2. ✅ View today's run
3. ✅ Register for events
4. ✅ Receive notifications
5. ✅ View club info

### **SHOULD HAVE (Phase 2):**
6. ✅ View all events
7. ✅ Read announcements
8. ✅ View history
9. ✅ Configure settings
10. ✅ View statistics

### **NICE TO HAVE (Phase 3):**
11. ✅ Share events
12. ✅ Add to calendar
13. ✅ Download files
14. ✅ View participants
15. ✅ Multi-language

---

## 💡 **USER TIPS**

**For Best Experience:**
- ✅ Complete accessibility wizard
- ✅ Enable notifications
- ✅ Check app before each run
- ✅ Register early (limited spots)
- ✅ Update profile info
- ✅ Set quiet hours

**Common Actions:**
- Home → Today's run → Register (3 taps)
- Events → Filter "My group" (2 taps)
- Notifications → Tap → Open event (1 tap)

---

This is your complete quick reference for USER (Adhérant) features! 🏃‍♂️
