import 'package:chess/core/firebase/firestore_paths.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Low-level Firestore access — no business logic.
abstract class FirestoreService {
  FirebaseFirestore get instance;

  CollectionReference<Map<String, dynamic>> collection(String path);

  DocumentReference<Map<String, dynamic>> document(String path);
}

/// Default [FirestoreService] using [FirebaseFirestore.instance].
class FirestoreServiceImpl implements FirestoreService {
  FirestoreServiceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  FirebaseFirestore get instance => _firestore;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  @override
  DocumentReference<Map<String, dynamic>> document(String path) {
    return _firestore.doc(path);
  }

  CollectionReference<Map<String, dynamic>> get users =>
      collection(FirestorePaths.users);

  CollectionReference<Map<String, dynamic>> get games =>
      collection(FirestorePaths.games);

  CollectionReference<Map<String, dynamic>> get matchmaking =>
      collection(FirestorePaths.matchmaking);
}
