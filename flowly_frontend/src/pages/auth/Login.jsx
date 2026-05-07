import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import axios from "axios";
import { FaEnvelope, FaLock, FaSignInAlt, FaEye, FaEyeSlash } from 'react-icons/fa';
import { API_ENDPOINTS } from "../../config/config";
import { authUtils } from "../../config/authUtils";
import LightPillar from "../../components/backgrounds/LightPillar";
import "../../styles/pages/auth/Login.css";

function Login() {
  const [email, setEmail] = useState("");
  const [senha, setSenha] = useState("");
  const [erro, setErro] = useState("");
  const [loading, setLoading] = useState(false);
  const [mostrarSenha, setMostrarSenha] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setErro("");

    try {
      const res = await axios.post(API_ENDPOINTS.LOGIN, {
        email,
        senha,
      });

      // Usar o método centralizado para salvar dados
      authUtils.saveAuthData(res.data.token, res.data.user);

      // Redirecionar baseado no tipo de usuário
      if (res.data.user.tipo === "admin") {
        window.location.href = "/admin";
      } else {
        window.location.href = "/dashboard";
      }
    } catch (err) {
      const errorMessage = err.response?.data?.error || err.response?.data?.erro || "Erro ao fazer login";
      const redirectTo = err.response?.data?.redirectTo;
      const normalizedError = errorMessage.toLowerCase();

      if (redirectTo) {
        navigate(redirectTo, { replace: true });
        return;
      }

      if (normalizedError.includes("usuário não verificado") || normalizedError.includes("usuario nao verificado")) {
        navigate(`/verificar-2fa?email=${encodeURIComponent(email)}`);
        return;
      }

      setErro(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-container">
      <div className="auth-background">
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
      <div className="auth-card glass-panel">
        <div className="auth-header">
          <h2>Bem-vindo(a) de volta!</h2>
          <p>Faça login na plataforma The Bend</p>
        </div>

        <form className="auth-form" onSubmit={handleSubmit}>
          {erro && <div className="erro-container">{erro}</div>}

          <div className="input-group">
            <div className="input-icon">
              <FaEnvelope />
            </div>
            <input
              type="email"
              placeholder="Seu email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              disabled={loading}
            />
          </div>

          <div className="input-group">
            <div className="input-icon">
              <FaLock />
            </div>
            <input
              type={mostrarSenha ? "text" : "password"}
              placeholder="Sua senha"
              value={senha}
              onChange={(e) => setSenha(e.target.value)}
              required
              disabled={loading}
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

          <button type="submit" className="glass-btn primary" disabled={loading}>
            <FaSignInAlt /> {loading ? "Entrando..." : "Entrar"}
          </button>

          <div className="auth-footer">
            <p>
              Não tem uma conta? <Link to="/register">Cadastre-se</Link>
            </p>
          </div>
        </form>
      </div>
    </div>
  );
}

export default Login;
