import React from 'react';

const NextPiece = ({ pieces }) => {
  return (
    <div className="next-piece-container">
      <h3>NEXT</h3>
      {pieces.map((piece, index) => (
        <div key={index} className="next-piece-preview">
          <div
            className="mini-board"
            style={{
              gridTemplateColumns: `repeat(${piece.shape[0].length}, 1fr)`,
            }}
          >
            {piece.shape.map((row, r) =>
              row.map((cell, c) => (
                <div
                  key={`${r}-${c}`}
                  className={`mini-cell ${cell ? piece.className : ''}`}
                />
              ))
            )}
          </div>
        </div>
      ))}
    </div>
  );
};

export default React.memo(NextPiece);
