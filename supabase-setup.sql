create table if not exists public.stock_opname_state (
  id text primary key check (id = 'stock-opname-team'),
  data jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid not null references auth.users(id)
);

create table if not exists public.stock_opname_usernames (
  username text primary key check (username = lower(username) and username ~ '^[a-z0-9][a-z0-9._-]{2,29}$'),
  email text not null unique check (email = lower(email)),
  created_at timestamptz not null default now()
);

alter table public.stock_opname_state enable row level security;
alter table public.stock_opname_usernames enable row level security;

revoke all on table public.stock_opname_state from anon;
revoke all on table public.stock_opname_state from authenticated;
grant select, insert, update on table public.stock_opname_state to authenticated;
revoke all on table public.stock_opname_usernames from anon;
revoke all on table public.stock_opname_usernames from authenticated;
grant select on table public.stock_opname_usernames to service_role;

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

create or replace function public.guard_stock_opname_workspace_membership()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  old_workspace_ids text[];
  new_workspace_ids text[];
begin
  select array_agg(workspace ->> 'id' order by workspace ->> 'id')
    into old_workspace_ids
    from jsonb_array_elements(coalesce(old.data -> 'workspaces', '[]'::jsonb)) as workspace;
  select array_agg(workspace ->> 'id' order by workspace ->> 'id')
    into new_workspace_ids
    from jsonb_array_elements(coalesce(new.data -> 'workspaces', '[]'::jsonb)) as workspace;

  if old_workspace_ids is distinct from new_workspace_ids
    and (
      coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '') <> 'super_admin'
      or coalesce(auth.jwt() -> 'app_metadata' ->> 'owner_username', '') <> 'indra'
    ) then
    raise exception 'Only the workspace super admin can add or remove workspaces.'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

drop trigger if exists guard_stock_opname_workspace_membership on public.stock_opname_state;
create trigger guard_stock_opname_workspace_membership
  before update on public.stock_opname_state
  for each row execute function public.guard_stock_opname_workspace_membership();
