'use client';

import { FormEvent, useState } from 'react';
import { createClient } from '@/lib/supabase/client';

export default function UpdatePasswordPage() {
  const [message, setMessage] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  async function updatePassword(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setPending(true);
    setMessage(null);
    const form = new FormData(event.currentTarget);
    const password = String(form.get('password') ?? '');
    const supabase = createClient();
    const { error } = await supabase.auth.updateUser({ password });
    setPending(false);

    if (error) {
      setMessage('Не удалось изменить пароль.');
      return;
    }

    window.location.href = '/dashboard';
  }

  return (
    <main className="grid min-h-screen place-items-center px-5 py-10">
      <form onSubmit={updatePassword} className="w-full max-w-md rounded-[28px] border border-[var(--border)] bg-[var(--surface)] p-7 shadow-xl">
        <p className="text-sm font-semibold text-[var(--primary)]">LUMÉA Suite</p>
        <h1 className="mt-3 text-3xl font-semibold">Новый пароль</h1>
        <label className="mt-7 block text-sm font-medium">
          Новый пароль
          <input name="password" type="password" minLength={8} required autoComplete="new-password" className="mt-2 w-full rounded-2xl border border-[var(--border)] bg-transparent px-4 py-3 outline-none focus:border-[var(--primary)]" />
        </label>
        {message ? <p className="mt-4 text-sm text-[var(--danger)]">{message}</p> : null}
        <button disabled={pending} className="mt-6 w-full rounded-2xl bg-[var(--primary)] px-5 py-3 font-semibold text-white disabled:opacity-60">
          {pending ? 'Сохраняем…' : 'Сохранить пароль'}
        </button>
      </form>
    </main>
  );
}
