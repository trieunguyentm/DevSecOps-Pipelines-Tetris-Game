import React from 'react';

const HoldPiece = ({ piece, canHold }) => {
  return (
    <div className={`hold-piece-container ${!canHold ? 'hold-used' : ''}`}>
      <h3>HOLD</h3>
      <div className="hold-piece-preview">
        {piece ? (
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
        ) : (
          <div className="hold-empty">
            <span>C</span>
          </div>
        )}
      </div>
    </div>
  );
};

export default React.memo(HoldPiece);
