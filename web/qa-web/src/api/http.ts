export interface ApiEnvelope<T> {
  code: number;
  message: string;
  data: T;
}

const BASE_URL: string =
  (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? 'http://localhost:8080';

export class ApiError extends Error {
  constructor(message: string, readonly status?: number) {
    super(message);
    this.name = 'ApiError';
  }
}

/**
 * 统一请求封装：解析后端 { code, message, data } 响应体。
 * HTTP 非 2xx 或 code !== 0 时抛出 ApiError。
 */
export async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const headers: Record<string, string> = { Accept: 'application/json' };
  if (init?.body) {
    headers['Content-Type'] = 'application/json';
  }

  const response = await fetch(`${BASE_URL}${path}`, {
    ...init,
    headers: { ...headers, ...(init?.headers as Record<string, string> | undefined) },
  });

  if (response.status === 204) {
    return undefined as T;
  }

  let body: ApiEnvelope<T> | undefined;
  try {
    body = (await response.json()) as ApiEnvelope<T>;
  } catch {
    body = undefined;
  }

  if (!response.ok) {
    throw new ApiError(body?.message ?? `请求失败 (HTTP ${response.status})`, response.status);
  }
  if (!body) {
    throw new ApiError('响应格式不正确');
  }
  if (body.code !== 0) {
    throw new ApiError(body.message || '业务处理失败');
  }
  return body.data;
}
