const THEME_STORAGE_KEY = 'flowly-theme';

const mockUser = {
  _id: 'user-1',
  id: 'user-1',
  nome: 'Usuario Teste',
  email: 'usuario.teste@flowly.local',
  tipo: 'user',
  fotoPerfil: '',
};

const mockAdmin = {
  ...mockUser,
  _id: 'admin-1',
  id: 'admin-1',
  nome: 'Admin Teste',
  email: 'admin.teste@flowly.local',
  tipo: 'admin',
};

const mockTeam = {
  _id: 'team-1',
  nome: 'Equipe Cypress',
  membros: [mockUser],
};

const mockTask = {
  _id: 'task-1',
  descricao: 'Validar tema em todas as paginas',
  detalhes: 'Tarefa usada pelos testes E2E de tema.',
  dataEntrega: '2026-06-10T12:00:00.000Z',
  status: 'pendente',
  urgencia: 'media',
  tempoEstimado: 30,
  tempoGasto: 0,
  cronometroAtivo: false,
  equipe: mockTeam,
  user: mockUser,
  subtarefas: [],
  comentarios: [],
  anexos: [],
};

const mockBacklogTask = {
  ...mockTask,
  _id: 'backlog-task-1',
  user: null,
};

const apiResponseFor = (req) => {
  const { method } = req;
  const url = new URL(req.url);
  const path = url.pathname.replace(/^\/api/, '');

  if (method === 'GET') {
    if (path === '/tarefas/minhas') {
      return [mockTask];
    }

    if (path === '/tarefas/backlog') {
      return [mockBacklogTask];
    }

    if (/^\/tarefas\/[^/]+\/detalhes$/.test(path)) {
      return { tarefa: mockBacklogTask };
    }

    if (/^\/tarefas\/[^/]+$/.test(path)) {
      return mockTask;
    }

    if (path === '/tarefas') {
      return [mockTask];
    }

    if (path === '/equipes/minhas') {
      return [mockTeam];
    }

    if (/^\/equipes\/[^/]+\/membros$/.test(path)) {
      return [mockUser];
    }

    if (/^\/equipes\/[^/]+\/messages$/.test(path)) {
      return [
        {
          _id: 'message-1',
          texto: 'Mensagem de teste',
          user: mockUser,
          createdAt: '2026-06-03T12:00:00.000Z',
        },
      ];
    }

    if (/^\/equipes\/[^/]+$/.test(path)) {
      return mockTeam;
    }

    if (path === '/equipes') {
      return [mockTeam];
    }

    if (path === '/users/me') {
      return mockUser;
    }

    if (path === '/users/search') {
      return [mockUser];
    }

    if (path === '/users') {
      return [mockUser, mockAdmin];
    }

    if (path === '/notificacoes/count') {
      return { count: 1 };
    }

    if (path === '/notificacoes') {
      return [
        {
          _id: 'notification-1',
          tipo: 'task',
          texto: 'Notificacao de teste',
          lida: false,
          createdAt: '2026-06-03T12:00:00.000Z',
        },
      ];
    }
  }

  if (method === 'POST' && path === '/auth/2fa/enviar-codigo') {
    return { userId: mockUser._id };
  }

  if (method === 'POST' && path === '/auth/2fa/validar-codigo') {
    return { token: 'fake-jwt-token-for-theme-test', redirect: '/dashboard' };
  }

  if (method === 'GET' && path === '/auth/2fa/validar-token') {
    return { token: 'fake-jwt-token-for-theme-test', redirect: '/dashboard' };
  }

  if (/\/cronometro$/.test(path)) {
    return { tarefa: mockTask, tempoExcedido: false };
  }

  return { ok: true };
};

const protectedPages = [
  { name: 'Dashboard admin', path: '/admin', role: 'admin' },
  { name: 'Editar equipe', path: '/admin/equipe/team-1', role: 'admin' },
  { name: 'Criar equipe', path: '/admin/criar-equipe', role: 'admin' },
  { name: 'Dashboard de tarefas admin', path: '/admin/tarefas', role: 'admin' },
  { name: 'Criar tarefa', path: '/admin/criar-tarefa', role: 'admin' },
  { name: 'Editar tarefa', path: '/admin/editar-tarefa/task-1', role: 'admin' },
  { name: 'Painel geral admin', path: '/admin/geral', role: 'admin' },
  { name: 'Chats admin', path: '/admin/chats', role: 'admin' },
  { name: 'Perfil', path: '/perfil', role: 'user' },
  { name: 'Dashboard usuario', path: '/dashboard', role: 'user' },
  { name: 'Kanban usuario', path: '/minhas-tarefas', role: 'user' },
  { name: 'Backlog', path: '/backlog', role: 'user' },
  { name: 'Detalhe do backlog', path: '/backlog/backlog-task-1', role: 'user' },
  { name: 'Equipes usuario', path: '/equipes', role: 'user' },
  { name: 'Chats usuario', path: '/chats', role: 'user' },
  { name: 'Notificacoes', path: '/notificacoes', role: 'user' },
];

const publicPages = [
  { name: 'Login', path: '/' },
  { name: 'Cadastro', path: '/register' },
  { name: 'Verificacao de email', path: '/verificar-2fa' },
];

const seedAuth = (win, role) => {
  const user = role === 'admin' ? mockAdmin : mockUser;

  win.localStorage.setItem('token', 'fake-jwt-token-for-theme-test');
  win.localStorage.setItem('tipo', role);
  win.localStorage.setItem('nome', user.nome);
  win.localStorage.setItem('id', user._id);
  win.localStorage.setItem('fotoPerfil', user.fotoPerfil || '');
};

const visitPage = ({ path, role }) => {
  cy.visit(path, {
    onBeforeLoad(win) {
      win.localStorage.removeItem(THEME_STORAGE_KEY);

      if (role) {
        seedAuth(win, role);
      }
    },
  });
};

const themeToggle = () => cy.get('[data-testid="theme-toggle"]');

const assertTheme = (theme) => {
  const expectedBgBody = theme === 'dark' ? '#0d0c13' : '#f0f2f5';
  const expectedAriaLabel = theme === 'dark' ? 'Ativar tema claro' : 'Ativar tema escuro';

  cy.document().its('documentElement').should('have.attr', 'data-theme', theme);

  cy.window().then((win) => {
    expect(win.localStorage.getItem(THEME_STORAGE_KEY)).to.eq(theme);

    const bgBody = win
      .getComputedStyle(win.document.documentElement)
      .getPropertyValue('--bg-body')
      .trim();

    expect(bgBody).to.eq(expectedBgBody);
  });

  themeToggle()
    .should('be.visible')
    .and('have.attr', 'aria-label', expectedAriaLabel);
};

const assertPageRendered = (path) => {
  cy.location('pathname').should('eq', path);
  cy.get('#root')
    .should('be.visible')
    .invoke('text')
    .should('match', /\S/);
  themeToggle().should('be.visible');
};

const assertThemeCycleWorks = (page) => {
  visitPage(page);
  assertPageRendered(page.path);
  assertTheme('dark');

  themeToggle().click();
  assertTheme('light');

  cy.reload();
  assertPageRendered(page.path);
  assertTheme('light');

  themeToggle().click();
  assertTheme('dark');
};

describe('Temas claro e escuro em todas as paginas', () => {
  beforeEach(() => {
    cy.intercept('http://localhost:5000/socket.io/**', { statusCode: 200, body: '' });

    cy.intercept({ url: 'http://localhost:5000/api/**' }, (req) => {
      req.reply({
        statusCode: 200,
        body: apiResponseFor(req),
      });
    });
  });

  publicPages.forEach((page) => {
    it(`${page.name} deve alternar entre tema claro e escuro`, () => {
      assertThemeCycleWorks(page);
    });
  });

  protectedPages.forEach((page) => {
    it(`${page.name} deve alternar entre tema claro e escuro`, () => {
      assertThemeCycleWorks(page);
    });
  });
});
