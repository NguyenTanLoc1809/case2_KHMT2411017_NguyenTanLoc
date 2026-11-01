const Notification = require('../models/Notification');
const { queueEmail } = require('./emailService');

/**
 * Tạo thông báo trong ứng dụng (và email nếu có) cho danh sách người nhận.
 * - actor: người thực hiện thao tác (không tự thông báo cho chính mình), có thể null (tác vụ hệ thống)
 * - recipients: mảng User (cần _id, email, fullName)
 * - email: hàm (user) => ({ subject, html }) hoặc null nếu chỉ thông báo trong ứng dụng
 * Lỗi ở đây không được làm hỏng thao tác chính nên chỉ ghi log.
 */
async function dispatch({ task, actor, recipients, type, title, message, email }) {
  try {
    const actorId = actor ? actor._id.toString() : null;
    const seen = new Set();
    const targets = [];
    for (const u of recipients) {
      const id = u._id.toString();
      if (id === actorId || seen.has(id)) continue;
      seen.add(id);
      targets.push(u);
    }
    if (!targets.length) return;

    await Notification.insertMany(
      targets.map((u) => ({ userId: u._id, taskId: task._id, type, title, message }))
    );

    if (email) {
      for (const u of targets) {
        const { subject, html } = email(u);
        await queueEmail({ taskId: task._id, recipientEmail: u.email, eventType: type, subject, html });
      }
    }
  } catch (err) {
    console.error('[notify] Không gửi được thông báo:', err.message);
  }
}

module.exports = { dispatch };
