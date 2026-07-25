import 'package:shared_preferences/shared_preferences.dart';

class SharedpreferenceHelper {
  static const String _userIdKey = "USER_ID";
  static const String _userNameKey = "USER_NAME";
  static const String _userEmailKey = "USER_EMAIL";
  static const String _userTypeKey = "USER_TYPE";

  // save user ID
  Future<void> saveUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, id);
  }

  // save user name
  Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  // save user email
  Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
  }

  // get user ID
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // get user name
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  // get user email
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  // clear all user data
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static String userProfileUrlKey = "USERPROFILEURLKEY";
  static const String _userNidKey = "USER_NID";
  static const String _userPhoneKey = "USER_PHONE";

  Future<bool> saveUserProfileUrl(String userProfileUrl) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userProfileUrlKey, userProfileUrl);
  }

  Future<String?> getUserProfileUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userProfileUrlKey);
  }

  // save user NID
  Future<void> saveUserNid(String nid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNidKey, nid);
  }

  // get user NID
  Future<String?> getUserNid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNidKey);
  }

  // save user phone
  Future<void> saveUserPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userPhoneKey, phone);
  }

  // get user phone
  Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhoneKey);
  }

  Future<void> saveUserType(String userType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userTypeKey, userType);
  }

  Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey);
  }
}
