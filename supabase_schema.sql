-- ==============================================================================
-- 🚀 CV AI STUDIO - COMPLETE PRODUCTION SUPABASE DATABASE SCHEMA & POLICIES
-- ==============================================================================
-- Bu SQL kodunu Supabase Dashboard -> SQL Editor alanına yapıştırıp "RUN" butonuna basarak
-- tüm tabloları, RLS güvenlik politikalarını, Storage kurallarını ve otomatik tetikleyicileri
-- tek seferde eksiksiz kurabilirsiniz.
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 👤 2. PROFILES TABLOSU (Kullanıcı Profilleri, VIP Durumu & Sayaçlar)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT,
    avatar_url TEXT,
    is_vip BOOLEAN DEFAULT false,
    vip_tier TEXT DEFAULT 'free', -- 'free', 'weekly', 'monthly', 'yearly', 'unlimited'
    vip_expires_at TIMESTAMPTZ,
    vip_status TEXT DEFAULT 'free', -- 'active', 'cancelled', 'expired', 'free'
    vip_auto_renew BOOLEAN DEFAULT false,
    vip_cancelled_at TIMESTAMPTZ,
    cv_count INT DEFAULT 0,
    scan_count INT DEFAULT 0,
    conversion_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==============================================================================
-- 📄 3. RESUMES TABLOSU (CV ve Özgeçmişler)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.resumes (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    job_title TEXT,
    email TEXT,
    phone TEXT,
    location TEXT,
    website TEXT,
    linkedin TEXT,
    github TEXT,
    summary TEXT,
    experiences JSONB DEFAULT '[]'::jsonb,
    educations JSONB DEFAULT '[]'::jsonb,
    skills JSONB DEFAULT '[]'::jsonb,
    languages JSONB DEFAULT '[]'::jsonb,
    certificates JSONB DEFAULT '[]'::jsonb,
    projects JSONB DEFAULT '[]'::jsonb,
    references_list JSONB DEFAULT '[]'::jsonb,
    selected_template TEXT DEFAULT 'classic',
    primary_color TEXT DEFAULT '#2563EB',
    font_family TEXT DEFAULT 'Roboto',
    pdf_url TEXT,
    photo_url TEXT,
    is_active BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==============================================================================
-- 📁 4. DOCUMENTS TABLOSU (Office & PDF Dönüştürücü Arşivi)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.documents (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    document_type TEXT NOT NULL, -- 'pdf', 'docx', 'xlsx', 'pptx', 'txt', 'image'
    file_size TEXT,
    page_count INT DEFAULT 1,
    file_url TEXT,
    preview_image_url TEXT,
    is_favorite BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==============================================================================
-- 📸 5. SCANS TABLOSU (CamScanner HD Belge Taramaları)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.scans (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    mode TEXT DEFAULT 'document', -- 'document', 'id_card', 'passport', 'receipt', 'ocr'
    filter_applied TEXT DEFAULT 'magic',
    page_count INT DEFAULT 1,
    extracted_ocr_text TEXT,
    pages_data JSONB DEFAULT '[]'::jsonb,
    pdf_url TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==============================================================================
-- 🔍 6. OCR_HISTORY TABLOSU (Metin Tanıma Geçmişi)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.ocr_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    source_filename TEXT,
    extracted_text TEXT NOT NULL,
    character_count INT DEFAULT 0,
    word_count INT DEFAULT 0,
    language_detected TEXT DEFAULT 'auto',
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==============================================================================
-- ⚡ 7. ROW LEVEL SECURITY (RLS) POLİTİKALARI (Herkes Sadece Kendi Verisini Görür)
-- ==============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resumes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ocr_history ENABLE ROW LEVEL SECURITY;

-- Profiles RLS
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Resumes RLS
CREATE POLICY "Users can CRUD own resumes" ON public.resumes
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Documents RLS
CREATE POLICY "Users can CRUD own documents" ON public.documents
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Scans RLS
CREATE POLICY "Users can CRUD own scans" ON public.scans
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- OCR History RLS
CREATE POLICY "Users can CRUD own ocr history" ON public.ocr_history
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ==============================================================================
-- 🔁 8. OTOMATİK PROFİL OLUŞTURMA TETİKLEYİCİSİ (Auth -> Profile Trigger)
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, avatar_url, is_vip, vip_tier)
    VALUES (
        new.id,
        new.email,
        COALESCE(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
        new.raw_user_meta_data->>'avatar_url',
        false,
        'free'
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ==============================================================================
-- 📊 9. RPC FUNCTION (Sayaç Artırma Fonksiyonu)
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.increment_user_metric(user_uuid UUID, metric_type TEXT)
RETURNS VOID AS $$
BEGIN
    IF metric_type = 'cv_count' THEN
        UPDATE public.profiles SET cv_count = cv_count + 1, updated_at = now() WHERE id = user_uuid;
    ELSIF metric_type = 'scan_count' THEN
        UPDATE public.profiles SET scan_count = scan_count + 1, updated_at = now() WHERE id = user_uuid;
    ELSIF metric_type = 'conversion_count' THEN
        UPDATE public.profiles SET conversion_count = conversion_count + 1, updated_at = now() WHERE id = user_uuid;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==============================================================================
-- 🗄️ 10. STORAGE BUCKETS & POLICIES (Dosya Depolama)
-- ==============================================================================
-- Buckets oluşturma (resumes, documents, scans, avatars)
INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('resumes', 'resumes', true),
    ('documents', 'documents', true),
    ('scans', 'scans', true),
    ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS Politikaları
CREATE POLICY "Public Read Resumes" ON storage.objects FOR SELECT USING (bucket_id = 'resumes');
CREATE POLICY "Authenticated Users Upload Resumes" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'resumes' AND auth.role() = 'authenticated');
CREATE POLICY "Users Update Own Resumes" ON storage.objects FOR UPDATE USING (bucket_id = 'resumes' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users Delete Own Resumes" ON storage.objects FOR DELETE USING (bucket_id = 'resumes' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Public Read Documents" ON storage.objects FOR SELECT USING (bucket_id = 'documents');
CREATE POLICY "Authenticated Users Upload Documents" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'documents' AND auth.role() = 'authenticated');
CREATE POLICY "Users Update Own Documents" ON storage.objects FOR UPDATE USING (bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users Delete Own Documents" ON storage.objects FOR DELETE USING (bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Public Read Scans" ON storage.objects FOR SELECT USING (bucket_id = 'scans');
CREATE POLICY "Authenticated Users Upload Scans" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'scans' AND auth.role() = 'authenticated');
CREATE POLICY "Users Update Own Scans" ON storage.objects FOR UPDATE USING (bucket_id = 'scans' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users Delete Own Scans" ON storage.objects FOR DELETE USING (bucket_id = 'scans' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Public Read Avatars" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "Authenticated Users Upload Avatars" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');
CREATE POLICY "Users Update Own Avatars" ON storage.objects FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users Delete Own Avatars" ON storage.objects FOR DELETE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
