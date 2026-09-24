'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { onboardingSchema } from '@/lib/validation/onboarding';

export type OnboardingState = {
  error: string | null;
};

function slugify(value: string) {
  return value
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 48);
}

export async function createBusinessAction(
  _previousState: OnboardingState,
  formData: FormData,
): Promise<OnboardingState> {
  const parsed = onboardingSchema.safeParse({
    businessName: formData.get('businessName'),
    businessType: formData.get('businessType'),
    country: formData.get('country'),
    city: formData.get('city'),
    address: formData.get('address'),
    phone: formData.get('phone'),
    timezone: formData.get('timezone'),
    currency: formData.get('currency'),
  });

  if (!parsed.success) {
    return { error: 'Проверьте обязательные поля и попробуйте ещё раз.' };
  }

  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return { error: 'Сессия закончилась. Войдите в аккаунт заново.' };
  }

  const slugBase = slugify(parsed.data.businessName) || 'business';
  const suffix = crypto.randomUUID().slice(0, 6);

  const { error } = await supabase.rpc('create_business_onboarding', {
    p_name: parsed.data.businessName,
    p_slug: `${slugBase}-${suffix}`,
    p_category: parsed.data.businessType,
    p_country: parsed.data.country,
    p_city: parsed.data.city,
    p_address: parsed.data.address,
    p_phone: parsed.data.phone,
    p_timezone: parsed.data.timezone,
    p_currency: parsed.data.currency,
  });

  if (error) {
    console.error('Business onboarding failed', { code: error.code });
    return { error: 'Не удалось создать бизнес. Данные не были сохранены.' };
  }

  redirect('/dashboard');
}
