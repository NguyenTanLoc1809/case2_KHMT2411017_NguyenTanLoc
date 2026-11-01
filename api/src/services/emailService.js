const EmailLog = require('../models/EmailLog');
const { getTransporter, getFrom } = require('../config/email');

const MAX_ATTEMPTS = () => Number(process.env.EMAIL_MAX_ATTEMPTS) || 3;

/** Gửi một email theo log. Chỉ một tiến trình "giành" được lượt gửi (tránh gửi trùng). */
async function deliver(logId) {
  const current = await EmailLog.findById(logId).select('+htmlBody');
  if (!current || current.status !== 'pending') return;

  // Giành lượt gửi bằng cách tăng attempts có điều kiện (optimistic locking)
  const claim = await EmailLog.updateOne(
    { _id: logId, status: 'pending', attempts: current.attempts },
    { $inc: { attempts: 1 } }
  );
  if (claim.modifiedCount !== 1) return;

  const transporter = getTransporter();
  if (!transporter) {
    await EmailLog.updateOne(
      { _id: logId },
      { status: 'failed', errorMessage: 'SMTP chưa được cấu hình trên máy chủ' }
    );
    return;
  }

  try {
    await transporter.sendMail({
      from: getFrom(),
      to: current.recipientEmail,
      subject: current.subject,
      html: current.htmlBody,
    });
    await EmailLog.updateOne({ _id: logId }, { status: 'sent', sentAt: new Date(), errorMessage: '' });
  } catch (err) {
    await EmailLog.updateOne(
      { _id: logId },
      { status: 'failed', errorMessage: String(err.message || err).slice(0, 300) }
    );
  }
}

/** Ghi log trạng thái pending rồi gửi nền (không làm chậm response API). */
async function queueEmail({ taskId, recipientEmail, eventType, subject, html }) {
  const log = await EmailLog.create({
    taskId: taskId || null,
    recipientEmail,
    eventType,
    subject,
    htmlBody: html,
    status: 'pending',
    attempts: 0,
  });
  setImmediate(() => deliver(log._id).catch((e) => console.error('[email] lỗi:', e.message)));
  return log;
}

/** Chuyển failed -> pending (nguyên tử) rồi gửi lại. Trả về false nếu không đủ điều kiện. */
async function retryEmail(logId) {
  const res = await EmailLog.updateOne(
    { _id: logId, status: 'failed', attempts: { $lt: MAX_ATTEMPTS() } },
    { $set: { status: 'pending' } }
  );
  if (res.modifiedCount !== 1) return false;
  setImmediate(() => deliver(logId).catch((e) => console.error('[email] lỗi:', e.message)));
  return true;
}

module.exports = { queueEmail, retryEmail, deliver };
