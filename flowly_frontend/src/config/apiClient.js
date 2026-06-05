/**
 * Cliente Axios centralizado para toda a aplicação
 * Garante que todas as requisições usem as URLs corretas do ambiente
 */

import axios from 'axios';
import { authUtils } from './authUtils';

const normalizePublicApiUrl = (url = '') =>
  url.trim().replace(/\/+$/, '').replace(/\/api$/, '');

// Obtém a URL base da API das variáveis de ambiente
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api';
const API_PUBLIC_URL =
  normalizePublicApiUrl(process.env.REACT_APP_API_PUBLIC_URL || '') ||
  normalizePublicApiUrl(API_BASE_URL) ||
  'http://localhost:5000';

// Cria uma instância do axios com configurações padrão
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000,
});

// Interceptor para adicionar o token em todas as requisições
apiClient.interceptors.request.use(
  (config) => {
    const token = authUtils.getToken();
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Interceptor para tratar erros de resposta
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    // Se for erro 401, limpar autenticação
    if (error.response?.status === 401) {
      authUtils.clearAuthData();
      // Redirecionar para login se necessário
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

/**
 * Obtém URL completa da API (incluindo domínio)
 * Útil para URLs de arquivos e imagens
 */
export const getFullApiUrl = (path = '') => {
  if (path.startsWith('http')) {
    return path;
  }
  return `${API_PUBLIC_URL}${path}`;
};

/**
 * Obtém a URL base pública da API
 */
export const getApiPublicUrl = () => API_PUBLIC_URL;

/**
 * Obtém a URL base da API
 */
export const getApiBaseUrl = () => API_BASE_URL;

export default apiClient;
