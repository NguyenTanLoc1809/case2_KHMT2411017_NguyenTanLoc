const mongoose = require('mongoose');
const { Schema } = mongoose;

const emailLogSchema = new Schema(
  {
    taskId: { type: Schema.Types.ObjectId, ref: 'Task', default: null },
    recipientEmail: { type: String, required: true },
    eventType: { type: String, required: true },
    subject: { type: String, required: true },
    htmlBody: { type: String, select: false }, // nội dung để có thể gửi lại
    status: { type: String, enum: ['pending', 'sent', 'failed'], default: 'pending' },
    attempts: { type: Number, default: 0 },
    errorMessage: { type: String, default: '' },
    sentAt: { type: Date, default: null },
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

emailLogSchema.index({ taskId: 1, createdAt: -1 });

module.exports = mongoose.model('EmailLog', emailLogSchema);
