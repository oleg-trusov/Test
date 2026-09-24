import { redirect } from 'next/navigation';
import { OnboardingForm } from './onboarding-form';
import { createClient } from '@/lib/supabase/server';

const steps = ['Business', 'Location', 'Hours', 'First service', 'First staff member'];

export default async function OnboardingPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) redirect('/login');

  const { data: existing } = await supabase
    .from('business_members')
    .select('business_id')
    .eq('user_id', user.id)
    .eq('status', 'active')
    .limit(1);

  if (existing?.length) redirect('/dashboard');

  return (
    <main className="min-h-screen px-5 py-8">
      <section className="mx-auto grid max-w-5xl gap-6 lg:grid-cols-[300px_1fr]">
        <aside className="rounded-[28px] bg-[#171820] p-6 text-white">
          <p className="text-sm font-semibold text-white/60">Setup</p>
          <h1 className="mt-2 text-2xl font-semibold">Create your business</h1>
          <ol className="mt-8 space-y-3">
            {steps.map((step, index) => (
              <li key={step} className="flex items-center gap-3 rounded-2xl bg-white/6 p-3">
                <span className="grid size-8 place-items-center rounded-full bg-white/10 text-sm">{index + 1}</span>
                <span>{step}</span>
              </li>
            ))}
          </ol>
        </aside>
        <div className="rounded-[28px] border border-[var(--border)] bg-[var(--surface)] p-7 md:p-10">
          <OnboardingForm />
        </div>
      </section>
    </main>
  );
}
