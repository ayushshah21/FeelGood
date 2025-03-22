# FeelGood App

A simple, intuitive mobile app to help users track their daily happiness levels, understand patterns affecting their mood, and receive personalized recommendations to improve their happiness.

## Features

- **Daily Check-ins**: Rate your happiness (1-10 scale) twice a day (morning and night)
- **Mood Tracking**: Add voice/text notes explaining your mood
- **Analytics**: View insightful statistics on mood fluctuations and trends
- **Personalized AI Recommendations**: Get suggestions based on your mood patterns (optional)

## Setup Instructions

### Prerequisites

- Xcode 15 or later
- iOS 17.0+ for running the app
- Firebase account

### Firebase Setup

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Create a new project named "FeelGood"
3. Add an iOS app with the bundle identifier matching your Xcode project
4. Download the `GoogleService-Info.plist` file
5. Add the downloaded file to your Xcode project root (make sure "Copy items if needed" is checked)

### Xcode Project Setup

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/FeelGood.git
   cd FeelGood
   ```

2. Open the project in Xcode:
   ```
   open FeelGood.xcodeproj
   ```

3. Install the Firebase dependencies using Swift Package Manager:
   - In Xcode, go to File > Add Packages...
   - Enter the URL: https://github.com/firebase/firebase-ios-sdk
   - Select the Firebase products: 
     - FirebaseAnalytics
     - FirebaseAuth
     - FirebaseFirestore
     - FirebaseStorage
   - Click "Add Package"

4. Build and run the app

## App Structure

- **OnboardingView**: Color selection and initial app setup
- **CheckInView**: Daily happiness rating and mood journaling
- **AnalyticsView**: Visualizations of mood trends (coming soon)
- **SettingsView**: App preferences and user account management (coming soon)

## Data Model

The app uses Firebase Firestore to store:
- User profiles and preferences
- Daily mood entries with ratings
- Text and voice notes attached to mood entries

## License

[MIT License](LICENSE) 