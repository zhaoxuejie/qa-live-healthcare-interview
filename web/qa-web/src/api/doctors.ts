import { request } from './http';

/** 医生信息（后端不返回密码） */
export interface Doctor {
  id: string;
  username: string;
  name: string;
  title: string;
  department: string;
  avatar: string;
  experience: string;
  specialties: string[];
  isActive: boolean;
}

export function fetchDoctors(activeOnly = false): Promise<Doctor[]> {
  const query = activeOnly ? '?active=true' : '';
  return request<Doctor[]>(`/api/doctors${query}`);
}

export function loginDoctor(username: string, password: string): Promise<Doctor> {
  return request<Doctor>('/api/doctors/login', {
    method: 'POST',
    body: JSON.stringify({ username, password }),
  });
}
