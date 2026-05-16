import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property.dart';

class PropertyRepository {
  static final PropertyRepository instance = PropertyRepository._internal();
  PropertyRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Schema: propertyID(PK), agentID(FK→Users, idx), propertyType(idx),
  //         Status(idx), Price(idx), Bathrooms(idx)

  Future<List<Property>> getAll() async {
    final snapshot = await _firestore.collection('Properties').get();
    return snapshot.docs.map((doc) => Property.fromFirestore(doc)).toList();
  }

  /// Query by agentID (FK/idx field)
  Future<List<Property>> getByAgent(String agentID) async {
    final snapshot = await _firestore
        .collection('Properties')
        .where('agentID', isEqualTo: agentID)
        .get();
    return snapshot.docs.map((doc) => Property.fromFirestore(doc)).toList();
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

  void toggleSave(String id) {
    // Local toggle for now, can be synced with a 'SavedProperties' collection later
  }
}
