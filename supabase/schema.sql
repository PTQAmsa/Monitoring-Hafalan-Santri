-- =====================================================================
-- Monitoring Hafalan Santri — skema database Supabase
-- Jalankan SELURUH isi file ini di dasbor Supabase: SQL Editor -> New query -> Run.
-- Aman dijalankan ulang (tidak menggandakan data).
-- =====================================================================

-- 1) TABEL ------------------------------------------------------------
create table if not exists public.pengaturan (
  id int primary key default 1 check (id = 1),
  nama_pesantren text not null default 'PTQ — Bagian Ketahfidhan',
  semester text not null default 'Semester 1 · Tahun Ajaran 2026/2027',
  mulai date not null default '2026-10-27',
  interval_hari int not null default 14,
  jumlah_periode int not null default 12,
  updated_at timestamptz not null default now()
);
create table if not exists public.santri (
  id text primary key,
  nama text not null,
  pp text not null check (pp in ('Pa','Pi')),
  kelas text not null,
  target_juz int,
  aktif boolean not null default true,
  updated_at timestamptz not null default now()
);
create table if not exists public.setoran (
  santri_id text not null references public.santri(id) on delete cascade,
  periode int not null,
  mode text not null check (mode in ('juz','surat')),
  juz int, kaca int, surat int, ayat int,
  catatan text,
  updated_at timestamptz not null default now(),
  updated_by text default (auth.jwt() ->> 'email'),
  primary key (santri_id, periode)
);
create index if not exists setoran_periode_idx on public.setoran(periode);

-- stempel waktu otomatis saat diubah
create or replace function public.set_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); if to_jsonb(new) ? 'updated_by' then new.updated_by = auth.jwt() ->> 'email'; end if; return new; end $$;
drop trigger if exists trg_pengaturan_upd on public.pengaturan; create trigger trg_pengaturan_upd before update on public.pengaturan for each row execute function public.set_updated_at();
drop trigger if exists trg_santri_upd on public.santri;         create trigger trg_santri_upd before update on public.santri for each row execute function public.set_updated_at();
drop trigger if exists trg_setoran_upd on public.setoran;       create trigger trg_setoran_upd before update on public.setoran for each row execute function public.set_updated_at();

-- 2) PERAN & ATURAN AKSES (Row Level Security) -------------------------
-- Peran diambil dari app_metadata.role pada akun: 'admin' (Ketahfidhan), 'Pa' (putra), 'Pi' (putri)
create or replace function public.app_role() returns text language sql stable as $$
  select coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '') $$;

alter table public.pengaturan enable row level security;
alter table public.santri enable row level security;
alter table public.setoran enable row level security;

drop policy if exists pengaturan_baca on public.pengaturan;
create policy pengaturan_baca on public.pengaturan for select to authenticated using (public.app_role() in ('admin','Pa','Pi'));
drop policy if exists pengaturan_ubah on public.pengaturan;
create policy pengaturan_ubah on public.pengaturan for all to authenticated using (public.app_role() = 'admin') with check (public.app_role() = 'admin');

drop policy if exists santri_akses on public.santri;
create policy santri_akses on public.santri for all to authenticated
  using (public.app_role() = 'admin' or pp = public.app_role())
  with check (public.app_role() = 'admin' or pp = public.app_role());

drop policy if exists setoran_akses on public.setoran;
create policy setoran_akses on public.setoran for all to authenticated
  using (exists (select 1 from public.santri s where s.id = santri_id and (public.app_role() = 'admin' or s.pp = public.app_role())))
  with check (exists (select 1 from public.santri s where s.id = santri_id and (public.app_role() = 'admin' or s.pp = public.app_role())));

-- 3) DATA AWAL -----------------------------------------------------------
insert into public.pengaturan (id) values (1) on conflict (id) do nothing;

insert into public.santri (id, nama, pp, kelas) values
  ('zvh5zsq', 'Maulana Rahman Yusuf', 'Pa', '1'),
  ('sgemcuw', 'Muhammad Ibrahim El-Mahir Jamil', 'Pa', '1'),
  ('mecz7nw', 'Muhammad Fadlan Muharram', 'Pa', '1'),
  ('bcwpx24', 'Muhammad Rifky Al-Faruk', 'Pa', '1'),
  ('ek5s40q', 'Muhammad Abdurrohman Nurruslan', 'Pa', '1'),
  ('5yae964', 'Nahdan Riandi', 'Pa', '1'),
  ('wce75us', 'Muhammad Risa Sunarya', 'Pa', '1'),
  ('26eyz3u', 'Muhammad Rayyan Aqil', 'Pa', '1'),
  ('f9sukc2', 'Uwais Al-Qorni', 'Pa', '1'),
  ('f6pxrh3', 'Tian Saputra', 'Pa', '1'),
  ('3pk4g6q', 'Danish Syakieb Hidayat', 'Pa', '1'),
  ('dbp5fc8', 'Muhammad Rizki Maulidan', 'Pa', '1'),
  ('i540mji', 'Muhammad Azka Asy Syuhada', 'Pa', '1'),
  ('e4f2bdy', 'Muhammad Ibad Syahmi', 'Pa', '1'),
  ('im355tf', 'Muhammad Fikri Al-Basit', 'Pa', '1'),
  ('rt5o1so', 'Achmad Syarif Hidayatullah', 'Pa', '1'),
  ('r7c7mmr', 'Muhammad Rafli Riswandi', 'Pa', '1'),
  ('ismgxwc', 'Muhammad Fadlan Fadillah', 'Pa', '1'),
  ('ooew04h', 'Gibran Omarovic Danendra', 'Pa', '1'),
  ('2cdosbh', 'Muhammad Hadi Al Gofar', 'Pa', '1'),
  ('scjw29m', 'Ahsan Ar Rasyid', 'Pa', '1'),
  ('u39tgks', 'Muhamad Nur Alamsyah', 'Pa', '1'),
  ('oveaynl', 'Azzriel Rayyan', 'Pa', '1'),
  ('dc1mcbl', 'Rafa Saputra', 'Pa', '2'),
  ('xcwjebj', 'Muhammad Alwi Al-Gifari', 'Pa', '2'),
  ('ple489n', 'Abdul Rasyid Fayyadh', 'Pa', '2'),
  ('ug7yoi1', 'Muhammad Alief Abdul Riziq', 'Pa', '2'),
  ('n26n2bv', 'Akhawira Alfarizky Saputra', 'Pa', '2'),
  ('bvzhu4g', 'Muhammad Dareel', 'Pa', '2'),
  ('bpp9cao', 'Jevski Fratama', 'Pa', '2'),
  ('d4zc1hk', 'Hildan Allyatar', 'Pa', '2'),
  ('hxqozjs', 'Ridho Surya Prasetyo', 'Pa', '2'),
  ('1rjz4wl', 'Andika Febriansyah', 'Pa', '2'),
  ('mla05n5', 'Anggi Ramadani', 'Pa', '2'),
  ('cmjket0', 'Muhammad Dzaka Al-Ghozy', 'Pa', '2'),
  ('q682bth', 'Nauval Haikal Pratama', 'Pa', '2'),
  ('8zzk5jq', 'Muhammad Wildan Ahsan', 'Pa', '2'),
  ('zh1p6vs', 'Muhamad Wildan Arifin', 'Pa', '3'),
  ('drol2wi', 'Rizki Purnama Ramadhani', 'Pa', '3'),
  ('fmbc535', 'Lukman Nur Hakim', 'Pa', '3'),
  ('vz3mkyn', 'Muhammad Zein Al-Ghozali', 'Pa', '3'),
  ('rdx309i', 'Virgo', 'Pa', '3'),
  ('6a92j23', 'Muhammad Akbar Pratama', 'Pa', '3'),
  ('qhexhx2', 'Muhamad Zidan Ramdani', 'Pa', '3'),
  ('5aq1izk', 'Muhammad Albi Salman Saputra', 'Pa', '3'),
  ('jcd6ie9', 'Fadhal Harith', 'Pa', 'Intensif'),
  ('5gdqd4v', 'Ridhotul Iffat', 'Pa', 'Intensif'),
  ('64v2586', 'Muhammad Shafar Azami', 'Pa', 'Intensif'),
  ('t4ps38j', 'Dede Ramdani', 'Pa', 'Intensif'),
  ('ko466rh', 'Zulqarnayn', 'Pa', 'Intensif'),
  ('7912fv3', 'Irpan Aidil Faizin', 'Pa', '5'),
  ('gqq0l1e', 'Muhammad Miftah Muhtaram', 'Pa', '5'),
  ('xqphpgm', 'Fayyadh Aghil', 'Pa', '5'),
  ('gpc1z2q', 'Muhammad Raffi Putra Lasmana', 'Pa', '5'),
  ('qspkrxb', 'Kanza Oktaviani Safari', 'Pi', '1'),
  ('cco9bew', 'Nur Assyifa Alifa', 'Pi', '1'),
  ('sdo4fgs', 'Syarah', 'Pi', '1'),
  ('d71exj3', 'Adilla Febriana Bilqis', 'Pi', '1'),
  ('3lkqprk', 'Aira Syhanaz Zaneta', 'Pi', '1'),
  ('alx0o5q', 'Azumy Nazwa Fayruz', 'Pi', '1'),
  ('6acsroo', 'Siti Sahila Maulida', 'Pi', '1'),
  ('in9ylnz', 'Resti Syabani', 'Pi', '1'),
  ('b72hk3w', 'Azka Sevania Putri', 'Pi', '2'),
  ('j84qczy', 'Siti Nur Sagita', 'Pi', '2'),
  ('3qzgko0', 'Syahla Sahila Rhamadani', 'Pi', '2'),
  ('zroq5t0', 'Nurmaulida Azzahra Mardanniel', 'Pi', '2'),
  ('zuzwibz', 'Nibras Naila', 'Pi', '2'),
  ('1dmcc6t', 'Naysila Aulia Apriani', 'Pi', '2'),
  ('gujp3vx', 'Syakira Agni Septia Idris', 'Pi', '2'),
  ('ggh01im', 'Raisa Shafwa Diwani Rahmi', 'Pi', '2'),
  ('1ppwtuo', 'Kaeira Rafika', 'Pi', '3'),
  ('5rq83sf', 'Sabrina Sheryl Prichilia', 'Pi', '3'),
  ('7hss6po', 'Kaisya Satika Humaira', 'Pi', '3'),
  ('yytomzf', 'Siti Raisyara Nadifa', 'Pi', '3'),
  ('vvji8bz', 'Siti Septiani', 'Pi', '3'),
  ('gmcii82', 'Dinda Syakira Rahmah', 'Pi', '3'),
  ('4mvp2p0', 'Safira Nur Azizah', 'Pi', '3'),
  ('0qqtk4s', 'Risnawati', 'Pi', '3'),
  ('hrdy2z0', 'Syarah Busrha', 'Pi', '3')
on conflict (id) do nothing;

-- 4) PERAN AKUN ---------------------------------------------------------
-- Buat dulu 3 akun di dasbor: Authentication -> Users -> Add user (centang "Auto Confirm User"):
--   ketahfidhan@ptqamsa.id   putra@ptqamsa.id   putri@ptqamsa.id
-- lalu jalankan bagian ini (boleh diulang):
update auth.users set raw_app_meta_data = coalesce(raw_app_meta_data,'{}'::jsonb) || '{"role":"admin"}'::jsonb, email_confirmed_at = coalesce(email_confirmed_at, now()) where email = 'ketahfidhan@ptqamsa.id';
update auth.users set raw_app_meta_data = coalesce(raw_app_meta_data,'{}'::jsonb) || '{"role":"Pa"}'::jsonb,    email_confirmed_at = coalesce(email_confirmed_at, now()) where email = 'putra@ptqamsa.id';
update auth.users set raw_app_meta_data = coalesce(raw_app_meta_data,'{}'::jsonb) || '{"role":"Pi"}'::jsonb,    email_confirmed_at = coalesce(email_confirmed_at, now()) where email = 'putri@ptqamsa.id';

-- Pemeriksaan: harus tampil 3 baris dengan kolom role terisi
select email, raw_app_meta_data ->> 'role' as role, email_confirmed_at is not null as terkonfirmasi from auth.users where email like '%@ptqamsa.id' order by email;
