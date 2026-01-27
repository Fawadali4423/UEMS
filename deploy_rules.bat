@echo off
echo ====================================
echo  UEMS Firestore Rules Deployment
echo ====================================
echo.

echo Checking Firebase CLI installation...
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Firebase CLI is not installed!
    echo.
    echo Please install it first:
    echo npm install -g firebase-tools
    echo.
    pause
    exit /b 1
)

echo Firebase CLI found!
echo.

echo Deploying Firestore rules...
echo.
firebase deploy --only firestore:rules

if %errorlevel% equ 0 (
    echo.
    echo ====================================
    echo  SUCCESS! Rules deployed!
    echo ====================================
    echo.
    echo The following rules are now active:
    echo - proposals collection (read/write)
    echo - votes collection (read/write)
    echo - users collection (admin can update)
    echo - event_certificates (admin write, all read)
    echo.
    echo You can now test:
    echo - Event request submission
    echo - Organizer role assignment
    echo - Certificate uploads
    echo.
) else (
    echo.
    echo ====================================
    echo  DEPLOYMENT FAILED!
    echo ====================================
    echo.
    echo Possible issues:
    echo 1. Not logged in to Firebase
    echo 2. Wrong project selected
    echo 3. No firebase.json in this directory
    echo.
    echo Try these commands:
    echo   firebase login
    echo   firebase use --add
    echo.
)

pause
