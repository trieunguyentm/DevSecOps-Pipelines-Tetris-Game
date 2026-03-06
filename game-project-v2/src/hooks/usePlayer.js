import { useState, useCallback } from "react";
import { TETROMINOES, randomTetromino, rotate } from "../utils/Tetrominoes";
import { hasCollision } from "../utils/Board";
import { BOARD_COLUMNS } from "../utils/constants";

const buildPlayer = (tetromino) => {
  const piece = tetromino || randomTetromino();
  return {
    tetromino: piece,
    position: {
      row: 0,
      col:
        Math.floor(BOARD_COLUMNS / 2) - Math.floor(piece.shape[0].length / 2),
    },
    collided: false,
  };
};

const usePlayer = () => {
  const [player, setPlayer] = useState(buildPlayer());
  const [nextPieces, setNextPieces] = useState([
    randomTetromino(),
    randomTetromino(),
    randomTetromino(),
  ]);
  const [holdPiece, setHoldPiece] = useState(null);
  const [canHold, setCanHold] = useState(true);

  const resetPlayer = useCallback(() => {
    const queue = [randomTetromino(), randomTetromino(), randomTetromino()];
    setNextPieces(queue);
    setPlayer(buildPlayer(randomTetromino()));
    setHoldPiece(null);
    setCanHold(true);
  }, []);

  const movePlayer = useCallback(({ row, col, board }) => {
    setPlayer((prev) => {
      const newPos = {
        row: prev.position.row + row,
        col: prev.position.col + col,
      };

      if (hasCollision(board, newPos, prev.tetromino.shape)) {
        if (row > 0) {
          return { ...prev, collided: true };
        }
        return prev;
      }

      return {
        ...prev,
        position: newPos,
        collided: false,
      };
    });
  }, []);

  const rotatePlayer = useCallback((board) => {
    setPlayer((prev) => {
      const rotated = rotate(prev.tetromino.shape);

      // Wall kick: try offsets 0, -1, +1, -2, +2
      const offsets = [0, -1, 1, -2, 2];
      for (const offset of offsets) {
        const newPos = {
          row: prev.position.row,
          col: prev.position.col + offset,
        };
        if (!hasCollision(board, newPos, rotated)) {
          return {
            ...prev,
            tetromino: { ...prev.tetromino, shape: rotated },
            position: newPos,
          };
        }
      }
      return prev;
    });
  }, []);

  const hardDrop = useCallback((board) => {
    setPlayer((prev) => {
      let newRow = prev.position.row;
      while (
        !hasCollision(
          board,
          { row: newRow + 1, col: prev.position.col },
          prev.tetromino.shape,
        )
      ) {
        newRow++;
      }
      return {
        ...prev,
        position: { row: newRow, col: prev.position.col },
        collided: true,
      };
    });
  }, []);

  const spawnNextPiece = useCallback(() => {
    setNextPieces((prev) => {
      const [next, ...rest] = prev;
      setPlayer(buildPlayer(next));
      return [...rest, randomTetromino()];
    });
    setCanHold(true);
  }, []);

  const holdCurrentPiece = useCallback(() => {
    if (!canHold) return;
    setCanHold(false);

    setPlayer((prev) => {
      const currentTetromino = {
        type: prev.tetromino.type,
        shape: TETROMINOES[prev.tetromino.type].shape,
        color: prev.tetromino.color,
        className: prev.tetromino.className,
      };

      if (holdPiece) {
        const swapped = buildPlayer(holdPiece);
        setHoldPiece(currentTetromino);
        return swapped;
      } else {
        setHoldPiece(currentTetromino);
        setNextPieces((prevQueue) => {
          const [next, ...rest] = prevQueue;
          return [...rest, randomTetromino()];
        });
        return buildPlayer(nextPieces[0]);
      }
    });
  }, [canHold, holdPiece, nextPieces]);

  return {
    player,
    movePlayer,
    rotatePlayer,
    hardDrop,
    resetPlayer,
    spawnNextPiece,
    nextPieces,
    holdPiece,
    holdCurrentPiece,
    canHold,
  };
};

export default usePlayer;
