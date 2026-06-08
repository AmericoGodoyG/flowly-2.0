const User = require('../models/User');
const sendEmail = require('./sendEmail');

const DUPLICATE_FACE_USER_MESSAGE =
  'Este rosto já está vinculado a outra conta Flowly. Use apenas uma conta por pessoa ou entre com a conta original.';

function maskEmail(email = '') {
  const [localPart, domain] = email.split('@');
  if (!localPart || !domain) {
    return 'conta oculta';
  }

  if (localPart.length <= 2) {
    return `${localPart.charAt(0)}***@${domain}`;
  }

  return `${localPart.charAt(0)}***${localPart.charAt(localPart.length - 1)}@${domain}`;
}

async function notifyFaceDuplicateAttempt({ ownerUserId, requesterUserId }) {
  const [owner, requester] = await Promise.all([
    User.findById(ownerUserId).select('nome email'),
    User.findById(requesterUserId).select('nome email'),
  ]);

  if (!owner?.email || !requester) {
    return;
  }

  const requesterLabel = maskEmail(requester.email);
  const baseUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
  const html = `<!DOCTYPE html><html><head><meta charset="utf-8"/>
  <style>
  body{background:linear-gradient(135deg, #9F7AEA 0%, #6B21A8 50%, #1F1F1F 100%);margin:0;font-family:Arial,sans-serif;color:#2D1B3D}
  .wrap{max-width:600px;margin:24px auto;background:#fff;border:1px solid #8B5CF6;border-radius:12px;overflow:hidden}
  .head{background:linear-gradient(135deg, #8B5CF6 0%, #6D28D9 100%);color:#fff;padding:18px 24px;font-size:20px;font-weight:bold}
  .content{padding:24px}
  .alert{background:#FFF3E0;border:1px solid #FFB74D;border-radius:8px;padding:12px 16px;margin:16px 0}
  .footer{color:#6B4889;font-size:12px;margin-top:20px}
  </style></head><body>
  <div class="wrap">
    <div class="head">Flowly • Alerta de verificação facial</div>
    <div class="content">
      <p>Olá <strong>${owner.nome}</strong>,</p>
      <div class="alert">
        Detectamos uma tentativa de cadastrar um rosto já vinculado à sua conta em outro perfil.
      </div>
      <p>Conta que tentou o cadastro: <strong>${requesterLabel}</strong></p>
      <p>O cadastro foi bloqueado automaticamente. Se você reconhece esta ação, nenhuma medida é necessária.</p>
      <p>Se não foi você, recomendamos alterar sua senha e revisar o acesso à sua conta.</p>
      <p><a href="${baseUrl}/">Acessar Flowly</a></p>
      <div class="footer">
        <p>Este é um aviso automático de segurança. Não compartilhe códigos ou senhas com terceiros.</p>
      </div>
    </div>
  </div>
  </body></html>`;

  await sendEmail(
    owner.email,
    'Flowly • Tentativa de cadastro facial detectada',
    null,
    html
  );
}

module.exports = {
  DUPLICATE_FACE_USER_MESSAGE,
  maskEmail,
  notifyFaceDuplicateAttempt,
};
