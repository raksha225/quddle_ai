# Quddle App - Project Context

## 📱 **Project Overview**
Quddle is a social media application built with Flutter (frontend) and Node.js (backend), featuring user authentication, content sharing, and social interactions. The app includes features like shorts/videos, live streaming, urban services, store, and chat functionality.

## 🏗️ **Architecture**

### **Frontend (Flutter)**
- **Location**: `/quddle_ai_frontend/`
- **Framework**: Flutter (Dart)
- **State Management**: StatefulWidget/StatelessWidget
- **Navigation**: Centralized routing with `AppRoutes`
- **Storage**: Flutter Secure Storage for tokens and user data
- **HTTP Client**: Custom HTTP service for API calls

### **Backend (Node.js)**
- **Location**: `/quddle_ai_backend/`
- **Framework**: Express.js
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth + Custom Users Table
- **Environment**: Node.js with dotenv for configuration

## 📁 **Project Structure**

```
quddle_app/
├── quddle_ai_frontend/          # Flutter App
│   ├── lib/
│   │   ├── app.dart             # Main app configuration
│   │   ├── main.dart            # App entry point
│   │   ├── screen/              # UI Screens
│   │   │   ├── auth/            # Authentication screens
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── signup_screen.dart
│   │   │   ├── home/            # Home screen
│   │   │   │   └── home_screen.dart
│   │   │   ├── shots/           # Video/Content screens
│   │   │   │   ├── shots_profile.dart
│   │   │   │   └── upload_reel.dart
│   │   │   └── splash_screen/   # App startup
│   │   ├── services/            # API Services
│   │   │   └── auth_service.dart
│   │   └── utils/               # Utilities
│   │       ├── routes.dart      # Centralized routing
│   │       ├── helpers/         # Helper functions
│   │       └── theme/           # App theming
│   ├── assets/                  # Images and resources
│   └── pubspec.yaml            # Dependencies
└── quddle_ai_backend/          # Node.js Backend
    ├── controllers/            # API Controllers
    │   └── auth.js             # Authentication logic
    ├── middleware/             # Express middleware
    │   └── authMiddleware.js    # JWT verification
    ├── config/                 # Configuration
    │   └── database.js         # Supabase setup
    ├── index.js                # Server entry point
    └── package.json            # Dependencies
```

## 🔐 **Authentication System**

### **Frontend Authentication Flow**
1. **Signup**: User provides name, email, password, phone (optional)
2. **Login**: User provides email and password
3. **Token Storage**: JWT tokens stored securely using `flutter_secure_storage`
4. **Profile Fetching**: Dynamic user name display on home screen
5. **Logout**: Clear stored tokens and redirect to login

### **Backend Authentication Flow**
1. **Registration**: 
   - Create user in Supabase Auth
   - Insert user data into custom `users` table
   - Check for duplicate phone numbers
   - Return user data with session
2. **Login**:
   - Authenticate with Supabase Auth
   - Fetch user details from custom `users` table
   - Return user data with session
3. **Profile Retrieval**:
   - Verify JWT token
   - Fetch user details from custom `users` table

### **Database Schema**
```sql
-- Supabase Auth (managed by Supabase)
auth.users (
  id UUID PRIMARY KEY,
  email TEXT,
  encrypted_password TEXT,
  -- ... other auth fields
)

-- Custom Users Table
users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  name TEXT NOT NULL,
  phone TEXT UNIQUE,  -- Optional, unique if provided
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
)
```

## 🎨 **UI/UX Design**

### **Theme**
- **Primary Color**: Purple (`#940D8E`)
- **Background**: Dark theme (`#1A1A1A`, `#2A2A2A`)
- **Text**: White with grey accents
- **Cards**: Dark grey containers with rounded corners

### **Key Screens**

#### **1. Home Screen** (`home_screen.dart`)
- **Purpose**: Main hub with category navigation
- **Features**:
  - Dynamic user greeting with name from backend
  - Category grid: Shorts, Live Stream, Urban Clap, Store, Chatting
  - Logout button in top-right
  - Loading state while fetching user profile

#### **2. Authentication Screens**
- **Login** (`login_screen.dart`): Email/password with dark theme
- **Signup** (`signup_screen.dart`): Name, email, password, phone with dark theme
- **Design**: Dark cards with white text, purple accents

#### **3. Shots Profile** (`shots_profile.dart`)
- **Purpose**: Video content viewing
- **Features**:
  - Interactive heart (like) and share icons
  - Profile section with user info
  - Bottom navigation with purple active indicator
  - Back button navigation

#### **4. Upload Reel** (`upload_reel.dart`)
- **Purpose**: Video content creation
- **Features**:
  - Background image overlay
  - Duration selection (15s, 60s)
  - Effects, Record, Upload buttons
  - Transparent UI elements over background

## 🔄 **Navigation System**

### **Centralized Routing** (`utils/routes.dart`)
```dart
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String shotsProfile = '/shots-profile';
  static const String uploadReel = '/upload-reel';
  
  // Navigation methods
  static void navigateToHome(BuildContext context)
  static void navigateToLogin(BuildContext context)
  // ... other navigation methods
}
```

### **Navigation Flow**
1. **Splash** → **Login/Signup** → **Home**
2. **Home** → **Shots Profile** → **Upload Reel**
3. **Back navigation** available on all screens

## 🌐 **API Integration**

### **Base URL Configuration**
- **Emulator**: `http://10.0.2.2:3000/api`
- **Physical Device**: `http://172.20.10.4:3000/api`
- **Dynamic**: Configured in `AuthService.baseUrl`

### **API Endpoints**
```
POST /api/auth/register    # User registration
POST /api/auth/login       # User login
GET  /api/auth/profile     # Get user profile
```

### **Request/Response Format**
```javascript
// Register Request
{
  "name": "John Doe",
  "email": "john@example.com", 
  "password": "password123",
  "phone": "+1234567890"  // Optional
}

// Register Response
{
  "success": true,
  "message": "User registered successfully",
  "user": {
    "id": "uuid",
    "email": "john@example.com",
    "name": "John Doe",
    "phone": "+1234567890"
  },
  "session": { /* Supabase session */ }
}
```

## 🛠️ **Development Setup**

### **Frontend Setup**
```bash
cd quddle_ai_frontend
flutter pub get
flutter run
```

### **Backend Setup**
```bash
cd quddle_ai_backend
npm install
npm start  # Runs on port 3000
```

### **Environment Variables** (Backend)
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
PORT=3000
```

## 🔧 **Key Features Implemented**

### **Authentication**
- ✅ User registration with name, email, password, phone
- ✅ User login with email/password
- ✅ JWT token management
- ✅ Secure storage of user data
- ✅ Dynamic user profile display
- ✅ Duplicate phone number prevention
- ✅ Logout functionality

### **UI/UX**
- ✅ Dark theme implementation
- ✅ Centralized routing system
- ✅ Responsive design
- ✅ Loading states
- ✅ Error handling with snackbars
- ✅ Interactive elements (heart, share, navigation)

### **Navigation**
- ✅ Screen-to-screen navigation
- ✅ Back button functionality
- ✅ Route management
- ✅ State preservation

## 🚧 **Current Status & Next Steps**

### **Completed**
- Authentication system (frontend + backend)
- UI/UX design implementation
- Navigation system
- User profile management
- Phone number integration

### **Potential Next Steps**
1. **Content Management**: Implement video upload, storage, and streaming
2. **Social Features**: Like, share, comment functionality
3. **Real-time Features**: Live streaming, chat
4. **Database Optimization**: Implement Supabase triggers for transaction safety
5. **Testing**: Unit tests, integration tests
6. **Deployment**: Production deployment setup

## 🔍 **Technical Notes**

### **Transaction Safety**
- Current implementation has potential race condition between Supabase Auth and custom table insert
- Long-term solution: Implement Supabase triggers or Postgres functions
- Current workaround: Graceful degradation with logging

### **Security Considerations**
- JWT tokens stored securely using `flutter_secure_storage`
- Phone number uniqueness validation
- Input validation on both frontend and backend
- Error handling without exposing sensitive information

### **Performance Optimizations**
- Centralized routing reduces bundle size
- Secure storage for offline token persistence
- Efficient state management with StatefulWidget
- Background image optimization

## 📱 **Platform Support**
- **iOS**: Fully supported with Xcode configuration
- **Android**: Fully supported with Gradle configuration
- **Web**: Basic support (Flutter web)
- **Desktop**: Not configured (can be added)

This project represents a modern, scalable social media application with robust authentication, intuitive UI/UX, and a solid foundation for future feature development.
