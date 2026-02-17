# AMAVEL Backend - Quick Start Guide

Get the Firebase Cloud Functions backend up and running in minutes.

## Prerequisites

1. **Node.js 20+**: Download from https://nodejs.org
2. **Firebase CLI**: `npm install -g firebase-tools`
3. **Google Cloud SDK**: https://cloud.google.com/sdk/docs/install (optional, for backups)
4. **Firebase Project**: Create at https://firebase.google.com
   - Enable Firestore
   - Enable Storage
   - Enable Cloud Functions (Blaze plan required)

## 5-Minute Setup

### Step 1: Login to Firebase
```bash
firebase login
```
Follow the authentication flow in your browser.

### Step 2: Set Your Project
```bash
firebase use --add
```
Choose your project from the list or enter project ID.

### Step 3: Deploy Everything
```bash
./deployment/deploy.sh
```

This script will:
- Install dependencies
- Compile TypeScript
- Deploy Cloud Functions
- Deploy Firestore security rules
- Deploy Storage security rules
- Verify deployment

### Step 4: Verify Success
```bash
firebase functions:log
```

You should see no errors. The functions are now live!

## What Got Deployed?

### Cloud Functions
- **onAlertCreated**: Sends notifications when alerts are created
- **onMessageCreated**: Sends notifications for new messages
- **onUserCreated**: Initializes new user profiles
- **cleanupOldData**: Weekly data cleanup (Sundays 3am UTC)
- **generateWellnessReport**: Weekly reports (Mondays 9am UTC)

### Security Rules
- **firestore.rules**: Protects user data, family member access
- **storage.rules**: Secures audio files and user uploads

## Manual Testing

### Test an Alert Notification

1. Open Firebase Console → Firestore
2. Create a test user document:
   ```
   /users/test-user-123
   {
     "name": "Test User",
     "email": "test@example.com",
     "fcmTokens": [],
     "familyMembers": {}
   }
   ```

3. Create an alert:
   ```
   /users/test-user-123/alerts/test-alert-1
   {
     "severity": "high",
     "title": "Test Alert",
     "description": "This is a test alert",
     "createdAt": {Timestamp},
     "resolved": false
   }
   ```

4. Watch the logs:
   ```bash
   firebase functions:log --follow
   ```

You should see the function execute!

### Test Message Notification

1. Create two test users with FCM tokens
2. Create a message:
   ```
   /users/recipient-uid/messages/msg-1
   {
     "senderId": "sender-uid",
     "senderName": "Sender Name",
     "recipientId": "recipient-uid",
     "content": "Hello!",
     "isVoiceMessage": false,
     "createdAt": {Timestamp}
   }
   ```

3. Check logs for FCM notification sent

## Development Workflow

### Local Testing with Emulator

```bash
# Start the Firebase emulator
firebase emulators:start

# In another terminal, deploy to emulator
firebase deploy --only functions --project=emulator
```

### Making Changes

1. Edit TypeScript files in `functions/src/`
2. Build: `cd functions && npm run build`
3. Deploy: `firebase deploy --only functions`

### Common Commands

```bash
# View all Cloud Functions
firebase functions:list

# View specific function details
firebase functions:describe onAlertCreated

# View live logs
firebase functions:log --follow

# View logs for specific function
firebase functions:log --function=onAlertCreated

# Check function errors
firebase functions:log --only errors
```

## System Architecture

### Alert Flow
```
User in App
    ↓
Create Alert (Firestore)
    ↓
Trigger: onAlertCreated
    ↓
Get Family Members
    ↓
Fetch FCM Tokens
    ↓
Send Push Notifications (FCM)
    ↓
Family Members Receive Notification
```

### Wellness Report Flow
```
Monday 9:00 AM UTC
    ↓
Trigger: generateWellnessReport
    ↓
For Each Active User:
  - Query conversations (past 7 days)
  - Count alerts by severity
  - Calculate sentiment average
  - Identify discussion topics
    ↓
Create wellness report document
    ↓
Send summary to primary contact
```

### Data Cleanup Flow
```
Sunday 3:00 AM UTC
    ↓
Trigger: cleanupOldData
    ↓
For Each User:
  - Delete conversations > 90 days
  - Delete resolved alerts > 180 days
  - Delete audio files > 30 days
    ↓
Log cleanup statistics
```

## Configuration

### Firestore Rules
Edit `firestore.rules` to customize:
- Who can read/write their profile
- Family member access levels
- Collection-level security

Example: Allow family members to see more data:
```javascript
match /users/{uid} {
  allow read: if isUser(uid) || isFamilyMember(uid);
  // More permissive than default
}
```

### Storage Rules
Edit `storage.rules` to customize file size limits, types, and access.

### System Prompt
Edit `functions/src/config/system_prompt.ts` to customize:
- AI companion personality
- Communication guidelines
- Safety guardrails
- Response patterns

### Guardrails
Edit `functions/src/config/guardrails_config.ts` to customize:
- Alert keywords and severity levels
- Scam detection patterns
- Medical risk keywords
- Abuse indicators

## Scheduling

All scheduled functions run in UTC:

| Function | Schedule | Time |
|----------|----------|------|
| cleanupOldData | Weekly | Sunday 3:00 AM |
| generateWellnessReport | Weekly | Monday 9:00 AM |

Modify in the function code (e.g., `.pubsub.schedule('0 9 * * 1')`)

## Monitoring

### Check Function Metrics
1. Firebase Console → Functions
2. Select a function
3. View:
   - Invocations
   - Execution time
   - Error rate
   - Runtime stats

### Set Up Alerts
1. Firebase Console → Monitoring → Alerting
2. Create alert for:
   - Error rate threshold
   - Execution time threshold
   - Quota exceeded

## Troubleshooting

### Deployment Fails
```bash
# Clean and retry
cd functions && npm install && npm run build
firebase deploy --only functions --debug
```

### Function Not Triggering
1. Check Firestore collection path matches trigger
2. Verify rules allow document creation
3. Check logs: `firebase functions:log`
4. Test with small sample data first

### FCM Notifications Not Working
1. Verify FCM tokens exist on user document
2. Check app has notification permissions
3. Ensure billing enabled
4. Review FCM errors in logs

### "Quota Exceeded" Error
- Upgrade to Blaze plan
- Check Cloud Functions quotas
- Scale functions with `memory` parameter

### Permission Denied Errors
1. Check Firebase project permissions
2. Verify service account has required roles
3. Check Firestore rules don't block operations

## Next Steps

1. **Customize AI Prompt**: Edit `functions/src/config/system_prompt.ts`
2. **Add Guardrails**: Update keyword lists in `guardrails_config.ts`
3. **Set Up Backup**: Configure Cloud Storage and schedule `backup.sh`
4. **Enable Monitoring**: Set up Firebase alerts for errors
5. **Test Thoroughly**: Create test users and run through all flows
6. **Configure Clients**: Set up mobile/web apps to send FCM tokens

## Production Checklist

Before going live:

- [ ] All secrets stored in Firebase Cloud Functions config
- [ ] Backups configured and tested
- [ ] Monitoring alerts set up
- [ ] Error tracking enabled (Sentry, Cloud Error Reporting)
- [ ] Load testing completed
- [ ] Security rules tested with Firestore rules simulator
- [ ] Data retention policies reviewed with legal
- [ ] Privacy policy updated to mention data collection
- [ ] GDPR compliance verified
- [ ] Rate limiting configured if needed
- [ ] SSL/TLS enabled for all communications
- [ ] Admin access restricted and logged

## Support

For detailed information, see:
- `README.md` - Complete documentation
- Firebase Docs: https://firebase.google.com/docs
- Google Cloud Functions: https://cloud.google.com/functions/docs

## Need Help?

1. Check logs: `firebase functions:log --follow`
2. Enable debug mode: `firebase deploy --debug`
3. Test with Firebase Emulator: `firebase emulators:start`
4. Review Firestore Rules Simulator
5. Check Cloud Functions quotas and limits

---

Ready to deploy? Start with:
```bash
./deployment/deploy.sh
```

Good luck!
