const mongoose = require('mongoose');
const { Schema } = mongoose;

const notificationSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    taskId: { type: Schema.Types.ObjectId, ref: 'Task', default: null },
    type: { type: String, required: true },
    title: { type: String, required: true },
    message: { type: String, default: '' },
    isRead: { type: Boolean, default: false },
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

notificationSchema.index({ userId: 1, createdAt: -1 });
notificationSchema.index({ userId: 1, isRead: 1 });

module.exports = mongoose.model('Notification', notificationSchema);
