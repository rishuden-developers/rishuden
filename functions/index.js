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
const { onSchedule } = require("firebase-functions/v2/scheduler");
const ical = require("node-ical");

// icsの表記形式をDateに変換する関数
function _parseIcsDateToDateTime(dtStr) {
  // icsの表記形式は "20231001T120000Z" のような形式
  return new Date(
    `${dtStr.substring(0, 4)}-${dtStr.substring(4, 6)}-${dtStr.substring(6, 8)}` +
    `T${dtStr.substring(9, 11)}:${dtStr.substring(11, 13)}:${dtStr.substring(13, 15)}`
  );
}

// 開始時間から授業の時限を計算する関数
function _getClassPeriodNumber(startHour) {
  switch (startHour) {
    case 8:
      return 1;
    case 10:
      return 2;
    case 13:
      return 3;
    case 14:
      return 4;
    case 16:
      return 5;
    case 18:
      return 6;
    default:
      return 0;
  }
}

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

// ログインボーナス通知を毎日8:30に送信
exports.sendLoginBonusNotification = onSchedule("30 8 * * *", async (event) => {
  try {
    logger.info("Starting login bonus notification check");

    // 全ユーザーのFCMトークンを取得
    const usersSnapshot = await admin.firestore().collection("users").get();
    const tokens = [];
    usersSnapshot.forEach((doc) => {
      const userData = doc.data();
      if (userData.fcmToken) {
        tokens.push(userData.fcmToken);
      }
    });

    if (tokens.length === 0) {
      logger.info("No FCM tokens found for any user");
      return;
    }

    // プッシュ通知のペイロードを作成
    const payload = {
      notification: {
        title: "ログインボーナスのお知らせ！",
        body: "今日のログインボーナスを受け取ろう！",
      },
      data: {
        type: "login_bonus",
      },
    };

    // プッシュ通知を送信
    const response = await admin.messaging().sendToDevice(tokens, payload);

    logger.info(`Login bonus notification sent to ${tokens.length} users`);
    logger.info(
      `Success count: ${response.successCount}, Failure count: ${response.failureCount}`
    );

    // 失敗したトークンを処理
    if (response.failureCount > 0) {
      response.results.forEach((result, index) => {
        if (!result.success) {
          logger.error(
            `Failed to send login bonus notification to token: ${tokens[index]}`
          );
        }
      });
    }
  } catch (error) {
    logger.error("Error sending login bonus notification:", error);
  }
});

// 毎日8:30に時間割を更新し、休講情報を通知
exports.updateTimetableAndNotifyCancellations = onSchedule("30 8 * * *", async (event) => {
  try {
    logger.info("Starting timetable update and cancellation notification check");

    const today = new Date();
    today.setHours(0, 0, 0, 0); // 今日の0時に設定

    const usersSnapshot = await admin.firestore().collection("users").get();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const userData = userDoc.data();
      const calendarUrl = userData.calendarUrl;
      const fcmToken = userData.fcmToken;

      if (!calendarUrl || !fcmToken) {
        logger.info(`Skipping user ${userId}: Missing calendarUrl or fcmToken`);
        continue;
      }

      try {
        const data = await ical.async.fromURL(calendarUrl);
        const todayTimetable = [];
        const cancelledClasses = [];

        for (const key in data) {
          const event = data[key];
          if (event.type === "VEVENT" && event.start && event.summary) {
            const eventStart = new Date(event.start);
            eventStart.setHours(0, 0, 0, 0);

            // 今日のイベントのみを対象
            if (eventStart.getTime() === today.getTime()) {
              const subject = event.summary;
              const location = event.location || "";
              const period = _getClassPeriodNumber(new Date(event.start).getHours());

              const isCancelled = subject.includes("[休]");

              const timetableEntry = {
                subject: subject,
                location: location,
                period: period,
                isCancelled: isCancelled,
              };
              todayTimetable.push(timetableEntry);

              if (isCancelled) {
                cancelledClasses.push(timetableEntry);
              }
            }
          }
        }

        // Firestoreに今日の時間割を保存/更新
        await admin.firestore().collection("users").doc(userId).collection("timetables").doc(today.toISOString().split('T')[0]).set({
          date: today,
          entries: todayTimetable,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        logger.info(`Timetable updated for user ${userId} for ${today.toISOString().split('T')[0]}`);

        // 休講通知を送信
        if (cancelledClasses.length > 0) {
          const cancellationMessages = cancelledClasses.map(cls => 
            `${cls.period}時限 ${cls.subject} (${cls.location})`
          ).join("\n");

          const payload = {
            notification: {
              title: "休講情報のお知らせ！",
              body: `今日の休講があります！\n${cancellationMessages}`,
            },
            data: {
              type: "cancellation_notification",
              date: today.toISOString().split('T')[0],
            },
          };

          await admin.messaging().sendToDevice(fcmToken, payload);
          logger.info(`Cancellation notification sent to user ${userId}`);
        }
      } catch (error) {
        logger.error(`Error processing timetable for user ${userId}:`, error);
      }
    }
  } catch (error) {
    logger.error("Error in timetable update and cancellation notification:", error);
  }
});

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
