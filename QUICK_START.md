# Bet App - Quick Start Guide

This guide will help you see your app running visually in under 5 minutes!

## Prerequisites
- Mac with macOS 12.0 or later
- Xcode 14.0 or later (download from Mac App Store)
- 10GB free disk space

## 🚀 Fastest Way to See Your App

### Option 1: Xcode Simulator (Recommended)

1. **Open the project**
   ```bash
   cd /path/to/bet
   open BetApp.xcodeproj
   ```

2. **Select a simulator**
   - In Xcode toolbar, click the device selector (next to the app name)
   - Choose "iPhone 14 Pro" or any iPhone model

3. **Run the app**
   - Press the Play button (▶️) or press `Cmd+R`
   - Wait for build to complete (first time takes 2-3 minutes)

4. **You're live!** 
   - The app will launch in the iOS Simulator
   - Navigate through all screens
   - Everything is fully interactive

### Option 2: SwiftUI Live Preview

1. **Open any SwiftUI file** (e.g., `ContentView.swift`)

2. **Enable Canvas**
   - Press `Cmd+Option+Return` or
   - Editor menu → Canvas

3. **See live preview**
   - The preview updates as you make changes
   - Click "Live Preview" button to interact

## 📱 What You'll See

### First Launch
1. **Welcome Screen** - Animated logo and feature highlights
2. **Age Verification** - Date picker to verify 18+
3. **Region Selection** - Choose your location
4. **Account Creation** - Sign up form

### Main App (After Sign In)
Use these test credentials:
- Email: `free@test.com`
- Password: `Test123!`

**Bottom Tab Bar:**
- 🏠 **Home** - Dashboard with stats and quick actions
- 🎮 **Matches** - Active and pending matches
- 💰 **Wallet** - Balance and transactions
- 👥 **Friends** - Social features and leaderboard  
- 👤 **Profile** - Settings and premium subscription

## 🎨 Visual Features to Explore

### Animations & Effects
- Token count-up animation when purchasing
- Match card flip animations
- Celebration effects on wins
- Pull-to-refresh animations
- Smooth tab transitions

### UI Polish
- Dark mode by default (change in Settings)
- Haptic feedback on all buttons
- Loading states with skeletons
- Empty states with helpful messages
- Error handling with alerts

### Key Flows to Test

1. **Create a Match**
   - Tap + in Matches tab
   - Select activity (Chess, Poker, etc.)
   - Set stake amount
   - See the creation animation

2. **Wallet Operations**
   - Go to Wallet tab
   - Tap "Add Tokens"
   - Select a package
   - See purchase flow (mock in simulator)

3. **Social Features**
   - Go to Friends tab
   - View leaderboard
   - Send friend request
   - See friend profiles

4. **Premium Upgrade**
   - Go to Profile → Bet+ Subscription
   - See premium benefits
   - Test subscription flow

## 🛠 Customization Tips

### Change App Appearance
In `ContentView.swift`:
```swift
.preferredColorScheme(.light)  // Force light mode
.preferredColorScheme(.dark)   // Force dark mode
```

### Modify Test Data
Edit `Environment.Test.swift` to change:
- Initial balance
- Test user names
- Available regions

### Skip Onboarding
In `BetApp.swift`, add:
```swift
.environment(\.skipOnboarding, true)
```

## 📸 Taking Screenshots

1. **In Simulator**
   - Device → Screenshot (or `Cmd+S`)
   - Saves to Desktop

2. **For App Store**
   Required sizes:
   - Run on iPhone 14 Pro Max (6.7")
   - Run on iPhone 8 Plus (5.5")
   - Take screenshots of key screens

## 🧪 Test with Backend

To see the app with a real backend:

1. **Install Docker Desktop** (if not installed)

2. **Start local services**
   ```bash
   docker-compose up -d
   ```

3. **The app will now**:
   - Save real data
   - Show test users and matches
   - Process mock payments

## ❓ Troubleshooting

**Build Failed**
- Clean build: `Cmd+Shift+K`
- Delete derived data: `~/Library/Developer/Xcode/DerivedData`

**Simulator Issues**
- Reset simulator: Device → Erase All Content and Settings
- Try different simulator model

**Preview Not Working**
- Clean: `Cmd+Shift+K`
- Restart Xcode

## 📱 Next Steps

1. **Run on Your iPhone**
   - Connect via USB
   - Select your device in Xcode
   - Trust developer certificate on phone

2. **Share with Testers**
   - Archive the app
   - Upload to TestFlight
   - Invite beta testers

3. **Prepare for App Store**
   - Take final screenshots
   - Write app description
   - Submit for review

---

**Need Help?** The app is fully functional and ready to run. Just open in Xcode and press Play!