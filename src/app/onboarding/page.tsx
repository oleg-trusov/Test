const steps = ['Business', 'Location', 'Hours', 'First service', 'First staff member'];

export default function OnboardingPage() {
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
          <p className="text-sm font-semibold text-[var(--primary)]">Step 1 of 5</p>
          <h2 className="mt-3 text-3xl font-semibold">Tell us about your salon</h2>
          <p className="mt-2 text-[var(--muted)]">The database transaction for this wizard is defined in the Foundation migration.</p>
          <div className="mt-8 grid gap-4 sm:grid-cols-2">
            {['Business name', 'Business type', 'Country', 'City', 'Phone', 'Timezone'].map((field) => (
              <label key={field} className="text-sm font-medium">
                {field}
                <input disabled className="mt-2 w-full rounded-2xl border border-[var(--border)] bg-[var(--surface-strong)] px-4 py-3 text-[var(--muted)]" placeholder="Foundation wiring in progress" />
              </label>
            ))}
          </div>
        </div>
      </section>
    </main>
  );
}
