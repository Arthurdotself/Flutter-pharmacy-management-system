import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  String _userId = '';
  static const String _userIdKey = 'user_id';
  String get userId => _userId;


  String _PharmacyId = '';
  static const String _PharmacyIdKey = 'Pharmacy_id';
  String get PharmacyId => _PharmacyId;


  UserProvider() {
    // Load user ID from shared preferences when the provider is initialized
    _loadUserId();
    _loadPharmacyId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString(_userIdKey) ?? '';
    notifyListeners();
  }

  Future<void> setUserId(String userId) async {
    _userId = userId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }



  Future<void> _loadPharmacyId() async {
    final prefs = await SharedPreferences.getInstance();
    _PharmacyId = prefs.getString(_PharmacyIdKey) ?? '';
    notifyListeners();
  }

  Future<void> setPharmacyId(String PharmacyId) async {
    _PharmacyId = PharmacyId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_PharmacyIdKey, PharmacyId);
  }
}
