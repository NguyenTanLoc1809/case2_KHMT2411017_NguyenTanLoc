const PRIORITIES = ['low', 'medium', 'high'];
const STATUSES = ['todo', 'in_progress', 'completed'];

const isValidDate = (v) => v === null || v === '' || !Number.isNaN(new Date(v).getTime());

function checkFields(body, errors) {
  if (body.description !== undefined && typeof body.description !== 'string') {
    errors.push('Mo ta khong hop le');
  } else if (typeof body.description === 'string' && body.description.length > 5000) {
    errors.push('Mo ta toi da 5000 ky tu');
  }
  if (body.priority !== undefined && !PRIORITIES.includes(body.priority)) {
    errors.push('Muc do uu tien phai la low, medium hoac high');
  }
  if (body.status !== undefined && !STATUSES.includes(body.status)) {
    errors.push('Trang thai phai la todo, in_progress hoac completed');
  }
  if (body.startDate !== undefined && !isValidDate(body.startDate)) errors.push('Ngay bat dau khong hop le');
  if (body.dueDate !== undefined && !isValidDate(body.dueDate)) errors.push('Han hoan thanh khong hop le');

  if (body.startDate && body.dueDate && isValidDate(body.startDate) && isValidDate(body.dueDate)) {
    if (new Date(body.dueDate) < new Date(body.startDate)) {
      errors.push('Han hoan thanh phai sau hoac bang ngay bat dau');
    }
  }
}

function validateCreateTask(body) {
  const errors = [];
  if (typeof body.title !== 'string' || body.title.trim() === '') {
    errors.push('Ten cong viec khong duoc de trong');
  } else if (body.title.trim().length > 200) {
    errors.push('Ten cong viec toi da 200 ky tu');
  }
  checkFields(body, errors);
  return errors;
}

function validateUpdateTask(body) {
  const errors = [];
  if (body.title !== undefined) {
    if (typeof body.title !== 'string' || body.title.trim() === '') {
      errors.push('Ten cong viec khong duoc de trong');
    } else if (body.title.trim().length > 200) {
      errors.push('Ten cong viec toi da 200 ky tu');
    }
  }
  checkFields(body, errors);
  return errors;
}

function validateStatus(body) {
  if (!STATUSES.includes(body.status)) {
    return ['Trang thai phai la todo, in_progress hoac completed'];
  }
  return [];
}

module.exports = { validateCreateTask, validateUpdateTask, validateStatus, PRIORITIES, STATUSES };
