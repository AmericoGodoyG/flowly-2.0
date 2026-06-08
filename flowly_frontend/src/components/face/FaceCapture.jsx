import { useCallback, useEffect, useRef, useState } from 'react';
import FaceLoadingSpinner from './FaceLoadingSpinner';
import '../../styles/components/FaceCapture.css';

const DUAL_STEPS = [
  {
    key: 'front',
    buttonLabel: 'Capturar foto de frente',
    tip: 'Olhe de frente para a câmera, com o rosto centralizado na moldura.',
  },
  {
    key: 'side',
    buttonLabel: 'Capturar foto levemente de lado',
    tip: 'Gire levemente a cabeça (~15°) mantendo o rosto visível.',
  },
];

function FaceCapture({
  onCapture,
  disabled = false,
  buttonLabel = 'Capturar rosto',
  captureMode = 'single',
  processing = false,
  processingLabel = 'Processando...',
}) {
  const videoRef = useRef(null);
  const streamRef = useRef(null);
  const [cameraReady, setCameraReady] = useState(false);
  const [cameraError, setCameraError] = useState('');
  const [preview, setPreview] = useState('');
  const [captureStep, setCaptureStep] = useState(0);
  const [dualCaptures, setDualCaptures] = useState([]);

  const isDual = captureMode === 'dual';
  const currentDualStep = DUAL_STEPS[captureStep] || DUAL_STEPS[0];

  const stopCamera = useCallback(() => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((track) => track.stop());
      streamRef.current = null;
    }
    if (videoRef.current) {
      videoRef.current.srcObject = null;
    }
    setCameraReady(false);
  }, []);

  const isStreamAlive = useCallback(() => {
    const stream = streamRef.current;
    if (!stream) {
      return false;
    }
    return stream.getVideoTracks().some((track) => track.readyState === 'live');
  }, []);

  const attachStream = useCallback((stream) => {
    streamRef.current = stream;

    stream.getVideoTracks().forEach((track) => {
      track.onended = () => {
        setCameraReady(false);
      };
    });

    if (videoRef.current) {
      videoRef.current.srcObject = stream;
      videoRef.current.play().catch(() => {});
    }

    setCameraReady(true);
    setCameraError('');
  }, []);

  const startCamera = useCallback(async () => {
    if (isStreamAlive()) {
      if (videoRef.current && videoRef.current.srcObject !== streamRef.current) {
        videoRef.current.srcObject = streamRef.current;
        videoRef.current.play().catch(() => {});
      }
      setCameraReady(true);
      setCameraError('');
      return;
    }

    stopCamera();

    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: 'user', width: { ideal: 640 }, height: { ideal: 480 } },
        audio: false,
      });

      attachStream(stream);
    } catch (error) {
      setCameraError('Não foi possível acessar a câmera. Verifique as permissões do navegador.');
      setCameraReady(false);
    }
  }, [attachStream, isStreamAlive, stopCamera]);

  useEffect(() => {
    startCamera();
    return stopCamera;
  }, [startCamera, stopCamera]);

  const resetCapture = useCallback(() => {
    setPreview('');
    setCaptureStep(0);
    setDualCaptures([]);
    onCapture(isDual ? [] : '');
  }, [isDual, onCapture]);

  const handleCapture = () => {
    const video = videoRef.current;
    if (!video || !cameraReady || processing) {
      return;
    }

    const canvas = document.createElement('canvas');
    canvas.width = video.videoWidth || 640;
    canvas.height = video.videoHeight || 480;
    const context = canvas.getContext('2d');
    context.drawImage(video, 0, 0, canvas.width, canvas.height);
    const imageBase64 = canvas.toDataURL('image/jpeg', 0.92);
    setPreview(imageBase64);

    if (!isDual) {
      onCapture(imageBase64);
      return;
    }

    const nextCaptures = [...dualCaptures, imageBase64];
    setDualCaptures(nextCaptures);

    if (nextCaptures.length < DUAL_STEPS.length) {
      setCaptureStep(nextCaptures.length);
      setPreview('');
      return;
    }

    onCapture(nextCaptures);
  };

  const handleRetake = async () => {
    resetCapture();

    if (!isStreamAlive()) {
      await startCamera();
    }
  };

  const activeButtonLabel = isDual ? currentDualStep.buttonLabel : buttonLabel;
  const showPreview = Boolean(preview);
  const dualProgress = isDual ? `${Math.min(dualCaptures.length + (preview ? 1 : 0), 2)}/2` : null;

  return (
    <div className="face-capture">
      {cameraError && <div className="face-capture-error">{cameraError}</div>}

      {isDual && (
        <p className="face-capture-tip">
          Foto {dualProgress}: {currentDualStep.tip}
        </p>
      )}

      <div className="face-capture-video-wrap">
        <video
          ref={videoRef}
          autoPlay
          playsInline
          muted
          className="face-capture-video"
        />
        {!showPreview && !processing && <div className="face-capture-oval" aria-hidden="true" />}
        {showPreview && (
          <img
            src={preview}
            alt="Prévia do rosto capturado"
            className="face-capture-preview-overlay"
          />
        )}
        {processing && (
          <div className="face-capture-processing-overlay">
            <FaceLoadingSpinner label={processingLabel} />
          </div>
        )}
        {!cameraReady && !cameraError && !showPreview && !processing && (
          <p className="face-capture-loading">Iniciando câmera...</p>
        )}
      </div>

      <div className="face-capture-actions">
        <button
          type="button"
          className="glass-btn primary"
          onClick={handleCapture}
          disabled={disabled || processing || !cameraReady || (showPreview && !isDual)}
        >
          {activeButtonLabel}
        </button>
        {(showPreview || dualCaptures.length > 0) && (
          <button
            type="button"
            className="glass-btn secondary"
            onClick={handleRetake}
            disabled={disabled || processing}
          >
            Tirar outra foto
          </button>
        )}
      </div>
    </div>
  );
}

export default FaceCapture;
