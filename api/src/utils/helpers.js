const escapeRegex = (s) => String(s).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const STATUS_LABEL = {
  todo: 'Chưa thực hiện',
  in_progress: 'Đang thực hiện',
  completed: 'Đã hoàn thành',
};
const PRIORITY_LABEL = { low: 'Thấp', medium: 'Trung bình', high: 'Cao' };
const PERMISSION_LABEL = { viewer: 'Chỉ xem', editor: 'Chỉnh sửa' };

const formatDateTimeVN = (d) =>
  d
    ? new Date(d).toLocaleString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh', hour12: false })
    : 'Chưa đặt';

const sameDate = (a, b) => (a ? new Date(a).getTime() : null) === (b ? new Date(b).getTime() : null);

module.exports = { escapeRegex, STATUS_LABEL, PRIORITY_LABEL, PERMISSION_LABEL, formatDateTimeVN, sameDate };
