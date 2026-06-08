import axios from 'axios';
import { authUtils } from './authUtils';

const DEFAULT_API_PUBLIC_URL = 'https://flowly-api-backend-646126851973.southamerica-east1.run.app';
const DEFAULT_API_BASE_URL = `${DEFAULT_API_PUBLIC_URL}/api`;

const isLocalHost =
  typeof window !== 'undefined' &&
  ['localhost', '127.0.0.1'].includes(window.location.hostname);

const normalizePublicApiUrl = (url = '') =>
  url.trim().replace(/\/+$/, '').replace(/\/api$/, '');

const API_BASE_URL =
  (process.env.REACT_APP_API_URL || '').trim() ||
  (isLocalHost ? 'http://localhost:5000/api' : DEFAULT_API_BASE_URL);

const API_PUBLIC_URL =
  normalizePublicApiUrl(process.env.REACT_APP_API_PUBLIC_URL || '') ||
  normalizePublicApiUrl(API_BASE_URL) ||
  (isLocalHost ? 'http://localhost:5000' : DEFAULT_API_PUBLIC_URL);

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000,
});

apiClient.interceptors.request.use(
  (config) => {
    const token = authUtils.getToken();
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      authUtils.clearAuthData();
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

export const getFullApiUrl = (path = '') => {
  if (path.startsWith('http')) {
    return path;
  }
  return `${API_PUBLIC_URL}${path}`;
};

export const getApiPublicUrl = () => API_PUBLIC_URL;

export const getApiBaseUrl = () => API_BASE_URL;

export const FACE_API_TIMEOUT_MS = 120000;

export default apiClient;
