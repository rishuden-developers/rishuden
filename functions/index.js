/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");

// Firebase Admin SDKの初期化
const admin = require("firebase-admin");
admin.initializeApp();

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

// クエスト作成時に同じ授業を取っているユーザーにプッシュ通知を送信
exports.sendPushOnQuestCreated = onDocumentCreated(
  "quests/{questId}",
  async (event) => {
    try {
      const quest = event.data.data();
      const questId = event.params.questId;

      if (!quest) {
        logger.error("Quest data not found");
        return;
      }

      const enrolledUserIds = quest.enrolledUserIds || [];
      const creatorId = quest.createdBy;
      const questName = quest.name || "クエスト";
      const courseName = quest.courseId || "授業";

      logger.info(`Quest created: ${questName} by ${creatorId}`);

      // 作成者の情報を取得
      let creatorName = "誰か";
      try {
        const creatorDoc = await admin
          .firestore()
          .collection("users")
          .doc(creatorId)
          .get();
        if (creatorDoc.exists) {
          creatorName = creatorDoc.data().character || "誰か";
        }
      } catch (error) {
        logger.error("Error getting creator info:", error);
      }

      // 各ユーザーのFCMトークンを取得
      const tokens = [];
      for (const userId of enrolledUserIds) {
        // 作成者自身には送らない
        if (userId === creatorId) continue;

        try {
          const userDoc = await admin
            .firestore()
            .collection("users")
            .doc(userId)
            .get();
          if (userDoc.exists && userDoc.data().fcmToken) {
            tokens.push(userDoc.data().fcmToken);
            logger.info(`Found FCM token for user: ${userId}`);
          }
        } catch (error) {
          logger.error(`Error getting FCM token for user ${userId}:`, error);
        }
      }

      if (tokens.length === 0) {
        logger.info("No FCM tokens found for enrolled users");
        return;
      }

      // プッシュ通知のペイロードを作成
      const payload = {
        notification: {
          title: "新しいクエストが作成されました！",
          body: `${creatorName}が${courseName}で「${questName}」クエストを作成しました`,
        },
        data: {
          type: "new_quest_created",
          questId: questId,
          courseName: courseName,
          questName: questName,
        },
      };

      // プッシュ通知を送信
      const response = await admin.messaging().sendToDevice(tokens, payload);

      logger.info(`Push notification sent to ${tokens.length} users`);
      logger.info(
        `Success count: ${response.successCount}, Failure count: ${response.failureCount}`
      );

      // 失敗したトークンを処理
      if (response.failureCount > 0) {
        const failedTokens = [];
        response.results.forEach((result, index) => {
          if (!result.success) {
            failedTokens.push(tokens[index]);
            logger.error(
              `Failed to send notification to token: ${tokens[index]}`
            );
          }
        });
      }
    } catch (error) {
      logger.error("Error sending push notification:", error);
    }
  }
);

// たこ焼き受信時にプッシュ通知を送信
exports.sendPushOnTakoyakiReceived = onDocumentCreated(
  "users/{userId}/notifications/{notificationId}",
  async (event) => {
    try {
      const notification = event.data.data();
      const userId = event.params.userId;
      const notificationId = event.params.notificationId;

      if (!notification) {
        logger.error("Notification data not found");
        return;
      }

      // たこ焼き受信通知のみを処理
      if (notification.type !== "takoyaki_received") {
        return;
      }

      logger.info(
        `Takoyaki received notification: ${notificationId} for user: ${userId}`
      );

      // 受信者のFCMトークンを取得
      let fcmToken = null;
      try {
        const userDoc = await admin
          .firestore()
          .collection("users")
          .doc(userId)
          .get();
        if (userDoc.exists && userDoc.data().fcmToken) {
          fcmToken = userDoc.data().fcmToken;
          logger.info(`Found FCM token for user: ${userId}`);
        }
      } catch (error) {
        logger.error(`Error getting FCM token for user ${userId}:`, error);
      }

      if (!fcmToken) {
        logger.info("No FCM token found for user");
        return;
      }

      // 送信者の情報を取得（キャラクター名で匿名性を保つ）
      let senderName = "誰か";
      if (notification.senderId) {
        try {
          const senderDoc = await admin
            .firestore()
            .collection("users")
            .doc(notification.senderId)
            .get();
          if (senderDoc.exists) {
            senderName = senderDoc.data().character || "誰か";
          }
        } catch (error) {
          logger.error("Error getting sender info:", error);
        }
      }

      // プッシュ通知のペイロードを作成
      const payload = {
        notification: {
          title: "たこ焼きを貰いました！",
          body: `${senderName}から${
            notification.reason || "クエスト"
          }でたこ焼きを送ってもらいました！`,
        },
        data: {
          type: "takoyaki_received",
          notificationId: notificationId,
          senderId: notification.senderId || "",
          reason: notification.reason || "",
        },
      };

      // プッシュ通知を送信
      const response = await admin
        .messaging()
        .sendToDevice([fcmToken], payload);

      logger.info(`Takoyaki notification sent to user: ${userId}`);
      logger.info(
        `Success count: ${response.successCount}, Failure count: ${response.failureCount}`
      );

      // 失敗した場合の処理
      if (response.failureCount > 0) {
        response.results.forEach((result, index) => {
          if (!result.success) {
            logger.error(
              `Failed to send takoyaki notification to token: ${fcmToken}`
            );
          }
        });
      }
    } catch (error) {
      logger.error("Error sending takoyaki notification:", error);
    }
  }
);

// クエスト締切1時間前通知を送信（定期的に実行）
exports.sendQuestDeadlineNotifications = onRequest(
  async (request, response) => {
    try {
      logger.info("Starting quest deadline notification check");

      const now = new Date();
      const oneHourFromNow = new Date(now.getTime() + 60 * 60 * 1000); // 1時間後

      // 1時間以内に締切が来るクエストを取得
      const questsSnapshot = await admin
        .firestore()
        .collection("quests")
        .where("deadline", ">=", now)
        .where("deadline", "<=", oneHourFromNow)
        .get();

      logger.info(
        `Found ${questsSnapshot.size} quests with deadline within 1 hour`
      );

      for (const questDoc of questsSnapshot.docs) {
        const quest = questDoc.data();
        const questId = questDoc.id;
        const deadline = quest.deadline.toDate();
        const enrolledUserIds = quest.enrolledUserIds || [];

        // 既に通知済みかチェック
        const notificationSent = quest.deadlineNotificationSent || false;
        if (notificationSent) {
          logger.info(
            `Deadline notification already sent for quest: ${questId}`
          );
          continue;
        }

        logger.info(`Sending deadline notification for quest: ${questId}`);

        // 各ユーザーに通知を送信
        const tokens = [];
        for (const userId of enrolledUserIds) {
          try {
            const userDoc = await admin
              .firestore()
              .collection("users")
              .doc(userId)
              .get();
            if (userDoc.exists && userDoc.data().fcmToken) {
              tokens.push(userDoc.data().fcmToken);
            }
          } catch (error) {
            logger.error(`Error getting FCM token for user ${userId}:`, error);
          }
        }

        if (tokens.length === 0) {
          logger.info("No FCM tokens found for enrolled users");
          continue;
        }

        // プッシュ通知のペイロードを作成
        const deadlineTime = deadline.toLocaleString("ja-JP", {
          month: "2-digit",
          day: "2-digit",
          hour: "2-digit",
          minute: "2-digit",
        });

        const payload = {
          notification: {
            title: "クエスト締め切り間近！",
            body: `「${
              quest.name || "クエスト"
            }」の締め切りが${deadlineTime}です。残り1時間です！`,
          },
          data: {
            type: "quest_deadline",
            questId: questId,
            questName: quest.name || "クエスト",
            deadline: deadline.toISOString(),
          },
        };

        // プッシュ通知を送信
        const response = await admin.messaging().sendToDevice(tokens, payload);

        logger.info(
          `Deadline notification sent to ${tokens.length} users for quest: ${questId}`
        );
        logger.info(
          `Success count: ${response.successCount}, Failure count: ${response.failureCount}`
        );

        // 通知済みフラグを設定
        await admin.firestore().collection("quests").doc(questId).update({
          deadlineNotificationSent: true,
          deadlineNotificationSentAt:
            admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      response.json({
        success: true,
        message: "Deadline notification check completed",
      });
    } catch (error) {
      logger.error("Error in deadline notification check:", error);
      response.status(500).json({ error: "Internal server error" });
    }
  }
);
