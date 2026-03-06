import { useState, useCallback } from "react";
import {
  POINTS,
  LINES_PER_LEVEL,
  COMBO_MULTIPLIER,
  HIGH_SCORE_KEY,
} from "../utils/constants";

const getHighScore = () => {
  try {
    return parseInt(localStorage.getItem(HIGH_SCORE_KEY), 10) || 0;
  } catch {
    return 0;
  }
};

const saveHighScore = (score) => {
  try {
    const current = getHighScore();
    if (score > current) {
      localStorage.setItem(HIGH_SCORE_KEY, score.toString());
      return score;
    }
    return current;
  } catch {
    return score;
  }
};

const useGameStats = () => {
  const [stats, setStats] = useState({
    score: 0,
    level: 1,
    lines: 0,
    combo: 0,
    highScore: getHighScore(),
  });

  const addLines = useCallback((linesCleared) => {
    setStats((prev) => {
      if (linesCleared === 0) {
        return { ...prev, combo: 0 };
      }

      const newCombo = prev.combo + 1;
      const newLines = prev.lines + linesCleared;
      const newLevel = Math.floor(newLines / LINES_PER_LEVEL) + 1;
      const points = POINTS[linesCleared] || 0;
      const comboMultiplier = COMBO_MULTIPLIER[Math.min(newCombo, 5)] || 3;
      const newScore =
        prev.score + Math.floor(points * prev.level * comboMultiplier);
      const highScore = saveHighScore(newScore);

      return {
        score: newScore,
        level: Math.min(newLevel, 10),
        lines: newLines,
        combo: newCombo,
        highScore,
      };
    });
  }, []);

  const resetStats = useCallback(() => {
    setStats((prev) => ({
      score: 0,
      level: 1,
      lines: 0,
      combo: 0,
      highScore: prev.highScore,
    }));
  }, []);

  return { stats, addLines, resetStats };
};

export default useGameStats;
