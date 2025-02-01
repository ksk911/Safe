import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreStructure {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Recursively fetch and print Firestore structure
  Future<void> printFirestoreStructure({String? path}) async {
    CollectionReference collection = firestore.collection(path ?? "");

    try {
      // Fetch all documents in the collection
      QuerySnapshot querySnapshot = await collection.get();

      for (var doc in querySnapshot.docs) {
        print("📂 Collection: ${collection.path}");
        print("📄 Document ID: ${doc.id}");
        print("📜 Data: ${doc.data()}");

        // Fetch subcollections of the document
        await fetchSubcollections(doc.reference);
      }
    } catch (e) {
      print("⚠️ Error fetching Firestore structure: $e");
    }
  }

  /// Fetch subcollections of a document
  Future<void> fetchSubcollections(DocumentReference docRef) async {
    try {
      // Manually list subcollections by querying known subcollection names
      List<String> subcollectionNames = [
        'subcollection1',
        'subcollection2'
      ]; // Add your subcollection names here

      for (var subcollectionName in subcollectionNames) {
        CollectionReference subcollection =
            docRef.collection(subcollectionName);
        QuerySnapshot subcollectionSnapshot = await subcollection.get();

        if (subcollectionSnapshot.docs.isNotEmpty) {
          print("📂 Subcollection: ${subcollection.path}");
          for (var subDoc in subcollectionSnapshot.docs) {
            print("📄 Subdocument ID: ${subDoc.id}");
            print("📜 Subdocument Data: ${subDoc.data()}");
          }
        }
      }
    } catch (e) {
      print("⚠️ Error fetching subcollections: $e");
    }
  }

  /// Function to start fetching Firestore structure
  Future<void> fetchFirestoreStructure() async {
    print("🔍 Fetching Firestore structure...");
    await printFirestoreStructure();
    print("✅ Firestore structure retrieval complete.");
  }
}
