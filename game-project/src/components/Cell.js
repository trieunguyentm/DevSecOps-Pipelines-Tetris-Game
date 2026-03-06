import React from 'react';

const Cell = React.memo(({ cell }) => {
  const classNames = `cell ${cell.className}`;
  return <div className={classNames} />;
});

Cell.displayName = 'Cell';

export default Cell;
