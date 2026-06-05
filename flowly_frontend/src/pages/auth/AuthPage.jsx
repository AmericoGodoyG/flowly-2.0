import { useEffect, useState, useCallback } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import apiClient from "../../config/apiClient";
import { API_ENDPOINTS } from "../../config/config";
import { authUtils } from "../../config/authUtils";
import {
  FaEnvelope, FaLock, FaSignInAlt, FaEye, FaEyeSlash,
  FaUser, FaUserGraduate, FaUserPlus
} from "react-icons/fa";
import LightRays from "../../components/backgrounds/LightRays";
import CurvedLoop from "../../components/text/CurvedLoop";
import "../../styles/pages/auth/Auth.css";

function AuthPage() {
  // Water ripple effect handler
  const handleRipple = useCallback((e) => {
    const btn = e.currentTarget;
    const rect = btn.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    const size = Math.max(rect.width, rect.height) * 0.5;

    // Create main ripple
    const ripple = document.createElement("span");
    ripple.className = "ripple";
    ripple.style.width = ripple.style.height = `${size}px`;
    ripple.style.left = `${x - size / 2}px`;
    ripple.style.top = `${y - size / 2}px`;

    // Create first ring
    const ring = document.createElement("span");
    ring.className = "ripple-ring";
    ring.style.width = ring.style.height = `${size}px`;
    ring.style.left = `${x - size / 2}px`;
    ring.style.top = `${y - size / 2}px`;

    // Create outer ring
    const ringOuter = document.createElement("span");
    ringOuter.className = "ripple-ring-outer";
    ringOuter.style.width = ringOuter.style.height = `${size}px`;
    ringOuter.style.left = `${x - size / 2}px`;
    ringOuter.style.top = `${y - size / 2}px`;

    btn.appendChild(ripple);
    btn.appendChild(ring);
    btn.appendChild(ringOuter);

    // Add wobble class for surface distortion
    btn.classList.add("rippling");

    // Cleanup after animations finish
    setTimeout(() => {
      ripple.remove();
      ring.remove();
      ringOuter.remove();
      btn.classList.remove("rippling");
    }, 1200);
  }, []);
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
  const location = useLocation();

  useEffect(() => {
    const query = new URLSearchParams(location.search);
    const fromRegister = query.get("fromRegister");
    const email = query.get("email");

    if (fromRegister === "1" && email) {
      setIsRegistering(false);
      setLoginEmail(email);
      navigate(`/verificar-2fa?email=${encodeURIComponent(email)}`, { replace: true });
    }
  }, [location.search, navigate]);

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
      const res = await apiClient.post(API_ENDPOINTS.LOGIN, {
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

  // Register handler
  const handleRegister = async (e) => {
    e.preventDefault();
    setRegLoading(true);
    setRegErro("");

    try {
      await apiClient.post(API_ENDPOINTS.REGISTER, {
        nome: regNome,
        email: regEmail,
        senha: regSenha,
        tipo: regTipo,
      });

      navigate(`/?fromRegister=1&email=${encodeURIComponent(regEmail)}`, { replace: true });
    } catch (err) {
      setRegErro(
        err.response?.data?.error || err.response?.data?.erro || "Erro ao cadastrar"
      );
    } finally {
      setRegLoading(false);
    }
  };

  return (
    <div className="auth-fullscreen">
      {/* ========== FULLSCREEN BACKGROUND — LightRays ========== */}
      <div className="auth-bg-layer">
        <LightRays
          raysOrigin="top-center"
          raysColor="#ffffff"
          raysSpeed={1}
          lightSpread={0.5}
          rayLength={3}
          followMouse={true}
          mouseInfluence={0.1}
          noiseAmount={0}
          distortion={0}
          pulsating={false}
          fadeDistance={1}
          saturation={1}
        />
      </div>

      {/* ========== BRAND — Above card ========== */}
      <div className="auth-brand-above">
        <span className="brand-name">Flowly</span>
      </div>

      {/* ========== CENTERED CARD ========== */}
      <div className="auth-center-card">

        {/* ========== FORM CAROUSEL ========== */}
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

                <button type="submit" className="glass-btn primary" disabled={loginLoading} onMouseDown={handleRipple}>
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

      {/* ========== CURVED LOOP FOOTER ========== */}
      <div className="auth-curved-footer">
        <CurvedLoop
          marqueeText="Crie  ✦  Defina  ✦  Gerencie  ✦  Entregue  ✦  "
          speed={1}
          curveAmount={0}
          direction="left"
        />
      </div>
    </div>
  );
}

export default AuthPage;
