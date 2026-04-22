import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smet/model/chat/chat_models.dart';
import 'package:smet/service/common/base_url.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/model/user_model.dart';
import 'dart:developer';

/// Chat Service - API calls cho tính năng chat
/// Backend endpoints:
/// - POST /api/chat/rooms - Create/get room
/// - GET /api/chat/rooms/{roomId}/messages - Get messages
/// - POST /api/chat/messages - Send message
/// - POST /api/chat/rooms/{roomId}/read - Mark as read
/// - GET /api/chat/rooms - Get my rooms
class ChatService {
  static const String _baseChatUrl = "$baseUrl/chat";

  /// ===== 1. CREATE OR GET ROOM =====
  /// POST /api/chat/rooms?mentorId=X&contextType=X&contextId=X
  /// Trả về roomId (tạo mới hoặc lấy room hiện có)
  static Future<int> createOrGetRoom({
    required int mentorId,
    required ChatContextType contextType,
    required int contextId,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception("Token not found");
    }

    final url = Uri.parse(
      "$_baseChatUrl/rooms?mentorId=$mentorId&contextType=${contextType.value}&contextId=$contextId",
    );

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    log("CREATE ROOM STATUS: ${response.statusCode}");
    log("CREATE ROOM BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['roomId'] as int;
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body["message"] ?? "Không thể tạo/phòng chat");
    }
  }

  /// ===== 2. GET MESSAGES =====
  /// GET /api/chat/rooms/{roomId}/messages?cursor=X
  /// cursor = null: lấy 50 tin nhắn mới nhất
  /// cursor = messageId: lấy 50 tin nhắn trước message đó
  static Future<List<ChatMessageModel>> getMessages({
    required int roomId,
    int? cursor,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception("Token not found");
    }

    String url = "$_baseChatUrl/rooms/$roomId/messages";
    if (cursor != null) {
      url += "?cursor=$cursor";
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    log("GET MESSAGES STATUS: ${response.statusCode}");
    log("GET MESSAGES BODY: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => ChatMessageModel.fromJson(e)).toList();
    } else {
      throw Exception("Không thể tải tin nhắn");
    }
  }

  /// ===== 3. SEND MESSAGE =====
  /// POST /api/chat/messages
  /// Body: { roomId, content, clientMessageId }
  static Future<ChatMessageModel> sendMessage({
    required int roomId,
    required String content,
    required String clientMessageId,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception("Token not found");
    }

    final url = Uri.parse("$_baseChatUrl/messages");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "roomId": roomId,
        "content": content,
        "clientMessageId": clientMessageId,
      }),
    );

    log("SEND MESSAGE STATUS: ${response.statusCode}");
    log("SEND MESSAGE BODY: ${response.body}");

    if (response.statusCode == 200) {
      return ChatMessageModel.fromJson(jsonDecode(response.body));
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body["message"] ?? "Không thể gửi tin nhắn");
    }
  }

  /// ===== 4. MARK AS READ =====
  /// POST /api/chat/rooms/{roomId}/read
  static Future<void> markAsRead(int roomId) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception("Token not found");
    }

    final url = Uri.parse("$_baseChatUrl/rooms/$roomId/read");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    log("MARK AS READ STATUS: ${response.statusCode}");

    if (response.statusCode != 200) {
      log("MARK AS READ FAILED: ${response.body}");
    }
  }

  /// ===== 5. GET MY ROOMS =====
  /// GET /api/chat/rooms
  /// Lấy danh sách phòng chat của user hiện tại
  static Future<List<ChatRoomPreviewModel>> getMyRooms() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception("Token not found");
    }

    final url = Uri.parse("$_baseChatUrl/rooms");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    log("GET MY ROOMS STATUS: ${response.statusCode}");
    log("GET MY ROOMS BODY: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => ChatRoomPreviewModel.fromJson(e)).toList();
    } else {
      throw Exception("Không thể tải danh sách chat");
    }
  }

  /// ===== HELPER: Get current user ID =====
  static Future<int> getCurrentUserId() async {
    final user = await AuthService.getCurrentUser();
    return user.id;
  }

  /// ===== HELPER: Check if message is from current user =====
  static Future<bool> isMessageFromMe(int senderId) async {
    final currentUserId = await getCurrentUserId();
    return senderId == currentUserId;
  }

  /// ===== CALCULATE TOTAL UNREAD =====
  static Future<int> calculateTotalUnread(
    List<ChatRoomPreviewModel> rooms,
  ) async {
    int total = 0;
    for (final room in rooms) {
      total += room.unreadCount;
    }
    return total;
  }
}
