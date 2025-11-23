// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/address.dart';

// Enum dan Class AppUser Anda sudah sangat bagus.
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

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _addressSubscription;
  StreamSubscription? _adminUsersSubscription;

  AppUser? get currentUser => _currentUser;
  List<AppUser> get allUsers => _allUsers;
  bool get isLoggedIn => _currentUser != null;

  // Getter PENTING: UI harus bergantung pada ini untuk memberikan akses.
  UserRole get userRole => _currentUser?.role ?? UserRole.none;

  List<AppUser> get pendingSellerRequests =>
      _allUsers.where((u) => u.sellerRequestStatus == SellerRequestStatus.pending).toList();

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _currentUser = null;
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
    notifyListeners();
  }

  Future<void> _fetchCurrentUser(User user) async {
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      _currentUser = _mapDataToUser(user.uid, doc.data()!);
    } else {
      // Jika dokumen tidak ada (kasus yang jarang terjadi setelah signup),
      // buat objek AppUser sementara.
      _currentUser = AppUser(
          uid: user.uid, email: user.email!, name: 'New User', phone: '', role: UserRole.buyer
      );
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
      // Ini adalah baris kunci. Role diambil dari database.
      role: UserRole.values.firstWhere((e) => e.name == (data['role'] ?? 'buyer'), orElse: () => UserRole.buyer),
      sellerRequestStatus: SellerRequestStatus.values.firstWhere((e) => e.name == (data['sellerRequestStatus'] ?? 'none'), orElse: () => SellerRequestStatus.none),
      sellerRequestDate: (data['sellerRequestDate'] as Timestamp?)?.toDate(),
      addresses: _currentUser?.uid == uid ? (_currentUser?.addresses ?? []) : [],
    );
  }

  // --- STANDARD AUTH ---

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    // _onAuthStateChanged akan otomatis terpanggil dan menangani sisanya.
  }

  Future<void> signup(String email, String password, String name, String phone) async {
    UserCredential uc = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (uc.user != null) {
      await _firestore.collection('users').doc(uc.user!.uid).set({
        'email': email,
        'name': name,
        'phone': phone,
        'role': 'buyer', // Role awal SELALU buyer
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
        'role': 'buyer', // <-- PENEGASAN: Role awal TETAP 'buyer'.
        'sellerRequestStatus': 'pending', // <-- HANYA status yang 'pending'.
        'shopName': shopName,
        'shopDescription': description,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }


  // --- ADMIN FUNCTIONS ---

  Future<void> approveSellerRequest(String email) async {
    try {
      final querySnapshot = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        // --- LOGIKA KUNCI ---
        // Saat disetujui, role diubah menjadi 'seller'.
        await _firestore.collection('users').doc(docId).update({
          'role': UserRole.seller.name,
          'sellerRequestStatus': SellerRequestStatus.approved.name,
        });
      } else {
        throw Exception("User with email $email not found for approval.");
      }
    } catch (e) {
      throw Exception("Failed to approve seller: $e");
    }
  }

  Future<void> rejectSellerRequest(String email, {required String message}) async {
    try {
      final querySnapshot = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await _firestore.collection('users').doc(docId).update({
          // Role tidak diubah, tetap 'buyer'
          'sellerRequestStatus': SellerRequestStatus.rejected.name,
        });
      } else {
        throw Exception("User with email $email not found for rejection.");
      }
    } catch (e) {
      throw Exception("Failed to reject seller: $e");
    }
  }

  // --- Fungsi lain yang sudah ada ---
  // (adminCreateUser, updateUserAsAdmin, deleteUser, dll. tetap sama)

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

  Future<void> adminCreateUser({ required String email, required String password, required String name, required String phone, required UserRole role, }) async { FirebaseApp? tempApp; try { tempApp = await Firebase.initializeApp( name: 'tempAdminCreate_${DateTime.now().millisecondsSinceEpoch}', options: Firebase.app().options, ); UserCredential uc = await FirebaseAuth.instanceFor(app: tempApp) .createUserWithEmailAndPassword(email: email, password: password); if (uc.user != null) { await _firestore.collection('users').doc(uc.user!.uid).set({ 'email': email, 'name': name, 'phone': phone, 'role': role.name, 'sellerRequestStatus': role == UserRole.seller ? 'approved' : 'none', 'shopName': role == UserRole.seller ? '$name\'s Shop' : '', 'createdAt': FieldValue.serverTimestamp(), }); } } catch (e) { throw Exception("Failed to create user: $e"); } finally { await tempApp?.delete(); } }
  void _listenToAllUsers() { _adminUsersSubscription?.cancel(); _adminUsersSubscription = _firestore.collection('users').snapshots().listen((snapshot) { _allUsers = snapshot.docs.map((doc) => _mapDataToUser(doc.id, doc.data())).toList(); notifyListeners(); }); }
  Future<void> deleteUser(String uid) async { print("DEPRECATED: deleteUser(uid) was called. Use a Cloud Function for secure deletion."); }
  Future<void> setUserRole(String email, UserRole newRole) async { try { final querySnapshot = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get(); if (querySnapshot.docs.isNotEmpty) { final docId = querySnapshot.docs.first.id; await _firestore.collection('users').doc(docId).update({'role': newRole.name}); } } catch (e) { print("Error setting user role: $e"); } }
  Future<void> updateUserProfile(String name, String phone) async { if (_currentUser == null) return; await _firestore.collection('users').doc(_currentUser!.uid).update({'name': name, 'phone': phone}); _currentUser!.name = name; _currentUser!.phone = phone; notifyListeners(); }
  Future<void> updateShopName(String newName) async { if (_currentUser == null) return; await _firestore.collection('users').doc(_currentUser!.uid).update({'shopName': newName}); _currentUser!.shopName = newName; notifyListeners(); }
  Future<void> requestSellerAccess() async { if (_currentUser == null) return; await _firestore.collection('users').doc(_currentUser!.uid).update({'sellerRequestStatus': 'pending', 'sellerRequestDate': FieldValue.serverTimestamp()}); _currentUser!.sellerRequestStatus = SellerRequestStatus.pending; notifyListeners(); }
  Future<void> updateUserAsAdmin({ required String uid, required String name, required String phone, required UserRole role, }) async { if (role == UserRole.admin) { throw Exception("Cannot assign 'admin' role directly."); } try { await _firestore.collection('users').doc(uid).update({ 'name': name, 'phone': phone, 'role': role.name, }); } catch (e) { throw Exception("Failed to update user: $e"); } }
  void _listenToAddresses(String uid) { _addressSubscription?.cancel(); _addressSubscription = _firestore.collection('users').doc(uid).collection('addresses').snapshots().listen((snapshot) { if (_currentUser != null) { _currentUser!.addresses.clear(); for (var doc in snapshot.docs) { _currentUser!.addresses.add(Address.fromMap(doc.data(), doc.id)); } notifyListeners(); } }); }
  Future<void> addAddress(Map<String, dynamic> data) async { if (_currentUser != null) await _firestore.collection('users').doc(_currentUser!.uid).collection('addresses').add(data); }
  Future<void> deleteAddress(String id) async { if (_currentUser != null) await _firestore.collection('users').doc(_currentUser!.uid).collection('addresses').doc(id).delete(); }

}
