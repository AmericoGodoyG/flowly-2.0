import React from "react";
import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router-dom";
import { publicRoutes, adminRoutes, userRoutes } from "./config/routes";
import { authUtils } from "./config/authUtils";
import FloatingTimer from "./components/timer/FloatingTimer";
import ColorBendsBackground from "./components/layout/ColorBendsBackground";
import "./styles/common/App.css";

function App() {
  return (
    <Router>
      <AppContent />
    </Router>
  );
}

function AppContent() {
  /**
   * Componente para renderizar rotas protegidas
   */
  const ProtectedRoute = ({ element, requiredRole }) => {
    const isAuthenticated = authUtils.isAuthenticated();
    const userType = authUtils.getUserType();

    if (!isAuthenticated) {
      return <Navigate to="/" replace />;
    }

    if (requiredRole && userType !== requiredRole) {
      return <Navigate to="/" replace />;
    }

    return (
      <>
        <ColorBendsBackground />
        {element}
        <FloatingTimer />
      </>
    );
  };

  return (
    <>
      <ColorBendsBackground />
      <Routes>
        {/* Rotas públicas */}
        {publicRoutes.map((route) => (
          <Route key={route.path} path={route.path} element={route.element} />
        ))}

        {/* Rotas protegidas de admin */}
        {adminRoutes.map((route) => (
          <Route
            key={route.path}
            path={route.path}
            element={
              <ProtectedRoute
                element={route.element}
                requiredRole={route.requiredRole}
              />
            }
          />
        ))}

        {/* Rotas protegidas de usuário comum */}
        {userRoutes.map((route) => (
          <Route
            key={route.path}
            path={route.path}
            element={
              <ProtectedRoute
                element={route.element}
                requiredRole={route.requiredRole}
              />
            }
          />
        ))}

        {/* Rota padrão para URLs não encontradas */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </>
  );
}

export default App;
