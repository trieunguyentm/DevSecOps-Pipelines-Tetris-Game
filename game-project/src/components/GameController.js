import React, { useState, useCallback, useEffect } from 'react';
import Board from './Board';
import GameStats from './GameStats';
import NextPiece from './NextPiece';
import usePlayer from '../hooks/usePlayer';
import useBoard from '../hooks/useBoard';
import useGameStats from '../hooks/useGameStats';
import useInterval from '../hooks/useInterval';
import { LEVEL_SPEEDS } from '../utils/constants';

const GameController = () => {
  const [gameState, setGameState] = useState('idle'); // idle, playing, paused, gameover
  const { stats, addLines, resetStats } = useGameStats();
  const { player, movePlayer, rotatePlayer, hardDrop, resetPlayer, spawnNextPiece, nextPieces } = usePlayer();
  const { displayBoard, board, resetBoard, isGameOver } = useBoard(player, addLines, spawnNextPiece);

  const speed = gameState === 'playing' ? (LEVEL_SPEEDS[stats.level] || 100) : null;

  const drop = useCallback(() => {
    if (gameState !== 'playing') return;
    movePlayer({ row: 1, col: 0, board });
  }, [gameState, movePlayer, board]);

  useInterval(drop, speed);

  useEffect(() => {
    if (gameState === 'playing' && player.position.row === 0 && isGameOver()) {
      setGameState('gameover');
    }
  }, [player, gameState, isGameOver]);

  const startGame = useCallback(() => {
    resetBoard();
    resetPlayer();
    resetStats();
    setGameState('playing');
  }, [resetBoard, resetPlayer, resetStats]);

  const togglePause = useCallback(() => {
    setGameState((prev) => (prev === 'playing' ? 'paused' : prev === 'paused' ? 'playing' : prev));
  }, []);

  const handleKeyDown = useCallback(
    (e) => {
      if (gameState !== 'playing') {
        if (e.key === 'Enter' && (gameState === 'idle' || gameState === 'gameover')) {
          startGame();
        }
        if (e.key === 'p' && gameState === 'paused') {
          togglePause();
        }
        return;
      }

      switch (e.key) {
        case 'ArrowLeft':
          e.preventDefault();
          movePlayer({ row: 0, col: -1, board });
          break;
        case 'ArrowRight':
          e.preventDefault();
          movePlayer({ row: 0, col: 1, board });
          break;
        case 'ArrowDown':
          e.preventDefault();
          movePlayer({ row: 1, col: 0, board });
          break;
        case 'ArrowUp':
          e.preventDefault();
          rotatePlayer(board);
          break;
        case ' ':
          e.preventDefault();
          hardDrop(board);
          break;
        case 'p':
        case 'P':
          togglePause();
          break;
        default:
          break;
      }
    },
    [gameState, movePlayer, rotatePlayer, hardDrop, board, startGame, togglePause]
  );

  useEffect(() => {
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [handleKeyDown]);

  const renderOverlay = () => {
    if (gameState === 'idle') {
      return (
        <div className="overlay">
          <div className="overlay-content">
            <h1 className="game-title">TETRIS</h1>
            <p className="overlay-text">Press ENTER or click Start to play</p>
            <button className="btn-start" onClick={startGame}>
              START GAME
            </button>
          </div>
        </div>
      );
    }
    if (gameState === 'gameover') {
      return (
        <div className="overlay overlay-gameover">
          <div className="overlay-content">
            <h2 className="gameover-title">GAME OVER</h2>
            <p className="final-score">Score: {stats.score.toLocaleString()}</p>
            <p className="final-score">Level: {stats.level}</p>
            <p className="final-score">Lines: {stats.lines}</p>
            <button className="btn-start" onClick={startGame}>
              PLAY AGAIN
            </button>
          </div>
        </div>
      );
    }
    if (gameState === 'paused') {
      return (
        <div className="overlay overlay-paused">
          <div className="overlay-content">
            <h2 className="paused-title">PAUSED</h2>
            <p className="overlay-text">Press P to resume</p>
            <button className="btn-start" onClick={togglePause}>
              RESUME
            </button>
          </div>
        </div>
      );
    }
    return null;
  };

  return (
    <div className="game-container">
      <div className="game-left-panel">
        <GameStats stats={stats} />
        <div className="controls-info">
          <h3>CONTROLS</h3>
          <div className="control-item">
            <span className="key">&#8592; &#8594;</span> Move
          </div>
          <div className="control-item">
            <span className="key">&#8593;</span> Rotate
          </div>
          <div className="control-item">
            <span className="key">&#8595;</span> Soft Drop
          </div>
          <div className="control-item">
            <span className="key">Space</span> Hard Drop
          </div>
          <div className="control-item">
            <span className="key">P</span> Pause
          </div>
        </div>
      </div>
      <div className="game-board-wrapper">
        <Board board={displayBoard} />
        {renderOverlay()}
      </div>
      <div className="game-right-panel">
        <NextPiece pieces={nextPieces} />
      </div>
    </div>
  );
};

export default GameController;
