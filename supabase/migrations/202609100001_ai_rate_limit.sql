create table if not exists public.ai_request_limits (
  user_id uuid primary key references auth.users(id) on delete cascade,
  window_start timestamptz not null,
  request_count integer not null
);
alter table public.ai_request_limits enable row level security;
revoke all on public.ai_request_limits from anon, authenticated;

create or replace function public.consume_ai_request()
returns boolean language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  used integer;
begin
  if uid is null then return false; end if;
  insert into public.ai_request_limits as limits (user_id, window_start, request_count)
  values (uid, now(), 1)
  on conflict (user_id) do update set
    window_start = case when limits.window_start < now() - interval '1 hour'
      then now() else limits.window_start end,
    request_count = case when limits.window_start < now() - interval '1 hour'
      then 1 else limits.request_count + 1 end
  returning request_count into used;
  return used <= 30;
end;
$$;
revoke all on function public.consume_ai_request() from public, anon;
grant execute on function public.consume_ai_request() to authenticated;
