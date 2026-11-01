const mongoose = require('mongoose');
const { Schema } = mongoose;

const PRIORITIES = ['low', 'medium', 'high'];
const STATUSES = ['todo', 'in_progress', 'completed'];
const PRIORITY_RANK = { low: 1, medium: 2, high: 3 };

const taskSchema = new Schema(
  {
    title: { type: String, required: [true, 'Tên công việc không được để trống'], trim: true, maxlength: 200 },
    description: { type: String, default: '', maxlength: 2000 },
    createdBy: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    assigneeIds: [{ type: Schema.Types.ObjectId, ref: 'User' }],
    primaryAssigneeId: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    startDate: { type: Date, default: null },
    dueDate: { type: Date, required: [true, 'Hạn hoàn thành là bắt buộc'] },
    priority: { type: String, enum: PRIORITIES, default: 'medium' },
    priorityRank: { type: Number, default: 2 }, // phục vụ sắp xếp theo mức ưu tiên
    status: { type: String, enum: STATUSES, default: 'todo' },
    completedAt: { type: Date, default: null },
    reminderSentAt: { type: Date, default: null }, // đã gửi nhắc hạn hay chưa
  },
  { timestamps: true }
);

taskSchema.index({ assigneeIds: 1 });
taskSchema.index({ dueDate: 1, status: 1 });

taskSchema.pre('save', async function () {
  if (this.isNew || this.isModified('priority')) {
    this.priorityRank = PRIORITY_RANK[this.priority] || 2;
  }
});

module.exports = mongoose.model('Task', taskSchema);
module.exports.PRIORITIES = PRIORITIES;
module.exports.STATUSES = STATUSES;
