const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const isBlank = (v) => typeof v !== 'string' || v.trim() === '';

function validateRegister(body) {
  const errors = [];
  if (isBlank(body.fullName)) errors.push('Ho ten khong duoc de trong');
  else if (body.fullName.trim().length > 100) errors.push('Ho ten toi da 100 ky tu');

  if (isBlank(body.email) || !EMAIL_REGEX.test(body.email.trim())) errors.push('Email khong hop le');

  if (typeof body.password !== 'string' || body.password.length < 6) {
    errors.push('Mat khau phai co it nhat 6 ky tu');
  }
  return errors;
}

function validateLogin(body) {
  const errors = [];
  if (isBlank(body.email) || !EMAIL_REGEX.test(body.email.trim())) errors.push('Email khong hop le');
  if (typeof body.password !== 'string' || body.password === '') errors.push('Vui long nhap mat khau');
  return errors;
}

function validateUpdateProfile(body) {
  const errors = [];
  if (body.fullName === undefined && body.avatarUrl === undefined) {
    errors.push('Khong co thong tin nao de cap nhat');
  }
  if (body.fullName !== undefined) {
    if (isBlank(body.fullName)) errors.push('Ho ten khong duoc de trong');
    else if (body.fullName.trim().length > 100) errors.push('Ho ten toi da 100 ky tu');
  }
  if (body.avatarUrl !== undefined && typeof body.avatarUrl !== 'string') {
    errors.push('avatarUrl khong hop le');
  }
  return errors;
}

function validateChangePassword(body) {
  const errors = [];
  if (typeof body.currentPassword !== 'string' || body.currentPassword === '') {
    errors.push('Vui long nhap mat khau hien tai');
  }
  if (typeof body.newPassword !== 'string' || body.newPassword.length < 6) {
    errors.push('Mat khau moi phai co it nhat 6 ky tu');
  } else if (body.newPassword === body.currentPassword) {
    errors.push('Mat khau moi phai khac mat khau hien tai');
  }
  return errors;
}

module.exports = { validateRegister, validateLogin, validateUpdateProfile, validateChangePassword };
