#!/bin/bash

# Automated Screenshot Generator for App Store
# This script captures all required screenshots for App Store submission

set -e

# Configuration
SCHEME="BetApp"
PROJECT="BetApp.xcodeproj"
OUTPUT_DIR="Screenshots"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Devices for App Store requirements
DEVICES=(
    "iPhone 14 Pro Max"    # 6.7 inch
    "iPhone 11 Pro Max"    # 6.5 inch
    "iPhone 8 Plus"        # 5.5 inch
)

# Screens to capture
SCREENS=(
    "home:Home Dashboard"
    "wallet:Wallet Balance"
    "create_match:Create Match"
    "active_match:Active Match"
    "social:Friends & Leaderboard"
    "premium:Premium Features"
)

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo -e "${BLUE}🎬 Bet App Screenshot Generator${NC}"
echo "================================"

# Function to take screenshot
take_screenshot() {
    local device="$1"
    local screen_id="$2"
    local screen_name="$3"
    local filename="${device// /_}_${screen_id}.png"
    
    echo -e "${GREEN}📸 Capturing:${NC} $screen_name on $device"
    
    # Here you would add the actual screenshot capture logic
    # This is a placeholder that shows what would be done
    
    # xcrun simctl io "$device_id" screenshot "$OUTPUT_DIR/$filename"
    
    # For now, create a placeholder
    touch "$OUTPUT_DIR/$filename"
}

# Function to setup simulator
setup_simulator() {
    local device="$1"
    
    echo -e "${BLUE}Setting up $device...${NC}"
    
    # Boot simulator
    # xcrun simctl boot "$device" || true
    
    # Wait for boot
    sleep 5
    
    # Set status bar
    # xcrun simctl status_bar "$device" override \
    #     --time "9:41" \
    #     --dataNetwork "wifi" \
    #     --wifiMode "active" \
    #     --wifiBars 3 \
    #     --cellularMode "active" \
    #     --cellularBars 4 \
    #     --batteryState "charged" \
    #     --batteryLevel 100
}

# Main execution
main() {
    echo "Starting screenshot capture..."
    echo ""
    
    # Build app once
    echo -e "${BLUE}Building app...${NC}"
    xcodebuild build \
        -scheme "$SCHEME" \
        -project "$PROJECT" \
        -configuration Release \
        -derivedDataPath build \
        -destination "generic/platform=iOS Simulator" \
        -quiet || {
            echo "Build failed"
            exit 1
        }
    
    # Process each device
    for device in "${DEVICES[@]}"; do
        echo ""
        echo -e "${BLUE}Processing $device${NC}"
        echo "------------------------"
        
        setup_simulator "$device"
        
        # Install app
        # xcrun simctl install "$device" "build/Build/Products/Release-iphonesimulator/BetApp.app"
        
        # Launch app
        # xcrun simctl launch "$device" "com.betapp.bet"
        
        # Wait for app to load
        sleep 3
        
        # Take screenshots for each screen
        for screen in "${SCREENS[@]}"; do
            IFS=':' read -r screen_id screen_name <<< "$screen"
            take_screenshot "$device" "$screen_id" "$screen_name"
            sleep 2
        done
        
        # Shutdown simulator
        # xcrun simctl shutdown "$device" || true
    done
    
    echo ""
    echo -e "${GREEN}✅ Screenshot capture complete!${NC}"
    echo "Screenshots saved to: $OUTPUT_DIR/"
    echo ""
    echo "Next steps:"
    echo "1. Review screenshots in $OUTPUT_DIR"
    echo "2. Edit if needed in Preview or Photoshop"
    echo "3. Upload to App Store Connect"
}

# Create README for screenshots
create_readme() {
    cat > "$OUTPUT_DIR/README.md" << EOF
# App Store Screenshots

## Device Requirements

### 6.7" Display (iPhone 14 Pro Max)
- Required for iPhone 14 Pro Max
- Dimensions: 1290 x 2796 pixels

### 6.5" Display (iPhone 11 Pro Max)
- Required for iPhone 11 Pro Max, iPhone 12 Pro Max
- Dimensions: 1242 x 2688 pixels

### 5.5" Display (iPhone 8 Plus)
- Required for iPhone 6s Plus, 7 Plus, 8 Plus
- Dimensions: 1242 x 2208 pixels

## Screenshot Order

1. **Home Dashboard** - Shows main app interface
2. **Wallet Balance** - Displays token balance and transactions
3. **Create Match** - Match creation flow
4. **Active Match** - Live match interface
5. **Friends & Leaderboard** - Social features
6. **Premium Features** - Bet+ subscription benefits

## Upload Instructions

1. Sign in to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app
3. Go to "App Store" tab → "App Information"
4. Under "Media Manager", upload screenshots for each device size
5. Arrange in the order listed above

## Tips

- Ensure status bar shows 9:41 AM with full battery
- Show app with realistic data
- Highlight key features in each screenshot
- Consider adding marketing text overlay
EOF
}

# Run main function
main
create_readme

echo -e "${BLUE}📝 Created README.md with upload instructions${NC}"