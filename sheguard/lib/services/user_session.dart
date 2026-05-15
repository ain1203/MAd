class UserSession {
  static String displayName = 'User';
  static String email = 'user@example.com';
  static String? fullName;
  static String? profileImageUrl;

  static void setFromEmail(String emailAddress) {
    email = emailAddress;
    final local = emailAddress.split('@').first;
    final firstName = local.replaceAll(RegExp(r'[._\-]'), ' ').trim().split(' ').first;
    displayName = _cap(firstName);
  }

  static void setFromFullName(String name) {
    fullName = name;
    if (name.isNotEmpty) {
      displayName = _cap(name.trim().split(' ').first);
    }
  }

  static void setProfileImage(String url) {
    profileImageUrl = url;
  }

  static void clearSession() {
    displayName = 'User';
    email = '';
    fullName = null;
    profileImageUrl = null;
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}
