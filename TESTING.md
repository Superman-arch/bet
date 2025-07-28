# Bet App Testing Guide

This guide provides comprehensive instructions for testing the Bet app, including setup, test execution, and troubleshooting.

## Table of Contents
1. [Environment Setup](#environment-setup)
2. [Running Tests](#running-tests)
3. [Test Architecture](#test-architecture)
4. [Manual Testing](#manual-testing)
5. [Performance Testing](#performance-testing)
6. [Troubleshooting](#troubleshooting)

## Environment Setup

### Prerequisites
- macOS with Xcode 14+
- Docker Desktop for Mac
- Homebrew package manager
- Node.js 18+ (for Supabase CLI)

### 1. Install Dependencies

```bash
# Install Supabase CLI
brew install supabase/tap/supabase

# Install Docker (if not already installed)
brew install --cask docker

# Clone the repository
git clone <repository-url>
cd bet
```

### 2. Configure Test Environment

Copy the test environment configuration:
```bash
cp BetApp/App/Environment.Test.swift BetApp/App/Environment.swift
```

### 3. Start Local Services

```bash
# Start Supabase and mock services
docker-compose up -d

# Wait for services to be ready
sleep 30

# Apply database migrations
supabase db push

# Seed test data
psql postgresql://postgres:postgres@localhost:54322/postgres < supabase/seed.sql
```

### 4. Verify Services

Check that all services are running:
```bash
docker-compose ps
```

Access service dashboards:
- Supabase Studio: http://localhost:54323
- Mailhog (Email): http://localhost:8025
- Kong Gateway: http://localhost:54321

## Running Tests

### Unit Tests

Run all unit tests:
```bash
# Using Xcode
open BetApp.xcodeproj
# Press Cmd+U

# Using command line
xcodebuild test \
  -scheme BetApp \
  -destination 'platform=iOS Simulator,name=iPhone 14 Pro' \
  -only-testing:BetAppTests/Unit
```

Run specific test classes:
```bash
xcodebuild test \
  -scheme BetApp \
  -destination 'platform=iOS Simulator,name=iPhone 14 Pro' \
  -only-testing:BetAppTests/Unit/WalletManagerTests
```

### UI Tests

Run all UI tests:
```bash
xcodebuild test \
  -scheme BetApp \
  -destination 'platform=iOS Simulator,name=iPhone 14 Pro' \
  -only-testing:BetAppTests/UI
```

### Integration Tests

Run integration tests with real services:
```bash
# Ensure local services are running
docker-compose up -d

xcodebuild test \
  -scheme BetApp \
  -destination 'platform=iOS Simulator,name=iPhone 14 Pro' \
  -only-testing:BetAppTests/Integration
```

### Test Coverage

Generate test coverage report:
```bash
xcodebuild test \
  -scheme BetApp \
  -destination 'platform=iOS Simulator,name=iPhone 14 Pro' \
  -enableCodeCoverage YES

# View coverage in Xcode
# Product > Show Build Folder in Finder
# Navigate to Logs/Test/*.xcresult
```

## Test Architecture

### Test Structure
```
BetAppTests/
├── Unit/                    # Fast, isolated unit tests
│   ├── WalletManagerTests   # Wallet business logic
│   ├── AuthManagerTests     # Authentication logic
│   └── MatchViewModelTests  # Match view models
├── Integration/             # Tests with real services
│   ├── SupabaseTests       # Database integration
│   └── StripeTests         # Payment integration
├── UI/                     # UI automation tests
│   ├── OnboardingUITests   # Onboarding flow
│   └── WalletUITests       # Wallet UI
└── Mocks/                  # Mock objects and data
    ├── MockData            # Test data generators
    └── MockServices        # Service mocks
```

### Test Patterns

**Unit Tests**: Use dependency injection with mocks
```swift
class WalletManagerTests: XCTestCase {
    var sut: WalletManager!
    var mockSupabase: MockSupabaseManager!
    
    override func setUp() {
        mockSupabase = MockSupabaseManager()
        sut = WalletManager(supabase: mockSupabase)
    }
}
```

**UI Tests**: Use page object pattern
```swift
class WalletPage {
    let app: XCUIApplication
    
    var balanceLabel: XCUIElement {
        app.staticTexts["Total Balance"]
    }
    
    func tapAddTokens() {
        app.buttons["Add Tokens"].tap()
    }
}
```

## Manual Testing

### Test Accounts

Use these pre-configured test accounts:

| Email | Password | Type | Balance |
|-------|----------|------|---------|
| free@test.com | Test123! | Free User | 1000 tokens |
| premium@test.com | Test123! | Premium User | 5000 tokens |
| rich@test.com | Test123! | Rich User | 10000 tokens |

### Test Scenarios

#### 1. Onboarding Flow
- [ ] Launch app fresh (delete and reinstall)
- [ ] Complete age verification (try under 18)
- [ ] Select region
- [ ] Create new account
- [ ] Verify email (check Mailhog)

#### 2. Wallet Operations
- [ ] View balance
- [ ] Purchase tokens (use test card 4242 4242 4242 4242)
- [ ] Test all token tiers
- [ ] Withdraw tokens
- [ ] View transaction history

#### 3. Match Creation
- [ ] Create match with each activity type
- [ ] Set custom rules
- [ ] Invite friends
- [ ] Test stake validation

#### 4. Match Participation
- [ ] Join existing match
- [ ] Wait for match to start
- [ ] Vote for winner
- [ ] Test dispute flow
- [ ] Verify payout

#### 5. Social Features
- [ ] Send friend request
- [ ] Accept friend request
- [ ] View leaderboard
- [ ] Challenge friend

#### 6. Premium Features
- [ ] Subscribe to Bet+
- [ ] Verify premium features unlock
- [ ] Test subscription restoration
- [ ] Cancel subscription

### Payment Testing

Use Stripe test cards:

| Card Number | Scenario |
|-------------|----------|
| 4242 4242 4242 4242 | Success |
| 4000 0000 0000 0002 | Decline |
| 4000 0025 0000 3155 | Requires authentication |

## Performance Testing

### Load Testing

Test with large datasets:
```swift
func testPerformanceWithManyMatches() {
    let matches = (0..<1000).map { _ in
        MockDataGenerator.createMatch()
    }
    
    measure {
        viewModel.processMatches(matches)
    }
}
```

### Memory Testing

Use Instruments to detect leaks:
1. Product > Profile (Cmd+I)
2. Choose "Leaks" template
3. Run the app through test scenarios
4. Analyze retain cycles

## Troubleshooting

### Common Issues

**Services not starting**
```bash
# Check logs
docker-compose logs -f

# Reset everything
docker-compose down -v
docker-compose up -d
```

**Database connection failed**
```bash
# Check Postgres is running
docker exec -it bet-postgres psql -U postgres -c "SELECT 1"

# Reset database
supabase db reset
```

**Tests failing randomly**
- Disable parallel test execution
- Increase async timeouts
- Check for race conditions

**UI tests flaky**
- Add explicit waits
- Disable animations
- Use accessibility identifiers

### Debug Tools

**View Network Traffic**
```swift
// In Environment.swift
static let debugNetworkCalls = true
```

**Enable SQL Logging**
```sql
-- In Supabase dashboard
SET log_statement = 'all';
```

**Mock Slow Network**
```bash
# Use Network Link Conditioner
# Xcode > Open Developer Tool > More Developer Tools
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_14.3.app
      - name: Run tests
        run: |
          xcodebuild test \
            -scheme BetApp \
            -destination 'platform=iOS Simulator,name=iPhone 14 Pro'
```

## Best Practices

1. **Keep tests fast**: Mock external dependencies
2. **Test one thing**: Each test should verify a single behavior
3. **Use descriptive names**: `testWithdrawFailsWhenBalanceInsufficient`
4. **Clean up**: Reset state in `tearDown`
5. **Avoid UI tests for logic**: Use unit tests for business logic
6. **Document flaky tests**: Add comments explaining intermittent failures

## Test Checklist

Before submitting a PR:
- [ ] All tests pass locally
- [ ] New features have tests
- [ ] Test coverage > 80%
- [ ] No memory leaks
- [ ] Performance benchmarks pass
- [ ] Manual testing completed

## Resources

- [Apple Testing Documentation](https://developer.apple.com/documentation/xctest)
- [Supabase Testing Guide](https://supabase.com/docs/guides/testing)
- [Stripe Testing](https://stripe.com/docs/testing)
- [UI Testing Best Practices](https://developer.apple.com/documentation/xctest/user_interface_tests)