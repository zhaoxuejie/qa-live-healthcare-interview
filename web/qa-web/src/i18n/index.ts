import { createI18n } from 'vue-i18n';
import zhCN from '../locales/zh-CN';
import enUS from '../locales/en-US';

export const SUPPORTED_LOCALES = ['zh-CN', 'en-US'] as const;
export type AppLocale = (typeof SUPPORTED_LOCALES)[number];

const LOCALE_STORAGE_KEY = 'qa_locale';
const DEFAULT_LOCALE: AppLocale = 'zh-CN';

/** 读取用户上次选择的语言；不可用或非法值时回退中文。 */
function readStoredLocale(): AppLocale {
  try {
    const stored = localStorage.getItem(LOCALE_STORAGE_KEY);
    if (stored === 'zh-CN' || stored === 'en-US') {
      return stored;
    }
  } catch {
    // localStorage 被禁用时忽略，使用默认语言
  }
  return DEFAULT_LOCALE;
}

export const i18n = createI18n({
  legacy: false,
  globalInjection: true,
  locale: readStoredLocale(),
  fallbackLocale: DEFAULT_LOCALE,
  messages: {
    'zh-CN': zhCN,
    'en-US': enUS,
  },
});

/** 切换语言：同时更新 i18n、localStorage 与 <html lang>。 */
export function setLocale(locale: AppLocale): void {
  i18n.global.locale.value = locale;
  try {
    localStorage.setItem(LOCALE_STORAGE_KEY, locale);
  } catch {
    // 存储失败不影响当前会话切换
  }
  document.documentElement.lang = locale;
}

document.documentElement.lang = i18n.global.locale.value;
