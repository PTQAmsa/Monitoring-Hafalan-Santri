-- =====================================================================
-- Akun PEMBACA (lihat saja) untuk guru di luar bagian ketahfidhan
-- Jalankan SETELAH schema.sql. Aman diulang.
--
-- Langkah 1 (dasbor): Authentication -> Users -> Add user (centang "Auto Confirm User"):
--   lihat.ketahfidhan@ptqamsa.id   (PIN pembaca ketahfidhan: lihat putra & putri)
--   lihat.putra@ptqamsa.id         (PIN pembaca putra)
--   lihat.putri@ptqamsa.id         (PIN pembaca putri)
-- Langkah 2: jalankan seluruh isi file ini di SQL Editor.
-- =====================================================================

-- Peran pembaca memakai akhiran "_r": admin_r, Pa_r, Pi_r
create or replace function public.app_base() returns text language sql stable as $$
  select regexp_replace(coalesce(auth.jwt() -> 'app_metadata' ->> 'role', ''), '_r$', '') $$;
create or replace function public.app_can_write() returns boolean language sql stable as $$
  select coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '') in ('admin','Pa','Pi') $$;

-- ---- pengaturan: semua peran boleh baca; hanya admin penulis yang boleh ubah
drop policy if exists pengaturan_baca on public.pengaturan;
drop policy if exists pengaturan_ubah on public.pengaturan;
create policy pengaturan_baca on public.pengaturan for select to authenticated
  using (public.app_base() in ('admin','Pa','Pi'));
create policy pengaturan_tulis on public.pengaturan for all to authenticated
  using (public.app_base() = 'admin' and public.app_can_write())
  with check (public.app_base() = 'admin' and public.app_can_write());

-- ---- santri: baca sesuai marhalah; tulis hanya akun penulis
drop policy if exists santri_akses on public.santri;
drop policy if exists santri_baca on public.santri;
drop policy if exists santri_tulis on public.santri;
create policy santri_baca on public.santri for select to authenticated
  using (public.app_base() = 'admin' or pp = public.app_base());
create policy santri_tulis on public.santri for all to authenticated
  using (public.app_can_write() and (public.app_base() = 'admin' or pp = public.app_base()))
  with check (public.app_can_write() and (public.app_base() = 'admin' or pp = public.app_base()));

-- ---- setoran: sama seperti santri
drop policy if exists setoran_akses on public.setoran;
drop policy if exists setoran_baca on public.setoran;
drop policy if exists setoran_tulis on public.setoran;
create policy setoran_baca on public.setoran for select to authenticated
  using (exists (select 1 from public.santri s where s.id = santri_id and (public.app_base() = 'admin' or s.pp = public.app_base())));
create policy setoran_tulis on public.setoran for all to authenticated
  using (public.app_can_write() and exists (select 1 from public.santri s where s.id = santri_id and (public.app_base() = 'admin' or s.pp = public.app_base())))
  with check (public.app_can_write() and exists (select 1 from public.santri s where s.id = santri_id and (public.app_base() = 'admin' or s.pp = public.app_base())));

-- ---- beri peran ke akun pembaca
update auth.users set raw_app_meta_data = coalesce(raw_app_meta_data,'{}'::jsonb) || '{"role":"admin_r"}'::jsonb, email_confirmed_at = coalesce(email_confirmed_at, now()) where email = 'lihat.ketahfidhan@ptqamsa.id';
update auth.users set raw_app_meta_data = coalesce(raw_app_meta_data,'{}'::jsonb) || '{"role":"Pa_r"}'::jsonb,    email_confirmed_at = coalesce(email_confirmed_at, now()) where email = 'lihat.putra@ptqamsa.id';
update auth.users set raw_app_meta_data = coalesce(raw_app_meta_data,'{}'::jsonb) || '{"role":"Pi_r"}'::jsonb,    email_confirmed_at = coalesce(email_confirmed_at, now()) where email = 'lihat.putri@ptqamsa.id';

-- Pemeriksaan: harus tampil 6 baris (3 penulis + 3 pembaca) dengan kolom role terisi
select email, raw_app_meta_data ->> 'role' as role from auth.users where email like '%@ptqamsa.id' order by email;
