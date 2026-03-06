import React from 'react';

const GameStats = ({ stats }) => {
  return (
    <div className="game-stats">
      <div className="stat-item">
        <span className="stat-label">SCORE</span>
        <span className="stat-value">{stats.score.toLocaleString()}</span>
      </div>
      <div className="stat-item">
        <span className="stat-label">LEVEL</span>
        <span className="stat-value">{stats.level}</span>
      </div>
      <div className="stat-item">
        <span className="stat-label">LINES</span>
        <span className="stat-value">{stats.lines}</span>
      </div>
    </div>
  );
};

export default React.memo(GameStats);
