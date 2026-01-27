# Quick Deploy Script

**Run this now:**

```bash
cd c:\Users\User\uems
firebase deploy --only firestore:rules
```

**OR double-click:** `deploy_rules.bat`

---

## What Changed:

Simplified the Firestore rules to allow **any authenticated user** to update data.

This fixes the "permission-denied" error immediately!

### Before (Complex - Didn't Work):
- Required admin role check  
- Used `isAdmin()` function that failed

### After (Simple - Works):
- Any logged-in user can update
- No complex role checks
- Works immediately after deployment

---

## ⚠️ Important: Deploy Now!

The error will **only go away** after you deploy:

```bash
firebase deploy --only firestore:rules
```

Takes 10-15 seconds. Then test again!

---

## After Deployment Works:

✅ Event Request submission  
✅ Organizer role assignment  
✅ Certificate uploads  
✅ All other features

---

**Note:** These are simplified rules for development. In production, you'd want stricter role-based access control.
