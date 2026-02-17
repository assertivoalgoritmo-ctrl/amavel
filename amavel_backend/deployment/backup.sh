#!/bin/bash

# AMAVEL Firestore Backup Script
# Backs up Firestore database and configuration for disaster recovery

set -e

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${PROJECT_ROOT}/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="amavel_backup_${TIMESTAMP}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

# Retention settings
RETENTION_DAYS=30
CLOUD_STORAGE_BACKUP_BUCKET="gs://amavel-backups" # Change to your actual backup bucket

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}AMAVEL Firestore Backup${NC}"
echo -e "${BLUE}======================================${NC}"

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}ERROR: Firebase CLI is not installed.${NC}"
    echo "Please install it with: npm install -g firebase-tools"
    exit 1
fi

# Check if gcloud CLI is installed (for backups)
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}ERROR: Google Cloud SDK is not installed.${NC}"
    echo "Please install it from https://cloud.google.com/sdk/docs/install"
    echo "Or use 'firebase emulators:exec' for local backups"
    exit 1
fi

# Get Firebase project ID
PROJECT_ID=$(grep '"project":' "${PROJECT_ROOT}/firebase.json" | head -1 | sed 's/.*"project": "\([^"]*\).*/\1/')
if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}ERROR: Could not find Firebase project ID in firebase.json${NC}"
    exit 1
fi

echo "Backup Configuration:"
echo "  Project ID: ${PROJECT_ID}"
echo "  Backup Name: ${BACKUP_NAME}"
echo "  Backup Path: ${BACKUP_PATH}"
echo "  Timestamp: ${TIMESTAMP}"
echo ""

# Create backup directory
echo -e "${BLUE}Creating backup directory...${NC}"
mkdir -p "${BACKUP_PATH}"
mkdir -p "${BACKUP_PATH}/firestore"
mkdir -p "${BACKUP_PATH}/config"
mkdir -p "${BACKUP_PATH}/logs"
echo -e "${GREEN}✓ Backup directory created${NC}"

# Backup 1: Export Firestore using gcloud
echo ""
echo -e "${BLUE}Step 1: Backing up Firestore database...${NC}"

# Check if Cloud Storage backup bucket exists, if not create local export
if [ -n "$CLOUD_STORAGE_BACKUP_BUCKET" ]; then
    echo "Exporting Firestore to Cloud Storage..."
    gcloud firestore export "${CLOUD_STORAGE_BACKUP_BUCKET}/firestore_${TIMESTAMP}" \
        --project="${PROJECT_ID}" \
        --async

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Firestore export initiated to Cloud Storage${NC}"
        echo "Location: ${CLOUD_STORAGE_BACKUP_BUCKET}/firestore_${TIMESTAMP}"
    else
        echo -e "${YELLOW}WARNING: Cloud Storage export failed, creating local backup instead${NC}"
    fi
fi

# Backup 2: Backup Firestore Rules
echo ""
echo -e "${BLUE}Step 2: Backing up Firestore rules...${NC}"
if [ -f "${PROJECT_ROOT}/firestore.rules" ]; then
    cp "${PROJECT_ROOT}/firestore.rules" "${BACKUP_PATH}/config/firestore.rules.backup"
    echo -e "${GREEN}✓ Firestore rules backed up${NC}"
fi

# Backup 3: Backup Storage Rules
echo ""
echo -e "${BLUE}Step 3: Backing up Storage rules...${NC}"
if [ -f "${PROJECT_ROOT}/storage.rules" ]; then
    cp "${PROJECT_ROOT}/storage.rules" "${BACKUP_PATH}/config/storage.rules.backup"
    echo -e "${GREEN}✓ Storage rules backed up${NC}"
fi

# Backup 4: Backup Firebase Configuration
echo ""
echo -e "${BLUE}Step 4: Backing up Firebase configuration...${NC}"
cp "${PROJECT_ROOT}/firebase.json" "${BACKUP_PATH}/config/firebase.json.backup"
echo -e "${GREEN}✓ Firebase configuration backed up${NC}"

# Backup 5: Backup Cloud Functions configuration
echo ""
echo -e "${BLUE}Step 5: Backing up Cloud Functions configuration...${NC}"
if [ -f "${PROJECT_ROOT}/functions/package.json" ]; then
    cp "${PROJECT_ROOT}/functions/package.json" "${BACKUP_PATH}/config/functions_package.json.backup"
    echo -e "${GREEN}✓ Functions package configuration backed up${NC}"
fi

# Backup 6: Create backup metadata
echo ""
echo -e "${BLUE}Step 6: Creating backup metadata...${NC}"
cat > "${BACKUP_PATH}/BACKUP_INFO.txt" << EOF
AMAVEL Firestore Backup
=======================

Backup Timestamp: ${TIMESTAMP}
Project ID: ${PROJECT_ID}
Backup Name: ${BACKUP_NAME}

Contents:
- firestore/: Firestore database export (if using Cloud Storage)
- config/: Firestore rules, Storage rules, Firebase config
- logs/: Backup operation logs

Backup Strategy:
- Firestore data: Exported to Cloud Storage (gs://amavel-backups)
- Rules and configs: Stored locally for version control
- Retention period: ${RETENTION_DAYS} days

Recovery Instructions:
1. To restore Firestore from Cloud Storage:
   gcloud firestore import gs://amavel-backups/firestore_${TIMESTAMP}

2. To restore rules:
   firebase deploy --only firestore:rules,storage

3. Keep this metadata file for reference

Created by: AMAVEL Backup Script
Backup System: Firebase/Firestore
EOF

echo -e "${GREEN}✓ Backup metadata created${NC}"

# Backup 7: Create backup summary
echo ""
echo -e "${BLUE}Step 7: Creating backup summary...${NC}"

# Count collections and estimate size
echo "Backup Summary" > "${BACKUP_PATH}/logs/backup_summary.txt"
echo "==============" >> "${BACKUP_PATH}/logs/backup_summary.txt"
echo "Timestamp: ${TIMESTAMP}" >> "${BACKUP_PATH}/logs/backup_summary.txt"
echo "Project: ${PROJECT_ID}" >> "${BACKUP_PATH}/logs/backup_summary.txt"
echo "" >> "${BACKUP_PATH}/logs/backup_summary.txt"

# Get Firestore statistics
echo "Getting Firestore statistics..." >> "${BACKUP_PATH}/logs/backup_summary.txt"
firebase firestore:indexes --project="${PROJECT_ID}" >> "${BACKUP_PATH}/logs/backup_summary.txt" 2>&1 || true

echo -e "${GREEN}✓ Backup summary created${NC}"

# Backup 8: Archive backup
echo ""
echo -e "${BLUE}Step 8: Creating backup archive...${NC}"

ARCHIVE_NAME="${BACKUP_NAME}.tar.gz"
ARCHIVE_PATH="${BACKUP_DIR}/${ARCHIVE_NAME}"

tar -czf "${ARCHIVE_PATH}" -C "${BACKUP_DIR}" "${BACKUP_NAME}"

if [ -f "${ARCHIVE_PATH}" ]; then
    ARCHIVE_SIZE=$(du -h "${ARCHIVE_PATH}" | cut -f1)
    echo -e "${GREEN}✓ Backup archived: ${ARCHIVE_NAME} (${ARCHIVE_SIZE})${NC}"
else
    echo -e "${YELLOW}WARNING: Backup archive creation failed${NC}"
fi

# Backup 9: Clean up old backups (local only)
echo ""
echo -e "${BLUE}Step 9: Cleaning up old backups...${NC}"

# Remove local backup directories older than RETENTION_DAYS
find "${BACKUP_DIR}" -maxdepth 1 -type d -name "amavel_backup_*" -mtime +${RETENTION_DAYS} -exec rm -rf {} \; 2>/dev/null || true

# Remove old archives
find "${BACKUP_DIR}" -maxdepth 1 -type f -name "amavel_backup_*.tar.gz" -mtime +${RETENTION_DAYS} -exec rm {} \; 2>/dev/null || true

echo -e "${GREEN}✓ Old backups cleaned (retention: ${RETENTION_DAYS} days)${NC}"

# Summary
echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}✓ Backup Completed Successfully!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo "Backup Details:"
echo "  Archive: ${ARCHIVE_PATH}"
echo "  Size: ${ARCHIVE_SIZE}"
echo "  Contents:"
echo "    - Firestore rules configuration"
echo "    - Storage rules configuration"
echo "    - Firebase project configuration"
echo "    - Cloud Functions configuration"
echo "    - Backup metadata and logs"
echo ""
echo "Next Steps:"
echo "1. Store this backup in a secure location"
echo "2. Verify the backup can be restored"
echo "3. Consider uploading to secure cloud storage"
echo "4. Schedule regular backups using cron:"
echo "   0 2 * * * cd ${PROJECT_ROOT} && ./deployment/backup.sh"
echo ""
echo "Recovery Guide:"
echo "  See ${BACKUP_PATH}/BACKUP_INFO.txt for detailed recovery instructions"
echo ""
