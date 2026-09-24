'use client';

import { useActionState } from 'react';
import { createBusinessAction, type OnboardingState } from './actions';

const initialState: OnboardingState = { error: null };

export function OnboardingForm() {
  const [state, action, pending] = useActionState(createBusinessAction, initialState);

  return (
    <form action={action} className="space-y-6">
      <div>
        <p className="text-sm font-semibold text-[var(--primary)]">Foundation onboarding</p>
        <h2 className="mt-3 text-3xl font-semibold">Создайте первый филиал</h2>
        <p className="mt-2 text-[var(--muted)]">
          Эти данные сохраняются одной серверной операцией, без полу-созданного салона при ошибке.
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Название бизнеса" name="businessName" placeholder="LUMÉA Hair Studio" />
        <label className="text-sm font-medium">
          Тип бизнеса
          <select name="businessType" required defaultValue="hair_salon" className="mt-2 w-full rounded-2xl border border-[var(--border)] bg-[var(--surface)] px-4 py-3">
            <option value="hair_salon">Парикмахерская</option>
            <option value="barbershop">Барбершоп</option>
            <option value="nail_studio">Nail studio</option>
            <option value="massage">Массаж</option>
            <option value="beauty_salon">Beauty salon</option>
            <option value="other">Другое</option>
          </select>
        </label>
        <Field label="Страна (ISO)" name="country" defaultValue="CZ" maxLength={2} />
        <Field label="Город" name="city" defaultValue="Praha" />
        <Field label="Адрес" name="address" placeholder="Praha 10, Strašnice" />
        <Field label="Телефон" name="phone" type="tel" placeholder="+420 ..." />
        <label className="text-sm font-medium">
          Timezone
          <select name="timezone" required defaultValue="Europe/Prague" className="mt-2 w-full rounded-2xl border border-[var(--border)] bg-[var(--surface)] px-4 py-3">
            <option value="Europe/Prague">Europe/Prague</option>
            <option value="Europe/Kyiv">Europe/Kyiv</option>
            <option value="Europe/Warsaw">Europe/Warsaw</option>
            <option value="Europe/London">Europe/London</option>
          </select>
        </label>
        <label className="text-sm font-medium">
          Валюта
          <select name="currency" required defaultValue="CZK" className="mt-2 w-full rounded-2xl border border-[var(--border)] bg-[var(--surface)] px-4 py-3">
            {['CZK', 'EUR', 'USD', 'UAH', 'PLN', 'GBP'].map((currency) => (
              <option key={currency} value={currency}>{currency}</option>
            ))}
          </select>
        </label>
      </div>

      {state.error ? (
        <div role="alert" className="rounded-2xl bg-red-500/10 px-4 py-3 text-sm text-[var(--danger)]">
          {state.error}
        </div>
      ) : null}

      <button disabled={pending} className="w-full rounded-2xl bg-[var(--primary)] px-5 py-3.5 font-semibold text-white transition hover:bg-[var(--primary-strong)] disabled:cursor-not-allowed disabled:opacity-60 sm:w-auto">
        {pending ? 'Создаём…' : 'Создать бизнес'}
      </button>
    </form>
  );
}

type FieldProps = {
  label: string;
  name: string;
  placeholder?: string;
  defaultValue?: string;
  type?: string;
  maxLength?: number;
};

function Field({ label, name, placeholder, defaultValue, type = 'text', maxLength }: FieldProps) {
  return (
    <label className="text-sm font-medium">
      {label}
      <input
        name={name}
        type={type}
        required
        placeholder={placeholder}
        defaultValue={defaultValue}
        maxLength={maxLength}
        className="mt-2 w-full rounded-2xl border border-[var(--border)] bg-transparent px-4 py-3 outline-none transition focus:border-[var(--primary)]"
      />
    </label>
  );
}
