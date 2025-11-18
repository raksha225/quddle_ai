import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import '../screen/chat/models/chat_session.dart';
import '../screen/chat/models/chat_session_metadata.dart';

class ChatSessionStorage {
  static final ChatSessionStorage _instance = ChatSessionStorage._internal();

  factory ChatSessionStorage() => _instance;

  ChatSessionStorage._internal();

  static const String _sessionsDirName = 'chat_sessions';
  static const String _sessionsFileName = 'chat_sessions.json';
  static const String _activeSessionIdKey = 'active_chat_session_id';

  // Get sessions directory
  Future<Directory> _getSessionsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final sessionsDir = Directory(p.join(appDir.path, _sessionsDirName));
    if (!await sessionsDir.exists()) {
      await sessionsDir.create(recursive: true);
    }
    return sessionsDir;
  }

  // Get sessions file path
  Future<File> _getSessionsFile() async {
    final sessionsDir = await _getSessionsDirectory();
    return File(p.join(sessionsDir.path, _sessionsFileName));
  }

  // Get active session ID from SharedPreferences
  Future<String?> getActiveSessionId() async {
    try {
      // Add retry mechanism for SharedPreferences
      SharedPreferences? prefs;
      for (int i = 0; i < 3; i++) {
        try {
          prefs = await SharedPreferences.getInstance();
          break;
        } catch (e) {
          debugPrint('⚠️ SharedPreferences getInstance attempt ${i + 1} failed: $e');
          if (i < 2) {
            await Future.delayed(Duration(milliseconds: 100 * (i + 1)));
          }
        }
      }
      
      if (prefs == null) {
        debugPrint('❌ Failed to get SharedPreferences instance after retries');
        // Fallback: try to get from sessions data directly
        return await _getActiveSessionIdFromFile();
      }
      
      return prefs.getString(_activeSessionIdKey);
    } catch (e) {
      debugPrint('❌ Error getting active session ID: $e');
      // Fallback: try to get from sessions data directly
      return await _getActiveSessionIdFromFile();
    }
  }

  // Set active session ID in SharedPreferences
  Future<bool> setActiveSessionId(String? sessionId) async {
    try {
      // Add retry mechanism for SharedPreferences
      SharedPreferences? prefs;
      for (int i = 0; i < 3; i++) {
        try {
          prefs = await SharedPreferences.getInstance();
          break;
        } catch (e) {
          debugPrint('⚠️ SharedPreferences getInstance attempt ${i + 1} failed: $e');
          if (i < 2) {
            await Future.delayed(Duration(milliseconds: 100 * (i + 1)));
          }
        }
      }
      
      if (prefs == null) {
        debugPrint('❌ Failed to get SharedPreferences instance after retries');
        // Fallback: save to sessions data file
        return await _setActiveSessionIdInFile(sessionId);
      }
      
      bool result;
      if (sessionId == null) {
        result = await prefs.remove(_activeSessionIdKey);
      } else {
        result = await prefs.setString(_activeSessionIdKey, sessionId);
      }
      
      // Also save to file as backup
      await _setActiveSessionIdInFile(sessionId);
      
      return result;
    } catch (e) {
      debugPrint('❌ Error setting active session ID: $e');
      // Fallback: save to sessions data file
      return await _setActiveSessionIdInFile(sessionId);
    }
  }

  // Fallback: Get active session ID from file
  Future<String?> _getActiveSessionIdFromFile() async {
    try {
      final sessionsData = await _loadSessionsData();
      return sessionsData['activeSessionId'] as String?;
    } catch (e) {
      debugPrint('❌ Error getting active session ID from file: $e');
      return null;
    }
  }

  // Fallback: Set active session ID in file
  Future<bool> _setActiveSessionIdInFile(String? sessionId) async {
    try {
      final sessionsData = await _loadSessionsData();
      sessionsData['activeSessionId'] = sessionId;
      return await _saveSessionsData(sessionsData);
    } catch (e) {
      debugPrint('❌ Error setting active session ID in file: $e');
      return false;
    }
  }

  // Load all sessions from file
  Future<Map<String, dynamic>> _loadSessionsData() async {
    try {
      final sessionsFile = await _getSessionsFile();
      if (!await sessionsFile.exists()) {
        return {
          'sessions': <Map<String, dynamic>>[],
          'activeSessionId': null,
        };
      }

      final content = await sessionsFile.readAsString();
      if (content.isEmpty) {
        return {
          'sessions': <Map<String, dynamic>>[],
          'activeSessionId': null,
        };
      }

      return json.decode(content) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading sessions data: $e');
      return {
        'sessions': <Map<String, dynamic>>[],
        'activeSessionId': null,
      };
    }
  }

  // Save sessions data to file
  Future<bool> _saveSessionsData(Map<String, dynamic> data) async {
    try {
      final sessionsFile = await _getSessionsFile();
      final content = json.encode(data);
      await sessionsFile.writeAsString(content);
      return true;
    } catch (e) {
      debugPrint('Error saving sessions data: $e');
      return false;
    }
  }

  // Load active session
  Future<ChatSession?> loadActiveSession() async {
    try {
      final activeSessionId = await getActiveSessionId();
      if (activeSessionId == null) {
        return null;
      }

      return await loadSession(activeSessionId);
    } catch (e) {
      debugPrint('Error loading active session: $e');
      return null;
    }
  }

  // Load a specific session by ID
  Future<ChatSession?> loadSession(String sessionId) async {
    try {
      final sessionsData = await _loadSessionsData();
      final sessions = sessionsData['sessions'] as List?;

      if (sessions == null) return null;

      for (final sessionJson in sessions) {
        final session = ChatSession.fromJson(sessionJson as Map<String, dynamic>);
        if (session.id == sessionId) {
          return session;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error loading session $sessionId: $e');
      return null;
    }
  }

  // Load all sessions metadata (lightweight)
  Future<List<ChatSessionMetadata>> loadSessionMetadata() async {
    try {
      final sessionsData = await _loadSessionsData();
      final sessions = sessionsData['sessions'] as List?;

      if (sessions == null) return [];

      return sessions
          .map((json) => ChatSessionMetadata.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading session metadata: $e');
      return [];
    }
  }

  // Save a session
  Future<bool> saveSession(ChatSession session) async {
    try {
      final sessionsData = await _loadSessionsData();
      final sessions = (sessionsData['sessions'] as List?) ?? [];

      // Find if session exists and update it, otherwise add new
      final sessionIndex = sessions.indexWhere(
        (s) => (s as Map<String, dynamic>)['id'] == session.id,
      );

      final sessionJson = session.toJson();
      if (sessionIndex >= 0) {
        sessions[sessionIndex] = sessionJson;
      } else {
        sessions.add(sessionJson);
      }

      // Keep active session ID in sync
      if (session.isActive) {
        sessionsData['activeSessionId'] = session.id;
        // Try to set in SharedPreferences, but don't fail if it doesn't work
        setActiveSessionId(session.id).catchError((e) {
          debugPrint('⚠️ Failed to set active session ID in SharedPreferences, but saved in file: $e');
          return false;
        });
      }

      sessionsData['sessions'] = sessions;
      return await _saveSessionsData(sessionsData);
    } catch (e) {
      debugPrint('Error saving session: $e');
      return false;
    }
  }

  // End a session
  Future<bool> endSession(String sessionId) async {
    try {
      final session = await loadSession(sessionId);
      if (session == null) return false;

      final endedSession = session.endSession();
      final saved = await saveSession(endedSession);

      // Clear active session ID if this was the active session
      final activeSessionId = await getActiveSessionId();
      if (activeSessionId == sessionId) {
        await setActiveSessionId(null);
      }

      return saved;
    } catch (e) {
      debugPrint('Error ending session: $e');
      return false;
    }
  }

  // Delete a session
  Future<bool> deleteSession(String sessionId) async {
    try {
      final sessionsData = await _loadSessionsData();
      final sessions = (sessionsData['sessions'] as List?) ?? [];

      // Remove session from list
      sessions.removeWhere(
        (s) => (s as Map<String, dynamic>)['id'] == sessionId,
      );

      // Clear active session ID if this was the active session
      final activeSessionId = await getActiveSessionId();
      if (activeSessionId == sessionId) {
        sessionsData['activeSessionId'] = null;
        await setActiveSessionId(null);
      }

      sessionsData['sessions'] = sessions;
      return await _saveSessionsData(sessionsData);
    } catch (e) {
      debugPrint('Error deleting session: $e');
      return false;
    }
  }

  // Create a new session
  Future<ChatSession> createNewSession() async {
    try {
      final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
      final newSession = ChatSession(
        id: sessionId,
        createdAt: DateTime.now(),
        messages: [],
      );

      await saveSession(newSession);
      await setActiveSessionId(sessionId);

      return newSession;
    } catch (e) {
      debugPrint('Error creating new session: $e');
      rethrow;
    }
  }

  // Get all sessions count
  Future<int> getSessionsCount() async {
    try {
      final metadata = await loadSessionMetadata();
      return metadata.length;
    } catch (e) {
      debugPrint('Error getting sessions count: $e');
      return 0;
    }
  }
}

