const mongoose = require('mongoose');

const taskActivitySchema = new mongoose.Schema(
  {
    taskId: { type: mongoose.Schema.Types.ObjectId, ref: 'Task', required: true, index: true },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    action: { type: String, required: true }, // created, updated, status_changed, ...
    details: { type: Object, default: {} },
  },
  { timestamps: { createdAt: true, updatedAt: false }, collection: 'task_activities' }
);

module.exports = mongoose.model('TaskActivity', taskActivitySchema);
