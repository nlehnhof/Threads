# THREADLINE
Threadline is a mobile application designed to streamline costume inventory management and repair workflows for shows and performances. By centralizing costume data and connecting users across teams, Threadline simplifies communication, tracking, and maintenance of costume pieces.

## Features
Dance Inventory Management: Create and manage dances, linked with detailed men’s and women’s costume pieces.
Costume Assignments: Assign costume pieces to users with identifiers such as size and marker numbers.
Repair Requests: Submit and track repair requests with detailed descriptions and photo attachments.
Team Management: Link users to costume directors via unique codes; manage teams and user roles.
Show Management: Admins can add shows, specifying locations, dates, dances, and associated teams.
User Authentication: Secure login and role-based access control using Firebase Authentication.
Real-Time Sync: Live data synchronization across users through Firebase Realtime Database.

## Technology Stack
Flutter & Dart: Cross-platform app development framework for iOS and Android.
Firebase: Authentication, Realtime Database, and Storage services for backend support.
Provider: State management solution for reactive UI updates.

## Getting Started
Clone the repository.
Set up a Firebase project and configure authentication and database rules.
Update the google-services.json and GoogleService-Info.plist files for Android and iOS respectively.
Run flutter pub get to install dependencies.
Launch the app on your device or emulator using flutter run.

## Usage
Admin users can add shows, dances, and manage teams, including overseeing costume inventory and assignments. Admin can also mark repairs as complete, assign dances to teams/shows, and update dance status (not ready, prepped, distributed). 
Users can see shows, dances, and costumes and submit repair requests. Users link to an admin's account through an admin code.

## License
MIT License
