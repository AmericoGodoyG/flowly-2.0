import React, { useEffect, useState } from "react";
import axios from "axios";
import { Link, useNavigate } from "react-router-dom";
import { formatarStatus } from "../../config/statusUtils";
import "../../styles/pages/admin/DashboardAdmin.css";
import Sidebar from "../../components/layout/Sidebar";

function DashboardTarefasAdmin() {
  const [tarefas, setTarefas] = useState([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchTarefas = async () => {
      try {
        const res = await axios.get("http://localhost:5000/api/tarefas", {
          headers: {
            Authorization: `Bearer ${localStorage.getItem("token")}`,
          },
        });
        setTarefas(res.data);
        setLoading(false);
      } catch (err) {
        console.error("Erro ao carregar tarefas", err);
        setLoading(false);
      }
    };

    fetchTarefas();
  }, []);

  const handleDelete = async (id) => {
    try {
      await axios.delete(`http://localhost:5000/api/tarefas/${id}`, {
        headers: {
          Authorization: `Bearer ${localStorage.getItem("token")}`,
        },
      });
      setTarefas(tarefas.filter((tarefa) => tarefa._id !== id));
    } catch (err) {
      console.error("Erro ao excluir tarefa", err);
    }
  };

  const handleEdit = (tarefaId) => {
    navigate(`/admin/editar-tarefa/${tarefaId}`);
  };

  return (
    <div className="admin-page">
      <Sidebar />

      <main className="dashboard-container">
        <h2 className="dashboard-title">Tarefas</h2>

        <div className="dashboard-actions">
          <Link to="/admin/criar-tarefa" className="btn-create">
            Criar nova tarefa
          </Link>
        </div>

        <div className="metrics">
          <div className="metric">
            <span className="metric-title">Número de Tarefas:</span>
            <span className="metric-value">{tarefas.length}</span>
          </div>
        </div>

        <div className="teams-list">
          {loading ? (
            <p>Carregando tarefas...</p>
          ) : tarefas.length === 0 ? (
            <p>Nenhuma tarefa encontrada.</p>
          ) : (
            tarefas.map((tarefa) => (
              <div key={tarefa._id} className="team-item">
                <h3>{tarefa.descricao}</h3>
                <p><strong>Entrega:</strong> {new Date(tarefa.dataEntrega).toLocaleDateString()}</p>
                <p><strong>Usuário:</strong> {tarefa.user?.nome || 'Sem responsável (Backlog)'}</p>
                <p><strong>Equipe:</strong> {tarefa.equipe?.nome}</p>
                <p><strong>Status:</strong> {formatarStatus(tarefa.status)}</p>

                <div className="actions">
                  <button className="btn-edit" onClick={() => handleEdit(tarefa._id)}>
                    Editar
                  </button>
                  <button className="btn-delete" onClick={() => handleDelete(tarefa._id)}>
                    Excluir
                  </button>
                </div>
              </div>
            ))
          )}
        </div>
      </main>
    </div>
  );
}

export default DashboardTarefasAdmin;
