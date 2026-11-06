const mongoose = require('mongoose');

const taskSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true, maxlength: 200 },
    description: { type: String, default: '', trim: true, maxlength: 5000 },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    assigneeIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    primaryAssigneeId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    startDate: { type: Date, default: null },
    dueDate: { type: Date, default: null },
    priority: { type: String, enum: ['low', 'medium', 'high'], default: 'medium' },
    status: { type: String, enum: ['todo', 'in_progress', 'completed'], default: 'todo' },
  },
  { timestamps: true, collection: 'tasks' }
);

taskSchema.index({ assigneeIds: 1 });
taskSchema.index({ dueDate: 1 });

module.exports = mongoose.model('Task', taskSchema);
