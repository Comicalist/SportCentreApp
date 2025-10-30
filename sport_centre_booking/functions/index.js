const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onRequest} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();
const db = admin.firestore();

// Set global options for cost control
setGlobalOptions({maxInstances: 10});

// Email transporter (Gmail)
const getTransporter = () => {
  return nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: process.env.EMAIL_USER || "l.ehrwein@gmail.com",
      pass: process.env.EMAIL_PASSWORD || "xabp dsrz kwjf rnsb",
    },
  });
};

// 🎯 Function 1: When booking is created, schedule a reminder
exports.onBookingCreated = onDocumentCreated("bookings/{bookingId}", async (event) => {
  const booking = event.data.data();
  const bookingId = event.params.bookingId;

  console.log(`New booking created: ${bookingId}`);

  // Get user preferences
  const userDoc = await db.collection("users").doc(booking.userId).get();
  const userData = userDoc.data();
  const prefs = userData?.notificationPreferences || {
    method: "inApp",
    reminderHoursBefore: 2,
  };

  // Calculate reminder time
  const bookingTime = booking.scheduledDate.toDate();
  const reminderTime = new Date(
    bookingTime.getTime() - prefs.reminderHoursBefore * 60 * 60 * 1000
  );

  // Save pending notification
  await db.collection("pendingNotifications").add({
    userId: booking.userId,
    bookingId: bookingId,
    type: "bookingReminder",
    scheduledFor: admin.firestore.Timestamp.fromDate(reminderTime),
    bookingTime: admin.firestore.Timestamp.fromDate(bookingTime),
    activityName: booking.activityName,
    reminderHoursBefore: prefs.reminderHoursBefore,
    method: prefs.method,
    userEmail: userData?.email,
    created: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Scheduled reminder for ${reminderTime}`);
});

// 🎯 Function 2: When booking is cancelled
exports.onBookingCancelled = onDocumentUpdated("bookings/{bookingId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  // Check if status changed to cancelled
  if (before.status !== "cancelled" && after.status === "cancelled") {
    const bookingId = event.params.bookingId;
    console.log(`Booking cancelled: ${bookingId}`);

    // Get user preferences
    const userDoc = await db.collection("users").doc(after.userId).get();
    const userData = userDoc.data();
    const prefs = userData?.notificationPreferences || {method: "inApp"};

    // Send notification based on preference
    if (prefs.method === "inApp") {
      await db.collection("notifications").add({
        userId: after.userId,
        type: "bookingCancellation",
        title: "Booking Cancelled",
        body: `Your booking for ${after.activityName} has been cancelled`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
        bookingId: bookingId,
        activityName: after.activityName,
      });
      console.log("In-app notification created");
    } else if (prefs.method === "email") {
      await sendCancellationEmail(userData?.email, after);
      console.log("Cancellation email sent");
    }

    // Delete pending reminder
    const pendingSnap = await db
      .collection("pendingNotifications")
      .where("bookingId", "==", bookingId)
      .get();

    const batch = db.batch();
    pendingSnap.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  }
});

// 🎯 Function 3: Check pending notifications every hour
exports.checkPendingNotifications = onSchedule("every 1 hours", async (event) => {
  const now = admin.firestore.Timestamp.now();
  console.log("Checking pending notifications...");

  const pendingSnap = await db
    .collection("pendingNotifications")
    .where("scheduledFor", "<=", now.toDate())
    .get();

  console.log(`Found ${pendingSnap.size} notifications to send`);

  for (const doc of pendingSnap.docs) {
    const pending = doc.data();

    try {
      if (pending.method === "inApp") {
        // Create in-app notification
        await db.collection("notifications").add({
          userId: pending.userId,
          type: pending.type,
          title: "Booking Reminder",
          body: `Your ${pending.activityName} starts in ${pending.reminderHoursBefore || 2} hours!`,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false,
          bookingId: pending.bookingId,
          activityName: pending.activityName,
        });
        console.log(`In-app notification created for ${pending.bookingId}`);
      } else if (pending.method === "email" && pending.userEmail) {
        // Send email
        await sendReminderEmail(pending.userEmail, pending);
        console.log(`Email sent to ${pending.userEmail}`);
      }

      // Delete from pending
      await doc.ref.delete();
    } catch (error) {
      console.error(`Error sending notification: ${error}`);
    }
  }
});

// 🎯 Function 4: Cleanup old notifications (30 days)
exports.cleanupOldNotifications = onSchedule("every 24 hours", async (event) => {
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  console.log(`Cleaning notifications older than ${thirtyDaysAgo}`);

  const oldNotifs = await db
    .collection("notifications")
    .where("timestamp", "<", admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
    .get();

  console.log(`Found ${oldNotifs.size} old notifications to delete`);

  const batch = db.batch();
  oldNotifs.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
});

// 📧 Send reminder email
async function sendReminderEmail(email, data) {
  const transporter = getTransporter();
  const bookingTime = data.bookingTime.toDate();

  const mailOptions = {
    from: process.env.EMAIL_USER || "l.ehrwein@gmail.com",
    to: email,
    subject: `🏃 Booking Reminder - ${data.activityName}`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #00897b;">Your activity is coming up!</h2>
        <p style="font-size: 16px;"><strong>${data.activityName}</strong> starts soon.</p>
        <p style="font-size: 14px; color: #666;">
          📅 Date: ${bookingTime.toLocaleString("en-US", {
            weekday: "long",
            year: "numeric",
            month: "long",
            day: "numeric",
            hour: "2-digit",
            minute: "2-digit",
          })}
        </p>
        <p style="margin-top: 20px;">See you there! 🎉</p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
        <p style="font-size: 12px; color: #999;">
          Sport Centre Booking App
        </p>
      </div>
    `,
  };

  await transporter.sendMail(mailOptions);
}

// 📧 Send cancellation email
async function sendCancellationEmail(email, booking) {
  const transporter = getTransporter();
  const bookingTime = booking.scheduledDate.toDate();

  const mailOptions = {
    from: process.env.EMAIL_USER || "l.ehrwein@gmail.com",
    to: email,
    subject: `❌ Booking Cancelled - ${booking.activityName}`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #d32f2f;">Your booking has been cancelled</h2>
        <p style="font-size: 16px;">
          <strong>${booking.activityName}</strong> scheduled for 
          ${bookingTime.toLocaleString("en-US", {
            weekday: "long",
            year: "numeric",
            month: "long",
            day: "numeric",
            hour: "2-digit",
            minute: "2-digit",
          })} 
          has been cancelled.
        </p>
        <p style="margin-top: 20px;">If you have any questions, please contact us.</p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
        <p style="font-size: 12px; color: #999;">
          Sport Centre Booking App
        </p>
      </div>
    `,
  };

  await transporter.sendMail(mailOptions);
}

// 🔧 Migration Function: Add default notification preferences to all users
exports.migrateUserPreferences = onRequest({cors: true}, async (req, res) => {
  console.log("🚀 Starting user preferences migration...");

  try {
    const usersSnapshot = await db.collection("users").get();
    console.log(`Found ${usersSnapshot.size} users`);

    let updated = 0;
    let skipped = 0;

    // Process in batches of 500 (Firestore limit)
    const batchSize = 500;
    let batch = db.batch();
    let operationCount = 0;

    for (const doc of usersSnapshot.docs) {
      const data = doc.data();

      // If user doesn't have notification preferences
      if (!data.notificationPreferences) {
        batch.update(doc.ref, {
          notificationPreferences: {
            method: "inApp",
            reminderHoursBefore: 2,
          },
        });
        updated++;
        operationCount++;
        console.log(`✅ Will add preferences for user: ${doc.id}`);

        // Commit batch if we reach the limit
        if (operationCount >= batchSize) {
          await batch.commit();
          batch = db.batch();
          operationCount = 0;
        }
      } else {
        skipped++;
        console.log(`⏭️  User ${doc.id} already has preferences`);
      }
    }

    // Commit remaining operations
    if (operationCount > 0) {
      await batch.commit();
    }

    const result = {
      success: true,
      totalUsers: usersSnapshot.size,
      updated,
      skipped,
    };

    console.log("✅ Migration completed:", result);
    res.status(200).json(result);
  } catch (error) {
    console.error("❌ Migration failed:", error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// 🧪 HTTP Trigger for Manual Testing: Check Pending Notifications
exports.triggerCheckPendingNotifications = onRequest({cors: true}, async (req, res) => {
  console.log("🧪 Manual trigger: Checking pending notifications...");

  try {
    const now = admin.firestore.Timestamp.now();
    
    const pendingSnap = await db
      .collection("pendingNotifications")
      .where("scheduledFor", "<=", now.toDate())
      .get();

    console.log(`Found ${pendingSnap.size} notifications to send`);

    let sent = 0;
    let failed = 0;
    const errors = [];

    for (const doc of pendingSnap.docs) {
      const pending = doc.data();

      try {
        if (pending.method === "inApp") {
          // Create in-app notification
          await db.collection("notifications").add({
            userId: pending.userId,
            type: pending.type,
            title: "Booking Reminder",
            body: `Your ${pending.activityName} starts in ${pending.reminderHoursBefore || 2} hours!`,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            isRead: false,
            bookingId: pending.bookingId,
            activityName: pending.activityName,
          });
          console.log(`✅ In-app notification created for ${pending.bookingId}`);
          sent++;
        } else if (pending.method === "email" && pending.userEmail) {
          // Send email
          await sendReminderEmail(pending.userEmail, pending);
          console.log(`✅ Email sent to ${pending.userEmail}`);
          sent++;
        }

        // Delete from pending
        await doc.ref.delete();
      } catch (error) {
        console.error(`❌ Error sending notification: ${error}`);
        failed++;
        errors.push({bookingId: pending.bookingId, error: error.message});
      }
    }

    const result = {
      success: true,
      totalPending: pendingSnap.size,
      sent,
      failed,
      errors: errors.length > 0 ? errors : undefined,
      timestamp: new Date().toISOString(),
    };

    console.log("✅ Manual trigger completed:", result);
    res.status(200).json(result);
  } catch (error) {
    console.error("❌ Manual trigger failed:", error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});
