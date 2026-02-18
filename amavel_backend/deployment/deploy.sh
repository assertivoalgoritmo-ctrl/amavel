#!/bin/bash

# AMAVEL Cloud Functions Deployment Script
# One-click deployment of all Cloud Functions, Firestore rules, and Storage rules

set -e

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FUNCTIONS_DIR="${PROJECT_ROOT}/functions"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}AMAVEL Cloud Functions Deployment${NC}"
echo -e "${BLUE}======================================${NC}"

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}ERROR: Firebase CLI is not installed.${NC}"
    echo "Please install it with: npm install -g firebase-tools"
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}ERROR: Node.js is not installed.${NC}"
    echo "Please install Node.js from https://nodejs.org"
    exit 1
fi

# Display deployment info
echo -e "${YELLOW}Deployment Configuration:${NC}"
echo "Project Root: ${PROJECT_ROOT}"
echo "Functions Directory: ${FUNCTIONS_DIR}"
echo ""

# Step 1: Validate Firebase project
echo -e "${BLUE}Step 1: Validating Firebase project...${NC}"
if [ ! -f "${PROJECT_ROOT}/firebase.json" ]; then
    echo -e "${RED}ERROR: firebase.json not found in ${PROJECT_ROOT}${NC}"
    echo "Make sure you are in the correct directory."
    exit 1
fi
echo -e "${GREEN}✓ firebase.json found${NC}"

# Step 2: Install dependencies
echo ""
echo -e "${BLUE}Step 2: Installing Cloud Functions dependencies...${NC}"
cd "${FUNCTIONS_DIR}"
if [ ! -d "node_modules" ]; then
    echo "Running npm install..."
    npm install
    echo -e "${GREEN}✓ Dependencies installed${NC}"
else
    echo "Dependencies already installed. Skipping npm install."
    echo "Run 'npm install' manually if needed."
fi

# Step 3: Build TypeScript
echo ""
echo -e "${BLUE}Step 3: Building TypeScript...${NC}"
npm run build
if [ -d "lib" ]; then
    echo -e "${GREEN}✓ TypeScript compiled successfully${NC}"
else
    echo -e "${RED}ERROR: TypeScript compilation failed${NC}"
    exit 1
fi

# Step 4: Check for required files
echo ""
echo -e "${BLUE}Step 4: Validating required files...${NC}"
REQUIRED_FILES=(
    "${PROJECT_ROOT}/firestore.rules"
    "${PROJECT_ROOT}/storage.rules"
    "${FUNCTIONS_DIR}/src/config/system_prompt.ts"
    "${FUNCTIONS_DIR}/src/config/guardrails_config.ts"
    "${FUNCTIONS_DIR}/src/config/memory_tools.ts"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}ERROR: Required file not found: $file${NC}"
        exit 1
    fi
done
echo -e "${GREEN}✓ All required files present${NC}"

# Step 5: Deploy to Firebase
echo ""
echo -e "${BLUE}Step 5: Deploying to Firebase...${NC}"
cd "${PROJECT_ROOT}"

# Get Firebase project ID
PROJECT_ID=$(grep '"project":' firebase.json | head -1 | sed 's/.*"project": "\([^"]*\).*/\1/')
if [ -z "$PROJECT_ID" ]; then
    echo -e "${YELLOW}No project ID found in firebase.json. You may be asked to select a project.${NC}"
fi

# Run deployment
echo "Deploying Cloud Functions..."
firebase deploy --only functions

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Cloud Functions deployed${NC}"
else
    echo -e "${RED}ERROR: Cloud Functions deployment failed${NC}"
    exit 1
fi

# Deploy Firestore rules
echo ""
echo "Deploying Firestore security rules..."
firebase deploy --only firestore:rules

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Firestore rules deployed${NC}"
else
    echo -e "${YELLOW}WARNING: Firestore rules deployment had issues${NC}"
fi

# Deploy Storage rules
echo ""
echo "Deploying Storage security rules..."
firebase deploy --only storage

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Storage rules deployed${NC}"
else
    echo -e "${YELLOW}WARNING: Storage rules deployment had issues${NC}"
fi

# Step 6: Post-deployment verification
echo ""
echo -e "${BLUE}Step 6: Verifying deployment...${NC}"
echo "Cloud Functions deployed to Firebase project:"
firebase functions:list

# Summary
echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}✓ Deployment Completed Successfully!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo "Next steps:"
echo "1. Verify your Cloud Functions in the Firebase Console"
echo "2. Check function logs: firebase functions:log"
echo "3. Test the functions with sample data"
echo "4. Monitor alerts and wellness reports"
echo ""
echo "For more information:"
echo "  - Logs: firebase functions:log"
echo "  - Function details: firebase functions:describe [function-name]"
echo "  - Deployment docs: https://firebase.google.com/docs/functions/manage-functions"
