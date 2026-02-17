# AMAVEL Architecture Documentation

## Executive Summary

AMAVEL is a distributed, cloud-native system designed to provide AI-powered companionship to seniors with automatic memory extraction, emotional state monitoring, and family alerting. The system uses a client-server architecture with Firebase as the primary backend, OpenAI/Claude for conversational AI, and Google Cloud Functions for async processing.

**Current Version:** 1.0 (MVP)
**Target Deployment:** EU-region (europe-west1)
**Primary User Base:** Seniors 65+, with secondary family member access
**Scalability Target:** 10,000+ concurrent users within 18 months

---

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        AMAVEL System Architecture                │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────┐         ┌──────────────────────┐
│  Senior Tablet      │         │  Family Mobile App   │
│  (Android 9.0+)     │         │  (Android 9.0+)      │
│                     │         │                      │
│ - Voice Input       │         │ - Mood Dashboard     │
│ - Chat Interface    │         │ - Memory View        │
│ - Onboarding Flow   │         │ - Distress Alerts    │
│ - Settings          │         │ - Link Management    │
└──────────┬──────────┘         └──────────┬───────────┘
           │                               │
           └──────────┬────────────────────┘
                      │ HTTPS
                      ▼
        ┌─────────────────────────────────┐
        │   Firebase Cloud Services       │
        │   (europe-west1)                │
        │                                 │
        │ ┌──────────────────────────────┐│
        │ │  Authentication (Anonymous)  ││
        │ │  - Session tokens            ││
        │ │  - User identity mgmt        ││
        │ └──────────────────────────────┘│
        │ ┌──────────────────────────────┐│
        │ │  Firestore Database          ││
        │ │  - Users, conversations      ││
        │ │  - Memories, family links    ││
        │ │  - System logs               ││
        │ └──────────────────────────────┘│
        │ ┌──────────────────────────────┐│
        │ │  Cloud Storage               ││
        │ │  - Profile photos            ││
        │ │  - Audio recordings (opt)    ││
        │ └──────────────────────────────┘│
        │ ┌──────────────────────────────┐│
        │ │  Cloud Messaging             ││
        │ │  - Distress alerts to family ││
        │ │  - Family notifications      ││
        │ └──────────────────────────────┘│
        │ ┌──────────────────────────────┐│
        │ │  Cloud Functions             ││
        │ │  - Memory extraction         ││
        │ │  - Distress detection        ││
        │ │  - Mood analysis             ││
        │ └──────────────────────────────┘│
        └─────────────────────────────────┘
                      │
         ┌────────────┼────────────┐
         │            │            │
         ▼            ▼            ▼
    ┌─────────┐ ┌─────────┐ ┌──────────┐
    │  OpenAI │ │Anthropic│ │  Google  │
    │   GPT   │ │ Claude  │ │  Speech  │
    │  (text) │ │(fallback)│ │  to Text │
    │         │ │         │ │(backup)  │
    └─────────┘ └─────────┘ └──────────┘
         │
         ▼
    ┌──────────┐
    │  Azure   │
    │  Neural  │
    │   TTS    │
    │(backup)  │
    └──────────┘
```

---

## Technical Stack

### Core Technologies

| Component | Technology | Version | Purpose |
|---|---|---|---|
| **Senior App** | Android (Kotlin) | 9.0+ | Primary user interface |
| **Family App** | Android (Kotlin) | 9.0+ | Secondary user interface |
| **Backend** | Google Firebase | 9.x | Data, auth, messaging |
| **Primary LLM** | OpenAI GPT-4 | 4 | Main conversational AI |
| **Fallback LLM** | Anthropic Claude | 3.5 | Backup conversation engine |
| **Cloud Functions** | Node.js | 18.x LTS | Async processing, pipelines |
| **Authentication** | Firebase Auth | 9.x | Anonymous + email based |
| **Database** | Cloud Firestore | - | NoSQL document store |
| **File Storage** | Cloud Storage | - | Media files, backups |
| **Messaging** | Cloud Messaging | - | Push notifications |
| **Speech-to-Text** | OpenAI Whisper (primary), Google Cloud Speech-to-Text (backup) | Latest | Audio transcription |
| **Text-to-Speech** | OpenAI TTS (primary), Azure Neural TTS (backup) | Latest | Voice synthesis |
| **Monitoring** | Cloud Logging | - | System telemetry |
| **VCS** | GitHub | - | Code versioning, CI/CD |

### Development Tools

| Tool | Purpose | Version |
|---|---|---|
| Android Studio | IDE for Kotlin development | Latest |
| Firebase CLI | Deployment & management | 11.x |
| Node.js | Runtime for Cloud Functions | 18.x |
| Gradle | Build system for Android | 7.x+ |
| GitHub Actions | CI/CD pipeline | Built-in |

---

## Data Model & Firestore Schema

### Collection: `users/{userId}`

Represents an authenticated user (senior or family member).

```javascript
{
  userId: string,              // Firebase UID
  userType: "senior" | "family",
  profile: {
    name: string,              // Full name
    birthDate: ISO8601,        // Date of birth
    email: string,             // Contact email
    phone: string,             // Contact number
    preferredLanguage: "pt-PT" | "en-US" | ...,
    timezone: string,          // e.g., "Europe/Lisbon"
    onboardingComplete: boolean,
    createdAt: timestamp,
    lastActive: timestamp
  },
  settings: {
    voiceEnabled: boolean,
    avatarName: string,        // "Sofia" (default), customizable
    avatarVoice: string,       // Voice ID for TTS
    emotionalSensitivity: "low" | "medium" | "high",
    distressAlertThreshold: number, // 0-1 scale
    privacyMode: boolean       // Disable audio recording
  },
  aiConfig: {
    personality: string,       // "compassionate", "encouraging", etc.
    memoryDepth: number,       // How many past memories to consider
    responseLength: "brief" | "normal" | "detailed"
  }
}
```

**Security:** Only the user's own document can be read/written by that user.

---

### Subcollection: `users/{userId}/profile/{profileDocs}`

Extended profile information (photos, biographical details).

```javascript
{
  profilePhotoUrl: string,    // URL to Cloud Storage image
  biography: string,          // "About me" text (500 chars max)
  interests: [string],        // ["gardening", "reading", "cooking"]
  hobbies: [string],
  familyComposition: string,  // "Has 2 adult children, 4 grandchildren"
  significantEvents: [string] // ["retired 2015", "married 1975"]
}
```

---

### Subcollection: `users/{userId}/conversations/{conversationId}`

Records of all voice and text conversations.

```javascript
{
  conversationId: string,      // UUID
  timestamp: ISO8601,
  duration: number,            // seconds
  userMessage: string,         // Transcript of user input
  userAudioUrl: string,        // (Optional) URL to raw audio file
  avatarResponse: string,      // AMAVEL's text response
  avatarAudioUrl: string,      // URL to synthesized audio
  metadata: {
    inputMethod: "voice" | "text",
    transcriptionConfidence: number, // 0-1
    responseLatency: number,    // milliseconds
    modelUsed: "openai" | "anthropic",
    emotionalTone: string,      // "positive", "neutral", "sad", "anxious"
    hasFollowUp: boolean        // Did user continue conversation?
  },
  extracted: {
    memoryExtracted: string,    // If memory was extracted
    distressDetected: boolean,  // True if emotional crisis detected
    distressScore: number       // 0-1 scale
  }
}
```

**Indexing:** Queried by `timestamp` (most recent first).

---

### Subcollection: `users/{userId}/memories/{memoryId}`

Automatically extracted or manually entered life memories.

```javascript
{
  memoryId: string,
  timestamp: timestamp,        // When memory was created
  source: "extracted" | "manual" | "imported",
  sourceConversationId: string,// Reference to conversation where extracted

  content: {
    title: string,             // "Grandmother's Garden"
    description: string,       // Full memory text
    extractionScore: number,   // 0-1 confidence (auto-extracted only)
    keywords: [string],        // ["gardening", "grandson", "1995"]
    category: string,          // "family", "work", "hobby", "travel", etc.
    emotionalValence: "positive" | "neutral" | "negative"
  },

  details: {
    year: number,              // Approximate year (if mentioned)
    people: [string],          // Names of people mentioned
    places: [string],          // Locations mentioned
    relatedMemories: [string]  // IDs of linked memories
  },

  engagement: {
    accessCount: number,       // How many times retrieved
    lastAccessedAt: timestamp,
    isFavorite: boolean        // Marked as important
  }
}
```

---

### Subcollection: `users/{userId}/family/{familyMemberId}`

Links to family members with permissions.

```javascript
{
  familyMemberId: string,      // Firebase UID of family member
  relationship: "child" | "spouse" | "sibling" | "friend" | "carer",
  linkedAt: timestamp,

  permissions: {
    canViewConversations: boolean,
    canViewMemories: boolean,
    canReceiveAlerts: boolean,
    canModifySettings: boolean, // Usually false
    alertOn: {
      distress: boolean,       // Alert on distress
      inactivity: boolean,     // Alert if no activity 24h+
      moodChange: boolean,     // Alert on mood shift
      urgentMessages: boolean  // Alert on urgent requests
    }
  },

  metadata: {
    notificationEmail: string,
    notificationPhone: string,
    language: string
  }
}
```

---

### Subcollection: `users/{userId}/emotionalStates/{stateId}`

Periodic emotional state snapshots (auto-generated by Cloud Function).

```javascript
{
  stateId: string,
  timestamp: timestamp,

  assessment: {
    overallMood: number,       // 1-10 scale
    emotionalTone: string,     // "happy", "calm", "anxious", "sad", etc.
    loneliness: number,        // 1-10
    engagement: number,        // 1-10 (how engaged in conversation)
    anxiety: number,           // 1-10
    hopefulness: number        // 1-10
  },

  indicators: {
    conversationCount: number, // Conv. in last 24h
    memoryAccessCount: number, // Memories revisited
    familyContactInitiated: boolean,
    responsiveness: "high" | "medium" | "low",
    conversationQuality: string// "engaged", "brief", "distressed"
  },

  trends: {
    comparedToYesterday: "better" | "same" | "worse",
    comparedToLastWeek: string,
    consistencyScore: number   // 0-1 (how consistent is pattern)
  }
}
```

---

### Root Collection: `logs/{logId}`

System events, errors, and audit trail.

```javascript
{
  logId: string,
  timestamp: timestamp,

  event: {
    type: "api_call" | "error" | "user_action" | "system_event",
    service: string,           // "openai", "firebase", "function", etc.
    action: string,            // Specific action performed
    status: "success" | "error" | "pending"
  },

  userId: string,              // (if applicable)
  details: {
    errorMessage: string,      // (if error)
    statusCode: number,        // HTTP status
    latency: number,           // milliseconds
    metadata: object           // Custom data
  }
}
```

**TTL:** Logs older than 90 days are automatically deleted.

---

## API Integrations

### 1. OpenAI API (Primary LLM)

**Endpoint:** `https://api.openai.com/v1/chat/completions`

**Usage:**
- Text conversation generation
- Memory extraction from conversations
- Emotional state analysis
- Distress severity assessment

**Request Example:**
```json
{
  "model": "gpt-4",
  "messages": [
    {"role": "system", "content": "You are AMAVEL, an AI companion..."},
    {"role": "user", "content": "What did I tell you about my garden?"}
  ],
  "temperature": 0.7,
  "max_tokens": 150
}
```

**Pricing:** ~$0.001 per 100 tokens (~5 conversations per day = $5-10/month)

**Fallback:** If OpenAI is unavailable, route to Anthropic Claude.

---

### 2. Anthropic Claude API (Fallback LLM)

**Endpoint:** `https://api.anthropic.com/v1/messages`

**Usage:**
- Backup conversational AI
- More censored responses for sensitive topics

**Fallback Chain:**
```
OpenAI GPT-4 → (if error or rate limit) → Anthropic Claude 3.5
```

**Pricing:** ~$0.003 per 100 tokens (backup only, minimal usage)

---

### 3. Google Cloud Speech-to-Text API (Backup)

**Endpoint:** `https://speech.googleapis.com/v1/speech:recognize`

**Usage:**
- Convert audio to text (backup if OpenAI Whisper fails)
- Multi-language support
- Confidence scoring

**Request Example:**
```json
{
  "config": {
    "encoding": "LINEAR16",
    "language_code": "pt-PT",
    "audio_channel_count": 1
  },
  "audio": {
    "content": "base64_encoded_audio"
  }
}
```

**Fallback Chain:**
```
OpenAI Whisper → (if error) → Google Cloud Speech-to-Text
```

---

### 4. Azure Neural Text-to-Speech (Backup)

**Endpoint:** `https://<region>.tts.speech.microsoft.com/cognitiveservices/v1`

**Usage:**
- Natural voice synthesis (backup)
- Multiple voice options in Portuguese

**Request Headers:**
```
Authorization: Bearer <token>
X-Microsoft-OutputFormat: audio-16khz-32kbitrate-mono-mp3
Content-Type: application/ssml+xml
```

**Fallback Chain:**
```
OpenAI TTS → (if error) → Azure Neural TTS
```

---

## Data Flow Diagrams

### Flow 1: Voice Conversation Pipeline

```
Senior speaks into tablet
        │
        ▼
   Audio captured
        │
        ▼
   Audio sent to backend (Firebase)
        │
        ▼
   Google Cloud Function triggered
        │
    ┌───┴───┐
    │       │
    ▼       ▼
 Whisper  Google Cloud
  (primary) STT (backup)
    │       │
    └───┬───┘
        │ Transcription
        ▼
  Store in Firestore
        │
        ▼
  Call OpenAI Chat API
        │
    ┌───┴───┐
    │       │ (if error/rate limit)
    ▼       ▼
  GPT-4   Claude
  (primary) (fallback)
    │       │
    └───┬───┘
        │ Response text
        ▼
  Store in Firestore
        │
        ▼
  Synthesize with TTS
        │
    ┌───┴───┐
    │       │
    ▼       ▼
  OpenAI  Azure Neural
  TTS     TTS
  (primary)(fallback)
    │       │
    └───┬───┘
        │ Audio file
        ▼
  Store in Cloud Storage
        │
        ▼
  Return audio URL to app
        │
        ▼
  Play audio on tablet speakers
        │
        ▼
  Extract memory (async job)
        │
        ▼
  Analyze emotion (async job)
        │
        ▼
  Check for distress (async job)
```

---

### Flow 2: Memory Extraction Pipeline

```
Conversation stored in Firestore
        │
        ▼
 Cloud Function triggered
 (on_conversation_complete)
        │
        ▼
 Retrieve conversation history
 (last 10 conversations)
        │
        ▼
 Call OpenAI with prompt:
 "Extract important memories from this conversation.
  Return: title, description, category, keywords"
        │
        ▼
 Parse OpenAI response
        │
        ▼
 Score memory for relevance/importance
        │
        ▼
 If score > 0.7:
   Store in users/{userId}/memories
   Update memory index
        │
        ▼
 Link to source conversation
        │
        ▼
 Update user's memory count
```

---

### Flow 3: Distress Detection Pipeline

```
Conversation stored in Firestore
        │
        ▼
 Cloud Function triggered
 (on_conversation_change)
        │
        ▼
 Extract emotional keywords:
 • Negative words: "depressed", "alone", "hurt", "suicide"
 • Isolation signals: "no one", "nobody", "abandoned"
 • Physical distress: "pain", "sick", "dying"
 • Suicidal ideation: specific suicide references
        │
        ▼
 Score distress level (0-1 scale)
        │
        ▼
 If score > threshold (e.g., 0.6):
   Create alert in Firestore
   Mark conversation with distress flag
   Notify family via Cloud Messaging
   Store alert timestamp
        │
        ▼
 If score > critical (e.g., 0.9):
   Send priority alert to ALL family members
   Include conversation excerpt
   Provide emergency contact suggestions
   Log to system audit trail
        │
        ▼
 Email alert to family members
 (if emails configured)
        │
        ▼
 Push notification to Family App
 (if device registered)
```

---

### Flow 4: Family App Data Sync

```
Family member opens app
        │
        ▼
 Authenticate with Firebase
        │
        ▼
 Query Firestore:
 "Show me conversations from linked senior
  in last 7 days with mood assessments"
        │
        ▼
 Retrieve:
 • Mood trend chart
 • Last 5 conversation summaries
 • Recent memory extractions
 • Distress alerts (if any)
 • Family messages waiting
        │
        ▼
 Parse data in UI:
 • Dashboard shows mood gauge
 • Conversation list (with sentiment)
 • Memory timeline (scrollable)
 • Alert notifications (red badge)
        │
        ▼
 Subscribe to real-time updates
 (Firestore listeners)
        │
        ▼
 When senior has new conversation:
   Receive document update notification
   Refresh mood assessment
   Show badge on conversation count
```

---

## Cloud Functions

AMAVEL uses Google Cloud Functions (Node.js 18) for async, event-driven processing.

### Function 1: `onConversationCreated`

**Trigger:** Firestore write to `users/{userId}/conversations/{conversationId}`

**Purpose:**
1. Extract memories from conversation
2. Analyze emotional tone
3. Update user's engagement metrics

**Pseudocode:**
```javascript
exports.onConversationCreated = functions.firestore
  .document('users/{userId}/conversations/{conversationId}')
  .onCreate(async (snap, context) => {
    const conversation = snap.data();
    const userId = context.params.userId;

    // Extract memory if conversation is substantial
    if (conversation.userMessage.split(' ').length > 20) {
      const memory = await extractMemory(conversation, userId);
      if (memory.score > 0.7) {
        await db.collection('users').doc(userId)
          .collection('memories').add(memory);
      }
    }

    // Analyze emotion
    const emotionalAssessment = await analyzeEmotion(conversation);

    // Check for distress
    const distressScore = await detectDistress(conversation);
    if (distressScore > 0.6) {
      await notifyFamily(userId, distressScore, conversation);
    }

    // Update stats
    await db.collection('users').doc(userId).update({
      'stats.lastConversationAt': FieldValue.serverTimestamp()
    });
  });
```

**Execution Time:** ~10-15 seconds per conversation

---

### Function 2: `dailyMoodSummary`

**Trigger:** Cloud Scheduler (daily at 20:00 UTC)

**Purpose:**
1. Analyze conversations from past 24 hours
2. Generate mood summary
3. Send daily message to family (if configured)

**Pseudocode:**
```javascript
exports.dailyMoodSummary = functions.pubsub
  .schedule('0 20 * * *').timeZone('UTC')
  .onRun(async (context) => {
    const users = await db.collection('users').where('userType', '==', 'senior').get();

    for (const userDoc of users.docs) {
      const userId = userDoc.id;
      const conversations = await db.collection('users').doc(userId)
        .collection('conversations')
        .where('timestamp', '>=', FieldValue.serverTimestamp() - 86400000)
        .get();

      const moodScore = await calculateMoodFromConversations(conversations);

      // Store emotional state
      await db.collection('users').doc(userId)
        .collection('emotionalStates').add({
          timestamp: FieldValue.serverTimestamp(),
          assessment: {
            overallMood: moodScore,
            // ... other fields
          }
        });

      // Notify family if significant change
      if (moodScore < 3) {
        await notifyFamilyOfConcern(userId, 'Low mood detected');
      }
    }
  });
```

**Execution Time:** ~5 seconds per user

---

### Function 3: `cleanupOldData`

**Trigger:** Cloud Scheduler (weekly on Sundays at 02:00 UTC)

**Purpose:**
1. Delete conversation logs older than 6 months
2. Archive old memories
3. Purge system logs older than 90 days

**Pseudocode:**
```javascript
exports.cleanupOldData = functions.pubsub
  .schedule('0 2 * * 0').timeZone('UTC')
  .onRun(async (context) => {
    const sixMonthsAgo = Date.now() - (180 * 24 * 60 * 60 * 1000);

    // Delete old conversations
    const oldConversations = await db.collectionGroup('conversations')
      .where('timestamp', '<', sixMonthsAgo)
      .get();

    for (const doc of oldConversations.docs) {
      await doc.ref.delete();
    }

    // Cleanup logs older than 90 days
    const ninetyDaysAgo = Date.now() - (90 * 24 * 60 * 60 * 1000);
    const oldLogs = await db.collection('logs')
      .where('timestamp', '<', ninetyDaysAgo)
      .get();

    for (const doc of oldLogs.docs) {
      await doc.ref.delete();
    }
  });
```

---

### Function 4: `inactivityAlert`

**Trigger:** Cloud Scheduler (every 12 hours)

**Purpose:**
1. Detect users with no conversation in 24+ hours
2. Alert family members
3. Log inactivity for trend analysis

**Pseudocode:**
```javascript
exports.inactivityAlert = functions.pubsub
  .schedule('0 */12 * * *').timeZone('UTC')
  .onRun(async (context) => {
    const users = await db.collection('users').where('userType', '==', 'senior').get();

    for (const userDoc of users.docs) {
      const lastConversation = await db.collection('users')
        .doc(userDoc.id)
        .collection('conversations')
        .orderBy('timestamp', 'desc')
        .limit(1)
        .get();

      const hoursSinceLastConv = (Date.now() - lastConversation.docs[0].data().timestamp) / 3600000;

      if (hoursSinceLastConv > 24) {
        // Notify family members with inactivity alerts enabled
        const familyMembers = await db.collection('users').doc(userDoc.id)
          .collection('family')
          .where('permissions.alertOn.inactivity', '==', true)
          .get();

        for (const member of familyMembers.docs) {
          await sendAlert(member.id, `${userDoc.data().profile.name} has not used AMAVEL in 24 hours`);
        }
      }
    }
  });
```

---

## Security Model

### Authentication & Authorization

**Authentication:**
- Primary: Firebase Anonymous Auth (no sign-up required)
- Secondary: Email/password for family members
- Session tokens: Firebase auto-manages; 1-hour expiration

**Authorization:**
- Firestore Security Rules (see Part 3.1 of Setup Guide)
- Each user can only access their own data
- Family members have read-only access to specified fields
- Cloud Functions validate permissions before data access

**Secret Management:**
- All API keys stored in GitHub Secrets (encrypted)
- Environment variables injected at build time
- Keys never exposed in APK or client code
- Cloud Functions access keys via Google Cloud Secret Manager

---

### Data Encryption

**In Transit:**
- All traffic over HTTPS (TLS 1.3)
- Firebase enforces SSL pinning on client
- API calls use OAuth 2.0 bearer tokens

**At Rest:**
- Firestore: Google-managed encryption (256-bit AES)
- Cloud Storage: Google-managed encryption
- Audio files: Encrypted before storage
- Backups: Encrypted via Google Cloud backup system

**User Data Privacy:**
- Audio conversations: Transcribed immediately, raw audio can be deleted
- Sensitive conversations: Can be manually deleted by user
- Family access: Limited to specific fields
- No third-party data sharing (except required APIs)

---

### Audit & Logging

- All user actions logged to `/logs` collection with timestamp
- Failed authentication attempts logged
- API call failures logged (with error code)
- Distress alerts logged with full conversation context
- User data downloads (GDPR) logged
- Data deletions logged permanently

---

## Deployment Architecture

### Development Environment

```
Developer Machine
    │
    ├─ Android Studio (local builds)
    ├─ Firebase Emulator (local testing)
    └─ Git (version control)
```

### Staging Environment

```
GitHub Repository (staging branch)
    │
    ├─ GitHub Actions: Build APK
    ├─ GitHub Actions: Run tests
    └─ Artifact storage: APK artifacts
```

### Production Environment

```
GitHub Repository (main branch)
    │
    ├─ GitHub Actions: Build APK
    │
    ├─ Cloud Storage: APK distribution
    │
    └─ Firebase Production Project
        ├─ Firestore Database (europe-west1)
        ├─ Authentication
        ├─ Cloud Functions
        ├─ Cloud Messaging
        └─ Cloud Storage
```

### Disaster Recovery

**Backup Strategy:**
- Firestore automated daily backups (Google-managed)
- Cloud Storage versions enabled (30-day retention)
- Code backups: GitHub primary + offline copies
- Configuration backups: Documented in this architecture

**Recovery Time Objectives:**
- Database corruption: <1 hour (restore from backup)
- API key compromise: <10 minutes (rotate secrets)
- App code issues: <30 minutes (rollback to previous version)
- Full service outage: <4 hours (redeploy all services)

---

## Performance & Scalability

### Expected Capacity

**Current Phase (MVP):**
- 100-500 concurrent senior users
- 1000-5000 total registered users
- ~2,000 conversations per day
- ~500 memory extractions per day

**Scaling Target (12-month):**
- 5,000-10,000 concurrent users
- 50,000+ total users
- ~20,000 conversations per day
- Cloud Functions auto-scale to handle load

**Bottlenecks & Solutions:**
- **OpenAI API rate limits**: Use queue system (Firestore queue) if approaching limits
- **Audio processing**: Use Cloud Tasks for batching
- **Database write contention**: Shard by user ID, implement caching
- **Network latency**: Implement progressive cache, offline mode

### Performance Metrics

| Metric | Target | Current |
|---|---|---|
| Speech-to-text latency | <3 seconds | 2-3 sec |
| LLM response latency | <5 seconds | 4-6 sec |
| TTS synthesis latency | <2 seconds | 1.5-2 sec |
| Total conversation round-trip | <10 seconds | 8-10 sec |
| Memory extraction time | <30 seconds | 15-20 sec |
| Distress alert delivery | <10 seconds | 5-8 sec |
| App load time | <3 seconds | 2-2.5 sec |
| Firebase query latency | <500ms | 100-200 ms |

---

## Future Roadmap

### Version 1.1 (Q2 2025)
- [ ] Portuguese language optimizations
- [ ] Spanish language support
- [ ] Offline conversation mode (queued sync)
- [ ] Extended family group support (>1 family member)
- [ ] Conversation export (PDF)
- [ ] Memory search by keyword

### Version 2.0 (Q4 2025)
- [ ] Avatar system: 3D animated character ("Sofia")
- [ ] Video calling (Firebase WebRTC)
- [ ] iOS app (React Native port)
- [ ] Family group chat
- [ ] Medication reminders
- [ ] Integration with health wearables
- [ ] Caregiver scheduling

### Version 3.0 (2026)
- [ ] Multimodal AI: image recognition, handwriting
- [ ] Advanced emotion tracking (facial recognition opt-in)
- [ ] Integration with smart home devices (lighting, temperature)
- [ ] Social features: group activities, game invitations
- [ ] Advanced analytics dashboard for health professionals
- [ ] Blockchain-based consent management

---

## Integration Points & APIs

### Third-Party Services Status

| Service | Status | Impact | Alternative |
|---|---|---|---|
| OpenAI GPT-4 | Production | Critical: No alternative if down | Claude 3.5 |
| Firebase | Production | Critical: Core backend | AWS Amplify (major rewrite) |
| Google Cloud STT | Production | High: Voice transcription | Azure Speech-to-Text |
| Azure TTS | Production | Medium: Voice synthesis | Google Cloud TTS |
| Anthropic Claude | Production | Low: Fallback only | Manual conversation |

### API Rate Limits & Quotas

| API | Limit | Monitoring | Action |
|---|---|---|---|
| OpenAI | 3,500 req/min, 150K tokens/day | Built-in | Queue + delay |
| Firebase Writes | 20,000/sec (free tier) | Via logs | Implement sharding |
| Firebase Reads | 50,000/day (free tier) | Via logs | Implement caching |
| Cloud Functions | 540,000 seconds/month (free) | Via logs | Upgrade plan |

---

## Monitoring & Observability

### Key Metrics to Monitor

1. **System Health:**
   - API response times (per service)
   - Error rates (by service)
   - Uptime (9-nines target: 99.9%)

2. **User Engagement:**
   - Daily active users (DAU)
   - Conversation frequency
   - Memory extraction success rate
   - Family app engagement

3. **Financial:**
   - OpenAI API spend (track vs. budget)
   - Firebase costs (storage, functions, data transfer)
   - Total cost per user per month

4. **Quality:**
   - Conversation satisfaction (inferred from repeat engagement)
   - Memory extraction quality (manual review)
   - Distress detection accuracy (false positive rate)
   - App crash rate

### Monitoring Tools

- **Firebase Console**: Firestore metrics, function executions
- **Google Cloud Console**: Cloud Functions logs, billing
- **GitHub Actions**: Build success/failure rates
- **Custom dashboards**: Spreadsheet tracking of KPIs

---

## Developer Workflow

### Branch Strategy

- `main`: Production-ready code, automatically deployed
- `develop`: Staging branch, manual testing
- `feature/*`: Feature branches, merged via pull request
- `hotfix/*`: Emergency fixes, merged to main + develop

### Deployment Pipeline

```
git push to main
    │
    ▼
GitHub Actions triggers
    │
    ├─ Run unit tests
    ├─ Run lint checks
    ├─ Build Android APK
    ├─ Run integration tests
    │
    ▼ (if all pass)
    │
    ├─ Upload APK to artifacts
    ├─ Deploy Cloud Functions
    ├─ Update Firestore rules
    │
    ▼
Production deployment complete
```

### Manual Testing Checklist

- [ ] Create new account, complete onboarding
- [ ] Test voice conversation (clarity, speed)
- [ ] Test memory extraction (accuracy)
- [ ] Test distress detection (with test phrases)
- [ ] Test family app linking (permissions, real-time sync)
- [ ] Test offline mode (if implemented)
- [ ] Check logs for errors
- [ ] Verify API usage (cost tracking)

---

## Known Limitations & Technical Debt

### Current Limitations

1. **No iOS app** - Android-only (React Native port planned for Q4 2025)
2. **No video calls** - Text/voice only (video planned for Version 2.0)
3. **Limited offline** - Requires internet for all features
4. **Single avatar** - Fixed "Sofia" character (customization planned)
5. **No prescription management** - No medication tracking
6. **Limited family coordination** - Single family member per senior (multi-family in V2.0)

### Technical Debt

- Audio files stored uncompressed (implement MP3 compression)
- Memory extraction uses simple keyword matching (should use NER/semantic search)
- Distress detection rule-based (should use ML model)
- No rate limiting on client (implement token bucket)
- Cloud Functions cold starts not optimized (implement keep-warm strategy)

---

## Compliance & Regulations

### GDPR Compliance

- [x] User data can be exported (via download request)
- [x] User data can be deleted (right to be forgotten)
- [x] Privacy policy available in app
- [x] Consent recorded for family linking
- [x] Data Processing Agreement with Firebase
- [x] EU data residency (europe-west1)

### Accessibility

- [x] Text-to-speech for all UI elements
- [x] Large font options
- [x] High contrast mode
- [x] Voice-based navigation (no touchscreen required)
- [x] Support for Android accessibility services

### Liability & Ethics

- Clear disclaimer: "AMAVEL is a companion tool, not a substitute for professional healthcare"
- Mental health crisis resources built into app
- Manual review of critical conversations (distress) by team
- No automated medical diagnosis or treatment

---

## Support & Maintenance

### Bug Reporting

Users/families report issues via:
1. In-app feedback form (automatically attaches logs)
2. Email: support@amavel.eu
3. GitHub issues (for public discussion)

### Update Schedule

- Bug fixes: Released within 2-3 days
- Feature updates: Monthly release cycle
- Security patches: Immediately (emergency deployment)

### End-of-Life Support

- Minimum 3 years of API support for each version
- Minimum 5 years of data access (for exports)
- Deprecation notice given 6 months in advance

---

## Appendix A: Environment Variables

Required environment variables (set in GitHub Secrets):

```bash
OPENAI_API_KEY=sk-proj-...
ANTHROPIC_API_KEY=sk-ant-...
FIREBASE_PROJECT_ID=amavel
FIREBASE_DATABASE_URL=https://amavel.firebaseio.com
FIREBASE_API_KEY=AIza...
GOOGLE_CLOUD_API_KEY=AIza...
AZURE_SPEECH_KEY=...
AZURE_SPEECH_REGION=westeurope
```

---

## Appendix B: Firebase Initialization Code

```javascript
// In main app class
import com.google.firebase.FirebaseApp
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.auth.FirebaseAuth

// Initialize Firebase (auto-configured via google-services.json)
FirebaseApp.initializeApp(context)

// Get Firestore instance
val db = FirebaseFirestore.getInstance()

// Get Auth instance
val auth = FirebaseAuth.getInstance()

// Enable offline persistence
db.firestoreSettings = FirebaseFirestoreSettings.Builder()
    .setPersistenceEnabled(true)
    .build()
```

---

## Appendix C: Error Handling Matrix

| Error | Cause | User Experience | Recovery |
|---|---|---|---|
| No internet | WiFi disconnected | "No connection" message | Auto-retry when online |
| OpenAI timeout | API slow/down | "Service busy, try again" | Fallback to Claude |
| Firebase auth failed | Token expired | Silent re-auth | Transparent to user |
| Audio record permission | Not granted | "Microphone unavailable" | Prompt to enable in settings |
| Memory extraction fails | LLM error | Silent (no memory saved) | Logged for review |
| Family link fails | Firestore rule violation | "Cannot link family member" | Check permissions |

---

**Document Version:** 1.0
**Last Updated:** February 2025
**Target Audience:** Technical leads, architects, new developers
**Maintainer:** AMAVEL Engineering Team
