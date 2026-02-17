# AMAVEL Setup Guide

## Introduction

AMAVEL is an AI-powered companion app designed to help seniors stay connected, maintain cognitive engagement, and get immediate support when needed. This guide walks you through everything needed to set up AMAVEL from scratch—no software development experience required.

**Time to Complete:** 3-4 hours (mostly waiting for automated processes)
**Cost to Get Started:** €5-25/month for AI services (testing phase)

---

## Part 1: What You'll Need

Before starting, gather these items:

### Hardware
- **A computer** (Windows, Mac, or Linux) with internet access
- **An Android tablet** (recommended: Samsung Galaxy Tab A8 or A9, €180-220)
  - Minimum: Android 9.0, 2GB RAM, 100MB free storage
  - Supports ages 65+
- **USB cable** (to connect tablet to computer, optional but recommended)

### Accounts & Credentials
- **Google account** (free; creates a Gmail if you don't have one)
- **Valid credit/debit card** (for AI service billing; won't charge without your approval)

### Time & Environment
- **3-4 hours** for complete setup
- **Quiet space** for testing voice features
- **Stable internet connection** (WiFi is fine)

---

## Part 2: Create Accounts and Get API Keys

You'll need accounts with several AI and cloud services. Each takes 5-10 minutes.

### 2.1: Create OpenAI Account

OpenAI provides the conversational AI that powers AMAVEL.

1. Go to **https://platform.openai.com**
2. Click **Sign up** (top right)
3. Enter your email address
4. Create a password
5. Verify your email (check your inbox)
6. Complete the phone verification (required for API access)
7. Agree to their terms
8. You'll land on the **Dashboard**

**Get Your API Key:**
1. Click your **profile icon** (bottom left)
2. Select **API keys**
3. Click **Create new secret key**
4. Copy the key immediately and **save it somewhere safe** (Notepad, password manager, etc.)
5. Name it "AMAVEL" so you remember what it's for
6. Click **Save**

**Add Billing Credits (Optional but Recommended):**
1. In the Dashboard, go to **Billing** → **Overview**
2. Click **Add to account**
3. Add $10 USD (approximately €9)
4. You'll receive a $5 free credit when you sign up, so total available is ~$15
5. Your API will only charge for what you actually use

**Save These for Later:**
- Your OpenAI API Key (looks like: `sk-proj-...`)

---

### 2.2: Create Firebase Project

Firebase handles user authentication, data storage, messaging, and cloud functions.

1. Go to **https://console.firebase.google.com**
2. Sign in with your **Google account**
3. Click **Create a project** (or **Add project**)
4. Enter project name: **amavel**
5. Accept the terms
6. Click **Continue**
7. Disable **Google Analytics** (not needed for this project)
8. Click **Create project**
9. Wait 1-2 minutes for setup to complete

**Configure Your Firebase Project:**

Once your project loads, you'll see the Firebase console. Now enable the services AMAVEL needs:

**Enable Authentication:**
1. Left sidebar → **Build** → **Authentication**
2. Click **Get started**
3. Click **Anonymous** (first option)
4. Toggle the switch to **Enable**
5. Click **Save**

**Enable Firestore Database:**
1. Left sidebar → **Build** → **Firestore Database**
2. Click **Create Database**
3. Select region: **europe-west1** (Belgium; closest to EU)
4. Click **Next**
5. Start in **Production mode** (secure by default)
6. Click **Create**
7. Wait 1-2 minutes for the database to initialize

**Enable Cloud Storage:**
1. Left sidebar → **Build** → **Storage**
2. Click **Get started**
3. Accept the default settings
4. Select region: **europe-west1**
5. Click **Done**

**Verify Cloud Messaging (for family alerts):**
Cloud Messaging is enabled automatically with every Firebase project — there is nothing to turn on. To confirm it's active:
1. Click the **gear icon** (⚙) next to "Project Overview" in the top-left
2. Select **Project settings**
3. Click the **Cloud Messaging** tab
4. You should see a **Server key** and **Sender ID** listed — if so, you're all set

**Get Firebase Configuration:**
1. In the console, click the **Settings icon** (⚙️, top left)
2. Select **Project settings**
3. Scroll down to find **Your apps** section
4. Click **Android** (the green Android icon)
5. If no Android app exists yet, click **Add app** and select **Android**
6. Fill in:
   - **Android package name:** `com.amavel.app`
   - Leave SHA-1 empty for now
7. Click **Register app**
8. Click **Download google-services.json**
9. **Save this file** in a safe place (you'll need it later)
10. Click **Next** through the remaining steps (you can skip the code snippets—the automated build will handle them)

**Save These for Later:**
- Your Firebase Project ID (shown in Project settings)
- Your Firebase Database URL (shown in Firestore Database page)
- The `google-services.json` file you downloaded

---

### 2.3: Create GitHub Account

GitHub stores your code and automates the APK building process.

1. Go to **https://github.com**
2. Click **Sign up** (top right)
3. Enter your email
4. Create a password
5. Choose a username (this will be visible; something like `amavel-setup` is fine)
6. Verify your email
7. Complete any additional steps GitHub asks for
8. You'll land on your GitHub home page

**Save These for Later:**
- Your GitHub username
- Your GitHub email

---

### 2.4 (Optional): Create Anthropic Account

Anthropic provides Claude AI as a backup for conversations if OpenAI is unavailable.

1. Go to **https://console.anthropic.com**
2. Click **Sign up**
3. Enter email and password
4. Verify your email
5. Go to **API Keys** section
6. Click **Create Key**
7. Copy and save the key

**This is optional.** You can skip this and use only OpenAI.

---

### 2.5 (Optional): Create Google Cloud Account

Google Cloud Speech-to-Text can provide backup voice recognition.

1. Go to **https://console.cloud.google.com**
2. Sign in with your Google account
3. Click **Select a project** → **New project**
4. Name it **AMAVEL**
5. Click **Create**
6. Enable the **Speech-to-Text API** (search in the search bar at top)
7. Create credentials: **API Keys** → **Create API Key**
8. Copy and save the key

**This is optional.** You can skip this and use only OpenAI.

---

### 2.6 (Optional): Create Azure Account

Microsoft Azure provides Neural Text-to-Speech as a backup for voice output.

1. Go to **https://azure.microsoft.com**
2. Click **Start free**
3. Sign in with your Microsoft account (or create one)
4. Complete account setup and add a payment method
5. You'll receive $200 free credits
6. Search for **Speech Services** in Azure Portal
7. Create a new Speech resource in region **West Europe**
8. Go to **Keys and Endpoint** and copy **Key 1** and your **Region**

**This is optional.** You can skip this and use only OpenAI.

---

## Part 3: Set Up Firebase

Now you'll configure Firebase in more detail for AMAVEL's data structure.

### 3.1: Set Up Firestore Security Rules

1. In Firebase console, go **Build** → **Firestore Database**
2. Click the **Rules** tab
3. Replace all text with this security configuration:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection: authenticated users only
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;

      // User profile data
      match /profile/{document=**} {
        allow read, write: if request.auth.uid == userId;
      }

      // Conversations
      match /conversations/{document=**} {
        allow read, write: if request.auth.uid == userId;
      }

      // Memory entries
      match /memories/{document=**} {
        allow read, write: if request.auth.uid == userId;
      }

      // Family links
      match /family/{document=**} {
        allow read, write: if request.auth.uid == userId;
      }
    }

    // Family profiles (read-only for linked family members)
    match /familyProfiles/{familyId} {
      allow read: if request.auth != null;
      allow write: if false;
    }

    // System logs
    match /logs/{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

4. Click **Publish**

### 3.2: Create Firestore Collections

You don't need to manually create these—the app will create them automatically. But here's what will be created:

**Collections AMAVEL will use:**
- `users/` — User profiles and settings
- `conversations/` — Chat history and timestamps
- `memories/` — Extracted life memories
- `family/` — Family member relationships
- `logs/` — System events and errors

---

## Part 4: Set Up GitHub Repository

Now you'll upload the AMAVEL code to GitHub where it can be built automatically.

### 4.1: Create a Repository

1. Go to **https://github.com/new**
2. Name it: **amavel**
3. Description: "AI companion app for seniors" (optional)
4. Select **Public** (so you can use GitHub Actions free)
5. Do NOT check "Add a README" (you'll upload your own files)
6. Click **Create repository**
7. You'll see an empty repository page with setup instructions

### 4.2: Upload the AMAVEL Code

**Option A: Using GitHub Web Interface (Easiest)**

1. In your new empty repository, click **Add file** → **Upload files**
2. Navigate to the AMAVEL project folder on your computer
3. Download the entire AMAVEL project to your computer first (from wherever you received the source files)
4. Select all AMAVEL files and folders
5. Drag and drop them into the GitHub upload page
6. Write commit message: `Initial commit: AMAVEL project setup`
7. Click **Commit changes**
8. GitHub will upload all files

**Option B: Using GitHub Desktop (If Comfortable with Software)**

This requires downloading GitHub Desktop—skip if you used Option A.

1. Download **GitHub Desktop** (https://desktop.github.com)
2. Install and sign in with your GitHub account
3. Clone your amavel repository
4. Copy all AMAVEL files into that folder
5. Commit with message: `Initial commit: AMAVEL project setup`
6. Push to GitHub

### 4.3: Add API Keys as GitHub Secrets

GitHub Secrets are a secure way to store sensitive information that the build process can access without exposing them publicly.

1. In your GitHub repository, click **Settings** (top menu)
2. Left sidebar → **Secrets and variables** → **Actions**
3. Click **New repository secret**

**Add each secret with these exact names:**

| Secret Name | Value | Where From |
|---|---|---|
| `OPENAI_API_KEY` | Your OpenAI API key | Section 2.1 |
| `FIREBASE_PROJECT_ID` | Your Firebase project ID | Section 2.2 |
| `FIREBASE_DATABASE_URL` | Your Firestore database URL | Section 2.2 |
| `ANTHROPIC_API_KEY` | Your Anthropic API key (if you created one) | Section 2.4 |
| `GOOGLE_CLOUD_API_KEY` | Your Google Cloud API key (if you created one) | Section 2.5 |
| `AZURE_SPEECH_KEY` | Your Azure Speech key (if you created one) | Section 2.6 |
| `AZURE_SPEECH_REGION` | Your Azure region, e.g., "westeurope" | Section 2.6 |

**How to add each:**
1. Click **New repository secret**
2. Name: (use exact name from table above)
3. Secret: (paste the value)
4. Click **Add secret**
5. Repeat for each API key

Your repository is now set up with secure access to all services!

---

## Part 5: Build the APK

An APK is the installation file for Android apps. GitHub will automatically build it for you.

### 5.1: Trigger the Automated Build

1. Go to your GitHub repository
2. Click the **Actions** tab (top menu)
3. You'll see a workflow called **Build AMAVEL APK** (defined in `.github/workflows/`)
4. Click **Build AMAVEL APK**
5. Click **Run workflow** (button on right)
6. Select branch: **main**
7. Click **Run workflow**
8. GitHub will start building—this takes 5-10 minutes

### 5.2: Wait for the Build

1. You'll see a yellow dot next to the workflow name (meaning it's running)
2. Click the workflow run to see progress details
3. Wait until you see a **green checkmark** (build succeeded)
4. If you see a red X, scroll down to see error details—common fixes are listed in the Troubleshooting section

### 5.3: Download the APK

Once the build succeeds:

1. Click the successful workflow run
2. Scroll to the bottom under **Artifacts**
3. You'll see `app-release.apk`
4. Click it to download (about 45-60 MB)
5. Save it to your computer (e.g., Desktop or Downloads folder)

---

## Part 6: Install on Tablet

Now you'll install the AMAVEL app on your Android tablet.

### 6.1: Prepare Your Tablet

1. **Turn on your tablet** and connect to WiFi
2. Go to **Settings** → **About** (or **About Tablet**)
3. Scroll down and find **Build number** (or **Software version**)
4. Tap **Build number** 7 times rapidly (you'll see a "Developer mode enabled" message)
5. Go back and look for **Developer options** (or **Developer tools**)
6. Open **Developer options**
7. Enable **USB Debugging** (toggle switch)

### 6.2: Transfer the APK to Your Tablet

**Option A: Via USB Cable (Most Reliable)**

1. Connect your tablet to your computer with a USB cable
2. On the tablet, you may see a prompt asking to allow access—tap **Allow** or **OK**
3. On your computer, the tablet should appear as a drive or device
4. Copy the `app-release.apk` file to the tablet's **Downloads** folder
5. Eject the tablet safely (right-click drive on Windows, drag to eject on Mac)
6. Disconnect the cable

**Option B: Via Email**

1. Email the APK to yourself or the tablet user's email
2. Open email on the tablet
3. Download the APK attachment to the Downloads folder

**Option C: Via Cloud Storage**

1. Upload the APK to Google Drive
2. Open Google Drive on the tablet
3. Download the APK to the Downloads folder

### 6.3: Install the APK

1. On the tablet, open **Files** or **File Manager**
2. Navigate to **Downloads**
3. Find and tap the `app-release.apk` file
4. Android will ask if you want to install this app
5. Tap **Install**
6. Wait 1-2 minutes for installation to complete
7. Tap **Open** once done
8. AMAVEL will launch!

### 6.4: Grant Permissions

When AMAVEL opens for the first time, it will ask for permissions. Grant these:

- **Microphone** — needed for voice conversations (tap **Allow**)
- **Camera** — optional but recommended for video calls (tap **Allow** or **Don't allow**)
- **Location** — optional but useful for emergency services (tap **Allow** or **Don't allow**)
- **Contacts** — optional for family linking (tap **Allow** or **Don't allow**)
- **Calendar** — optional for event reminders (tap **Allow** or **Don't allow**)

You can grant these later in **Settings** → **Apps** → **AMAVEL** → **Permissions** if needed.

---

## Part 7: Deploy Cloud Functions

Cloud Functions are small programs running on Google's servers that handle backend tasks like memory extraction and distress detection alerts.

### 7.1: Install Required Software on Your Computer

**Step 1: Install Node.js**

1. Go to **https://nodejs.org**
2. Download the **LTS version** (long-term support)
3. Follow the installer (accept defaults)
4. Restart your computer after installation

**Verify Installation:**
1. Open Command Prompt (Windows) or Terminal (Mac/Linux)
2. Type: `node --version`
3. You should see a version number (e.g., v18.12.0)

**Step 2: Install Firebase CLI**

1. In Command Prompt/Terminal, type:
```
npm install -g firebase-tools
```
2. Wait for installation to complete (1-2 minutes)

**Verify Installation:**
1. Type: `firebase --version`
2. You should see a version number

### 7.2: Deploy Functions

**Option A: Automated Deployment (Recommended)**

If your GitHub repository includes `.github/workflows/deploy-functions.yml`:

1. In GitHub, go to **Actions**
2. Click **Deploy Cloud Functions**
3. Click **Run workflow**
4. GitHub will deploy automatically (5 minutes)

**Option B: Manual Deployment**

If you need to deploy manually:

1. Open Command Prompt/Terminal
2. Navigate to your AMAVEL project folder:
```
cd /path/to/amavel
```
3. Login to Firebase:
```
firebase login
```
4. Follow the browser prompt to authorize
5. Set your Firebase project:
```
firebase use amavel
```
(Replace "amavel" with your actual project ID if different)

6. Deploy:
```
firebase deploy --only functions
```

7. Wait 2-3 minutes for deployment to complete
8. You should see "Deploy complete!"

**If you're not comfortable with this**, ask a technical person to run these commands once. They take 10 minutes total.

---

## Part 8: First Test on the Tablet

Now let's test that AMAVEL works end-to-end.

### 8.1: Open AMAVEL

1. On the tablet, find and tap the **AMAVEL** app icon
2. The app will take 2-3 seconds to load
3. You'll see a welcome screen with your language options

### 8.2: Complete Onboarding

AMAVEL will guide you through setup:

1. **Select Language** — Choose your preferred language (Portuguese, English, etc.)
2. **Enter Name** — Type the senior user's name
3. **Set Birth Date** — Select their date of birth
4. **Choose Voice** — Select a voice for AMAVEL to use
5. **Test Microphone** — Tap a button and speak "Hello" to test
6. **Review Permissions** — Confirm the app has needed permissions

### 8.3: Test Voice Conversation

1. You'll see a chat screen with a microphone button
2. Tap the **microphone icon**
3. Speak clearly: "What is my name?" or "Tell me about yourself"
4. Wait 2-3 seconds for a response
5. AMAVEL should respond with a sentence using the name you entered
6. Tap the speaker icon to hear the response read aloud

**If this works:** ✓ Your setup is successful!

**If the response is slow or silent:** Check that WiFi is connected and all API keys are correct (see Troubleshooting).

### 8.4: Test Memory

1. Say: "Remember that I love gardening"
2. Wait for confirmation
3. Later, say: "What do I like to do?"
4. AMAVEL should mention gardening from the previous message

### 8.5: Test Distress Detection

1. Say: "I'm feeling very alone and depressed"
2. The app should recognize emotional distress and offer support options
3. You should see a red alert displayed

### 8.6: Verify Internet Connection

1. Go to tablet **Settings** → **WiFi**
2. Confirm connected to WiFi network
3. Open a web browser and visit google.com to verify internet works

---

## Part 9: Set Up Family App

The Family App lets family members monitor the senior's well-being and receive alerts.

### 9.1: Build the Family App APK

The family app is a separate build. Repeat the GitHub Actions build process:

1. In your GitHub repository, go to **Actions**
2. Find **Build Family App APK** workflow
3. Click **Run workflow** → **Run workflow**
4. Wait 5-10 minutes for build to complete
5. Download the `family-app-release.apk` artifact

### 9.2: Install on Family Member's Phone

Use the same installation steps as Part 6, but for the family app APK:

1. Transfer APK to the family member's Android phone via USB, email, or cloud storage
2. Open **Files** and find the APK
3. Tap to install
4. Grant permissions
5. Open the Family App

### 9.3: Create Family Account and Link

In the Family App:

1. Tap **Create Account**
2. Enter family member name and email
3. Set a password
4. Tap **Create**
5. In the app, go to **Link Senior**
6. Enter the senior's AMAVEL username or ID
7. Tap **Send Link Request**
8. On the senior's AMAVEL app, accept the family link
9. Family member can now see:
   - Last conversation summary
   - Mood assessment
   - Memory entries
   - Distress alerts

---

## Part 10: Ongoing Costs (Estimated)

Here's what you can expect to pay monthly for running AMAVEL:

| Service | Usage Estimate | Monthly Cost |
|---|---|---|
| **OpenAI API** | 5 conversations/day (150/month) | €5-15 |
| **Firebase** | Free tier covers most users | €0 |
| **Google Cloud STT** | Optional backup | €2-5 |
| **Azure TTS** | Optional backup | €1-3 |
| **Total** | — | **€5-25/month** |

**Cost Breakdown:**
- At €0.001 per conversation token, 5 conversations daily costs about €5-10/month
- Firebase free tier includes 1GB storage and 50,000 reads/writes/deletes daily (more than enough)
- Adding Claude (Anthropic) fallback: +€3-5/month
- Adding Google Speech-to-Text: +€2-3/month
- Adding Azure Neural TTS: +€1-2/month

**You won't be charged** until you exceed Firebase's free tier or actively use paid APIs.

---

## Troubleshooting

### APK Build Fails in GitHub

**Problem:** Red X next to workflow, build failed

**Solution:**
1. Click the failed workflow run
2. Scroll down to see error message
3. Common errors:
   - **Missing API key**: Check that all secrets are added correctly in GitHub Settings
   - **Invalid Firebase project ID**: Copy-paste the exact project ID from Firebase console
   - **Gradle error**: This usually resolves on a retry—go back to Actions and run the workflow again

**If it still fails:** Check that `google-services.json` is in the repository's `android/app/` folder.

---

### APK Won't Install on Tablet

**Problem:** "Cannot install app" or "Blocked by security"

**Solution:**
1. Ensure **USB Debugging** is enabled (Part 6.1)
2. Ensure the APK is fully downloaded (check file size is ~45-60 MB)
3. Try uninstalling any previous version: **Settings** → **Apps** → **AMAVEL** → **Uninstall**
4. Delete the old APK file and re-download from GitHub

**If error persists:** On the tablet, go **Settings** → **Apps** → **Unknown Sources** and enable installation from unknown sources (may be required on some Android versions).

---

### No Voice Response in AMAVEL

**Problem:** App opens but doesn't respond when you speak

**Solution:**
1. Check tablet **Settings** → **WiFi** is connected (AMAVEL needs internet)
2. Check internet speed: open web browser and visit google.com (should load in <2 seconds)
3. Check **microphone permission**: **Settings** → **Apps** → **AMAVEL** → **Permissions** → **Microphone** (should be allowed)
4. Test microphone: **Settings** → **Accessibility** → **Hearing** → **Speech-to-Text** (if available) to verify microphone works
5. In GitHub, verify all API keys are correctly added as Secrets (typos will cause failures)
6. Close AMAVEL completely and reopen it
7. Force stop and clear cache: **Settings** → **Apps** → **AMAVEL** → **Storage** → **Clear Cache**

**If still silent:**
1. Check GitHub Actions logs to see if the build included the correct API keys
2. Rebuild the APK with corrected secrets and reinstall

---

### Slow Responses from AMAVEL

**Problem:** Takes >5 seconds to respond

**Solution:**
1. Check internet connection speed (WiFi should be 10+ Mbps)
2. Move tablet closer to WiFi router
3. Restart the WiFi router (unplug 30 seconds, plug back in)
4. Close other apps on the tablet that may be using bandwidth
5. Check if OpenAI API is having issues: visit **https://status.openai.com** (their status page)

If responses are consistently slow, it may be a network issue rather than an app issue.

---

### Distress Alert Not Showing

**Problem:** Said something concerning, but no red alert appeared

**Solution:**
1. Cloud Functions may not be deployed yet (Part 7)
2. Check that `firebase deploy --only functions` completed successfully
3. Test with very clear distress language: "I want to hurt myself" or "I am very depressed"
4. Check Firebase Cloud Functions logs to see if the function is running:
   - In Firebase console → **Build** → **Functions**
   - Look for recent executions and any error messages

---

### Family App Can't Link to Senior

**Problem:** Link request fails or doesn't appear

**Solution:**
1. Ensure both apps are open and connected to the same WiFi network
2. Ensure both apps are up to date (rebuild and reinstall if recent changes were made)
3. Check that both have Firestore permissions (Part 3.1)
4. Wait 30 seconds and try again (might be a sync delay)
5. Restart both apps

---

### Firebase Database Not Syncing

**Problem:** Changes in AMAVEL don't appear in Family App

**Solution:**
1. Check internet connection on both devices
2. Go to Firebase console → **Firestore Database** → **Data** and manually verify data is being written
3. Check security rules are correct (Part 3.1)
4. Rebuild and redeploy Cloud Functions (Part 7)
5. Force stop and clear cache on both apps, then reopen

---

### GitHub Actions Won't Run

**Problem:** No workflow appears or "Run workflow" button is missing

**Solution:**
1. Ensure the `.github/workflows/` folder and YAML files are in your repository (check in your repository file listing)
2. If missing, download the workflows from the AMAVEL project source and upload them manually
3. Go to **Actions** tab and click **Enable workflows** if prompted
4. Refresh the page (Ctrl+R or Cmd+R)

---

### "No Such File or Directory" Error During Deployment

**Problem:** Firebase deploy command fails with file not found

**Solution:**
1. Ensure you're in the correct folder (the AMAVEL root directory)
2. Check that `functions/` folder exists in your current directory
3. Type `ls` (Mac/Linux) or `dir` (Windows) to see what files are present
4. If `functions/` is missing, copy it from your AMAVEL project backup

---

### OpenAI API Returns Error

**Problem:** "Invalid API key" or "Rate limit exceeded"

**Solution:**
1. **Invalid API Key**: Log into OpenAI (https://platform.openai.com), go to **API keys**, and verify you copied the key correctly (no extra spaces)
2. **Rate Limit**: You've made too many requests. Wait 1 minute before trying again. Check your usage: https://platform.openai.com/account/billing/usage
3. **Insufficient Credits**: Add more credits at https://platform.openai.com/account/billing/overview
4. Update the API key in GitHub Secrets and rebuild the APK

---

### Need Additional Help

If issues persist:

1. **Check logs**:
   - GitHub Actions logs (for build issues)
   - Firebase Cloud Functions logs (for runtime issues)
   - Firebase Console → **Firestore** → **Logs** (for database issues)

2. **Test connectivity**:
   - Verify all devices can reach google.com
   - Verify tablet WiFi signal is strong
   - Restart WiFi router if needed

3. **Rebuild from scratch**:
   - Delete the GitHub repository
   - Create a new one
   - Re-upload AMAVEL code
   - Re-add all API keys
   - Rebuild the APK

---

## Next Steps

Once AMAVEL is running smoothly:

1. **Invite family members** to install the Family App and link to the senior
2. **Monitor the first week** of usage to ensure the senior is comfortable with the app
3. **Review memories monthly** that the app extracts to ensure quality
4. **Adjust AI personality** (if available) to better match the senior's preferences
5. **Add backup AI services** (Anthropic, Google STT) once you're comfortable with the basic setup

---

## Support & Feedback

AMAVEL is designed to be simple, but if you run into issues:

1. **Check this Troubleshooting section** first
2. **Review the logs** in GitHub Actions and Firebase Console
3. **Consult with a technical person** if needed (most issues take 15-30 minutes to fix)
4. **Take notes on what's breaking** so you can describe it accurately

Congratulations on setting up AMAVEL! You're now equipped to support a senior with AI-powered companionship.

---

**Document Version:** 1.0
**Last Updated:** February 2025
**Language:** English with Portuguese UI references
**Target Audience:** Non-technical setup lead / family member
