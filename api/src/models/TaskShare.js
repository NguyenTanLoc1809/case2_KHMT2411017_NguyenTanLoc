const mongoose = require('mongoose');
const { Schema } = mongoose;

const taskShareSchema = new Schema(
  {
    taskId: { type: Schema.Types.ObjectId, ref: 'Task', required: true },
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    permission: { type: String, enum: ['viewer', 'editor'], required: true },
    sharedBy: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

// Mỗi người chỉ có một bản ghi chia sẻ trên mỗi công việc
taskShareSchema.index({ taskId: 1, userId: 1 }, { unique: true });
taskShareSchema.index({ userId: 1 });

module.exports = mongoose.model('TaskShare', taskShareSchema);
