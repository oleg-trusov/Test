# Supabase schema workflow

The connected Supabase account currently contains an unrelated project named `VYBE`. It must not be reused for this salon SaaS.

`schema/foundation.sql` is the reviewed working schema. Once a dedicated LUMÉA Supabase project is created, the workflow is:

1. validate the SQL against the dedicated project;
2. run security and performance advisors;
3. create the real migration with the Supabase CLI migration command;
4. commit the generated migration file;
5. generate TypeScript database types;
6. run RLS integration tests.

This separation prevents accidental DDL changes against an unrelated production project.
