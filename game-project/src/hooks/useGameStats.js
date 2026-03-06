import { useState, useCallback } from 'react';
import { POINTS, LINES_PER_LEVEL } from '../utils/constants';

const useGameStats = () => {
  const [stats, setStats] = useState({
    score: 0,
    level: 1,
    lines: 0,
  });

  const addLines = useCallback((linesCleared) => {
    if (linesCleared === 0) return;

    setStats((prev) => {
      const newLines = prev.lines + linesCleared;
      const newLevel = Math.floor(newLines / LINES_PER_LEVEL) + 1;
      const points = POINTS[linesCleared] || 0;
      const newScore = prev.score + points * prev.level;

      return {
        score: newScore,
        level: Math.min(newLevel, 10),
        lines: newLines,
      };
    });
  }, []);

  const resetStats = useCallback(() => {
    setStats({ score: 0, level: 1, lines: 0 });
  }, []);

  return { stats, addLines, resetStats };
};

export default useGameStats;
