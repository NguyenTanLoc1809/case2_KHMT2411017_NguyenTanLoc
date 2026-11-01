const cron = require('node-cron');
const Task = require('../models/Task');
const User = require('../models/User');
const { dispatch } = require('../services/notificationService');
const tpl = require('../utils/emailTemplates');
const { formatDateTimeVN } = require('../utils/helpers');

async function runReminderJob() {
  const hours = Number(process.env.REMINDER_HOURS_BEFORE) || 24;
  const now = new Date();
  const limit = new Date(now.getTime() + hours * 3600 * 1000);

  const tasks = await Task.find({
    status: { $ne: 'completed' },
    dueDate: { $gt: now, $lte: limit },
    reminderSentAt: null,
  });

  for (const task of tasks) {
    // "Giành" việc gửi nhắc bằng cập nhật có điều kiện để không gửi trùng
    const claimed = await Task.updateOne(
      { _id: task._id, reminderSentAt: null },
      { $set: { reminderSentAt: new Date() } },
      { timestamps: false }
    );
    if (claimed.modifiedCount !== 1) continue;

    const recipientIds = task.assigneeIds.length ? task.assigneeIds : [task.createdBy];
    const recipients = await User.find({ _id: { $in: recipientIds } }).select('fullName email');

    await dispatch({
      task,
      actor: null,
      recipients,
      type: 'task_reminder',
      title: 'Công việc sắp đến hạn',
      message: `"${task.title}" sẽ đến hạn lúc ${formatDateTimeVN(task.dueDate)}`,
      email: (user) => tpl.taskReminder({ user, task }),
    });
  }
  if (tasks.length) console.log(`[reminder] Đã xử lý ${tasks.length} công việc sắp đến hạn`);
}

function startReminderJob() {
  if (process.env.ENABLE_REMINDER_JOB === 'false') {
    console.log('[reminder] Đã tắt tác vụ nhắc việc');
    return;
  }
  const expr = process.env.REMINDER_CRON || '*/15 * * * *';
  if (!cron.validate(expr)) {
    console.error(`[reminder] Biểu thức cron không hợp lệ: ${expr}`);
    return;
  }
  cron.schedule(expr, () => runReminderJob().catch((e) => console.error('[reminder] lỗi:', e.message)));
  console.log(`[reminder] Đã bật nhắc việc (${expr})`);
}

module.exports = { startReminderJob, runReminderJob };
