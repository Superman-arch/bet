# Visual Testing Guide - Bet App

This guide covers everything you need to visually test and preview the Bet app before publishing.

## 📱 Preview Options Overview

| Method | Speed | Interactivity | Best For |
|--------|-------|--------------|----------|
| SwiftUI Preview | Instant | Limited | Quick UI checks |
| Simulator | Fast | Full | Complete testing |
| Physical Device | Fast | Full | Real-world testing |
| TestFlight | Slow | Full | Beta testing |

## 🎯 Quick Visual Check (30 seconds)

1. Open `BetApp.xcodeproj` in Xcode
2. Select any SwiftUI file (e.g., `HomeView.swift`)
3. Press `Cmd+Option+Return` to show Canvas
4. See instant preview of that screen

## 🏃‍♂️ Full App Preview (2 minutes)

### Step 1: Open Project
```bash
cd /path/to/bet
open BetApp.xcodeproj
```

### Step 2: Select Device
In Xcode toolbar:
- Click device selector (next to "BetApp" and play button)
- Choose "iPhone 14 Pro" (recommended) or any iOS device

### Step 3: Run App
- Press Play button (▶️) or `Cmd+R`
- Wait for build (first time: ~2-3 min, subsequent: ~30 sec)

### Step 4: Navigate App
The app launches in simulator with:
- Full interactivity
- All animations
- Mock data pre-loaded

## 🎨 Visual Elements to Check

### 1. **Onboarding Flow**
- [ ] Welcome screen animation
- [ ] Smooth transitions between steps
- [ ] Date picker for age verification
- [ ] Region selection list
- [ ] Form validation on account creation

### 2. **Main Navigation**
- [ ] Tab bar icons and labels
- [ ] Tab switching animations
- [ ] Badge notifications on tabs

### 3. **Home Screen**
- [ ] Greeting changes by time of day
- [ ] Balance animation on load
- [ ] Stats cards layout
- [ ] Friend activity feed
- [ ] Premium banner (if not subscribed)

### 4. **Wallet Features**
- [ ] Balance display with count-up animation
- [ ] Token package selection
- [ ] Purchase flow animations
- [ ] Transaction history list
- [ ] Pull-to-refresh gesture

### 5. **Match Creation**
- [ ] Activity selection with icons
- [ ] Stake amount selector
- [ ] Custom rules editor
- [ ] Friend invitation UI
- [ ] Creation confirmation animation

### 6. **Social Features**
- [ ] Friend list with avatars
- [ ] Search functionality
- [ ] Leaderboard podium animation
- [ ] Profile views

### 7. **Premium Upgrade**
- [ ] Crown icon animations
- [ ] Benefits list presentation
- [ ] Plan selection UI
- [ ] Subscribe button states

## 🌓 Dark/Light Mode Testing

### Toggle Appearance
1. In Simulator: Settings → Developer → Dark Appearance
2. Or in code, force mode:
```swift
.preferredColorScheme(.dark)  // or .light
```

### Check These Elements
- [ ] Text readability in both modes
- [ ] Button contrast
- [ ] Card backgrounds
- [ ] Icon visibility
- [ ] Image tinting

## 📱 Device Size Testing

### Test On Multiple Sizes
1. **Small**: iPhone SE (4.7")
   - Check text truncation
   - Verify button sizing
   - Test keyboard overlap

2. **Standard**: iPhone 14 (6.1")
   - Primary testing device
   - Should look perfect

3. **Large**: iPhone 14 Pro Max (6.7")
   - Check spacing isn't too spread out
   - Verify images scale properly

### Quick Multi-Device Preview
In any SwiftUI file, add:
```swift
struct YourView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(["iPhone SE", "iPhone 14", "iPhone 14 Pro Max"], id: \.self) { device in
            YourView()
                .previewDevice(PreviewDevice(rawValue: device))
                .previewDisplayName(device)
        }
    }
}
```

## 🎬 Animation Testing

### Key Animations to Verify
1. **App Launch**
   - Logo animation
   - Fade in transition

2. **Token Purchase**
   - Package selection highlight
   - Purchase button loading state
   - Success celebration

3. **Match Creation**
   - Activity card selection
   - Stake amount changes
   - Creation progress

4. **Transitions**
   - Tab switching
   - Navigation push/pop
   - Modal presentations

### Test Animation Performance
- Run on older device simulator (iPhone 11)
- Check for smooth 60fps
- No stuttering or lag

## 🧪 Interactive Testing Checklist

### Essential User Flows

**1. New User Flow**
- [ ] Complete onboarding
- [ ] Verify age (try under 18)
- [ ] Select region
- [ ] Create account
- [ ] Land on home screen

**2. Token Purchase**
- [ ] Navigate to wallet
- [ ] Tap "Add Tokens"
- [ ] Select different packages
- [ ] Complete purchase (mock)
- [ ] See balance update

**3. Match Creation**
- [ ] Create match
- [ ] Select activity
- [ ] Set custom rules
- [ ] Choose stake
- [ ] Confirm creation

**4. Social Interaction**
- [ ] Search for friends
- [ ] Send friend request
- [ ] View leaderboard
- [ ] Check profiles

## 📸 Screenshot Guide

### For App Store Submission

**Required Sizes:**
1. 6.7" - iPhone 14 Pro Max
2. 6.5" - iPhone 11 Pro Max  
3. 5.5" - iPhone 8 Plus

**Key Screenshots:**
1. Home dashboard
2. Create match screen
3. Wallet with balance
4. Active match
5. Social/leaderboard
6. Premium features

### How to Take Screenshots
1. Run app in correct simulator size
2. Navigate to desired screen
3. Device → Screenshot (or `Cmd+S`)
4. Find on Desktop

### Screenshot Tips
- Clean status bar (9:41 AM, full battery/signal)
- Show app with good sample data
- Highlight key features
- Include some with premium features

## 🐛 Visual Bug Checklist

### Common Issues to Check
- [ ] Text truncation on small devices
- [ ] Overlapping UI elements
- [ ] Images not loading
- [ ] Incorrect colors in dark mode
- [ ] Keyboard covering input fields
- [ ] Safe area issues (notch/home indicator)
- [ ] Loading states showing indefinitely
- [ ] Empty states not showing

## 🎯 Demo Mode

To show the app with best sample data:

1. **Use Premium Test Account**
   ```
   Email: premium@test.com
   Password: Test123!
   ```

2. **Pre-loaded Features**
   - High balance (5000 tokens)
   - Active matches
   - Friend connections
   - Transaction history

3. **Best Screens to Demo**
   - Home (shows all stats)
   - Active match in voting
   - Wallet with transactions
   - Leaderboard with you near top

## 💡 Pro Tips

1. **Reset Simulator** for fresh demo:
   Device → Erase All Content and Settings

2. **Slow Animations** for recording:
   Simulator → Debug → Slow Animations

3. **Record App Preview**:
   - Use QuickTime Player
   - File → New Screen Recording
   - Select Simulator

4. **Test Offline Mode**:
   - Turn on Airplane Mode
   - Verify graceful degradation

## 🚀 Next Steps

After visual testing is complete:

1. **Fix any visual issues found**
2. **Take final App Store screenshots**
3. **Record app preview video**
4. **Upload to TestFlight for beta testing**
5. **Submit to App Store**

Remember: The app is fully built and functional. You just need to run it in Xcode to see everything working!