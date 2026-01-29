# TemanAman – Mobile Application (Flutter)

TemanAman is a Flutter-based mobile application designed to provide initial emotional support, education, and access to assistance services related to sexual violence issues. This application is primarily aimed at Generation Z with a modern, safe, and privacy-oriented user interface approach.

Important note: TemanAman is not a replacement for psychologists, medical professionals, or emergency services. This application serves as an educational medium and initial support tool.

---

## Key Features

AI Chatbot  
Provides educational, informative responses and initial emotional support through text-based conversations. This feature includes an Auto Disclaimer to explain the AI's limitations and emphasize that the responses provided are not professional diagnoses or decisions. Conversations are not permanently stored to maintain user privacy.

Safe Mode  
An additional protection feature that can be activated when users feel threatened or their privacy is potentially compromised.

"Need Help" Button and Assistance Services  
Provides quick access to support contacts such as phone, WhatsApp, email, and websites. Equipped with regional filters to display relevant and trusted services.

Educational Content  
Presents information on sexual violence prevention, victim rights and protection, and other educational materials in structured and easy-to-understand categories.

Interactive Quizzes  
Used to assess users' understanding of educational materials. The system displays answer explanations progressively to improve user understanding and awareness.

Privacy and Transparency  
Provides Privacy Policy, AI Disclaimer, and Terms of Use pages as a commitment to user data protection.

Onboarding  
Displayed once when the application is first used to introduce key features, AI limitations, Safe Mode, and TemanAman's privacy principles.

---

## Technologies Used

Flutter as the mobile application development framework  
Dart programming language  
REST API as a connector to the TemanAman backend  
Shared Preferences for local storage (onboarding and simple state)  
Material Design 3 for user interface  
AI API (OpenAI) accessed through the backend

---

## Application Architecture

Frontend (Flutter Mobile)  
Handles user interface, navigation, and interaction with application features.

Backend API  
Manages AI Chat processes, educational content, quizzes, and assistance service data.

Admin Panel (Filament)  
Used for centralized application content management by administrators.

---

## Installation and Running the Application

1. Clone repository
```bash
git clone https://github.com/rillyayidan/teman_aman.git
cd teman_aman
```

2. Install dependencies

```bash
flutter pub get
```

3. Run the application

```bash
flutter run
```

Ensure that Flutter SDK is installed and an emulator or physical device is available.

---

## Privacy and Security

AI Chat conversations are not permanently stored.
Conversation context is only managed temporarily during the session (in-memory).
When users exit the chat room, the context and chat room identity are deleted.
Data is processed minimally according to feature requirements and standard security principles.

---

## Development Objectives

TemanAman was developed to:

* Provide easily accessible educational media related to sexual violence
* Provide initial emotional support safely and responsibly
* Increase user awareness and understanding
* Help users find relevant assistance services

---

## Academic Context

This application was developed as part of a final project or thesis in the Informatics Study Program, focusing on AI-based mobile application development that considers ethical, privacy, and user security aspects.

---

## Developer

Name: Muhammad Rilly Ayidan
Application: TemanAman
Platform: Flutter Mobile

---

## License

This project was developed for academic and non-commercial purposes. Further use is subject to the developer's policies.

---
