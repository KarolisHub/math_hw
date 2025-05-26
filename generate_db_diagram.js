const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function generateDiagram() {
  let diagram = '';

  // Get all collections
  const collections = await db.listCollections();
  
  for (const collection of collections) {
    const collectionName = collection.id;
    const docs = await collection.limit(1).get();
    
    if (!docs.empty) {
      const doc = docs.docs[0];
      const data = doc.data();
      
      // Add table definition
      diagram += `Table ${collectionName} {\n`;
      
      // Add document ID as primary key
      diagram += `  id text [pk, note: 'Document ID']\n`;
      
      // Add fields
      for (const [field, value] of Object.entries(data)) {
        let type = 'text';
        if (typeof value === 'number') {
          type = 'float';
        } else if (typeof value === 'boolean') {
          type = 'boolean';
        } else if (value instanceof Date || value?.toDate) {
          type = 'timestamp';
        }
        diagram += `  ${field} ${type}\n`;
      }
      
      diagram += '}\n\n';
    }
  }

  // Add relationships
  diagram += 'Ref: vartotojai.id > klases_nariai.vartotojo_id\n';
  diagram += 'Ref: vartotojai.id > namu_darbai.kurejo_id\n';
  diagram += 'Ref: vartotojai.id > namu_darbo_pateikimai.vartotojo_id\n';
  diagram += 'Ref: vartotojai.id > namu_darbo_komentarai.vartotojo_id\n';
  diagram += 'Ref: vartotojai.id > uzduoties_atsakymai.vartotojo_id\n';
  diagram += 'Ref: klases.id > klases_nariai.klases_id\n';
  diagram += 'Ref: klases.id > namu_darbai.klases_id\n';
  diagram += 'Ref: namu_darbai.id > namu_darbo_uzduotys.namu_darbo_id\n';
  diagram += 'Ref: namu_darbai.id > namu_darbo_pateikimai.namu_darbo_id\n';
  diagram += 'Ref: namu_darbai.id > namu_darbo_komentarai.namu_darbo_id\n';
  diagram += 'Ref: namu_darbo_pateikimai.id > uzduoties_atsakymai.pateikimo_id\n';
  diagram += 'Ref: namu_darbo_uzduotys.id > uzduoties_atsakymai.uzduoties_id\n';

  // Save to file
  fs.writeFileSync('firestore_diagram.dbml', diagram);
  console.log('Diagram generated in firestore_diagram.dbml');
}

generateDiagram().catch(console.error); 