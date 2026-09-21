/// App-wide Constants for Drop.
class AppConstants {
  AppConstants._();

  static const String appName = 'Drop';
  static const String appTagline = 'Share moments in dark & white.';

  // Firebase Firestore Collection Names
  static const String usersCollection = 'users';
  static const String handlesCollection = 'handles';
  static const String postsCollection = 'posts';
  static const String likesCollection = 'likes';
  static const String commentsCollection = 'comments';
  static const String followersSubcollection = 'followers';
  static const String followingSubcollection = 'following';
  static const String conversationsCollection = 'conversations';
  static const String messagesSubcollection = 'messages';
  static const String notificationsCollection = 'notifications';

  // Firestore & Storage Limits
  static const int maxCaptionLength = 2200;
  static const int maxBioLength = 150;
  static const int handleMinLength = 3;
  static const int handleMaxLength = 20;

  // Handle Regex (@username validation: letters, numbers, underscores)
  static final RegExp handleRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
}
