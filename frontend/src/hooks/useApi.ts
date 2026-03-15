import { useCallback, useEffect, useState } from 'react';

interface ApiState<T> {
  data: T | null;
  loading: boolean;
  error: Error | null;
  refetch: () => Promise<void>;
}

export function useApi<T>(request: () => Promise<T>): ApiState<T> {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<Error | null>(null);

  const execute = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const result = await request();
      setData(result);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError : new Error('Unknown request error'));
    } finally {
      setLoading(false);
    }
  }, [request]);

  useEffect(() => {
    void execute();
  }, [execute]);

  return {
    data,
    loading,
    error,
    refetch: execute,
  };
}
