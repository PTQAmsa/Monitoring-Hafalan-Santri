-- =====================================================================
-- Ketahfidhan dapat mengganti PIN akun lain dari dalam aplikasi
-- Jalankan SETELAH schema.sql dan pembaca.sql. Aman diulang.
-- =====================================================================
create extension if not exists pgcrypto with schema extensions;

create or replace function public.set_pin(target_email text, pin_baru text)
returns text
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
begin
  -- hanya akun penulis Ketahfidhan (bukan pembaca)
  if coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '') <> 'admin' then
    raise exception 'Hanya Ketahfidhan yang boleh mengganti PIN akun lain.';
  end if;
  if target_email not in ('putra@ptqamsa.id','putri@ptqamsa.id',
                          'lihat.ketahfidhan@ptqamsa.id','lihat.putra@ptqamsa.id','lihat.putri@ptqamsa.id') then
    raise exception 'Akun tidak dikenal.';
  end if;
  if pin_baru !~ '^[0-9]{6,12}$' then
    raise exception 'PIN harus 6 sampai 12 angka.';
  end if;
  update auth.users
     set encrypted_password = extensions.crypt(pin_baru, extensions.gen_salt('bf')),
         updated_at = now()
   where email = target_email;
  if not found then
    raise exception 'Akun % belum dibuat di dasbor.', target_email;
  end if;
  return 'ok';
end
$$;

revoke all on function public.set_pin(text, text) from public, anon;
grant execute on function public.set_pin(text, text) to authenticated;
