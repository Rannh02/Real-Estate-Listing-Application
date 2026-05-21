import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/property.dart';

class PropertyRepository {
  static final PropertyRepository instance = PropertyRepository._internal();
  PropertyRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Schema: propertyID(PK), agentID(FK→Users, idx), propertyType(idx),
  //         Status(idx), Price(idx), Bathrooms(idx)

  Future<List<Property>> getAll() async {
    final snapshot = await _firestore.collection('Properties').get();
    var properties = snapshot.docs
        .map((doc) => Property.fromFirestore(doc))
        .where((p) => p.status != PropertyStatus.pending)
        .toList();

    properties = await _applySavedStatus(properties);
    return properties;
  }

  /// Query by agentID (FK/idx field)
  Future<List<Property>> getByAgent(String agentID) async {
    final snapshot = await _firestore
        .collection('Properties')
        .where('agentID', isEqualTo: agentID)
        .get();
    var properties = snapshot.docs.map((doc) => Property.fromFirestore(doc)).toList();
    
    properties = await _applySavedStatus(properties);
    return properties;
  }

  Future<List<Property>> _applySavedStatus(List<Property> properties) async {
    final buyerId = _auth.currentUser?.uid;
    if (buyerId != null) {
      final savedSnapshot = await _firestore
          .collection('SavedProperties')
          .where('buyerID', isEqualTo: buyerId)
          .get();
      
      final savedPropertyIds = savedSnapshot.docs
          .map((doc) => doc.data()['propertyID'] as String)
          .toSet();

      return properties.map((p) {
        if (savedPropertyIds.contains(p.id)) {
          return p.copyWith(isSaved: true);
        }
        return p;
      }).toList();
    }
    return properties;
  }

  Future<void> incrementViewCount(String propertyId) async {
    await _firestore.collection('Properties').doc(propertyId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  /// Uses propertyID as the Firestore document ID (PK)
  Future<void> add(Property property) async {
    await _firestore
        .collection('Properties')
        .doc(property.id)
        .set(property.toFirestore());
  }

  Future<void> delete(String id) async {
    await _firestore.collection('Properties').doc(id).delete();
  }

  Future<void> toggleSave(String propertyId) async {
    final buyerId = _auth.currentUser?.uid;
    if (buyerId == null) return;

    final query = await _firestore
        .collection('SavedProperties')
        .where('buyerID', isEqualTo: buyerId)
        .where('propertyID', isEqualTo: propertyId)
        .get();

    if (query.docs.isEmpty) {
      final docRef = _firestore.collection('SavedProperties').doc();
      await docRef.set({
        'savedID': docRef.id,
        'buyerID': buyerId,
        'propertyID': propertyId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } else {
      for (var doc in query.docs) {
        await doc.reference.delete();
      }
    }
  }
}
