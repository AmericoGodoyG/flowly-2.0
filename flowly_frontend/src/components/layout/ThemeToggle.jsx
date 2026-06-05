import React from 'react';
import { useTheme } from '../../config/ThemeContext';
import { FaSun, FaMoon } from 'react-icons/fa';
import '../../styles/components/ThemeToggle.css';

const ThemeToggle = () => {
  const { theme, toggleTheme } = useTheme();

  return (
    <button
      className="theme-toggle-btn"
      onClick={toggleTheme}
      aria-label={theme === 'dark' ? 'Ativar tema claro' : 'Ativar tema escuro'}
      data-testid="theme-toggle"
      title={theme === 'dark' ? 'Tema claro' : 'Tema escuro'}
    >
      <span className={`theme-icon ${theme === 'dark' ? 'show' : 'hide'}`}>
        <FaSun />
      </span>
      <span className={`theme-icon ${theme === 'light' ? 'show' : 'hide'}`}>
        <FaMoon />
      </span>
    </button>
  );
};

export default ThemeToggle;
