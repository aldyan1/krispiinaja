-- ====================================================================
-- SUPABASE DATABASE CODE - KrispiinAja POS
-- ====================================================================
-- Nama Proyek  : KrispiinAja POS
-- Tagline      : "Kasir Cepat, Bisnis Hebat"
-- Database     : Supabase (PostgreSQL)
-- Dibuat       : 2026-07-04
-- Deskripsi    : Script lengkap untuk setup database KrispiinAja POS.
--                Jalankan script ini di Supabase SQL Editor untuk
--                membuat semua tabel, relasi, trigger, RPC functions,
--                RLS policies, dan storage bucket.
-- ====================================================================


-- ====================================================================
-- BAGIAN 0: HAPUS TABEL LAMA (JIKA ADA)
-- ====================================================================
-- PENTING: Jalankan bagian ini untuk menghapus tabel dari schema lama
-- (misalnya dari Breaking News) agar tabel baru bisa dibuat dengan benar.
-- Urutan DROP harus dari tabel child ke parent (karena foreign key).
-- ====================================================================

-- Hapus tabel Breaking News (jika ada dari project sebelumnya)
DROP TABLE IF EXISTS public.hero_banner CASCADE;
DROP TABLE IF EXISTS public.notifikasi CASCADE;
DROP TABLE IF EXISTS public.berita_disimpan CASCADE;
DROP TABLE IF EXISTS public.berita CASCADE;
DROP TABLE IF EXISTS public.kategori CASCADE;

-- Hapus tabel KrispiinAja lama (jika ada, untuk fresh install)
DROP TABLE IF EXISTS public.pengeluaran CASCADE;
DROP TABLE IF EXISTS public.detail_transaksi CASCADE;
DROP TABLE IF EXISTS public.transaksi CASCADE;
DROP TABLE IF EXISTS public.shift_kasir CASCADE;
DROP TABLE IF EXISTS public.produk CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TABLE IF EXISTS public.toko CASCADE;

-- Hapus trigger lama
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_pengeluaran_created ON public.pengeluaran;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_pengeluaran() CASCADE;
DROP FUNCTION IF EXISTS public.admin_create_cashier(TEXT, TEXT, TEXT, UUID) CASCADE;


-- ====================================================================
-- BAGIAN 1: MEMBUAT TABEL-TABEL (CREATE TABLES)
-- ====================================================================

-- -----------------------------------------
-- 1.1 Tabel Toko
-- Menyimpan daftar toko/cabang milik admin
-- -----------------------------------------
CREATE TABLE public.toko (
    id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nama_toko       TEXT NOT NULL,
    lokasi          TEXT NOT NULL,
    nomor_telepon   TEXT NOT NULL,
    status_aktif    BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------
-- 1.2 Tabel Profiles
-- Menyimpan profil pengguna (admin & kasir),
-- terhubung ke auth.users dan tabel toko
-- -----------------------------------------
CREATE TABLE public.profiles (
    id              UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    nama_lengkap    TEXT NOT NULL,
    email           TEXT NOT NULL,
    role            TEXT NOT NULL DEFAULT 'admin',    -- 'admin' | 'kasir'
    toko_id         UUID REFERENCES public.toko(id) ON DELETE SET NULL,
    status          TEXT NOT NULL DEFAULT 'aktif',    -- 'aktif' | 'nonaktif'
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------
-- 1.3 Tabel Produk
-- Menyimpan daftar produk per toko
-- Tanpa stok (menu dibuat saat dipesan)
-- -----------------------------------------
CREATE TABLE public.produk (
    id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    toko_id         UUID NOT NULL REFERENCES public.toko(id) ON DELETE CASCADE,
    nama_produk     TEXT NOT NULL,
    harga_jual      NUMERIC NOT NULL,
    deskripsi       TEXT,
    foto_url        TEXT,
    status          TEXT NOT NULL DEFAULT 'tersedia',  -- 'tersedia' | 'habis'
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------
-- 1.4 Tabel Shift Kasir (Uang Laci / Cash Drawer)
-- Mencatat buka/tutup shift dan modal kas
-- -----------------------------------------
CREATE TABLE public.shift_kasir (
    id                      UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    kasir_id                UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    toko_id                 UUID NOT NULL REFERENCES public.toko(id) ON DELETE CASCADE,
    waktu_buka              TIMESTAMPTZ DEFAULT NOW(),
    waktu_tutup             TIMESTAMPTZ,
    modal_awal              NUMERIC NOT NULL DEFAULT 0,
    total_penjualan_tunai   NUMERIC NOT NULL DEFAULT 0,
    total_pengeluaran       NUMERIC NOT NULL DEFAULT 0,
    total_seharusnya        NUMERIC NOT NULL DEFAULT 0,
    uang_fisik              NUMERIC,
    selisih                 NUMERIC,
    status                  TEXT NOT NULL DEFAULT 'buka',  -- 'buka' | 'tutup'
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------
-- 1.5 Tabel Transaksi
-- Menyimpan header transaksi penjualan
-- -----------------------------------------
CREATE TABLE public.transaksi (
    id                  UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nomor_transaksi     TEXT NOT NULL UNIQUE,
    shift_id            UUID REFERENCES public.shift_kasir(id) ON DELETE SET NULL,
    kasir_id            UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    toko_id             UUID NOT NULL REFERENCES public.toko(id) ON DELETE CASCADE,
    metode_pembayaran   TEXT NOT NULL DEFAULT 'tunai',  -- 'tunai' | 'transfer' | 'qris'
    total               NUMERIC NOT NULL DEFAULT 0,
    jumlah_bayar        NUMERIC NOT NULL DEFAULT 0,
    kembalian           NUMERIC NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------
-- 1.6 Tabel Detail Transaksi
-- Menyimpan detail item per transaksi
-- -----------------------------------------
CREATE TABLE public.detail_transaksi (
    id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    transaksi_id    UUID NOT NULL REFERENCES public.transaksi(id) ON DELETE CASCADE,
    produk_id       UUID REFERENCES public.produk(id) ON DELETE SET NULL,
    nama_produk     TEXT NOT NULL,
    harga_produk    NUMERIC NOT NULL,
    qty             INT NOT NULL DEFAULT 1,
    subtotal        NUMERIC NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------
-- 1.7 Tabel Pengeluaran
-- Menyimpan catatan pengeluaran kasir selama shift
-- -----------------------------------------
CREATE TABLE public.pengeluaran (
    id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    shift_id    UUID NOT NULL REFERENCES public.shift_kasir(id) ON DELETE CASCADE,
    toko_id     UUID NOT NULL REFERENCES public.toko(id) ON DELETE CASCADE,
    kasir_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    nominal     NUMERIC NOT NULL DEFAULT 0,
    deskripsi   TEXT NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);


-- ====================================================================
-- BAGIAN 2: TRIGGER & FUNCTION
-- ====================================================================

-- -----------------------------------------
-- 2.1 Auto-create profile saat user baru signup
-- Function ini dipanggil otomatis setelah INSERT di auth.users
-- Membuat profile dengan role 'admin' (default untuk owner signup)
-- -----------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, nama_lengkap, email, role, status)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'nama_lengkap', split_part(NEW.email, '@', 1)),
        NEW.email,
        'admin',
        'aktif'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Hapus trigger lama jika ada, lalu buat ulang
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- -----------------------------------------
-- 2.2 Auto-update shift_kasir saat ada pengeluaran baru
-- Function ini dipanggil otomatis setelah INSERT di public.pengeluaran
-- -----------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_pengeluaran()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.shift_kasir
    SET total_pengeluaran = total_pengeluaran + NEW.nominal,
        total_seharusnya = total_seharusnya - NEW.nominal
    WHERE id = NEW.shift_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_pengeluaran_created ON public.pengeluaran;
CREATE TRIGGER on_pengeluaran_created
    AFTER INSERT ON public.pengeluaran
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_pengeluaran();


-- ====================================================================
-- BAGIAN 3: RPC FUNCTION - Admin Create Cashier
-- ====================================================================
-- Function ini dipanggil via supabase.rpc('admin_create_cashier', ...)
-- untuk membuat akun kasir baru (signup + profile insert)
-- Menggunakan supabase_auth_admin agar bisa create user dari server-side
-- -----------------------------------------

CREATE OR REPLACE FUNCTION public.admin_create_cashier(
    cashier_email TEXT,
    cashier_password TEXT,
    cashier_nama TEXT,
    cashier_toko_id UUID
)
RETURNS JSON AS $$
DECLARE
    new_user_id UUID;
    encrypted_pw TEXT;
BEGIN
    -- 1. Cek apakah email sudah terdaftar
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = cashier_email) THEN
        RETURN json_build_object('success', false, 'error', 'Email sudah terdaftar');
    END IF;

    -- 2. Aktifkan extension pgcrypto jika belum ada
    CREATE EXTENSION IF NOT EXISTS pgcrypto;
    encrypted_pw := crypt(cashier_password, gen_salt('bf'));

    -- 3. Insert ke auth.users
    INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at,
        confirmation_token,
        email_change,
        email_change_token_new,
        recovery_token
    ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        gen_random_uuid(),
        'authenticated',
        'authenticated',
        cashier_email,
        encrypted_pw,
        now(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        json_build_object('nama_lengkap', cashier_nama)::jsonb,
        now(),
        now(),
        '',
        '',
        '',
        ''
    ) RETURNING id INTO new_user_id;

    -- 4. Update profiles (yang dibuat otomatis oleh trigger handle_new_user)
    UPDATE public.profiles
    SET role = 'kasir',
        toko_id = cashier_toko_id
    WHERE id = new_user_id;

    RETURN json_build_object('success', true, 'message', 'Kasir berhasil dibuat');
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ====================================================================
-- BAGIAN 4: ROW LEVEL SECURITY (RLS) POLICIES
-- ====================================================================

-- -----------------------------------------
-- 4.0 Aktifkan RLS pada semua tabel
-- -----------------------------------------
ALTER TABLE public.toko              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produk            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shift_kasir       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transaksi         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.detail_transaksi  ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------
-- 4.1 Policies untuk tabel TOKO
-- - Authenticated users bisa melihat semua toko
-- - Authenticated users bisa CRUD (admin check di app level)
-- -----------------------------------------
DROP POLICY IF EXISTS "Allow authenticated read on toko" ON public.toko;
DROP POLICY IF EXISTS "Allow authenticated all on toko" ON public.toko;

CREATE POLICY "Allow authenticated read on toko"
    ON public.toko FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Allow authenticated all on toko"
    ON public.toko FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- -----------------------------------------
-- 4.2 Policies untuk tabel PROFILES
-- - Authenticated users bisa melihat semua profiles
-- - User bisa update profile sendiri
-- - Insert diizinkan (untuk trigger dan admin create cashier)
-- -----------------------------------------
DROP POLICY IF EXISTS "Allow authenticated read on profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow users to update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow insert on profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow authenticated all on profiles" ON public.profiles;

CREATE POLICY "Allow authenticated read on profiles"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Allow authenticated all on profiles"
    ON public.profiles FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- -----------------------------------------
-- 4.3 Policies untuk tabel PRODUK
-- - Authenticated users bisa melihat semua produk
-- - Authenticated users bisa CRUD
-- -----------------------------------------
DROP POLICY IF EXISTS "Allow authenticated read on produk" ON public.produk;
DROP POLICY IF EXISTS "Allow authenticated all on produk" ON public.produk;

CREATE POLICY "Allow authenticated read on produk"
    ON public.produk FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Allow authenticated all on produk"
    ON public.produk FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- -----------------------------------------
-- 4.4 Policies untuk tabel SHIFT_KASIR
-- - Authenticated users bisa melihat semua shift
-- - Authenticated users bisa CRUD
-- -----------------------------------------
DROP POLICY IF EXISTS "Allow authenticated read on shift_kasir" ON public.shift_kasir;
DROP POLICY IF EXISTS "Allow authenticated all on shift_kasir" ON public.shift_kasir;

CREATE POLICY "Allow authenticated read on shift_kasir"
    ON public.shift_kasir FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Allow authenticated all on shift_kasir"
    ON public.shift_kasir FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- -----------------------------------------
-- 4.5 Policies untuk tabel TRANSAKSI
-- - Authenticated users bisa melihat semua transaksi
-- - Authenticated users bisa insert transaksi baru
-- -----------------------------------------
DROP POLICY IF EXISTS "Allow authenticated read on transaksi" ON public.transaksi;
DROP POLICY IF EXISTS "Allow authenticated all on transaksi" ON public.transaksi;

CREATE POLICY "Allow authenticated read on transaksi"
    ON public.transaksi FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Allow authenticated all on transaksi"
    ON public.transaksi FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- -----------------------------------------
-- 4.6 Policies untuk tabel DETAIL_TRANSAKSI
-- - Authenticated users bisa melihat semua detail
-- - Authenticated users bisa insert detail
-- -----------------------------------------
DROP POLICY IF EXISTS "Allow authenticated read on detail_transaksi" ON public.detail_transaksi;
DROP POLICY IF EXISTS "Allow authenticated all on detail_transaksi" ON public.detail_transaksi;

CREATE POLICY "Allow authenticated read on detail_transaksi"
    ON public.detail_transaksi FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Allow authenticated all on detail_transaksi"
    ON public.detail_transaksi FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);


-- ====================================================================
-- BAGIAN 5: STORAGE BUCKET & POLICIES
-- ====================================================================

-- -----------------------------------------
-- 5.1 Buat storage bucket untuk foto produk
-- -----------------------------------------
INSERT INTO storage.buckets (id, name, public)
VALUES ('produk-images', 'produk-images', true)
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------
-- 5.2 Policies untuk storage bucket 'produk-images'
-- -----------------------------------------

-- Semua orang bisa melihat/download foto produk (public)
DROP POLICY IF EXISTS "Allow public select on produk-images" ON storage.objects;
CREATE POLICY "Allow public select on produk-images"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'produk-images');

-- User authenticated bisa upload foto
DROP POLICY IF EXISTS "Allow authenticated insert on produk-images" ON storage.objects;
CREATE POLICY "Allow authenticated insert on produk-images"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'produk-images');

-- User authenticated bisa update foto
DROP POLICY IF EXISTS "Allow authenticated update on produk-images" ON storage.objects;
CREATE POLICY "Allow authenticated update on produk-images"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (bucket_id = 'produk-images');

-- User authenticated bisa hapus foto
DROP POLICY IF EXISTS "Allow authenticated delete on produk-images" ON storage.objects;
CREATE POLICY "Allow authenticated delete on produk-images"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (bucket_id = 'produk-images');


-- ====================================================================
-- BAGIAN 6: RELASI ANTAR TABEL (ERD SUMMARY)
-- ====================================================================
--
-- auth.users
--     │
--     └──< profiles (1:1)  ─── id (UUID FK)
--            │
--            ├── toko_id ──> toko (N:1)
--            │
--            ├──< shift_kasir (1:N)  ─── kasir_id
--            │       │
--            │       └──< transaksi (1:N)  ─── shift_id
--            │
--            └──< transaksi (1:N)  ─── kasir_id
--
-- toko
--     │
--     ├──< profiles (1:N)  ─── toko_id
--     ├──< produk (1:N)  ─── toko_id
--     ├──< shift_kasir (1:N)  ─── toko_id
--     └──< transaksi (1:N)  ─── toko_id
--
-- transaksi
--     │
--     └──< detail_transaksi (1:N)  ─── transaksi_id
--            │
--            └── produk_id ──> produk (N:1)
--
-- ====================================================================


-- ====================================================================
-- BAGIAN 7: DESKRIPSI KOLOM TABEL
-- ====================================================================
--
-- TABEL: toko
-- ┌─────────────────┬──────────────┬──────────────────────────────────┐
-- │ Kolom           │ Tipe         │ Keterangan                       │
-- ├─────────────────┼──────────────┼──────────────────────────────────┤
-- │ id              │ UUID (PK)    │ ID auto-generate                 │
-- │ nama_toko       │ TEXT         │ Nama toko/cabang                 │
-- │ lokasi          │ TEXT         │ Alamat/lokasi toko               │
-- │ nomor_telepon   │ TEXT         │ Nomor telepon toko               │
-- │ status_aktif    │ BOOLEAN      │ Status aktif (default TRUE)      │
-- │ created_at      │ TIMESTAMPTZ  │ Waktu dibuat                     │
-- └─────────────────┴──────────────┴──────────────────────────────────┘
--
-- TABEL: profiles
-- ┌─────────────────┬──────────────┬──────────────────────────────────┐
-- │ Kolom           │ Tipe         │ Keterangan                       │
-- ├─────────────────┼──────────────┼──────────────────────────────────┤
-- │ id              │ UUID (PK/FK) │ ID dari auth.users               │
-- │ nama_lengkap    │ TEXT         │ Nama lengkap pengguna            │
-- │ email           │ TEXT         │ Email pengguna                   │
-- │ role            │ TEXT         │ 'admin' atau 'kasir'             │
-- │ toko_id         │ UUID (FK)    │ Toko yang ditugaskan → toko      │
-- │ status          │ TEXT         │ 'aktif' atau 'nonaktif'          │
-- │ created_at      │ TIMESTAMPTZ  │ Waktu dibuat                     │
-- └─────────────────┴──────────────┴──────────────────────────────────┘
--
-- TABEL: produk
-- ┌─────────────────┬──────────────┬──────────────────────────────────┐
-- │ Kolom           │ Tipe         │ Keterangan                       │
-- ├─────────────────┼──────────────┼──────────────────────────────────┤
-- │ id              │ UUID (PK)    │ ID auto-generate                 │
-- │ toko_id         │ UUID (FK)    │ Toko pemilik produk → toko       │
-- │ nama_produk     │ TEXT         │ Nama produk                      │
-- │ harga_jual      │ NUMERIC      │ Harga jual produk                │
-- │ deskripsi       │ TEXT         │ Deskripsi produk (opsional)      │
-- │ foto_url        │ TEXT         │ URL foto produk                  │
-- │ status          │ TEXT         │ 'tersedia' atau 'habis'          │
-- │ created_at      │ TIMESTAMPTZ  │ Waktu dibuat                     │
-- └─────────────────┴──────────────┴──────────────────────────────────┘
--
-- TABEL: shift_kasir
-- ┌─────────────────────────┬──────────────┬──────────────────────────────────┐
-- │ Kolom                   │ Tipe         │ Keterangan                       │
-- ├─────────────────────────┼──────────────┼──────────────────────────────────┤
-- │ id                      │ UUID (PK)    │ ID auto-generate                 │
-- │ kasir_id                │ UUID (FK)    │ Kasir pemilik shift → profiles   │
-- │ toko_id                 │ UUID (FK)    │ Toko shift ini → toko            │
-- │ waktu_buka              │ TIMESTAMPTZ  │ Waktu buka shift                 │
-- │ waktu_tutup             │ TIMESTAMPTZ  │ Waktu tutup shift (nullable)     │
-- │ modal_awal              │ NUMERIC      │ Modal kas awal                   │
-- │ total_penjualan_tunai   │ NUMERIC      │ Total penjualan tunai            │
-- │ total_pengeluaran       │ NUMERIC      │ Total pengeluaran                │
-- │ total_seharusnya        │ NUMERIC      │ Saldo yang seharusnya            │
-- │ uang_fisik              │ NUMERIC      │ Uang fisik saat tutup (nullable) │
-- │ selisih                 │ NUMERIC      │ Selisih kas (nullable)           │
-- │ status                  │ TEXT         │ 'buka' atau 'tutup'              │
-- │ created_at              │ TIMESTAMPTZ  │ Waktu dibuat                     │
-- └─────────────────────────┴──────────────┴──────────────────────────────────┘
--
-- TABEL: transaksi
-- ┌─────────────────────┬──────────────┬──────────────────────────────────┐
-- │ Kolom               │ Tipe         │ Keterangan                       │
-- ├─────────────────────┼──────────────┼──────────────────────────────────┤
-- │ id                  │ UUID (PK)    │ ID auto-generate                 │
-- │ nomor_transaksi     │ TEXT         │ Nomor unik (TRX-YYYYMMDD-HHMMSS)│
-- │ shift_id            │ UUID (FK)    │ Shift terkait → shift_kasir      │
-- │ kasir_id            │ UUID (FK)    │ Kasir pelaksana → profiles       │
-- │ toko_id             │ UUID (FK)    │ Toko transaksi → toko            │
-- │ metode_pembayaran   │ TEXT         │ 'tunai', 'transfer', atau 'qris' │
-- │ total               │ NUMERIC      │ Total belanja                    │
-- │ jumlah_bayar        │ NUMERIC      │ Jumlah yang dibayar              │
-- │ kembalian           │ NUMERIC      │ Kembalian                        │
-- │ created_at          │ TIMESTAMPTZ  │ Waktu transaksi                  │
-- └─────────────────────┴──────────────┴──────────────────────────────────┘
--
-- TABEL: detail_transaksi
-- ┌─────────────────┬──────────────┬──────────────────────────────────┐
-- │ Kolom           │ Tipe         │ Keterangan                       │
-- ├─────────────────┼──────────────┼──────────────────────────────────┤
-- │ id              │ UUID (PK)    │ ID auto-generate                 │
-- │ transaksi_id    │ UUID (FK)    │ Transaksi induk → transaksi      │
-- │ produk_id       │ UUID (FK)    │ Produk terkait → produk          │
-- │ nama_produk     │ TEXT         │ Nama produk (snapshot)           │
-- │ harga_produk    │ NUMERIC      │ Harga produk saat beli (snapshot)│
-- │ qty             │ INT          │ Jumlah dibeli                    │
-- │ subtotal        │ NUMERIC      │ Subtotal (harga × qty)           │
-- │ created_at      │ TIMESTAMPTZ  │ Waktu dibuat                     │
-- └─────────────────┴──────────────┴──────────────────────────────────┘
--
-- ====================================================================
-- SELESAI - Jalankan seluruh script ini di Supabase SQL Editor
-- ====================================================================
