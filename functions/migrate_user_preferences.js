/**
 * Script de migration pour ajouter les préférences de notifications
 * aux utilisateurs existants
 * 
 * Exécuter avec: node migrate_user_preferences.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin avec le projet ID
admin.initializeApp({
  projectId: 'sportcentreapp',
  credential: admin.credential.applicationDefault()
});

const db = admin.firestore();

async function migrateUserPreferences() {
  console.log('🚀 Starting user preferences migration...');

  try {
    // Récupérer tous les utilisateurs
    const usersSnapshot = await db.collection('users').get();
    console.log(`Found ${usersSnapshot.size} users`);

    let updated = 0;
    let skipped = 0;

    const batch = db.batch();

    usersSnapshot.docs.forEach((doc) => {
      const data = doc.data();

      // Si l'utilisateur n'a pas déjà de préférences
      if (!data.notificationPreferences) {
        batch.update(doc.ref, {
          notificationPreferences: {
            method: 'inApp',
            reminderHoursBefore: 2
          }
        });
        updated++;
        console.log(`✅ Will add preferences for user: ${doc.id}`);
      } else {
        skipped++;
        console.log(`⏭️  User ${doc.id} already has preferences`);
      }
    });

    // Commit le batch
    await batch.commit();

    console.log('\n📊 Migration Summary:');
    console.log(`   Total users: ${usersSnapshot.size}`);
    console.log(`   Updated: ${updated}`);
    console.log(`   Skipped: ${skipped}`);
    console.log('\n✅ Migration completed successfully!');

  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  }
}

// Exécuter la migration
migrateUserPreferences()
  .then(() => {
    console.log('Done!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Error:', error);
    process.exit(1);
  });
