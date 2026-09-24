'use client';

import { FormEvent, useState } from 'react';
import { createClient } from '@/lib/supabase/client';

export default function LoginPage() {
  const [message, setMessage] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  async function signIn(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setPending(true);
    setMessage(null);
    const form = new FormData(event.currentTarget);
    const email = String(form.get('email') ?? '');
    const password = String(form.get('password') ?? '');
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    setPending(false);
    if (error) {
      setMessage('Не удалось войти. Проверьте email и пароль.');
      return;
    }
    window.location.href = '/dashboard';
  }

  return (
    <main className="grid min-h-screen place-items-center px-5 py-10">
      <form onSubmit={signIn} className="w-full max-w-md rounded-[28px] border border-[var(--border)] bg-[var(--surface)] p-7 shadow-xl">
        <p className="text-sm font-semibold text-[var(--primary)]">LUMÉA Suite</p>
        <h1 className="mt-3 text-3xl font-semibold tracking-tight">Вход</h1>
        <p className="mt-2 text-[var(--muted)]">Войдите в кабинет бизнеса.</p>
        <label className="mt-7 block text-sm font-medium">Email</label>
        <input name="email" type="email" required autoComplete="email" className="mt-2 w-full rounded-2xl border border-[var(--border)] bg-transparent px-4 py-3 outline-none focus:border-[var(--primary)]" />
        <label className="mt-4 block text-sm font-medium">Пароль</label>
        <input name="password" type="password" required autoComplete="current-password" className="mt-2 w-full rounded-2xl border border-[var(--border)] bg-transparent px-4 py-3 outline-none focus:border-[var(--primary)]" />
        {message ? <p className="mt-4 text-sm text-[var(--danger)]">{message}</p> : null}
        <button disabled={pending} className="mt-6 w-full rounded-2xl bg-[var(--primary)] px-5 py-3 font-semibold text-white disabled:opacity-60">
          {pending ? 'Входим…' : 'Войти'}
        </button>
      </form>
    </main>
  );
}
