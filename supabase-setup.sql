create table if not exists public.stock_opname_state (
  id text primary key check (id = 'stock-opname-team'),
  data jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid not null references auth.users(id)
);

alter table public.stock_opname_state enable row level security;

revoke all on table public.stock_opname_state from anon;
revoke all on table public.stock_opname_state from authenticated;
grant select, insert, update on table public.stock_opname_state to authenticated;

drop policy if exists "Team members can read shared stock opname state" on public.stock_opname_state;
create policy "Team members can read shared stock opname state"
  on public.stock_opname_state for select to authenticated
  using (auth.uid() is not null);

drop policy if exists "Team members can create shared stock opname state" on public.stock_opname_state;
create policy "Team members can create shared stock opname state"
  on public.stock_opname_state for insert to authenticated
  with check (auth.uid() = updated_by);

drop policy if exists "Team members can update shared stock opname state" on public.stock_opname_state;
create policy "Team members can update shared stock opname state"
  on public.stock_opname_state for update to authenticated
  using (auth.uid() is not null)
  with check (auth.uid() = updated_by);

create or replace function public.set_stock_opname_state_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_stock_opname_state_updated_at on public.stock_opname_state;
create trigger set_stock_opname_state_updated_at
  before update on public.stock_opname_state
  for each row execute function public.set_stock_opname_state_updated_at();
