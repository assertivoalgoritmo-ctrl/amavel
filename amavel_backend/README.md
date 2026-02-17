# AMAVEL Cloud Functions Backend

Complete Firebase Cloud Functions backend for AMAVEL - a compassionate AI companion for elderly individuals.

## Project Structure

```
amavel_backend/
├── firebase.json                 # Firebase project configuration
├── firestore.rules              # Firestore security rules
├── storage.rules                # Firebase Storage security rules
├── functions/                   # Cloud Functions source code
│   ├── package.json            # Node.js dependencies
│   ├── tsconfig.json           # TypeScript configuration
│   └── src/
│       ├── index.ts            # Main entry point (exports all functions)
│       ├── config/
│       │   ├── system_prompt.ts       # AMAVEL system prompt (Portuguese)
│       │   ├── guardrails_config.ts   # Safety guardrails and alert keywords
│       │   └── memory_tools.ts        # Memory storage tool schemas
│       ├── functions/
│       │   ├── onAlertCreated.ts      # Alert notification trigger
│       │   ├── onMessageCreated.ts    # Message notification trigger
│       │   ├── onUserCreated.ts       # New user initialization
│       │   ├── cleanupOldData.ts      # Weekly data cleanup (GDPR)
│       │   └── generateWellnessReport.ts  # Weekly wellness summary
│       └── utils/
│           ├── fcm_sender.ts          # Push notification helper
│           └── firestore_helpers.ts   # Common Firestore operations
├── deployment/
│   ├── deploy.sh               # One-click deployment script
│   └── backup.sh               # Firestore backup script
└── README.md

```

## Features

### Cloud Functions (Serverless)

1. **Alert Notifications** (`onAlertCreated`)
   - Triggered when new alerts are created
   - Critical alerts: sent to all family members immediately
   - High severity: sent to primary contact
   - Medium/Low: aggregated for weekly report
   - Supports multiple FCM tokens per user

2. **Message Notifications** (`onMessageCreated`)
   - Real-time push notifications for new messages
   - Voice message transcript included in notifications
   - Automatic handling of invalid FCM tokens
   - Support for Android and iOS

3. **User Initialization** (`onUserCreated`)
   - Automatic setup of default settings
   - Data retention configuration
   - Welcome conversation creation
   - Privacy and accessibility defaults

4. **Data Cleanup** (`cleanupOldData`)
   - Weekly scheduled function (Sundays 3:00 AM UTC)
   - Respects user data retention preferences
   - Deletes old conversation turns (90+ days by default)
   - Deletes resolved alerts (180+ days by default)
   - Deletes audio files (30+ days)
   - GDPR-compliant

5. **Wellness Reports** (`generateWellnessReport`)
   - Weekly scheduled function (Mondays 9:00 AM UTC)
   - Aggregates conversation metrics
   - Calculates sentiment scores
   - Counts alerts by severity
   - Identifies discussion topics
   - Sends family notifications with recommendations

### Security & Safety

- **Firestore Rules**: Role-based access control
  - Users can only access their own data
  - Family members can view alerts with restrictions
  - Private conversations and memories
  - Public config readable by authenticated users

- **Storage Rules**: File-level security
  - Audio files: user and family members
  - Profile images: size and type validation
  - Memory attachments: 10MB limit
  - Temporary uploads with cleanup

- **Guardrails System**
  - Detects distress keywords (critical, high, medium)
  - Identifies scam/exploitation patterns
  - Recognizes medical emergencies
  - Detects abuse indicators
  - Automatic alert escalation

### Memory System

- Store and retrieve personal facts
- Categories: family, health, preferences, stories, dates, routines, concerns, interests
- Supports context-aware conversations
- Importance ranking (high/medium/low)

## Prerequisites

- Node.js 20+
- Firebase CLI: `npm install -g firebase-tools`
- Google Cloud SDK: `https://cloud.google.com/sdk`
- Active Firebase project with Firestore and Storage enabled
- Firebase billing account (Cloud Functions require Blaze plan)

## Setup Instructions

### 1. Initialize Firebase Project

```bash
# Login to Firebase
firebase login

# Select or create a project
firebase use --add

# Or use specific project
firebase use your-project-id
```

### 2. Install Dependencies

```bash
cd functions
npm install
```

### 3. Deploy to Firebase

**Automated deployment (recommended):**
```bash
./deployment/deploy.sh
```

**Manual deployment:**
```bash
cd functions
npm run build
firebase deploy --only functions,firestore:rules,storage
```

### 4. Verify Deployment

```bash
# Check deployed functions
firebase functions:list

# View recent logs
firebase functions:log

# Check function status
firebase functions:describe onAlertCreated
```

## Configuration

### Environment Variables (Optional)

Cloud Functions can use environment variables for configuration:

```bash
# Set function configuration
firebase functions:config:set amavel.alert_timeout_minutes="60"
firebase functions:config:set amavel.max_family_members="10"

# Deploy with config
firebase deploy --only functions
```

### Firestore Settings

- **Region**: europe-west1 (can be modified in functions/src/)
- **Database**: Default or named database
- **Indexes**: Auto-created as needed

## Cloud Function Details

### onAlertCreated

**Trigger**: `users/{userId}/alerts/{alertId}` document creation

**Behavior**:
- Critical alerts: FCM to all family members (high priority)
- High alerts: FCM to primary contact (high priority)
- Medium/Low alerts: Aggregated for weekly report

**Data flow**:
1. Alert created in Firestore
2. Trigger function executes
3. Get family member FCM tokens
4. Send FCM notification
5. Update alert with notificationSentAt timestamp

### onMessageCreated

**Trigger**: `users/{userId}/messages/{messageId}` document creation

**Behavior**:
- Sends FCM to recipient with message preview
- Handles voice message transcripts
- Removes invalid FCM tokens automatically

### onUserCreated

**Trigger**: `users/{userId}` document creation

**Behavior**:
- Creates default settings document
- Sets up data retention config
- Creates welcome conversation entry

### cleanupOldData

**Schedule**: Weekly on Sundays at 3:00 AM UTC

**Process**:
1. Get all active users
2. For each user:
   - Check data retention preferences
   - Delete old conversation turns
   - Delete resolved alerts
   - Delete old audio files
3. Log statistics

**GDPR Compliance**:
- Respects user retention preferences
- Supports opt-out of auto-deletion
- Maintains audit trail in system collection

### generateWellnessReport

**Schedule**: Weekly on Mondays at 9:00 AM UTC

**Metrics Calculated**:
- Conversation count
- Average sentiment (0-10 scale)
- Alert counts by severity
- Discussion topics
- Overall wellness score (excellent/good/fair/concerning)

**Actions**:
1. Query all active users
2. Calculate metrics for past 7 days
3. Create wellness report document
4. Send FCM to primary family contact with summary

## Firestore Data Structure

### Users Collection
```
/users/{userId}
├── createdAt: timestamp
├── email: string
├── name: string
├── status: string (active/inactive)
├── fcmTokens: array
├── primaryContact: string (uid)
├── familyMembers: map {
│   ├── {familyMemberId}: {
│   │   ├── relationship: string
│   │   ├── addedAt: timestamp
│   │   └── permissions: array
│   └── ...
├── conversations/
│   └── {conversationId}: {
│       ├── role: string (user/assistant)
│       ├── content: string
│       ├── timestamp: timestamp
│       ├── sentiment: number (0-10)
│       └── topics: array
├── memoryFacts/
│   └── {factId}: {
│       ├── category: string
│       ├── fact: string
│       ├── importance: string (high/medium/low)
│       └── createdAt: timestamp
├── alerts/
│   └── {alertId}: {
│       ├── severity: string (critical/high/medium/low)
│       ├── title: string
│       ├── description: string
│       ├── createdAt: timestamp
│       ├── resolved: boolean
│       └── notificationSentAt: timestamp
├── messages/
│   └── {messageId}: {
│       ├── senderId: string
│       ├── recipientId: string
│       ├── content: string
│       ├── isVoiceMessage: boolean
│       └── createdAt: timestamp
├── settings/
│   └── preferences: { ... }
├── dataRetention/
│   └── config: { ... }
└── wellnessReports/
    └── {reportId}: { ... }
```

## Testing Functions Locally

### Using Firebase Emulator

```bash
# Start emulator
firebase emulators:start

# In another terminal, run tests
# The emulator will process function triggers
```

### Testing with sample data

Create sample documents in Firestore to trigger functions:

```bash
# Create test alert
firebase firestore:set /users/test-user/alerts/test-alert1 \
  '{"severity":"high","title":"Test Alert","description":"Test","createdAt":{"_type":"timestamp","_seconds":1234567890}}'

# Watch logs
firebase functions:log
```

## Monitoring & Logs

### View logs in real-time
```bash
firebase functions:log
```

### Filter logs by function
```bash
firebase functions:log --function=onAlertCreated
```

### View specific function details
```bash
firebase functions:describe onAlertCreated
```

### Monitor in Firebase Console
1. Go to Firebase Console > Functions
2. Click on a function to see metrics
3. Check Runtime stats and Error rate

## Deployment & Versioning

### Rollback to previous version
```bash
# List available versions
gcloud functions list

# Redeploy specific function from source
firebase deploy --only functions:onAlertCreated
```

### Update only Firestore rules
```bash
firebase deploy --only firestore:rules
```

### Update only Storage rules
```bash
firebase deploy --only storage
```

## Backup & Disaster Recovery

### Create Backup
```bash
./deployment/backup.sh
```

**Backed up items**:
- Firestore rules configuration
- Storage rules configuration
- Firebase project configuration
- Cloud Functions configuration
- Metadata and logs

### Restore from Backup

1. **Restore Firestore data** (from Cloud Storage):
```bash
gcloud firestore import gs://amavel-backups/firestore_TIMESTAMP
```

2. **Restore rules**:
```bash
firebase deploy --only firestore:rules,storage
```

3. **Restore Cloud Functions**:
```bash
firebase deploy --only functions
```

## Cost Optimization

### Function Invocations
- Alert notifications: triggered on alert creation
- Message notifications: triggered on message creation
- Scheduled functions: two weekly jobs

### Firestore Operations
- Read: family member lookups, alert queries
- Write: notification timestamps, report documents

### Storage
- Audio files: cleaned up after 30 days
- Temporary uploads: auto-cleanup available

**Estimated monthly cost** (based on small deployment):
- Functions: ~$0.40 (1M invocations free)
- Firestore: ~$5-15 (read/write dependent)
- Storage: ~$0.20/GB

## Troubleshooting

### Function not triggering
1. Check Firestore collection path matches trigger
2. Verify rules allow document creation
3. Check function logs: `firebase functions:log`
4. Ensure billing enabled on project

### FCM notifications not sent
1. Verify FCM tokens exist in user document
2. Check device has app installed and permissions granted
3. Review FCM error in logs
4. Try sending to different device token

### Firestore rules blocking access
1. Check rules in Firestore console
2. Verify user is authenticated
3. Check isFamilyMember() function with correct family IDs
4. Test with Firebase rules simulator

### Script permission errors
```bash
# Make scripts executable
chmod +x deployment/*.sh
```

## Security Best Practices

1. **API Keys**: Store in Firebase console, never in code
2. **Data Access**: Use Firestore rules, not function-level checks
3. **Family Privacy**: Only share necessary data with family members
4. **Audio Storage**: Encrypted in transit and at rest
5. **Token Management**: Remove invalid FCM tokens promptly
6. **Logging**: Sensitive data not logged in production

## Additional Resources

- [Firebase Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [Firestore Security Rules Guide](https://firebase.google.com/docs/firestore/security/start)
- [Firebase Emulator Documentation](https://firebase.google.com/docs/emulator-suite)
- [Cloud Messaging (FCM) Docs](https://firebase.google.com/docs/cloud-messaging)

## Support & Issues

For issues, questions, or contributions:
1. Check this README and existing documentation
2. Review Firebase and Google Cloud documentation
3. Check Cloud Function logs for errors
4. Test with Firebase Emulator locally

## License

This backend is part of the AMAVEL project and is provided as-is for authorized use.

---

**Last Updated**: 2024
**Version**: 1.0.0
**Firebase Region**: europe-west1
