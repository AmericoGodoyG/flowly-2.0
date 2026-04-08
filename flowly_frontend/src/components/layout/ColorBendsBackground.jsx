import React from 'react';
import '../../styles/components/ColorBendsBackground.css';

const ColorBendsBackground = () => {
  return (
    <div className="color-bends-container">
      <div className="mesh-gradient">
        <div className="blob blob-1"></div>
        <div className="blob blob-2"></div>
        <div className="blob blob-3"></div>
        <div className="blob blob-4"></div>
      </div>
      <div className="noise-overlay"></div>
    </div>
  );
};

export default ColorBendsBackground;
