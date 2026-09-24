'use client';

import { FormEvent, useState } from 'react';
import { createClient } from '@/lib/supabase/client';

type Notice = { kind: 'error' | 'success'; text: string } | null;

export default function LoginPage() {
  const [notice, setNotice] = useState<Notice>(null);
  const [pending, setPending] = useState(false);
  const [email, setEmail] = useState('');

  async function signIn(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setPending(true);
    setNotice(null);
    const form = new FormData(event.currentTarget);
    const password = String(form.get('password') ?? '');
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    setPending(false);
    if (error) {
      setNotice({ kind: 'error', text: 'Не удалось войти. Проверьте email и пароль.' });
      return;
    }
    window.location.href = '/dashboard';
  }

  async function signUp() {
    const passwordInput = document.querySelector<HTMLInputElement>('input[name="password"]');
    const password = passwordInput?.value ?? '';
    if (!email || password.length < 8) {
      setNotice({ kind: 'error', text: 'Для регистрации укажите email и пароль минимум из 8 символов.' });
      return;
    }

    setPending(true);
    setNotice(null);
    const supabase = createClient();
    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        emailRedirectTo: `${window.location.origin}/auth/callback?next=/onboarding`,
      },
    });
    setPending(false);

    setNotice(error
      ? { kind: 'error', text: 'Не удалось создать аккаунт.' }
      : { kind: 'success', text: 'Аккаунт создан. Если включено подтверждение email, проверьте почту.' });
  }

  async function resetPassword() {
    if (!email) {
      setNotice({ kind: 'error', text: 'Сначала укажите email.' });
      return;
    }

    setPending(true);
    setNotice(null);
    const supabase = createClient();
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/auth/callback?next=/auth/update-password`,
    });
    setPending(false);
    setNotice(error
      ? { kind: 'error', text: 'Не удалось отправить письмо восстановления.' }
      : { kind: 'success', text: 'Если аккаунт существует, письмо для восстановления отправлено.' });
  }

  async function signInWithGoogle() {
    setPending(true);
    setNotice(null);
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: `${window.location.origin}/auth/callback?next=/dashboard`,
      },
    });
    if (error) {
      setPending(false);
      setNotice({ kind: 'error', text: 'Не удалось запустить вход через Google.' });
    }
  }

  return (
    <main className="grid min-h-screen place-items-center px-5 py-10">
      <form onSubmit={signIn} className="w-full max-w-md rounded-[28px] border border-[var(--border)] bg-[var(--surface)] p-7 shadow-xl">
        <p className="text-sm font-semibold text-[var(--primary)]">LUMÉA Suite</p>
        <h1 className="mt-3 text-3xl font-semibold tracking-tight">Вход и регистрация</h1>
        <p className="mt-2 text-[var(--muted)]">Один аккаунт для клиента и управления бизнесом.</p>

        <label className="mt-7 block text-sm font-medium">Email</label>
        <input
          name="email"
          type="email"
          required
          autoComplete="email"
          value={email}
          onChange={(event) => setEmail(event.target.value)}
          className="mt-2 w-full rounded-2xl border border-[var(--border)] bg-transparent px-4 py-3 outline-none focus:border-[var(--primary)]"
        />

        <label className="mt-4 block text-sm font-medium">Пароль</label>
        <input
          name="password"
          type="password"
          required
          minLength={8}
          autoComplete="current-password"
          className="mt-2 w-full rounded-2xl border border-[var(--border)] bg-transparent px-4 py-3 outline-none focus:border-[var(--primary)]"
        />

        {notice ? (
          <p role="status" className={`mt-4 rounded-2xl px-4 py-3 text-sm ${notice.kind === 'error' ? 'bg-red-500/10 text-[var(--danger)]' : 'bg-emerald-500/10 text-[var(--success)]'}`}>
            {notice.text}
          </p>
        ) : null}

        <button disabled={pending} className="mt-6 w-full rounded-2xl bg-[var(--primary)] px-5 py-3 font-semibold text-white disabled:opacity-60">
          {pending ? 'Обрабатываем…' : 'Войти'}
        </button>
        <button type="button" disabled={pending} onClick={signUp} className="mt-3 w-full rounded-2xl border border-[var(--border)] px-5 py-3 font-semibold disabled:opacity-60">
          Создать аккаунт
        </button>
        <button type="button" disabled={pending} onClick={signInWithGoogle} className="mt-3 w-full rounded-2xl border border-[var(--border)] px-5 py-3 font-semibold disabled:opacity-60">
          Продолжить с Google
        </button>
        <button type="button" disabled={pending} onClick={resetPassword} className="mt-4 w-full text-sm font-medium text-[var(--primary)] disabled:opacity-60">
          Забыли пароль?
        </button>
      </form>
    </main>
  );
}
