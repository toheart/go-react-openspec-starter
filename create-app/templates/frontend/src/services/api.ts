import axios from 'axios';

import type { ApiEnvelope } from '../types/api';
import type { SampleItem } from '../types/sample';

export class ApiClientError extends Error {
  code: number;
  detail?: unknown;

  constructor(message: string, code: number, detail?: unknown) {
    super(message);
    this.name = 'ApiClientError';
    this.code = code;
    this.detail = detail;
  }
}

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL ?? '/api/v1',
  timeout: 5000,
});

export async function fetchSamples(): Promise<SampleItem[]> {
  const response = await apiClient.get<ApiEnvelope<SampleItem[]>>('/samples');

  if (response.data.code !== 0) {
    throw new ApiClientError(
      response.data.message,
      response.data.code,
      response.data.detail,
    );
  }

  return response.data.data;
}
