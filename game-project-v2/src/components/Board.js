import React from 'react';
import Cell from './Cell';
import { BOARD_ROWS, BOARD_COLUMNS } from '../utils/constants';

const Board = ({ board }) => {
  return (
    <div className="board" style={{ gridTemplateColumns: `repeat(${BOARD_COLUMNS}, 1fr)` }}>
      {board.map((row, rowIndex) =>
        row.map((cell, colIndex) => (
          <Cell key={`${rowIndex}-${colIndex}`} cell={cell} />
        ))
      )}
    </div>
  );
};

export default React.memo(Board);
