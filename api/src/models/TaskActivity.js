const mongoose = require('mongoose');
const { Schema } = mongoose;

const taskActivitySchema = new Schema(
  {
    taskId: { type: Schema.Types.ObjectId, ref: 'Task', required: true },
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    action: { type: String, required: true },
    details: { type: Schema.Types.Mixed, default: {} },
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

taskActivitySchema.index({ taskId: 1, createdAt: -1 });

module.exports = mongoose.model('TaskActivity', taskActivitySchema);
