# Bet - Social Wagering Platform

A SwiftUI-based iOS app for social wagering with friends, featuring virtual tokens, auto-payouts, premium subscriptions, and regional compliance.

## Features

### Core Features
- **Dual Balance System**: Total balance and withdrawable balance tracking
- **Auto-Payouts**: Automatic winner determination through voting consensus
- **Premium Subscription (Bet+)**: Zero fees, exclusive activities, priority features
- **Social Features**: Friend system, leaderboards, activity feeds
- **Regional Compliance**: Age verification, regional restrictions, KYC support
- **Security**: Biometric authentication, SSL pinning, jailbreak detection

### Match System
- Create matches with custom rules or templates
- Join matches with friends or public games
- Automated voting and dispute resolution
- 24-hour dispute window with evidence submission
- Leave requests with unanimous approval

### Wallet Features
- Token purchases with Stripe integration
- Bonus tiers (Fortnite-style packages)
- Instant withdrawals to bank accounts
- Transaction history and analytics

## Tech Stack

- **iOS**: SwiftUI, iOS 16+, Combine
- **Backend**: Supabase (Auth, Database, Edge Functions)
- **Payments**: Stripe iOS SDK, Apple Pay
- **Subscriptions**: StoreKit 2
- **Push Notifications**: APNS
- **Architecture**: MVVM-C pattern

## Project Structure

```
BetApp/
├── App/                    # App entry point and configuration
├── Core/                   # Core services and managers
│   ├── Supabase/          # Database models and API
│   ├── Payment/           # Stripe integration
│   ├── Notifications/     # Push notification handling
│   └── Analytics/         # Event tracking
├── Features/              # Feature modules
│   ├── Auth/             # Authentication and onboarding
│   ├── Wallet/           # Balance and transactions
│   ├── Matches/          # Match creation and gameplay
│   ├── Social/           # Friends and leaderboards
│   ├── Premium/          # Subscription management
│   └── Dashboard/        # Home screen
├── Shared/               # Reusable components
│   ├── Components/       # UI components
│   ├── Modifiers/        # SwiftUI modifiers
│   └── Extensions/       # Swift extensions
└── Resources/            # Assets and configuration
```

## Database Schema

### Key Tables
- `users`: User profiles with dual balance tracking
- `matches`: Match details and status
- `match_participants`: Players and voting records
- `transactions`: All financial movements
- `friendships`: Social connections
- `compliance_settings`: Regional rules

## Setup Instructions

### Prerequisites
- Xcode 14+
- iOS 16+ device or simulator
- Supabase account
- Stripe account
- Apple Developer account

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/bet-app.git
cd bet-app
```

2. Open the project in Xcode:
```bash
open BetApp.xcodeproj
```

3. Configure environment variables in `Environment.swift`:
```swift
static let supabaseURL = URL(string: "YOUR_SUPABASE_URL")!
static let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"
static let stripePublishableKey = "YOUR_STRIPE_PUBLISHABLE_KEY"
```

4. Set up Supabase:
```bash
cd supabase
supabase start
supabase db push
```

5. Deploy Edge Functions:
```bash
supabase functions deploy process-match-payout
supabase functions deploy check-match-start
supabase functions deploy send-push-notification
```

6. Configure push notifications in Apple Developer Portal

7. Build and run the project

## Configuration

### Compliance Settings
Edit `supabase/migrations/001_initial_schema.sql` to add regional rules:
```sql
INSERT INTO compliance_settings (region, is_allowed, age_requirement, max_daily_deposit)
VALUES ('Your Region', true, 18, 10000);
```

### Activity Templates
Add custom activities:
```sql
INSERT INTO activity_templates (name, category, default_rules, icon_name)
VALUES ('Your Activity', 'Category', 'Rules here', 'icon.name');
```

## Testing

### Unit Tests
```bash
cmd+U in Xcode
```

### Test Accounts
- Free user: `test@example.com` / `password123`
- Premium user: `premium@example.com` / `password123`

### Test Payments
Use Stripe test cards:
- Success: `4242 4242 4242 4242`
- Decline: `4000 0000 0000 0002`

## Deployment

### App Store Preparation
1. Update version in project settings
2. Archive the app (Product > Archive)
3. Upload to App Store Connect
4. Submit for review with:
   - App description emphasizing skill-based activities
   - Age rating 17+
   - Regional availability settings

### Required App Store Information
- **Category**: Games / Casino
- **Age Rating**: 17+ (Simulated Gambling)
- **Privacy Policy**: Required for data collection
- **Terms of Service**: Required for virtual currency

## Security Considerations

- All API keys should be stored securely
- Enable certificate pinning in production
- Implement rate limiting on Edge Functions
- Regular security audits recommended
- KYC provider integration required for production

## Compliance

The app includes built-in compliance features:
- Age verification during onboarding
- Regional restrictions by country/state
- Deposit and stake limits
- KYC verification for high-value transactions
- Responsible gaming features

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is proprietary software. All rights reserved.

## Support

For support, email support@betapp.com or open an issue in the repository.