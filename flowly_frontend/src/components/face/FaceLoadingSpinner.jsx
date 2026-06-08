import '../../styles/components/FaceLoadingSpinner.css';

function FaceLoadingSpinner({ label = 'Verificando...' }) {
  return (
    <span className="face-loading-inline">
      <span className="face-loading-spinner" aria-hidden="true" />
      <span>{label}</span>
    </span>
  );
}

export default FaceLoadingSpinner;
