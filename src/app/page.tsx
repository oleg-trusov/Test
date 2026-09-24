import Link from 'next/link';

const cards = [
  ['Calendar', 'Day, week and agenda views built around staff availability.'],
  ['Booking', 'Public booking with real availability and server-side conflict protection.'],
  ['CRM', 'Tenant-isolated client history, notes, visits and spending.'],
];

export default function HomePage() {
  return (
    <main className="min-h-screen px-5 py-8 md:px-10 lg:px-16">
      <section className="mx-auto max-w-6xl overflow-hidden rounded-[32px] border border-[var(--border)] bg-[var(--surface)] shadow-[0_30px_90px_rgba(20,20,40,0.08)]">
        <div className="grid gap-10 p-7 md:p-12 lg:grid-cols-[1.15fr_.85fr] lg:p-16">
          <div>
            <span className="inline-flex rounded-full bg-[var(--secondary)] px-4 py-2 text-sm font-semibold text-[var(--primary)]">
              Salon operations, without the clutter
            </span>
            <h1 className="mt-6 max-w-3xl text-4xl font-semibold tracking-[-0.04em] md:text-6xl">
              Booking, calendar and CRM in one premium workspace.
            </h1>
            <p className="mt-5 max-w-2xl text-lg leading-8 text-[var(--muted)]">
              Multi-tenant by design, mobile-first for daily salon work, and backed by PostgreSQL and Row Level Security.
            </p>
            <div className="mt-8 flex flex-wrap gap-3">
              <Link className="rounded-2xl bg-[var(--primary)] px-5 py-3 font-semibold text-white transition hover:bg-[var(--primary-strong)]" href="/onboarding">
                Create business
              </Link>
              <Link className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] px-5 py-3 font-semibold" href="/login">
                Sign in
              </Link>
            </div>
          </div>
          <div className="rounded-[26px] bg-[linear-gradient(145deg,#151620,#27223a)] p-5 text-white">
            <div className="flex items-center justify-between text-sm text-white/65">
              <span>LUMÉA Hair Studio</span>
              <span>Praha 10</span>
            </div>
            <div className="mt-8 text-5xl font-semibold">12</div>
            <div className="mt-1 text-white/65">appointments today</div>
            <div className="mt-8 space-y-3">
              {['09:00 Anna · Women cut', '10:00 Marek · Men cut', '11:30 Sofia · Women cut'].map((item) => (
                <div key={item} className="rounded-2xl border border-white/10 bg-white/8 p-4">{item}</div>
              ))}
            </div>
          </div>
        </div>
        <div className="grid gap-px border-t border-[var(--border)] bg-[var(--border)] md:grid-cols-3">
          {cards.map(([title, body]) => (
            <article key={title} className="bg-[var(--surface)] p-7">
              <h2 className="text-lg font-semibold">{title}</h2>
              <p className="mt-2 leading-7 text-[var(--muted)]">{body}</p>
            </article>
          ))}
        </div>
      </section>
    </main>
  );
}
