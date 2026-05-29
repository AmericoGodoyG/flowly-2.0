import React, { useEffect, useMemo, useState } from 'react';
import apiClient from '../../config/apiClient';
import Sidebar from '../../components/layout/Sidebar';
import { API_ENDPOINTS } from '../../config/config';
import '../../styles/pages/admin/DashboardAdmin.css';
import '../../styles/pages/user/EquipesUser.css';

function EquipesUser() {
  const [equipes, setEquipes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    const carregarEquipes = async () => {
      setLoading(true);
      setError('');

      try {
        const response = await apiClient.get(API_ENDPOINTS.MINHAS_EQUIPES);
        setEquipes(response.data);
      } catch (err) {
        setError('Nao foi possivel carregar suas equipes.');
      } finally {
        setLoading(false);
      }
    };

    carregarEquipes();
  }, []);

  const totalMembros = useMemo(
    () => equipes.reduce((total, equipe) => total + (equipe.membros?.length || 0), 0),
    [equipes]
  );

  return (
    <div className="admin-page equipes-user-page">
      <Sidebar />

      <main className="dashboard-user equipes-user-content">
        <header className="equipes-user-header">
          <h2>Minhas Equipes</h2>
          <p>Veja as equipes em que voce participa.</p>
        </header>

        <section className="equipes-user-metrics">
          <article className="equipes-user-metric">
            <span className="metric-label">Equipes vinculadas</span>
            <strong>{equipes.length}</strong>
          </article>
          <article className="equipes-user-metric">
            <span className="metric-label">Total de membros nas equipes</span>
            <strong>{totalMembros}</strong>
          </article>
        </section>

        {loading && <p>Carregando equipes...</p>}
        {!loading && error && <p className="equipes-user-error">{error}</p>}

        {!loading && !error && equipes.length === 0 && (
          <p>Voce ainda nao esta vinculado a nenhuma equipe.</p>
        )}

        {!loading && !error && equipes.length > 0 && (
          <section className="equipes-user-grid">
            {equipes.map((equipe) => (
              <article key={equipe._id} className="equipe-user-card">
                <h3>{equipe.nome}</h3>
                <p>
                  <strong>Membros:</strong> {equipe.membros?.length || 0}
                </p>
                <ul>
                  {(equipe.membros || []).map((membro) => (
                    <li key={membro._id}>{membro.nome}</li>
                  ))}
                </ul>
              </article>
            ))}
          </section>
        )}
      </main>
    </div>
  );
}

export default EquipesUser;
