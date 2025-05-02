# Stem Vault - README

## Project Overview

**Stem Vault** is an interactive Flutter-based mobile application designed to provide users with easy access to STEM (Science, Technology, Engineering, and Mathematics) courses. The app fetches course data and teacher information from Firebase Firestore and presents it in a user-friendly interface. Users can explore courses by searching for titles or tags, filter by specific STEM categories, and track their learning progress.

## Features

* **Course Listing**: Displays courses from the STEM categories: Science, Technology, Engineering, and Mathematics.
* **Search Functionality**: Allows users to search for courses by title or tag.
* **Tab-Based Filtering**: Courses are organized under separate tabs for each STEM category.
* **Course Progress Tracking**: The app tracks student progress for lectures, marking them as completed or not.
* **Teacher Info**: Shows teacher details associated with each course.
* **Firestore Integration**: Fetches and updates data in real-time from Firebase Firestore.

## Prerequisites

To run Stem Vault locally, ensure that you have the following installed:

* **Flutter SDK**: [Install Flutter](https://flutter.dev/docs/get-started/install)
* **Dart SDK**: [Install Dart](https://dart.dev/get-dart)
* **Firebase Account**: [Set up Firebase](https://firebase.google.com/docs/flutter/setup)
* **Android Studio/VS Code**: IDE of your choice for Flutter development
* **Android Emulator/iOS Simulator** for testing

## Getting Started

### 1. Clone the Repository

First, clone the project to your local machine:

```bash
git clone https://github.com/talhanasir22/stem-vault.git
cd stem-vault
```

### 2. Install Dependencies

Make sure all the required dependencies are installed using the following command:

```bash
flutter pub get
```

### 3. Firebase Setup

1. **Create a Firebase Project**:

   * Go to the [Firebase Console](https://console.firebase.google.com/).
   * Create a new Firebase project.

2. **Configure Firestore**:

   * Go to the Firestore section in Firebase and create the `courses` and `teachers` collections.
   * Define documents for each course, including `title`, `category`, `tags`, and `teacherId`.

3. **Enable Firebase Authentication**:

   * In Firebase Console, enable **Email/Password Authentication** for user registration and login.

4. **Add Firebase SDK to the App**:

   * Follow the steps in the Firebase documentation to add Firebase SDK to your Flutter project.
   * Update the `google-services.json` file (for Android) and the `GoogleService-Info.plist` file (for iOS) in your project.

5. **Configure Firestore**:

   * Ensure the Firestore structure is set up to include collections like:

     * `courses` (Fields: `title`, `tags`, `category`, `teacherId`)
     * `teachers` (Fields: `name`, `email`, etc.)
     * `studentProgress` (Fields: `isCompleted`, `courseId`)

### 4. Running the App

1. Open the project in your IDE (Android Studio or VS Code).
2. Run the following command to start the app on an emulator or connected device:

```bash
flutter run
```

### 5. Firebase Firestore Structure

This is how the Firestore collections and documents should be structured:

#### `courses` Collection

Each course document contains:

* `title`: The name of the course.
* `tags`: A list of tags related to the course.
* `category`: One of `Science`, `Technology`, `Engineering`, `Mathematics`.
* `teacherId`: The ID of the teacher associated with the course.

#### `teachers` Collection

Each teacher document contains:

* `name`: The name of the teacher.
* `email`: The email address of the teacher.
* `photoUrl`: The URL of the teacher’s profile picture (optional).

#### `studentProgress` Collection

Each document represents the progress of a student in a particular course:

* `isCompleted`: A boolean value that indicates whether the course has been completed by the student.
* `courseId`: Reference to the course ID in the `courses` collection.

### 6. File Structure

```
lib/
├── main.dart               # Main entry point of the app
├── screens/                # Contains the UI screens of the app
│   ├── home_screen.dart    # Home screen where courses are listed
│   ├── course_detail.dart  # Detailed view of the course
│   ├── search_screen.dart  # Screen for searching courses
│   └── profile_screen.dart # User profile screen
├── models/                 # Data models for courses, teachers, and progress
│   ├── course_model.dart   # Course data model
│   ├── teacher_model.dart  # Teacher data model
│   └── progress_model.dart # Progress tracking model
├── services/               # Firebase services and methods
│   ├── firestore_service.dart # Functions for interacting with Firestore
│   └── authentication_service.dart # Handles Firebase authentication
└── widgets/                # Custom widgets for UI components
    ├── course_card.dart    # Widget for displaying course summary
    ├── search_bar.dart     # Search bar widget
    └── category_tab.dart   # Tabbed UI for filtering categories
```

### 7. Firebase Authentication

* The app uses Firebase Authentication for user login and registration.
* Users can sign up using an email and password, or sign in if they already have an account.

### 8. Progress Tracking

* Users can mark a lecture as completed. The app will update the `studentProgress` collection to reflect the completion status.

### 9. Future Enhancements

* **Push Notifications**: To notify users about new courses, updates, and progress.
* **Course Recommendations**: Based on user preferences and previous course completions.
* **Real-time Chat**: Enable students to ask questions or interact with teachers.

## Contributing

We welcome contributions to **Stem Vault**. If you'd like to contribute, please follow these steps:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature/your-feature`).
3. Commit your changes (`git commit -am 'Add new feature'`).
4. Push to the branch (`git push origin feature/your-feature`).
5. Create a new Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.



