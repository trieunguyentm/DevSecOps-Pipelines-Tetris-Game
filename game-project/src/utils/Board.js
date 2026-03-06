import { BOARD_ROWS, BOARD_COLUMNS } from './constants';

export const createEmptyBoard = () =>
  Array.from({ length: BOARD_ROWS }, () =>
    Array.from({ length: BOARD_COLUMNS }, () => ({ occupied: false, className: '' }))
  );

export const hasCollision = (board, position, shape) => {
  for (let r = 0; r < shape.length; r++) {
    for (let c = 0; c < shape[r].length; c++) {
      if (shape[r][c]) {
        const boardRow = r + position.row;
        const boardCol = c + position.col;

        if (boardRow < 0) continue;

        if (
          boardRow >= BOARD_ROWS ||
          boardCol < 0 ||
          boardCol >= BOARD_COLUMNS ||
          board[boardRow][boardCol].occupied
        ) {
          return true;
        }
      }
    }
  }
  return false;
};

export const placePiece = (board, position, shape, className) => {
  const newBoard = board.map((row) => row.map((cell) => ({ ...cell })));

  for (let r = 0; r < shape.length; r++) {
    for (let c = 0; c < shape[r].length; c++) {
      if (shape[r][c]) {
        const boardRow = r + position.row;
        const boardCol = c + position.col;
        if (boardRow >= 0 && boardRow < BOARD_ROWS && boardCol >= 0 && boardCol < BOARD_COLUMNS) {
          newBoard[boardRow][boardCol] = { occupied: true, className };
        }
      }
    }
  }
  return newBoard;
};

export const clearLines = (board) => {
  const newBoard = board.filter((row) => !row.every((cell) => cell.occupied));
  const linesCleared = BOARD_ROWS - newBoard.length;

  const emptyRows = Array.from({ length: linesCleared }, () =>
    Array.from({ length: BOARD_COLUMNS }, () => ({ occupied: false, className: '' }))
  );

  return { board: [...emptyRows, ...newBoard], linesCleared };
};

export const transferToBoard = (board, player) => {
  const displayBoard = board.map((row) => row.map((cell) => ({ ...cell })));

  // Add ghost piece
  let ghostRow = player.position.row;
  while (!hasCollision(board, { row: ghostRow + 1, col: player.position.col }, player.tetromino.shape)) {
    ghostRow++;
  }

  for (let r = 0; r < player.tetromino.shape.length; r++) {
    for (let c = 0; c < player.tetromino.shape[r].length; c++) {
      if (player.tetromino.shape[r][c]) {
        const bRow = ghostRow + r;
        const bCol = player.position.col + c;
        if (bRow >= 0 && bRow < BOARD_ROWS && bCol >= 0 && bCol < BOARD_COLUMNS) {
          if (!displayBoard[bRow][bCol].occupied) {
            displayBoard[bRow][bCol] = {
              occupied: false,
              className: `${player.tetromino.className} ghost`,
            };
          }
        }
      }
    }
  }

  // Add current piece
  for (let r = 0; r < player.tetromino.shape.length; r++) {
    for (let c = 0; c < player.tetromino.shape[r].length; c++) {
      if (player.tetromino.shape[r][c]) {
        const bRow = player.position.row + r;
        const bCol = player.position.col + c;
        if (bRow >= 0 && bRow < BOARD_ROWS && bCol >= 0 && bCol < BOARD_COLUMNS) {
          displayBoard[bRow][bCol] = {
            occupied: false,
            className: player.tetromino.className,
          };
        }
      }
    }
  }

  return displayBoard;
};
