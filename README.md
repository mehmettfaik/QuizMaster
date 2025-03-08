# QuizMaster

A quiz application built with UIKit and Firebase that allows users to test their knowledge in various categories.

## Features

- Firebase Authentication with email & password
- 5 quiz categories (Vehicle, Science, Sports, History, Art)
- Three difficulty levels (Easy, Medium, Hard)
- 10-second timer for each question
- Points system (10 points per correct answer)
- User profile with statistics
- Leaderboard
- Push notifications
- Multi-language support
- Sound effects and animations

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+
- Firebase account

## Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/QuizMaster.git
cd QuizMaster
```

2. Set up Firebase
- Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
- Add an iOS app to your Firebase project
- Download the `GoogleService-Info.plist` file
- Copy the file to the `QuizMaster` directory
- Enable Email/Password authentication in the Firebase Console
- Set up Cloud Firestore with the following structure:

```
/users
  /{user_id}
    - email: string
    - name: string
    - photoURL: string?
    - total_points: number
    - quizzes_played: number
    - quizzes_won: number
    - language: string

/quizzes
  /{quiz_id}
    - category: string
    - difficulty: string
    - questions: array
      - text: string
      - options: array<string>
      - correct_answer: string
    - time_per_question: number
    - points_per_question: number
```

3. Open the project in Xcode
```bash
open QuizMaster.xcodeproj
```

4. Build and run the project

## Firebase Setup

1. Authentication
- Enable Email/Password sign-in method

2. Cloud Firestore
- Create the database in test mode
- Set up the collections and documents as shown above
- Add some sample quiz questions

3. Storage
- Create a storage bucket for user profile images

4. Cloud Messaging
- Set up APNs authentication key for push notifications

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details 