import { request } from './http';

export interface ApiPatient {
  id: number;
  username: string;
  name: string;
  birthday: string | null;
  phone: string | null;
  gender: string | null;
}

export interface AuthResult {
  token: string;
  patient: ApiPatient;
}

export interface RegisterPayload {
  username: string;
  password: string;
  name: string;
  birthday?: string | null;
  phone?: string | null;
  gender?: string | null;
}

export const PATIENT_TOKEN_KEY = 'qa_patient_token';

export function registerPatient(payload: RegisterPayload): Promise<AuthResult> {
  return request<AuthResult>('/api/auth/patient/register', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export function loginPatient(username: string, password: string): Promise<AuthResult> {
  return request<AuthResult>('/api/auth/patient/login', {
    method: 'POST',
    body: JSON.stringify({ username, password }),
  });
}

export function fetchCurrentPatient(token: string): Promise<ApiPatient> {
  return request<ApiPatient>('/api/auth/patient/me', {
    headers: { Authorization: `Bearer ${token}` },
  });
}

export function logoutPatient(token: string): Promise<void> {
  return request<void>('/api/auth/patient/logout', {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
  });
}

export function savePatientToken(token: string): void {
  localStorage.setItem(PATIENT_TOKEN_KEY, token);
}

export function readPatientToken(): string | null {
  return localStorage.getItem(PATIENT_TOKEN_KEY);
}

export function clearPatientToken(): void {
  localStorage.removeItem(PATIENT_TOKEN_KEY);
}
