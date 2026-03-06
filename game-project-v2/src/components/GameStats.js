import React from "react";

const GameStats = ({ stats }) => {
  return (
    <div className="game-stats">
      <div className="stat-item">
        <span className="stat-label">SCORE</span>
        <span className="stat-value">{stats.score.toLocaleString()}</span>
      </div>
      <div className="stat-item">
        <span className="stat-label">HIGH</span>
        <span className="stat-value high-score">
          {stats.highScore.toLocaleString()}
        </span>
      </div>
      <div className="stat-item">
        <span className="stat-label">LEVEL</span>
        <span className="stat-value">{stats.level}</span>
      </div>
      <div className="stat-item">
        <span className="stat-label">LINES</span>
        <span className="stat-value">{stats.lines}</span>
      </div>
      {stats.combo > 1 && (
        <div className="stat-item combo-indicator">
          <span className="stat-label">COMBO</span>
          <span className="stat-value combo-value">x{stats.combo}</span>
        </div>
      )}
    </div>
  );
};

export default React.memo(GameStats);
