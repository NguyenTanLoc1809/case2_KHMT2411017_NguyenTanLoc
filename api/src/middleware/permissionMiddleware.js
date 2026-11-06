const mongoose = require('mongoose');
const AppError = require('../utils/AppError');
const asyncHandler = require('../utils/asyncHandler');
const { Task, getRoleForTask, can, POPULATE } = require('../services/taskService');

/**
 * Nap cong viec theo :id va kiem tra quyen o backend.
 * action: 'view' | 'status' | 'edit' | 'delete'
 * Gan req.task va req.taskRole cho controller.
 */
const requireTaskPermission = (action) =>
  asyncHandler(async (req, res, next) => {
    const id = req.params.id;
    if (!mongoose.isValidObjectId(id)) throw new AppError('ID cong viec khong hop le', 400);

    const task = await Task.findById(id).populate(POPULATE);
    if (!task) throw new AppError('Khong tim thay cong viec', 404);

    const role = await getRoleForTask(task, req.user._id);
    // Khong co quyen xem -> tra 404 de khong lo su ton tai cua cong viec
    if (!can(role, 'view')) throw new AppError('Khong tim thay cong viec', 404);
    if (!can(role, action)) throw new AppError('Ban khong co quyen thuc hien thao tac nay', 403);

    req.task = task;
    req.taskRole = role;
    next();
  });

module.exports = { requireTaskPermission };
