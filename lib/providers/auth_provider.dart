// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/address.dart';

enum UserRole { buyer, seller, admin, none }
enum SellerRequestStatus { none, pending, approved, rejected }

class AppUser {
  final String uid;
  final String email;
  String name;
  String phone;
  String shopName;
  String shopDescription;
  UserRole role;
  SellerRequestStatus sellerRequestStatus;
  DateTime? sellerRequestDate;
  final List<Address> addresses;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.phone,
    this.shopName = '',
    this.shopDescription = '',
    required this.role,
    this.sellerRequestStatus = SellerRequestStatus.none,
    this.sellerRequestDate,
    List<Address>? addresses,
  }) : addresses = addresses ?? [];
}

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  List<AppUser> _allUsers = [];

  // Loading state
  bool _isLoading = true;

  // Address list
  List<Address> _userAddresses = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _addressSubscription;
  StreamSubscription? _adminUsersSubscription;

  // --- GETTERS ---
  AppUser? get currentUser => _currentUser;
  List<AppUser> get allUsers => _allUsers;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  List<Address> get userAddresses => _userAddresses;
  UserRole get userRole => _currentUser?.role ?? UserRole.none;

  List<AppUser> get pendingSellerRequests =>
      _allUsers.where((u) => u.sellerRequestStatus == SellerRequestStatus.pending).toList();

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // --- AUTH LISTENER ---
  Future<void> _onAuthStateChanged(User? user) async {
    _isLoading = true;
    notifyListeners();

    if (user == null) {
      _currentUser = null;
      _userAddresses = [];
      _allUsers = [];
      _addressSubscription?.cancel();
      _adminUsersSubscription?.cancel();
    } else {
      await _fetchCurrentUser(user);
      if (_currentUser != null) {
        _listenToAddresses(_currentUser!.uid);
        if (_currentUser!.role == UserRole.admin) {
          _listenToAllUsers();
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchCurrentUser(User user) async {
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        _currentUser = _mapDataToUser(user.uid, doc.data()!);
      } else {
        _currentUser = AppUser(
            uid: user.uid, email: user.email!, name: 'New User', phone: '', role: UserRole.buyer
        );
      }
    } catch (e) {
      print("Error fetching user: $e");
    }
  }

  AppUser _mapDataToUser(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      shopName: data['shopName'] ?? '',
      shopDescription: data['shopDescription'] ?? '',
      role: UserRole.values.firstWhere((e) => e.name == (data['role'] ?? 'buyer'), orElse: () => UserRole.buyer),
      sellerRequestStatus: SellerRequestStatus.values.firstWhere((e) => e.name == (data['sellerRequestStatus'] ?? 'none'), orElse: () => SellerRequestStatus.none),
      sellerRequestDate: (data['sellerRequestDate'] as Timestamp?)?.toDate(),
      addresses: _userAddresses.isNotEmpty ? List.from(_userAddresses) : [],
    );
  }

  // --- ADDRESS LOGIC ---
  void _listenToAddresses(String uid) {
    _addressSubscription?.cancel();
    _addressSubscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .snapshots()
        .listen((snapshot) {
      _userAddresses = snapshot.docs.map((doc) => Address.fromMap(doc.data(), doc.id)).toList();
      if (_currentUser != null) {
        _currentUser!.addresses.clear();
        _currentUser!.addresses.addAll(_userAddresses);
      }
      notifyListeners();
    });
  }

  // --- STANDARD ACTIONS ---
  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> signup(String email, String password, String name, String phone) async {
    UserCredential uc = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (uc.user != null) {
      await _firestore.collection('users').doc(uc.user!.uid).set({
        'email': email,
        'name': name,
        'phone': phone,
        'role': 'buyer',
        'sellerRequestStatus': 'none',
        'shopName': '',
        'shopDescription': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> signupSeller(String email, String password, String name, String phone, String shopName, String description) async {
    UserCredential uc = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (uc.user != null) {
      await _firestore.collection('users').doc(uc.user!.uid).set({
        'email': email,
        'name': name,
        'phone': phone,
        'role': 'buyer',
        'sellerRequestStatus': 'pending',
        'shopName': shopName,
        'shopDescription': description,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // --- PROFILE & SHOP UPDATES ---

  Future<void> updateUserProfile(String name, String phone) async {
    if (_currentUser == null) return;
    await _firestore.collection('users').doc(_currentUser!.uid).update({
      'name': name,
      'phone': phone
    });
    _currentUser!.name = name;
    _currentUser!.phone = phone;
    notifyListeners();
  }

  // [RESTORED] This was missing and caused the error
  Future<void> updateShopName(String newName) async {
    if (_currentUser == null) return;
    await _firestore.collection('users').doc(_currentUser!.uid).update({'shopName': newName});
    _currentUser!.shopName = newName;
    notifyListeners();
  }

  Future<void> requestSellerAccess() async {
    if (_currentUser == null) return;
    await _firestore.collection('users').doc(_currentUser!.uid).update({
      'sellerRequestStatus': 'pending',
      'sellerRequestDate': FieldValue.serverTimestamp()
    });
    _currentUser!.sellerRequestStatus = SellerRequestStatus.pending;
    notifyListeners();
  }

  Future<void> addAddress(Map<String, dynamic> data) async {
    if (_currentUser != null) await _firestore.collection('users').doc(_currentUser!.uid).collection('addresses').add(data);
  }

  Future<void> deleteAddress(String id) async {
    if (_currentUser != null) await _firestore.collection('users').doc(_currentUser!.uid).collection('addresses').doc(id).delete();
  }

  // --- ADMIN FUNCTIONS ---

  Future<void> refreshData() async {
    final User? firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await _fetchCurrentUser(firebaseUser);
      if (_currentUser?.role == UserRole.admin) {
        _listenToAllUsers();
      }
      notifyListeners();
    }
  }

  void _listenToAllUsers() {
    _adminUsersSubscription?.cancel();
    _adminUsersSubscription = _firestore.collection('users').snapshots().listen((snapshot) {
      _allUsers = snapshot.docs.map((doc) => _mapDataToUser(doc.id, doc.data())).toList();
      notifyListeners();
    });
  }

  Future<void> approveSellerRequest(String email) async {
    final querySnapshot = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
    if (querySnapshot.docs.isNotEmpty) {
      final docId = querySnapshot.docs.first.id;
      await _firestore.collection('users').doc(docId).update({
        'role': UserRole.seller.name,
        'sellerRequestStatus': SellerRequestStatus.approved.name,
      });
    }
  }

  Future<void> rejectSellerRequest(String email, {required String message}) async {
    final querySnapshot = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
    if (querySnapshot.docs.isNotEmpty) {
      final docId = querySnapshot.docs.first.id;
      await _firestore.collection('users').doc(docId).update({
        'sellerRequestStatus': SellerRequestStatus.rejected.name,
      });
    }
  }

  Future<void> adminCreateUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
  }) async {
    FirebaseApp? tempApp;
    try {
      tempApp = await Firebase.initializeApp(
        name: 'tempAdminCreate_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      UserCredential uc = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: email, password: password);
      if (uc.user != null) {
        await _firestore.collection('users').doc(uc.user!.uid).set({
          'email': email,
          'name': name,
          'phone': phone,
          'role': role.name,
          'sellerRequestStatus': role == UserRole.seller ? 'approved' : 'none',
          'shopName': role == UserRole.seller ? '$name\'s Shop' : '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception("Failed to create user: $e");
    } finally {
      await tempApp?.delete();
    }
  }

  Future<void> updateUserAsAdmin({
    required String uid,
    required String name,
    required String phone,
    required UserRole role,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'name': name,
        'phone': phone,
        'role': role.name,
      });
    } catch (e) {
      throw Exception("Failed to update user: $e");
    }
  }

  Future<void> deleteUser(String uidOrEmail) async {
    String? docId;
    if (uidOrEmail.contains('@')) {
      final query = await _firestore.collection('users').where('email', isEqualTo: uidOrEmail).limit(1).get();
      if (query.docs.isNotEmpty) docId = query.docs.first.id;
    } else {
      docId = uidOrEmail;
    }
    if (docId != null) {
      await _firestore.collection('users').doc(docId).delete();
    }
  }

  Future<void> setUserRole(String email, UserRole newRole) async {
    final querySnapshot = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
    if (querySnapshot.docs.isNotEmpty) {
      final docId = querySnapshot.docs.first.id;
      await _firestore.collection('users').doc(docId).update({'role': newRole.name});
    }
  }
}