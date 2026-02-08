import {
    collection,
    doc,
    addDoc,
    updateDoc,
    deleteDoc,
    getDoc,
    getDocs,
    query,
    where,
    orderBy,
    Timestamp,
    serverTimestamp,
    onSnapshot
} from 'firebase/firestore';
import { db } from '../../lib/firebase';
import { RunningGroup } from './UserService';

export const EventType = {
    DAILY: 'daily',
    WEEKLY: 'weekly',
};

export const WeeklyEventSubType = {
    LONG_RUN: 'longRun',
    SPECIAL_EVENT: 'specialEvent',
};

export class EventModel {
    constructor({
        id,
        title,
        description,
        type,
        weeklySubType,
        group,
        date,
        time,
        startTime,
        endTime,
        duration,
        location,
        meetingPoint,
        route,
        distanceKm,
        targetPace,
        intensity,
        category,
        status,
        isAllGroups,
        isCancelled,
        isFeatured,
        isPinned,
        maxParticipants,
        participants,
        participantCount,
        waitlist,
        accessibility,
        parkingAvailable,
        publicTransport,
        groupId,
        groupName,
        groupColor,
        createdAt,
        createdBy,
        creatorName,
        creatorRole,
        publishedAt,
        updatedAt,
    }) {
        this.id = id;
        this.title = title;
        this.description = description;
        this.type = type;
        this.weeklySubType = weeklySubType;
        this.group = group;
        this.date = date; // JS Date object
        this.time = time;
        this.startTime = startTime;
        this.endTime = endTime;
        this.duration = duration;
        this.location = location;
        this.meetingPoint = meetingPoint;
        this.route = route;
        this.distanceKm = distanceKm;
        this.targetPace = targetPace;
        this.intensity = intensity;
        this.category = category;
        this.status = status;
        this.isAllGroups = isAllGroups;
        this.isCancelled = isCancelled;
        this.isFeatured = isFeatured;
        this.isPinned = isPinned;
        this.maxParticipants = maxParticipants;
        this.participants = participants;
        this.participantCount = participantCount;
        this.waitlist = waitlist;
        this.accessibility = accessibility;
        this.parkingAvailable = parkingAvailable;
        this.publicTransport = publicTransport;
        this.groupId = groupId;
        this.groupName = groupName;
        this.groupColor = groupColor;
        this.createdAt = createdAt;
        this.createdBy = createdBy;
        this.creatorName = creatorName;
        this.creatorRole = creatorRole;
        this.publishedAt = publishedAt;
        this.updatedAt = updatedAt;
    }

    static fromFirestore(doc) {
        const data = doc.data();
        return new EventModel({
            id: doc.id,
            title: data.title || '',
            description: data.description,
            type: normalizeEventType(data.type) || EventType.DAILY,
            weeklySubType: normalizeWeeklySubType(data.weeklySubType),
            group: data.group,
            date: data.date?.toDate() || new Date(),
            time: data.time || data.startTime || '09:00',
            startTime: data.startTime,
            endTime: data.endTime,
            duration: data.duration,
            location: data.location || '',
            meetingPoint: data.meetingPoint,
            route: data.route,
            distanceKm: data.distanceKm,
            targetPace: data.targetPace,
            intensity: data.intensity,
            category: data.category,
            status: data.status,
            isAllGroups: data.isAllGroups,
            isCancelled: data.isCancelled,
            isFeatured: data.isFeatured,
            isPinned: data.isPinned,
            maxParticipants: data.maxParticipants,
            participants: data.participants,
            participantCount: data.participantCount,
            waitlist: data.waitlist,
            accessibility: data.accessibility,
            parkingAvailable: data.parkingAvailable,
            publicTransport: data.publicTransport,
            groupId: data.groupId,
            groupName: data.groupName,
            groupColor: data.groupColor,
            createdAt: data.createdAt?.toDate() || new Date(),
            createdBy: data.createdBy,
            creatorName: data.creatorName,
            creatorRole: data.creatorRole,
            publishedAt: data.publishedAt?.toDate(),
            updatedAt: data.updatedAt?.toDate(),
        });
    }

    toFirestore() {
        const payload = {
            title: this.title,
            description: this.description,
            type: this.type,
            weeklySubType: this.weeklySubType,
            group: this.group,
            date: this.date ? Timestamp.fromDate(this.date) : serverTimestamp(),
            time: this.time,
            startTime: this.startTime,
            endTime: this.endTime,
            duration: this.duration,
            location: this.location,
            meetingPoint: this.meetingPoint,
            route: this.route,
            distanceKm: this.distanceKm,
            targetPace: this.targetPace,
            intensity: this.intensity,
            category: this.category,
            status: this.status,
            isAllGroups: this.isAllGroups,
            isCancelled: this.isCancelled,
            isFeatured: this.isFeatured,
            isPinned: this.isPinned,
            maxParticipants: this.maxParticipants,
            participants: this.participants,
            participantCount: this.participantCount,
            waitlist: this.waitlist,
            accessibility: this.accessibility,
            parkingAvailable: this.parkingAvailable,
            publicTransport: this.publicTransport,
            groupId: this.groupId,
            groupName: this.groupName,
            groupColor: this.groupColor,
            createdAt: this.createdAt ? Timestamp.fromDate(this.createdAt) : serverTimestamp(),
            createdBy: this.createdBy,
            creatorName: this.creatorName,
            creatorRole: this.creatorRole,
            publishedAt: this.publishedAt ? Timestamp.fromDate(this.publishedAt) : serverTimestamp(),
            updatedAt: this.updatedAt ? Timestamp.fromDate(this.updatedAt) : serverTimestamp(),
        };

        // Remove undefined fields so Firestore doesn't store them as null unintentionally.
        Object.keys(payload).forEach((k) => {
            if (payload[k] === undefined) delete payload[k];
        });

        return payload;
    }

    get typeDisplayName() {
        switch (this.type) {
            case EventType.DAILY: return 'Quotidien';
            case EventType.WEEKLY: return 'Hebdomadaire';
            default: return '';
        }
    }

    get weeklySubTypeDisplayName() {
        if (!this.weeklySubType) return '';
        switch (this.weeklySubType) {
            case WeeklyEventSubType.LONG_RUN: return 'Sortie longue';
            case WeeklyEventSubType.SPECIAL_EVENT: return 'Course officielle';
            default: return '';
        }
    }

    get groupDisplayName() {
        if (!this.group) return 'Tous les groupes';
        // Mapping from RunningGroup enum in UserService
        switch (this.group) {
            case RunningGroup.GROUP1: return 'Groupe 1';
            case RunningGroup.GROUP2: return 'Groupe 2';
            case RunningGroup.GROUP3: return 'Groupe 3';
            case RunningGroup.GROUP4: return 'Groupe 4';
            case RunningGroup.GROUP5: return 'Groupe 5';
            default: return 'Groupe Inconnu';
        }
    }
}

export const EventService = {
    get eventsCollection() {
        return collection(db, 'events');
    },

    // Stream events with optional filters
    getEventsStream({ fromDate, toDate, group }, onData, onError) {
        let q = query(this.eventsCollection, orderBy('date', 'asc'));

        if (fromDate) {
            q = query(q, where('date', '>=', Timestamp.fromDate(fromDate)));
        }
        if (toDate) {
            q = query(q, where('date', '<=', Timestamp.fromDate(toDate)));
        }

        return onSnapshot(q, (snapshot) => {
            let events = snapshot.docs.map(doc => EventModel.fromFirestore(doc));

            // Client-side filtering for group to avoid composite index requirement
            if (group) {
                events = events.filter(e => e.group === group);
            }

            onData(events);
        }, onError);
    },

    async createEvent(eventModel) {
        const docRef = await addDoc(this.eventsCollection, eventModel.toFirestore());
        return docRef.id;
    },

    async updateEvent(eventId, eventData) {
        // If eventData is EventModel, call toFirestore, else use as is
        const data = eventData instanceof EventModel ? eventData.toFirestore() : eventData;
        await updateDoc(doc(db, 'events', eventId), data);
    },

    async deleteEvent(eventId) {
        await deleteDoc(doc(db, 'events', eventId));
    },

    async getEventById(eventId) {
        const docSnap = await getDoc(doc(db, 'events', eventId));
        if (docSnap.exists()) {
            return EventModel.fromFirestore(docSnap);
        }
        return null;
    }
};

function normalizeEventType(raw) {
    if (!raw) return null;
    if (raw === EventType.DAILY || raw === EventType.WEEKLY) return raw;
    if (raw === 'EventType.daily') return EventType.DAILY;
    if (raw === 'EventType.weekly') return EventType.WEEKLY;
    if (raw === 'daily') return EventType.DAILY;
    if (raw === 'weekly') return EventType.WEEKLY;
    return null;
}

function normalizeWeeklySubType(raw) {
    if (!raw) return null;
    if (raw === WeeklyEventSubType.LONG_RUN || raw === WeeklyEventSubType.SPECIAL_EVENT) return raw;
    if (raw === 'WeeklyEventSubType.longRun') return WeeklyEventSubType.LONG_RUN;
    if (raw === 'WeeklyEventSubType.specialEvent') return WeeklyEventSubType.SPECIAL_EVENT;
    if (raw === 'longRun') return WeeklyEventSubType.LONG_RUN;
    if (raw === 'specialEvent') return WeeklyEventSubType.SPECIAL_EVENT;
    return null;
}
