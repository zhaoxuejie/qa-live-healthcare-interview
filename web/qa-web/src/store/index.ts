import { reactive } from 'vue';
import { fetchDoctors, loginDoctor as loginDoctorApi } from '../api/doctors';
import type { Doctor } from '../api/doctors';
import {
  clearPatientToken,
  fetchCurrentPatient,
  loginPatient as loginPatientApi,
  logoutPatient as logoutPatientApi,
  readPatientToken,
  registerPatient as registerPatientApi,
  savePatientToken,
  type ApiPatient,
  type RegisterPayload
} from '../api/auth';
import questionData from '../data/question-list.json';

export type { Doctor } from '../api/doctors';

export interface Patient {
  id: string;
  username: string;
  name: string;
  birthday: string;
  phone: string;
  gender: string;
}

export interface Question {
  id: string;
  patientId: string;
  patientName: string;
  doctorId: string;
  doctorName: string;
  question: string;
  submitTime: string;
  status: 'pending' | 'answered';
  answer: string | null;
  answerTime: string | null;
}

interface State {
  doctors: Doctor[];
  doctorsLoading: boolean;
  doctorsError: string | null;
  questions: Question[];
  currentDoctor: Doctor | null;
  currentPatient: Patient | null;
}

const state = reactive<State>({
  doctors: [],
  doctorsLoading: false,
  doctorsError: null,
  questions: questionData as Question[],
  currentDoctor: null,
  currentPatient: null,
});

function mapPatient(patient: ApiPatient): Patient {
  return {
    id: String(patient.id),
    username: patient.username,
    name: patient.name,
    birthday: patient.birthday ?? '',
    phone: patient.phone ?? '',
    gender: patient.gender ?? '',
  };
}

export const store = {
  state,

  /**
   * 从后端加载医生列表；已加载过则复用缓存，force=true 强制刷新。
   */
  async loadDoctors(force = false): Promise<void> {
    if (state.doctorsLoading) {
      return;
    }
    if (!force && state.doctors.length > 0) {
      return;
    }
    state.doctorsLoading = true;
    state.doctorsError = null;
    try {
      state.doctors = await fetchDoctors();
    } catch (error) {
      state.doctorsError = error instanceof Error ? error.message : '医生数据加载失败';
    } finally {
      state.doctorsLoading = false;
    }
  },

  async loginDoctor(username: string, password: string): Promise<Doctor | null> {
    try {
      const doctor = await loginDoctorApi(username, password);
      state.currentDoctor = doctor;
      return doctor;
    } catch {
      return null;
    }
  },

  logoutDoctor() {
    state.currentDoctor = null;
  },

  async loginPatient(username: string, password: string): Promise<Patient> {
    const result = await loginPatientApi(username, password);
    savePatientToken(result.token);
    state.currentPatient = mapPatient(result.patient);
    return state.currentPatient;
  },

  async registerPatient(payload: RegisterPayload): Promise<Patient> {
    const result = await registerPatientApi(payload);
    savePatientToken(result.token);
    state.currentPatient = mapPatient(result.patient);
    return state.currentPatient;
  },

  /**
   * 页面加载时用本地 token 恢复登录态；token 失效则静默清除。
   */
  async restorePatientSession(): Promise<void> {
    const token = readPatientToken();
    if (!token) {
      return;
    }
    try {
      state.currentPatient = mapPatient(await fetchCurrentPatient(token));
    } catch {
      clearPatientToken();
      state.currentPatient = null;
    }
  },

  async logoutPatient(): Promise<void> {
    const token = readPatientToken();
    if (token) {
      try {
        await logoutPatientApi(token);
      } catch {
        // 服务端不可用时也允许本地登出
      }
    }
    clearPatientToken();
    state.currentPatient = null;
  },

  getQuestionsByDoctor(doctorId: string): Question[] {
    return state.questions.filter(q => q.doctorId === doctorId);
  },

  getQuestionsByPatient(patientId: string): Question[] {
    return state.questions.filter(q => q.patientId === patientId);
  },

  addQuestion(question: Omit<Question, 'id' | 'submitTime' | 'status' | 'answer' | 'answerTime'>): Question {
    const newQuestion: Question = {
      ...question,
      id: `q${Date.now()}`,
      submitTime: new Date().toISOString(),
      status: 'pending',
      answer: null,
      answerTime: null,
    };
    state.questions.push(newQuestion);
    return newQuestion;
  },

  answerQuestion(questionId: string, answer: string) {
    const question = state.questions.find(q => q.id === questionId);
    if (question) {
      question.status = 'answered';
      question.answer = answer;
      question.answerTime = new Date().toISOString();
    }
  },

  markQuestionAsAnswered(questionId: string) {
    const question = state.questions.find(q => q.id === questionId);
    if (question) {
      question.status = 'answered';
      question.answer = '已口述解答';
      question.answerTime = new Date().toISOString();
    }
  },

  getDoctorByUsername(username: string): Doctor | undefined {
    return state.doctors.find(d => d.username === username);
  },

  getActiveDoctors(): Doctor[] {
    return state.doctors.filter(d => d.isActive);
  },

  getStatistics() {
    const totalDoctors = state.doctors.length;
    const totalQuestions = state.questions.length;
    const activeSessions = state.questions.filter(q => q.status === 'pending').length;
    const totalSessions = state.doctors.filter(d => d.isActive).length;

    return {
      totalDoctors,
      totalQuestions,
      activeSessions,
      totalSessions,
    };
  },
};
