import React, { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import apiClient from "../../config/apiClient";
import { API_ENDPOINTS } from "../../config/config";
import "../../styles/pages/auth/Login.css";
import "../../styles/pages/auth/Register.css";
import { FaUser, FaEnvelope, FaLock, FaUserGraduate, FaUserPlus, FaEye, FaEyeSlash } from 'react-icons/fa';

const TERMS_VERSION = "2026-06-08";

function Register() {
  const [nome, setNome] = useState("");
  const [email, setEmail] = useState("");
  const [senha, setSenha] = useState("");
  const [tipo, setTipo] = useState("user");
  const [erro, setErro] = useState("");
  const [mostrarSenha, setMostrarSenha] = useState(false);
  const [termsAccepted, setTermsAccepted] = useState(false);
  const [termsOpen, setTermsOpen] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setErro("");

    if (!termsAccepted) {
      setErro("Leia e aceite os Termos de Uso para finalizar o cadastro.");
      return;
    }

    try {
      const res = await apiClient.post(API_ENDPOINTS.REGISTER, {
        nome,
        email,
        senha,
        tipo,
        termsAccepted,
        termsVersion: TERMS_VERSION,
      });

      if (res.data?.redirectTo) {
        navigate(res.data.redirectTo, { replace: true });
        return;
      }

      navigate(`/verificar-2fa?email=${encodeURIComponent(email)}`, { replace: true });
    } catch (err) {
      setErro(err.response?.data?.erro || "Erro ao cadastrar");
    }
  };

  return (
    <div className="auth-container">
      <div className="auth-card">
        <div className="auth-header">
          <h2>Criar nova conta</h2>
          <p>Preencha os dados para se cadastrar</p>
        </div>

        <form className="auth-form" onSubmit={handleSubmit}>
          {erro && <div className="erro-container">{erro}</div>}

          <div className="input-group">
            <div className="input-icon">
              <FaUser />
            </div>
            <input
              type="text"
              placeholder="Seu nome completo"
              value={nome}
              onChange={(e) => setNome(e.target.value)}
              required
            />
          </div>

          <div className="input-group">
            <div className="input-icon">
              <FaEnvelope />
            </div>
            <input
              type="email"
              placeholder="Seu melhor email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>

          <div className="input-group">
            <div className="input-icon">
              <FaLock />
            </div>
            <input
              type={mostrarSenha ? "text" : "password"}
              placeholder="Escolha uma senha segura"
              value={senha}
              onChange={(e) => setSenha(e.target.value)}
              required
            />
            <button
              type="button"
              className="toggle-password"
              onClick={() => setMostrarSenha(!mostrarSenha)}
              tabIndex={-1}
            >
              {mostrarSenha ? <FaEyeSlash /> : <FaEye />}
            </button>
          </div>

          <div className="input-group">
            <div className="input-icon">
              <FaUserGraduate />
            </div>
            <select
              value={tipo}
              onChange={(e) => setTipo(e.target.value)}
              className="select-tipo"
            >
              <option value="user">User</option>
              <option value="admin">Admin</option>
            </select>
          </div>

          <label className="terms-check">
            <input
              type="checkbox"
              checked={termsAccepted}
              onChange={(e) => setTermsAccepted(e.target.checked)}
              required
            />
            <span>
              Li e aceito os{" "}
              <button
                type="button"
                className="terms-link"
                onClick={() => setTermsOpen(true)}
              >
                Termos de Uso e Privacidade
              </button>
            </span>
          </label>

          <button type="submit" disabled={!termsAccepted}>
            <FaUserPlus /> Criar conta
          </button>

          <div className="auth-footer">
            <p>
              Já tem uma conta? <Link to="/">Faça login</Link>
            </p>
          </div>
        </form>
      </div>

      {termsOpen && (
        <div
          className="terms-modal-backdrop"
          role="presentation"
          onMouseDown={() => setTermsOpen(false)}
        >
          <div
            className="terms-modal"
            role="dialog"
            aria-modal="true"
            aria-labelledby="terms-title"
            onMouseDown={(e) => e.stopPropagation()}
          >
            <div className="terms-modal-header">
              <div>
                <h3 id="terms-title">Termos de Uso e Privacidade</h3>
                <p>Versao {TERMS_VERSION}</p>
              </div>
              <button
                type="button"
                className="terms-close"
                onClick={() => setTermsOpen(false)}
                aria-label="Fechar termos"
              >
                x
              </button>
            </div>

            <div className="terms-content">
              <p>
                Ao criar uma conta no Flowly, voce declara que leu e concorda com estes
                Termos de Uso e com o tratamento de dados pessoais necessario para
                operar a plataforma de tarefas, equipes, mensagens, assistente e
                recursos de seguranca.
              </p>

              <h4>1. Finalidade da plataforma</h4>
              <p>
                O Flowly e uma ferramenta para organizacao de tarefas, equipes,
                comunicacao operacional, notificacoes, historico de atividades,
                assistente digital e recursos opcionais de verificacao facial.
              </p>

              <h4>2. Dados tratados</h4>
              <p>
                Podemos tratar nome, e-mail, senha protegida por hash, tipo de usuario,
                foto de perfil, tarefas, comentarios, equipes, mensagens, anexos,
                registros de uso, notificacoes, tokens de autenticacao e dados tecnicos
                como IP, data, horario e origem de acesso.
              </p>

              <h4>3. Biometria facial</h4>
              <p>
                Quando voce optar ou for solicitado a usar reconhecimento facial, o
                sistema processa imagens capturadas pela camera para gerar embeddings
                faciais usados na autenticacao. Esse dado e sensivel pela LGPD e deve
                ser usado apenas para verificacao de identidade, prevencao de fraude e
                seguranca da conta.
              </p>

              <h4>4. Assistente e voz</h4>
              <p>
                O assistente pode receber comandos, texto, contexto de tarefas, equipes
                e informacoes da sua conta para responder solicitacoes. Ao usar recursos
                de voz, sua fala pode ser convertida em texto para execucao do comando.
              </p>

              <h4>5. Bases legais e consentimento</h4>
              <p>
                O tratamento ocorre para execucao do servico, cumprimento de obrigacoes
                legais, seguranca, prevencao de fraude, legitimo interesse quando
                aplicavel e consentimento para dados sensiveis ou funcionalidades
                opcionais, conforme a LGPD.
              </p>

              <h4>6. Responsabilidades do usuario</h4>
              <p>
                Voce deve fornecer dados verdadeiros, manter sua senha em sigilo, usar a
                plataforma de forma licita, respeitar outros usuarios e nao enviar
                conteudos ofensivos, ilegais, discriminatorios, confidenciais de
                terceiros sem autorizacao ou arquivos maliciosos.
              </p>

              <h4>7. Compartilhamento e infraestrutura</h4>
              <p>
                Os dados podem ser processados por provedores de nuvem, banco de dados,
                armazenamento, e-mail, hospedagem, analytics operacional e servicos de
                apoio estritamente necessarios ao funcionamento e seguranca do Flowly.
              </p>

              <h4>8. Retencao e seguranca</h4>
              <p>
                Os dados sao mantidos pelo tempo necessario para fornecer o servico,
                cumprir obrigacoes legais, resolver disputas e proteger a plataforma.
                Medidas tecnicas e organizacionais devem ser adotadas para reduzir riscos
                de acesso indevido, perda, alteracao ou vazamento.
              </p>

              <h4>9. Direitos do titular</h4>
              <p>
                Nos termos da LGPD, voce pode solicitar confirmacao de tratamento,
                acesso, correcao, portabilidade, eliminacao, informacoes sobre
                compartilhamento, revisao de decisoes automatizadas quando aplicavel e
                revogacao de consentimento.
              </p>

              <h4>10. Alteracoes</h4>
              <p>
                Estes termos podem ser atualizados para refletir mudancas legais,
                tecnicas ou operacionais. Alteracoes relevantes poderao exigir novo
                aceite antes da continuidade de uso.
              </p>
            </div>

            <div className="terms-modal-actions">
              <button
                type="button"
                onClick={() => {
                  setTermsAccepted(true);
                  setTermsOpen(false);
                }}
              >
                Li e aceito
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default Register;
