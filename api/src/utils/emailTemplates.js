const { STATUS_LABEL, PRIORITY_LABEL, PERMISSION_LABEL, formatDateTimeVN } = require('./helpers');

const escapeHtml = (s) =>
  String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

// Chống chèn xuống dòng vào tiêu đề email (header injection)
const subjectLine = (s) => `[Task Manager] ${String(s).replace(/[\r\n]+/g, ' ')}`.slice(0, 200);

function layout({ heading, user, intro, task, rows = [] }) {
  const baseRows = [
    ['Công việc', task.title],
    ['Hạn hoàn thành', formatDateTimeVN(task.dueDate)],
    ['Mức độ ưu tiên', PRIORITY_LABEL[task.priority] || task.priority],
    ['Trạng thái', STATUS_LABEL[task.status] || task.status],
    ...rows,
  ];
  const rowHtml = baseRows
    .map(
      ([k, v]) =>
        `<tr><td style="padding:6px 12px;color:#64748b;white-space:nowrap">${escapeHtml(k)}</td>` +
        `<td style="padding:6px 12px;color:#0f172a"><b>${escapeHtml(v)}</b></td></tr>`
    )
    .join('');
  return `<!doctype html><html><body style="margin:0;background:#f1f5f9;font-family:Arial,Helvetica,sans-serif">
<div style="max-width:560px;margin:24px auto;background:#ffffff;border-radius:12px;overflow:hidden">
  <div style="background:#4f46e5;color:#ffffff;padding:18px 24px;font-size:18px;font-weight:bold">${escapeHtml(heading)}</div>
  <div style="padding:24px;color:#0f172a;font-size:15px;line-height:1.5">
    <p>Xin chào <b>${escapeHtml(user.fullName)}</b>,</p>
    <p>${intro}</p>
    <table style="border-collapse:collapse;background:#f8fafc;border-radius:8px;width:100%">${rowHtml}</table>
    <p style="color:#64748b;font-size:13px;margin-top:24px">Vui lòng mở ứng dụng Task Manager để xem chi tiết. Đây là email tự động, vui lòng không trả lời.</p>
  </div>
</div></body></html>`;
}

const b = (s) => `<b>${escapeHtml(s)}</b>`;

exports.taskAssigned = ({ user, task, actor }) => ({
  subject: subjectLine(`Bạn được giao công việc: ${task.title}`),
  html: layout({
    heading: 'Bạn được giao công việc mới',
    user,
    task,
    intro: `${b(actor.fullName)} đã giao công việc cho bạn.`,
  }),
});

exports.taskShared = ({ user, task, actor, permission }) => ({
  subject: subjectLine(`${actor.fullName} đã chia sẻ công việc: ${task.title}`),
  html: layout({
    heading: 'Công việc được chia sẻ với bạn',
    user,
    task,
    intro: `${b(actor.fullName)} đã mời bạn tham gia xem công việc này.`,
    rows: [['Quyền của bạn', PERMISSION_LABEL[permission] || permission]],
  }),
});

exports.dueDateChanged = ({ user, task, actor, oldDue, newDue }) => ({
  subject: subjectLine(`Hạn hoàn thành thay đổi: ${task.title}`),
  html: layout({
    heading: 'Hạn hoàn thành đã thay đổi',
    user,
    task,
    intro: `${b(actor.fullName)} đã thay đổi hạn hoàn thành của công việc.`,
    rows: [
      ['Hạn cũ', formatDateTimeVN(oldDue)],
      ['Hạn mới', formatDateTimeVN(newDue)],
    ],
  }),
});

exports.taskCompleted = ({ user, task, actor }) => ({
  subject: subjectLine(`Công việc đã hoàn thành: ${task.title}`),
  html: layout({
    heading: 'Công việc đã hoàn thành',
    user,
    task,
    intro: `${b(actor.fullName)} đã đánh dấu công việc là hoàn thành.`,
  }),
});

exports.taskReminder = ({ user, task }) => ({
  subject: subjectLine(`Sắp đến hạn: ${task.title}`),
  html: layout({
    heading: 'Nhắc việc sắp đến hạn',
    user,
    task,
    intro: 'Công việc dưới đây sắp đến hạn hoàn thành, hãy kiểm tra tiến độ nhé.',
  }),
});

exports.escapeHtml = escapeHtml;
