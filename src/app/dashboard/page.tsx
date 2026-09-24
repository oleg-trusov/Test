import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

export const dynamic = 'force-dynamic';

export default async function DashboardPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/login');

  const { data: memberships } = await supabase
    .from('business_members')
    .select('business_id, role, businesses(name, currency, timezone)')
    .eq('user_id', user.id)
    .eq('status', 'active')
    .limit(10);

  if (!memberships?.length) redirect('/onboarding');

  return (
    <main className="min-h-screen p-4 md:p-8">
      <div className="mx-auto max-w-7xl">
        <header className="flex items-center justify-between rounded-[24px] border border-[var(--border)] bg-[var(--surface)] p-5">
          <div>
            <p className="text-sm text-[var(--muted)]">Overview</p>
            <h1 className="mt-1 text-2xl font-semibold">Business dashboard</h1>
          </div>
          <span className="rounded-xl bg-[var(--secondary)] px-3 py-2 text-sm font-semibold text-[var(--primary)]">
            {memberships[0]?.role}
          </span>
        </header>
        <section className="mt-4 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          {['Appointments today', 'Revenue today', 'New clients', 'No-shows'].map((label) => (
            <article key={label} className="rounded-[24px] border border-[var(--border)] bg-[var(--surface)] p-5">
              <p className="text-sm text-[var(--muted)]">{label}</p>
              <p className="mt-4 text-3xl font-semibold">—</p>
              <p className="mt-2 text-xs text-[var(--muted)]">Live data appears after the Foundation migrations are connected.</p>
            </article>
          ))}
        </section>
      </div>
    </main>
  );
}
