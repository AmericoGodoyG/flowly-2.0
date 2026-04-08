import { useEffect, useState } from "react";
import { useParams, Link, useLocation, useNavigate } from "react-router-dom";
import axios from "axios";
import "../../styles/pages/admin/DashboardAdmin.css";
import "../../styles/pages/admin/Equipes.css";
import Sidebar from "../../components/layout/Sidebar";

export default function Equipes() {
  const [equipes, setEquipes] = useState([]);
  const [nome, setNome] = useState([]);
  const [membros, setMembros] = useState([]); // Array de objetos completos
  const [users, setUsers] = useState([]);
  const [editandoId, setEditandoId] = useState(null);
  const [mensagemErro, setMensagemErro] = useState("");
  const [mensagemSucesso, setMensagemSucesso] = useState("");
  const { id } = useParams();
  const location = useLocation();
  const navigate = useNavigate();

  const token = localStorage.getItem("token");



  useEffect(() => {
    carregarEquipes();
    carregarUsers();
  }, []);

  useEffect(() => {
  if (id) {
    const carregarEquipePorId = async () => {
      try {
        const res = await axios.get(`http://localhost:5000/api/equipes/${id}`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        const equipe = res.data;
        setNome(equipe.nome);
        setMembros(equipe.membros.map((m) => m._id));
        setEditandoId(equipe._id);
      } catch (err) {
        console.error("Erro ao carregar equipe para edição", err);
      }
    };

    carregarEquipePorId();
  }
}, [id]);


  const carregarEquipes = async () => {
    try {
      const res = await axios.get("http://localhost:5000/api/equipes", {
        headers: { Authorization: `Bearer ${token}` },
      });
      setEquipes(res.data);
    } catch (err) {
      console.error("Erro ao buscar equipes", err);
    }
  };

  const carregarUsers = async () => {
    try {
      const res = await axios.get("http://localhost:5000/api/users", {
        headers: { Authorization: `Bearer ${token}` },
      });
      setUsers(res.data);
    } catch (err) {
      console.error("Erro ao buscar usuários", err);
    }
  };

  const criarOuEditarEquipe = async (e) => {
    e.preventDefault();

    try {
      const dados = { nome, membros: [...new Set(membros)] };

      if (editandoId) {
        await axios.put(`http://localhost:5000/api/equipes/${editandoId}`, dados, {
          headers: { Authorization: `Bearer ${token}` },
        });
        setMensagemSucesso("Equipe editada com sucesso!");
      } else {
        await axios.post("http://localhost:5000/api/equipes", dados, {
          headers: { Authorization: `Bearer ${token}` },
        });
        setMensagemSucesso("Equipe criada com sucesso!");
      }

      setNome("");
      setMembros([]);
      setEditandoId(null);
      carregarEquipes();
    } catch (err) {
      setMensagemErro(
        "Erro ao salvar equipe: " +
          (err.response?.data?.erro || err.response?.data?.detalhe || err.message)
      );
    }
  };

  const excluirEquipe = async (id) => {
    try {
      await axios.delete(`http://localhost:5000/api/equipes/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      carregarEquipes();
    } catch (err) {
      console.error("Erro ao excluir equipe", err);
    }
  };

  const editarEquipe = (equipe) => {
    setNome(equipe.nome);
    setMembros(equipe.membros.map((m) => m._id)); // Passar os objetos completos dos membros
    setEditandoId(equipe._id);
  };

  return (
    <div className="admin-page">
      <Sidebar />

      <main className="dashboard-container">
        <div className="dashboard-header">
          <h2 className="dashboard-title">
            {location.pathname === '/admin/criar-equipe' ? 'Criar Nova Equipe' : 
             location.pathname.includes('/admin/equipe/') ? 'Editar Equipe' : 
             'Gerenciar Equipes'}
          </h2>
          {location.pathname !== '/admin' && (
            <Link to="/admin" className="btn-back">
              ← Voltar ao Dashboard
            </Link>
          )}
        </div>

        <form onSubmit={criarOuEditarEquipe} className="form">
          <input
            type="text"
            className="input"
            placeholder="Nome da equipe"
            value={nome}
            onChange={(e) => setNome(e.target.value)}
            required
          />

          <label className="label">Selecionar membros:</label>
          <div className="checkbox-list">
            {users
              .filter((user) => user.tipo !== "admin")
              .map((user) => (
                <label key={user._id} className="checkbox-item">
                  <input
                    type="checkbox"
                    checked={membros.includes(user._id)}
                    onChange={() => {
                      setMembros((prev) => {
                        if (prev.includes(user._id)) {
                          return prev.filter((id) => id !== user._id);
                        }
                        return [...prev, user._id];
                      });
                    }}
                  />
                  {user.nome} ({user.email})
                </label>
              ))}
          </div>

          <button type="submit" className="btn">
            {editandoId ? "Salvar Alterações" : "Criar Equipe"}
          </button>
        </form>

        {mensagemSucesso && <p className="success-message">{mensagemSucesso}</p>}
        {mensagemErro && <p className="error-message">{mensagemErro}</p>}

        {location.pathname === '/admin' && (
          <div className="equipes-list">
            {equipes.map((equipe) => (
              <div className="equipe-card" key={equipe._id}>
                <h3>{equipe.nome}</h3>
                <p>Membros: {equipe.membros.map((m) => m.nome).join(", ")}</p>
                <div className="buttons">
                  <button className="edit-btn" onClick={() => editarEquipe(equipe)}>
                    Editar
                  </button>
                  <button
                    className="delete-btn"
                    onClick={() => excluirEquipe(equipe._id)}
                  >
                    Excluir
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}