import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:smet/model/chat/chat_models.dart';
import 'package:smet/service/chat/chat_service.dart';
import 'package:smet/service/common/auth_service.dart';
import 'dart:developer';

/// Chat Connection Service - Singleton quản lý real-time chat
///
/// Chỉ có DUY NHẤT 1 Timer polling toàn app.
/// Mỗi widget/page chỉ subscribe/unsubscribe room cần thiết.
/// Khi app background → pause polling. Khi app foreground → sync + resume.
class ChatConnectionService with WidgetsBindingObserver {
  static ChatConnectionService? _instance;
  static ChatConnectionService get instance =>
      _instance ??= ChatConnectionService._();

  ChatConnectionService._() {
    WidgetsBinding.instance.addObserver(this);
  }

  // ===== Timer & Connection State =====
  Timer? _pollingTimer;
  bool _isConnected = false;
  bool _isPaused = false;

  // ===== Streams =====
  final _messageController = StreamController<ChatMessageModel>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _roomUpdateController =
      StreamController<ChatRoomUpdate>.broadcast(); // room preview update

  // ===== Subscribed Rooms =====
  List<int> _subscribedRooms = [];
  Map<int, int> _roomLastMessageIds = {};

  // ===== Debounce =====
  bool _pollInProgress = false;

  // ===== Polling Interval =====
  static const _pollInterval = Duration(seconds: 5);

  // ===== Public Streams =====
  Stream<ChatMessageModel> get messageStream => _messageController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<ChatRoomUpdate> get roomUpdateStream => _roomUpdateController.stream;
  bool get isConnected => _isConnected;
  List<int> get subscribedRooms => List.unmodifiable(_subscribedRooms);

  // ===== Connect =====
  Future<void> connect() async {
    if (_pollingTimer != null && _isConnected) return;

    try {
      final user = await AuthService.getCurrentUser();
      log("ChatConnection: Starting for user ${user.id}");

      _isConnected = true;
      _connectionController.add(true);
      _startPolling();
    } catch (e) {
      log("ChatConnection: error - $e");
      _isConnected = false;
      _connectionController.add(false);
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollInterval, (_) {
      _pollForNewMessages();
    });
  }

  Future<void> _pollForNewMessages() async {
    if (!_isConnected || _isPaused || _pollInProgress) return;
    if (_subscribedRooms.isEmpty) return;

    _pollInProgress = true;
    try {
      for (final roomId in List<int>.from(_subscribedRooms)) {
        await _pollSingleRoom(roomId);
      }
    } catch (e) {
      log("ChatConnection: poll error - $e");
    } finally {
      _pollInProgress = false;
    }
  }

  Future<void> _pollSingleRoom(int roomId) async {
    try {
      final messages = await ChatService.getMessages(roomId: roomId);

      if (messages.isEmpty) return;

      final latestId = messages.last.id;
      final lastKnownId = _roomLastMessageIds[roomId] ?? 0;

      if (latestId > lastKnownId) {
        _roomLastMessageIds[roomId] = latestId;

        final newMessages =
            messages.where((m) => m.id > lastKnownId).toList();
        for (final msg in newMessages) {
          _messageController.add(msg);
        }

        // Emit room preview update for room list screens
        _roomUpdateController.add(ChatRoomUpdate(
          roomId: roomId,
          lastMessage: messages.last.content,
          lastMessageTime: messages.last.createdAt,
        ));

        log("ChatConnection: $newMessages.length new messages in room $roomId");
      }
    } catch (e) {
      // Silent fail
    }
  }

  // ===== Subscribe / Unsubscribe =====
  void subscribeToRoom(int roomId) {
    if (_subscribedRooms.contains(roomId)) return;

    _subscribedRooms.add(roomId);
    _fetchLastMessageId(roomId);
    log("ChatConnection: Subscribed to room $roomId");
  }

  void unsubscribeFromRoom(int roomId) {
    _subscribedRooms.remove(roomId);
    _roomLastMessageIds.remove(roomId);
    log("ChatConnection: Unsubscribed from room $roomId");
  }

  Future<void> _fetchLastMessageId(int roomId) async {
    try {
      final messages = await ChatService.getMessages(roomId: roomId);
      if (messages.isNotEmpty) {
        _roomLastMessageIds[roomId] = messages.last.id;
      }
    } catch (e) {
      log("ChatConnection: error fetching last message ID for room $roomId");
    }
  }

  // ===== Notify when message sent locally =====
  void notifyMessageSent(ChatMessageModel message) {
    _roomLastMessageIds[message.roomId] = message.id;
  }

  // ===== Pause / Resume (App Lifecycle) =====
  void pause() {
    if (_isPaused) return;
    _isPaused = true;
    _pollingTimer?.cancel();
    log("ChatConnection: Paused (app background)");
  }

  Future<void> resumeAndSync() async {
    if (!_isPaused) return;
    _isPaused = false;

    // Sync last known message IDs for all subscribed rooms
    for (final roomId in List<int>.from(_subscribedRooms)) {
      await _fetchLastMessageId(roomId);
    }

    _startPolling();
    log("ChatConnection: Resumed with sync");
  }

  // ===== WidgetsBindingObserver =====
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      pause();
    } else if (state == AppLifecycleState.resumed) {
      resumeAndSync();
    }
  }

  // ===== Disconnect =====
  void disconnect() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isConnected = false;
    _isPaused = false;
    _subscribedRooms.clear();
    _roomLastMessageIds.clear();
    _connectionController.add(false);
    log("ChatConnection: Disconnected");
  }

  // ===== Dispose =====
  void dispose() {
    disconnect();
    WidgetsBinding.instance.removeObserver(this);
    _messageController.close();
    _connectionController.close();
    _roomUpdateController.close();
    _instance = null;
  }
}

/// Lightweight event for room preview updates (used by ChatListPage, FloatingChatButton)
class ChatRoomUpdate {
  final int roomId;
  final String lastMessage;
  final DateTime lastMessageTime;

  ChatRoomUpdate({
    required this.roomId,
    required this.lastMessage,
    required this.lastMessageTime,
  });
}