import React, { useEffect, useMemo, useState } from 'react';
import axios from 'axios';
import Sidebar from '../../components/layout/Sidebar';
import { API_ENDPOINTS, LOCAL_STORAGE_KEYS } from '../../config/config';
import { authUtils } from '../../config/authUtils';
import '../../styles/pages/admin/DashboardAdmin.css';
import '../../styles/pages/user/PerfilUser.css';

const API_PUBLIC_BASE = process.env.REACT_APP_API_PUBLIC_URL || 'http://localhost:5000';

function PerfilUser() {
  const [loading, setLoading] = useState(true);
  const [savingPerfil, setSavingPerfil] = useState(false);
  const [savingSenha, setSavingSenha] = useState(false);

  const [nome, setNome] = useState('');
  const [email, setEmail] = useState('');
  const [tipo, setTipo] = useState('');

  const [arquivoFoto, setArquivoFoto] = useState(null);
  const [fotoPerfil, setFotoPerfil] = useState('');

  const [senhaAtual, setSenhaAtual] = useState('');
  const [novaSenha, setNovaSenha] = useState('');
  const [confirmarSenha, setConfirmarSenha] = useState('');

  const [mensagemPerfil, setMensagemPerfil] = useState('');
  const [mensagemSenha, setMensagemSenha] = useState('');
  const [erro, setErro] = useState('');

  const authHeaders = useMemo(
    () => ({ headers: { Authorization: `Bearer ${authUtils.getToken()}` } }),
    []
  );

  const carregarPerfil = async () => {
    setLoading(true);
    setErro('');
    try {
      const res = await axios.get(API_ENDPOINTS.USER_ME, authHeaders);
      setNome(res.data.nome || '');
      setEmail(res.data.email || '');
      setTipo(res.data.tipo || '');
      setFotoPerfil(res.data.fotoPerfil || '');
    } catch (error) {
      setErro('Nao foi possivel carregar seu perfil.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    carregarPerfil();
  }, []);

  const resolverFoto = (url) => {
    if (!url) return '';
    if (url.startsWith('http')) return url;
    return `${API_PUBLIC_BASE}${url}`;
  };

  const salvarPerfil = async (e) => {
    e.preventDefault();
    setMensagemPerfil('');
    setErro('');
    setSavingPerfil(true);

    try {
      const formData = new FormData();
      formData.append('nome', nome);
      if (arquivoFoto) {
        formData.append('fotoPerfil', arquivoFoto);
      }

      const res = await axios.put(API_ENDPOINTS.USER_ME, formData, {
        headers: {
          Authorization: `Bearer ${authUtils.getToken()}`,
          'Content-Type': 'multipart/form-data',
        },
      });

      const usuarioAtualizado = res.data.user;
      localStorage.setItem(LOCAL_STORAGE_KEYS.USER_NAME, usuarioAtualizado.nome);
      if (usuarioAtualizado.fotoPerfil) {
        localStorage.setItem(LOCAL_STORAGE_KEYS.USER_PHOTO, usuarioAtualizado.fotoPerfil);
      } else {
        localStorage.removeItem(LOCAL_STORAGE_KEYS.USER_PHOTO);
      }

      setFotoPerfil(usuarioAtualizado.fotoPerfil || '');
      setArquivoFoto(null);
      setMensagemPerfil('Perfil atualizado com sucesso.');
    } catch (error) {
      setErro(error?.response?.data?.erro || 'Erro ao atualizar perfil.');
    } finally {
      setSavingPerfil(false);
    }
  };

  const redefinirSenha = async (e) => {
    e.preventDefault();
    setMensagemSenha('');
    setErro('');

    if (novaSenha !== confirmarSenha) {
      setErro('A confirmacao da nova senha nao confere.');
      return;
    }

    setSavingSenha(true);

    try {
      await axios.put(
        API_ENDPOINTS.USER_ME_PASSWORD,
        { senhaAtual, novaSenha },
        authHeaders
      );

      setSenhaAtual('');
      setNovaSenha('');
      setConfirmarSenha('');
      setMensagemSenha('Senha atualizada com sucesso.');
    } catch (error) {
      setErro(error?.response?.data?.erro || 'Erro ao redefinir senha.');
    } finally {
      setSavingSenha(false);
    }
  };

  return (
    <div className="admin-page perfil-page">
      <Sidebar />

      <main className="dashboard-user perfil-content">
        <header className="perfil-header">
          <h2>Meu Perfil</h2>
          <p>Adicione sua foto, edite seu nome e redefina sua senha.</p>
        </header>

        {loading && <p>Carregando perfil...</p>}
        {!loading && erro && <p className="perfil-erro">{erro}</p>}

        {!loading && (
          <div className="perfil-grid">
            <section className="perfil-card">
              <h3>Dados do Perfil</h3>
              <form onSubmit={salvarPerfil} className="perfil-form">
                <div className="perfil-avatar-wrap">
                  {fotoPerfil ? (
                    <img
                      src={resolverFoto(fotoPerfil)}
                      alt="Foto de perfil"
                      className="perfil-avatar-img"
                    />
                  ) : (
                    <div className="perfil-avatar-fallback">{(nome || 'U').charAt(0).toUpperCase()}</div>
                  )}
                </div>

                <label>Foto de perfil</label>
                <input
                  type="file"
                  accept="image/png,image/jpeg,image/jpg"
                  onChange={(event) => setArquivoFoto(event.target.files?.[0] || null)}
                />

                <label>Nome</label>
                <input
                  type="text"
                  value={nome}
                  onChange={(event) => setNome(event.target.value)}
                  required
                />

                <label>Email</label>
                <input type="email" value={email} disabled />

                <label>Perfil de acesso</label>
                <input type="text" value={tipo === 'admin' ? 'Administrador' : 'Colaborador'} disabled />

                <button type="submit" disabled={savingPerfil}>
                  {savingPerfil ? 'Salvando...' : 'Salvar Perfil'}
                </button>

                {mensagemPerfil && <p className="perfil-sucesso">{mensagemPerfil}</p>}
              </form>
            </section>

            <section className="perfil-card">
              <h3>Redefinir Senha</h3>
              <form onSubmit={redefinirSenha} className="perfil-form">
                <label>Senha atual</label>
                <input
                  type="password"
                  value={senhaAtual}
                  onChange={(event) => setSenhaAtual(event.target.value)}
                  required
                />

                <label>Nova senha</label>
                <input
                  type="password"
                  value={novaSenha}
                  onChange={(event) => setNovaSenha(event.target.value)}
                  required
                  minLength={6}
                />

                <label>Confirmar nova senha</label>
                <input
                  type="password"
                  value={confirmarSenha}
                  onChange={(event) => setConfirmarSenha(event.target.value)}
                  required
                  minLength={6}
                />

                <button type="submit" disabled={savingSenha}>
                  {savingSenha ? 'Atualizando...' : 'Atualizar Senha'}
                </button>

                {mensagemSenha && <p className="perfil-sucesso">{mensagemSenha}</p>}
              </form>
            </section>
          </div>
        )}
      </main>
    </div>
  );
}

export default PerfilUser;
