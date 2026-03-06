import { useEffect, useRef } from 'react';

const useInterval = (callback, delay) => {
  const callbackRef = useRef();

  useEffect(() => {
    callbackRef.current = callback;
  }, [callback]);

  useEffect(() => {
    if (delay === null) return;

    const id = setInterval(() => callbackRef.current(), delay);
    return () => clearInterval(id);
  }, [delay]);
};

export default useInterval;
