import 'package:flutter/material.dart';

enum UserRole { buyer, seller, admin, none }

enum SellerRequestStatus { none, pending, approved, rejected }

class AppUser {
  final String email;
  UserRole role;

  SellerRequestStatus sellerRequestStatus;
  DateTime? sellerRequestDate;
  String? sellerRequestMessage;

  AppUser({
    required this.email,
    required this.role,
    this.sellerRequestStatus = SellerRequestStatus.none,
    this.sellerRequestDate,
    this.sellerRequestMessage,
  });

  // Mark a request to become a seller
  void requestSeller({String? message}) {
    sellerRequestStatus = SellerRequestStatus.pending;
    sellerRequestDate = DateTime.now();
    sellerRequestMessage = message;
  }

  // Approve the seller request and promote the user
  void approveSeller() {
    sellerRequestStatus = SellerRequestStatus.approved;
  }

  // Reject the seller request
  void rejectSeller({String? message}) {
    sellerRequestStatus = SellerRequestStatus.rejected;
    sellerRequestMessage = message;
  }
}

class AuthProvider extends ChangeNotifier {
  // In-memory user registry (replace with Firestore in production)
  final Map<String, AppUser> _users = {};

  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  UserRole get userRole => _currentUser?.role ?? UserRole.none;

  bool get canAccessSellerFeatures => userRole == UserRole.seller;

  List<AppUser> get allUsers => _users.values.toList(growable: false);

  static const Set<String> _adminEmails = {'admin@umkm.com'};

  SellerRequestStatus sellerRequestStatusOf(String email) {
    final u = _users[email.toLowerCase().trim()];
    return u?.sellerRequestStatus ?? SellerRequestStatus.none;
  }

  bool get isSellerPending =>
      _currentUser?.sellerRequestStatus == SellerRequestStatus.pending;

  bool get isSellerApproved =>
      _currentUser?.sellerRequestStatus == SellerRequestStatus.approved;

  // --- New: buyer requests a seller account (needs admin approval) ---
  Future<bool> requestSellerAccount(
    String email,
    String password, {
    String? message,
  }) async {
    final e = email.toLowerCase().trim();

    // Create/find user as buyer in registry
    AppUser user = _users[e] ?? AppUser(email: e, role: UserRole.buyer);
    _users[e] = user;

    // If already a seller, block
    if (user.role == UserRole.seller) return false;

    // If already pending, treat as success (idempotent)
    if (user.sellerRequestStatus == SellerRequestStatus.pending) return true;

    // Record request
    user.requestSeller(message: message);
    notifyListeners();
    return true;
  }

  List<AppUser> get pendingSellerRequests => _users.values
      .where((u) => u.sellerRequestStatus == SellerRequestStatus.pending)
      .toList(growable: false);

  // --- New: admin approves seller request ---
  Future<bool> approveSellerRequest(String email) async {
    final e = email.toLowerCase().trim();
    final user = _users[e];
    if (user == null) return false;

    // Mark approved; role is upgraded only when applying upgrade below
    user.approveSeller();
    // If the approved user is currently logged in, notify
    if (_currentUser?.email == user.email) {
      notifyListeners();
    } else {
      notifyListeners();
    }
    return true;
  }

  Future<bool> upsertUser(
    String email, {
    UserRole role = UserRole.buyer,
  }) async {
    final e = email.toLowerCase().trim();
    if (e.isEmpty) return false;

    final u = _users[e] ?? AppUser(email: e, role: role);
    u.role = role;
    // If admin sets user to seller directly, mark as approved
    if (role == UserRole.seller) {
      u.sellerRequestStatus = SellerRequestStatus.approved;
    }
    // If demoted to buyer, clear seller status
    if (role == UserRole.buyer &&
        u.sellerRequestStatus != SellerRequestStatus.none) {
      u.sellerRequestStatus = SellerRequestStatus.none;
    }
    _users[e] = u;
    notifyListeners();
    return true;
  }

  // --- New: admin rejects seller request ---
  Future<bool> rejectSellerRequest(String email, {String? message}) async {
    final e = email.toLowerCase().trim();
    final user = _users[e];
    if (user == null) return false;

    user.rejectSeller(message: message);
    if (_currentUser?.email == user.email) {
      notifyListeners();
    } else {
      notifyListeners();
    }
    return true;
  }

  Future<bool> setUserRole(String email, UserRole role) async {
    final e = email.toLowerCase().trim();
    final u = _users[e];
    if (u == null) return false;

    u.role = role;
    if (role == UserRole.seller) {
      u.sellerRequestStatus = SellerRequestStatus.approved;
    } else if (role == UserRole.buyer) {
      u.sellerRequestStatus = SellerRequestStatus.none;
    }
    notifyListeners();
    return true;
  }

  bool deleteUser(String email) {
    final e = email.toLowerCase().trim();
    final removed = _users.remove(e) != null;
    if (removed && _currentUser?.email == e) {
      _currentUser = null;
    }
    if (removed) notifyListeners();
    return removed;
  }

  // Mock login function
  Future<void> login(String email, String password) async {
    final e = email.toLowerCase().trim();

    if (_adminEmails.contains(e)) {
      final existing = _users[e];
      if (existing == null) {
        final admin = AppUser(email: e, role: UserRole.admin);
        _users[e] = admin;
        _currentUser = admin;
      } else {
        existing.role = UserRole.admin;
        _currentUser = existing;
      }
      notifyListeners();
      return;
    }

    AppUser? user = _users[e];
    user ??= switch (e) {
      'buyer@test.com' => AppUser(email: e, role: UserRole.buyer),
      'seller@test.com' => AppUser(
        email: e,
        role: UserRole.seller,
        sellerRequestStatus: SellerRequestStatus.approved,
      ),
      _ => null,
    };

    if (user != null) {
      _users[e] = user;
      _currentUser = user;
    } else {
      _currentUser = null;
    }
    notifyListeners();
  }

  // Apply approved request to actually upgrade the logged-in user to seller
  Future<bool> upgradeToSeller() async {
    if (_currentUser == null) return false;
    // Only allow if request is approved by admin
    if (_currentUser!.sellerRequestStatus == SellerRequestStatus.approved) {
      _currentUser!.role = UserRole.seller;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }
}
