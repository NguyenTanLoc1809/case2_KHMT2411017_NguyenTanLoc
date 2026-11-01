const nodemailer = require('nodemailer');

let transporter; // undefined = chưa khởi tạo, null = chưa cấu hình SMTP

function getTransporter() {
  if (transporter !== undefined) return transporter;
  const { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS } = process.env;
  if (!SMTP_HOST || !SMTP_USER || !SMTP_PASS) {
    transporter = null;
    return transporter;
  }
  const port = Number(SMTP_PORT) || 587;
  transporter = nodemailer.createTransport({
    host: SMTP_HOST,
    port,
    secure: port === 465,
    auth: { user: SMTP_USER, pass: SMTP_PASS },
    connectionTimeout: 10000,
    greetingTimeout: 10000,
    socketTimeout: 15000,
  });
  return transporter;
}

const getFrom = () => process.env.EMAIL_FROM || process.env.SMTP_USER;

module.exports = { getTransporter, getFrom };
