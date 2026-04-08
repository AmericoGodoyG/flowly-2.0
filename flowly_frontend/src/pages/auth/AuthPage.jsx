import { useState } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import {
  FaEnvelope, FaLock, FaSignInAlt, FaEye, FaEyeSlash,
  FaUser, FaUserGraduate, FaUserPlus
} from "react-icons/fa";
import { API_ENDPOINTS } from "../../config/config";
import { authUtils } from "../../config/authUtils";
import LightPillar from "../../components/backgrounds/LightPillar";
import "../../styles/pages/auth/Auth.css";

function AuthPage() {
  // Carousel state
  const [isRegistering, setIsRegistering] = useState(false);
  const [slideDirection, setSlideDirection] = useState("");

  // Login state
  const [loginEmail, setLoginEmail] = useState("");
  const [loginSenha, setLoginSenha] = useState("");
  const [loginErro, setLoginErro] = useState("");
  const [loginLoading, setLoginLoading] = useState(false);
  const [mostrarSenhaLogin, setMostrarSenhaLogin] = useState(false);

  // Register state
  const [regNome, setRegNome] = useState("");
  const [regEmail, setRegEmail] = useState("");
  const [regSenha, setRegSenha] = useState("");
  const [regTipo, setRegTipo] = useState("user");
  const [regErro, setRegErro] = useState("");
  const [regLoading, setRegLoading] = useState(false);
  const [mostrarSenhaReg, setMostrarSenhaReg] = useState(false);

  const navigate = useNavigate();

  // Switch to Register
  const goToRegister = () => {
    setSlideDirection("slide-left");
    setTimeout(() => {
      setIsRegistering(true);
      setSlideDirection("enter-right");
    }, 350);
  };

  // Switch to Login
  const goToLogin = () => {
    setSlideDirection("slide-right");
    setTimeout(() => {
      setIsRegistering(false);
      setSlideDirection("enter-left");
    }, 350);
  };

  // Login handler
  const handleLogin = async (e) => {
    e.preventDefault();
    setLoginLoading(true);
    setLoginErro("");

    try {
      const res = await axios.post(API_ENDPOINTS.LOGIN, {
        email: loginEmail,
        senha: loginSenha,
      });

      authUtils.saveAuthData(res.data.token, res.data.user);

      if (res.data.user.tipo === "admin") {
        window.location.href = "/admin";
      } else {
        window.location.href = "/dashboard";
      }
    } catch (err) {
      setLoginErro(
        err.response?.data?.error || err.response?.data?.erro || "Erro ao fazer login"
      );
    } finally {
      setLoginLoading(false);
    }
  };

  // Register handler — auto-login after success
  const handleRegister = async (e) => {
    e.preventDefault();
    setRegLoading(true);
    setRegErro("");

    try {
      await axios.post(API_ENDPOINTS.REGISTER, {
        nome: regNome,
        email: regEmail,
        senha: regSenha,
        tipo: regTipo,
      });

      const res = await axios.post(API_ENDPOINTS.LOGIN, {
        email: regEmail,
        senha: regSenha,
      });

      authUtils.saveAuthData(res.data.token, res.data.user);

      if (res.data.user.tipo === "admin") {
        window.location.href = "/admin";
      } else {
        window.location.href = "/dashboard";
      }
    } catch (err) {
      setRegErro(
        err.response?.data?.error || err.response?.data?.erro || "Erro ao cadastrar"
      );
    } finally {
      setRegLoading(false);
    }
  };

  return (
    <div className="auth-split">
      {/* ========== LEFT PANEL — Decorative ========== */}
      <div className="auth-left-panel">
        <div className="auth-left-bg">
          <LightPillar
            topColor="#5227FF"
            bottomColor="#FF9FFC"
            intensity={1}
            rotationSpeed={0.3}
            glowAmount={0.002}
            pillarWidth={3}
            pillarHeight={0.4}
            noiseIntensity={0.5}
            pillarRotation={25}
            interactive={false}
            mixBlendMode="screen"
            quality="high"
          />
        </div>

        <div className="auth-left-content">
          <div className="auth-brand">
            <span className="brand-name">Flowly</span>
          </div>
          <div className="auth-left-text">
            <h1>
              {isRegistering ? "COMECE SUA" : "ENTRE NA SUA"}
              <br />
              <span className="highlight-text">
                {isRegistering ? "JORNADA!" : "AVENTURA!"}
              </span>
            </h1>
            <p className="auth-left-subtitle">
              Gerencie tarefas, colabore com equipes e alcance seus objetivos com o Flowly.
            </p>
          </div>
        </div>

        {/* Floating decorative elements */}
        <div className="floating-orb orb-1"></div>
        <div className="floating-orb orb-2"></div>
        <div className="floating-orb orb-3"></div>
      </div>

      {/* ========== RIGHT PANEL — Form ========== */}
      <div className="auth-right-panel">
        <div className={`auth-carousel-wrapper ${slideDirection}`}>
          {!isRegistering ? (
            /* ========== LOGIN FORM ========== */
            <div className="auth-form-container">
              <div className="auth-header">
                <h2>Bem-vindo(a) de volta!</h2>
                <p>Faça login na plataforma Flowly</p>
              </div>

              <form className="auth-form" onSubmit={handleLogin}>
                {loginErro && <div className="erro-container">{loginErro}</div>}

                <div className="input-group">
                  <div className="input-icon"><FaEnvelope /></div>
                  <input
                    type="email"
                    placeholder="Seu email"
                    value={loginEmail}
                    onChange={(e) => setLoginEmail(e.target.value)}
                    required
                    disabled={loginLoading}
                  />
                </div>

                <div className="input-group">
                  <div className="input-icon"><FaLock /></div>
                  <input
                    type={mostrarSenhaLogin ? "text" : "password"}
                    placeholder="Sua senha"
                    value={loginSenha}
                    onChange={(e) => setLoginSenha(e.target.value)}
                    required
                    disabled={loginLoading}
                  />
                  <button
                    type="button"
                    className="toggle-password"
                    onClick={() => setMostrarSenhaLogin(!mostrarSenhaLogin)}
                    tabIndex={-1}
                  >
                    {mostrarSenhaLogin ? <FaEyeSlash /> : <FaEye />}
                  </button>
                </div>

                <button type="submit" className="glass-btn primary" disabled={loginLoading}>
                  <FaSignInAlt /> {loginLoading ? "Entrando..." : "Entrar"}
                </button>

                <div className="auth-footer">
                  <p>
                    Não tem uma conta?{" "}
                    <button type="button" className="auth-switch-btn" onClick={goToRegister}>
                      Cadastre-se
                    </button>
                  </p>
                </div>
              </form>
            </div>
          ) : (
            /* ========== REGISTER FORM ========== */
            <div className="auth-form-container">
              <div className="auth-header">
                <h2>Criar nova conta</h2>
                <p>Preencha os dados para se cadastrar</p>
              </div>

              <form className="auth-form" onSubmit={handleRegister}>
                {regErro && <div className="erro-container">{regErro}</div>}

                <div className="input-group">
                  <div className="input-icon"><FaUser /></div>
                  <input
                    type="text"
                    placeholder="Seu nome completo"
                    value={regNome}
                    onChange={(e) => setRegNome(e.target.value)}
                    required
                    disabled={regLoading}
                  />
                </div>

                <div className="input-group">
                  <div className="input-icon"><FaEnvelope /></div>
                  <input
                    type="email"
                    placeholder="Seu melhor email"
                    value={regEmail}
                    onChange={(e) => setRegEmail(e.target.value)}
                    required
                    disabled={regLoading}
                  />
                </div>

                <div className="input-group">
                  <div className="input-icon"><FaLock /></div>
                  <input
                    type={mostrarSenhaReg ? "text" : "password"}
                    placeholder="Escolha uma senha segura"
                    value={regSenha}
                    onChange={(e) => setRegSenha(e.target.value)}
                    required
                    disabled={regLoading}
                  />
                  <button
                    type="button"
                    className="toggle-password"
                    onClick={() => setMostrarSenhaReg(!mostrarSenhaReg)}
                    tabIndex={-1}
                  >
                    {mostrarSenhaReg ? <FaEyeSlash /> : <FaEye />}
                  </button>
                </div>

                <div className="input-group">
                  <div className="input-icon"><FaUserGraduate /></div>
                  <select
                    value={regTipo}
                    onChange={(e) => setRegTipo(e.target.value)}
                    className="select-tipo"
                    disabled={regLoading}
                  >
                    <option value="user">Colaborador</option>
                    <option value="admin">Administrador</option>
                  </select>
                </div>

                <button type="submit" className="glass-btn primary" disabled={regLoading}>
                  <FaUserPlus /> {regLoading ? "Criando conta..." : "Criar conta"}
                </button>

                <div className="auth-footer">
                  <p>
                    Já tem uma conta?{" "}
                    <button type="button" className="auth-switch-btn" onClick={goToLogin}>
                      Faça login
                    </button>
                  </p>
                </div>
              </form>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default AuthPage;
