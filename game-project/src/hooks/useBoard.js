import { useState, useCallback, useEffect } from 'react';
import { createEmptyBoard, placePiece, clearLines, transferToBoard, hasCollision } from '../utils/Board';

const useBoard = (player, addLines, spawnNextPiece) => {
  const [board, setBoard] = useState(createEmptyBoard());
  const [displayBoard, setDisplayBoard] = useState(createEmptyBoard());

  useEffect(() => {
    if (!player.collided) {
      setDisplayBoard(transferToBoard(board, player));
      return;
    }

    const newBoard = placePiece(board, player.position, player.tetromino.shape, player.tetromino.className);
    const { board: clearedBoard, linesCleared } = clearLines(newBoard);

    setBoard(clearedBoard);
    addLines(linesCleared);
    spawnNextPiece();
  }, [player, board, addLines, spawnNextPiece]);

  const resetBoard = useCallback(() => {
    setBoard(createEmptyBoard());
  }, []);

  const isGameOver = useCallback(() => {
    return hasCollision(board, player.position, player.tetromino.shape);
  }, [board, player]);

  return { displayBoard, board, resetBoard, isGameOver };
};

export default useBoard;
