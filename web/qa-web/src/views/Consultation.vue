<template>
  <div class="consultation">
    <div class="consultation-container">
      <div v-if="!currentPatient" class="auth-section">
        <div class="auth-card">
          <h1>患者登录</h1>
          <p>登录后即可提交和查看您的问诊问题</p>
          <a-tabs v-model:activeKey="authTab" @change="clearAuthError">
            <a-tab-pane key="login" tab="登录">
              <a-form
                :model="loginForm"
                :rules="loginRules"
                @finish="handleLogin"
                layout="vertical"
              >
                <a-form-item label="用户名" name="username">
                  <a-input v-model:value="loginForm.username" size="large" placeholder="请输入用户名">
                    <template #prefix>
                      <UserOutlined />
                    </template>
                  </a-input>
                </a-form-item>
                <a-form-item label="密码" name="password">
                  <a-input-password v-model:value="loginForm.password" size="large" placeholder="请输入密码">
                    <template #prefix>
                      <LockOutlined />
                    </template>
                  </a-input-password>
                </a-form-item>
                <a-form-item>
                  <a-button type="primary" html-type="submit" size="large" block :loading="authSubmitting">
                    登录
                  </a-button>
                </a-form-item>
              </a-form>
              <a-alert v-if="authError" type="error" :message="authError" show-icon class="auth-error" />
            </a-tab-pane>

            <a-tab-pane key="register" tab="注册">
              <a-form
                :model="registerForm"
                :rules="registerRules"
                @finish="handleRegister"
                layout="vertical"
              >
                <a-form-item label="用户名" name="username">
                  <a-input v-model:value="registerForm.username" size="large" placeholder="4-32 位字母、数字、下划线或连字符" />
                </a-form-item>
                <a-form-item label="密码" name="password">
                  <a-input-password v-model:value="registerForm.password" size="large" placeholder="至少 6 位" />
                </a-form-item>
                <a-form-item label="姓名" name="name">
                  <a-input v-model:value="registerForm.name" size="large" placeholder="请输入您的姓名" />
                </a-form-item>
                <a-form-item label="生日（选填）" name="birthday">
                  <a-date-picker
                    v-model:value="registerForm.birthday"
                    size="large"
                    format="YYYY-MM-DD"
                    placeholder="请选择生日"
                    style="width: 100%"
                  />
                </a-form-item>
                <a-form-item label="手机号（选填）" name="phone">
                  <a-input v-model:value="registerForm.phone" size="large" placeholder="请输入手机号" />
                </a-form-item>
                <a-form-item>
                  <a-button type="primary" html-type="submit" size="large" block :loading="authSubmitting">
                    注册并登录
                  </a-button>
                </a-form-item>
              </a-form>
              <a-alert v-if="authError" type="error" :message="authError" show-icon class="auth-error" />
            </a-tab-pane>
          </a-tabs>

          <a-alert
            message="演示账号"
            description="用户名 demo_patient，密码 123456"
            type="info"
            show-icon
          />
        </div>
      </div>

      <div v-else class="patient-portal">
        <div class="portal-header">
          <div class="patient-info">
            <UserOutlined class="patient-icon-large" />
            <div>
              <h1>{{ currentPatient.name }} 的问诊</h1>
              <p>欢迎使用在线问诊服务</p>
            </div>
          </div>
          <div class="portal-actions">
            <a-button @click="handleLogout">
              <LogoutOutlined />
              切换用户
            </a-button>
          </div>
        </div>

        <div class="selected-doctor" v-if="selectedDoctor">
          <a-alert
            :message="`当前诊室: ${selectedDoctor.name} - ${selectedDoctor.department}`"
            type="success"
            show-icon
            closable
            @close="clearSelectedDoctor"
          />
        </div>

        <div class="questions-section">
          <div class="section-header">
            <h2>我的问题</h2>
            <a-button type="primary" @click="showSubmitModal">
              <PlusOutlined />
              提交问题
            </a-button>
          </div>

          <a-empty v-if="myQuestions.length === 0" description="您还没有提交过问题" />

          <div v-else class="my-questions-list">
            <a-card
              v-for="question in myQuestions"
              :key="question.id"
              class="question-item"
            >
              <template #title>
                <div class="question-title">
                  <span>{{ question.doctorName }}</span>
                  <a-tag :color="question.status === 'answered' ? 'green' : 'orange'">
                    {{ question.status === 'answered' ? '已解答' : '待解答' }}
                  </a-tag>
                </div>
              </template>
              <div class="question-detail">
                <p class="question-text"><strong>问题:</strong> {{ question.question }}</p>
                <p class="submit-time">提交时间: {{ formatTime(question.submitTime) }}</p>
                <div v-if="question.status === 'answered'" class="answer-section">
                  <a-divider />
                  <p class="answer-text"><strong>医生回复:</strong> {{ question.answer }}</p>
                  <p class="answer-time">回复时间: {{ formatTime(question.answerTime!) }}</p>
                </div>
              </div>
            </a-card>
          </div>
        </div>
      </div>
    </div>

    <a-modal
      v-model:open="submitModalVisible"
      title="提交问题"
      @ok="submitQuestion"
      @cancel="closeSubmitModal"
      :confirmLoading="submitting"
      width="600px"
    >
      <a-form layout="vertical">
        <a-form-item label="选择医生" required>
          <a-select
            v-model:value="questionForm.doctorId"
            size="large"
            placeholder="请选择您要咨询的医生"
            :disabled="!!selectedDoctor"
          >
            <a-select-option
              v-for="doctor in availableDoctors"
              :key="doctor.id"
              :value="doctor.id"
            >
              <div class="doctor-option">
                <img :src="doctor.avatar" :alt="doctor.name" class="doctor-option-avatar" />
                <div>
                  <div>{{ doctor.name }}</div>
                  <div style="font-size: 12px; color: #999;">
                    {{ doctor.title }} · {{ doctor.department }}
                  </div>
                </div>
              </div>
            </a-select-option>
          </a-select>
        </a-form-item>

        <a-form-item label="您的问题" required>
          <a-textarea
            v-model:value="questionForm.question"
            :rows="6"
            placeholder="请详细描述您的症状或问题..."
          />
        </a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { message } from 'ant-design-vue';
import dayjs, { Dayjs } from 'dayjs';
import {
  UserOutlined,
  LockOutlined,
  LogoutOutlined,
  PlusOutlined
} from '@ant-design/icons-vue';
import { store, Doctor } from '../store';

const route = useRoute();

const currentPatient = computed(() => store.state.currentPatient);
const myQuestions = computed(() =>
  currentPatient.value
    ? store.getQuestionsByPatient(currentPatient.value.id)
    : []
);

const selectedDoctor = ref<Doctor | null>(null);

const authTab = ref<'login' | 'register'>('login');
const authSubmitting = ref(false);
const authError = ref('');

const clearAuthError = () => {
  authError.value = '';
};

const loginForm = reactive({
  username: '',
  password: '',
});

const loginRules = {
  username: [{ required: true, message: '请输入用户名' }],
  password: [{ required: true, message: '请输入密码' }],
};

const registerForm = reactive({
  username: '',
  password: '',
  name: '',
  birthday: null as Dayjs | null,
  phone: '',
});

const registerRules = {
  username: [
    { required: true, message: '请输入用户名' },
    { pattern: /^[A-Za-z0-9_-]{4,32}$/, message: '4-32 位字母、数字、下划线或连字符' },
  ],
  password: [
    { required: true, message: '请输入密码' },
    { min: 6, max: 64, message: '密码长度需为 6-64 位' },
  ],
  name: [{ required: true, message: '请输入姓名' }],
};

const submitModalVisible = ref(false);
const submitting = ref(false);

const questionForm = reactive({
  doctorId: '',
  question: '',
});

const availableDoctors = computed(() => {
  return selectedDoctor.value
    ? [selectedDoctor.value]
    : store.getActiveDoctors();
});

onMounted(async () => {
  await Promise.all([store.loadDoctors(), store.restorePatientSession()]);
  const doctorUsername = route.params.doctorUsername as string;
  if (doctorUsername) {
    const doctor = store.getDoctorByUsername(doctorUsername);
    if (doctor && doctor.isActive) {
      selectedDoctor.value = doctor;
      questionForm.doctorId = doctor.id;
    }
  }
});

const handleLogin = async () => {
  authSubmitting.value = true;
  authError.value = '';
  try {
    const patient = await store.loginPatient(loginForm.username, loginForm.password);
    message.success(`欢迎回来，${patient.name}`);
  } catch (error) {
    authError.value = error instanceof Error ? error.message : '登录失败，请稍后重试';
  } finally {
    authSubmitting.value = false;
  }
};

const handleRegister = async () => {
  authSubmitting.value = true;
  authError.value = '';
  try {
    const patient = await store.registerPatient({
      username: registerForm.username,
      password: registerForm.password,
      name: registerForm.name,
      birthday: registerForm.birthday ? registerForm.birthday.format('YYYY-MM-DD') : null,
      phone: registerForm.phone || null,
    });
    message.success(`注册成功，欢迎 ${patient.name}`);
  } catch (error) {
    authError.value = error instanceof Error ? error.message : '注册失败，请稍后重试';
  } finally {
    authSubmitting.value = false;
  }
};

const handleLogout = async () => {
  await store.logoutPatient();
  selectedDoctor.value = null;
  message.success('已退出登录');
};

const clearSelectedDoctor = () => {
  selectedDoctor.value = null;
  questionForm.doctorId = '';
};

const showSubmitModal = () => {
  if (selectedDoctor.value) {
    questionForm.doctorId = selectedDoctor.value.id;
  }
  submitModalVisible.value = true;
};

const closeSubmitModal = () => {
  submitModalVisible.value = false;
  if (!selectedDoctor.value) {
    questionForm.doctorId = '';
  }
  questionForm.question = '';
};

const submitQuestion = () => {
  if (!questionForm.doctorId) {
    message.error('请选择医生');
    return;
  }

  if (!questionForm.question.trim()) {
    message.error('请输入问题');
    return;
  }

  submitting.value = true;

  setTimeout(() => {
    const doctor = store.state.doctors.find(d => d.id === questionForm.doctorId);
    if (doctor && currentPatient.value) {
      store.addQuestion({
        patientId: currentPatient.value.id,
        patientName: currentPatient.value.name,
        doctorId: doctor.id,
        doctorName: doctor.name,
        question: questionForm.question,
      });

      message.success('问题提交成功');
      closeSubmitModal();
    }

    submitting.value = false;
  }, 500);
};

const formatTime = (time: string) => {
  return dayjs(time).format('YYYY-MM-DD HH:mm');
};
</script>

<style scoped>
.consultation {
  min-height: calc(100vh - 64px);
  padding-top: 64px;
  background: #f0f2f5;
}

.consultation-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 24px;
}

.auth-section {
  min-height: calc(100vh - 112px);
  display: flex;
  align-items: center;
  justify-content: center;
}

.auth-card {
  background: #fff;
  border-radius: 16px;
  padding: 48px;
  width: 100%;
  max-width: 450px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
}

.auth-card h1 {
  font-size: 28px;
  font-weight: 700;
  color: #333;
  text-align: center;
  margin-bottom: 8px;
}

.auth-card > p {
  font-size: 16px;
  color: #666;
  text-align: center;
  margin-bottom: 32px;
}

.patient-portal {
  background: #fff;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
}

.portal-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 32px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  color: #fff;
}

.patient-info {
  display: flex;
  align-items: center;
  gap: 16px;
}

.patient-icon-large {
  font-size: 48px;
  color: #fff;
}

.patient-info h1 {
  font-size: 24px;
  font-weight: 600;
  color: #fff;
  margin: 0 0 4px;
}

.patient-info p {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.85);
  margin: 0;
}

.selected-doctor {
  padding: 16px 24px;
  background: #f6ffed;
  border-bottom: 1px solid #e8e8e8;
}

.questions-section {
  padding: 24px;
}

.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 24px;
}

.section-header h2 {
  font-size: 20px;
  font-weight: 600;
  color: #333;
  margin: 0;
}

.my-questions-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.question-item {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
}

.question-title {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.question-detail {
  line-height: 1.6;
}

.question-text,
.answer-text {
  margin-bottom: 12px;
  color: #333;
}

.submit-time,
.answer-time {
  font-size: 12px;
  color: #999;
  margin: 0;
}

.answer-section {
  margin-top: 16px;
}

.doctor-option {
  display: flex;
  align-items: center;
  gap: 12px;
}

.doctor-option-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  object-fit: cover;
}

@media (max-width: 768px) {
  .auth-card {
    margin: 24px;
    padding: 32px 24px;
  }

  .portal-header {
    flex-direction: column;
    gap: 16px;
    align-items: flex-start;
  }

  .portal-actions {
    width: 100%;
  }
}
.auth-error {
  margin-top: 8px;
}
</style>
