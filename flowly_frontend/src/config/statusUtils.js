export const formatarStatus = (status) => {
  const mapa = {
    pendente: 'Pendente',
    em_andamento: 'Em Andamento',
    concluido: 'Concluido',
  };

  if (!status) return '';

  if (mapa[status]) {
    return mapa[status];
  }

  return status
    .toString()
    .replace(/_/g, ' ')
    .replace(/\b\w/g, (letra) => letra.toUpperCase());
};
