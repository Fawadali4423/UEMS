# UEMS Firestore Rules Deployment Helper

## Quick Deploy

### Windows:
Double-click `deploy_rules.bat` or run:
```bash
deploy_rules.bat
```

### Mac/Linux:
```bash
firebase deploy --only firestore:rules
```

## Manual Steps (If Script Fails)

### 1. Install Firebase CLI (First time only)
```bash
npm install -g firebase-tools
```

### 2. Login to Firebase
```bash
firebase login
```

### 3. Select Your Project
```bash
firebase use --add
# Select your UEMS project from the list
```

### 4. Deploy Rules
```bash
firebase deploy --only firestore:rules
```

## Verify Deployment

After deployment, the console should show:
```
✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/YOUR-PROJECT/overview
```

## Test The Fixes

Once deployed, test these features:

1. **Event Request** - Student Dashboard → Request Event
2. **Organizer Assignment** - Admin Dashboard → Manage Organizers
3. **Certificate Upload** - Admin Dashboard → Upload Certificates

All should work without permission errors!

## Current Rules Summary

The deployed rules allow:

- ✅ Students to create proposals
- ✅ Anyone to vote on proposals  
- ✅ Admins to update user roles
- ✅ Admins to upload event certificates
- ✅ Students to read certificates

## Troubleshooting

### Error: "Firebase command not found"
→ Install Firebase CLI: `npm install -g firebase-tools`

### Error: "Not authorized"
→ Run: `firebase login`

### Error: "No project selected"
→ Run: `firebase use --add`

### Rules not taking effect?
→ Wait 1-2 minutes and try again (propagation delay)

## Alternative: Manual Upload

If CLI doesn't work:

1. Go to https://console.firebase.google.com
2. Select your UEMS project
3. Click **Firestore Database**
4. Click **Rules** tab
5. Copy content from `firestore.rules`
6. Paste and click **Publish**
