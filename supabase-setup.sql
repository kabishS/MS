-- =========================================================
-- MS FOOTWEAR — SUPABASE SETUP
-- Run this entire file once in the Supabase SQL Editor
-- (Project → SQL Editor → New Query → paste → Run)
-- =========================================================

-- ---------------------------------------------------------
-- 1. EXTENSIONS
-- ---------------------------------------------------------
create extension if not exists "uuid-ossp";

-- ---------------------------------------------------------
-- 2. TABLES
-- ---------------------------------------------------------

-- PRODUCTS
create table if not exists public.products (
  id           uuid primary key default uuid_generate_v4(),
  name         text not null,
  description  text default '',
  category     text not null check (category in ('Kids','Girls','Men')),
  price        numeric(10,2) not null check (price >= 0),
  image_url    text,
  sizes        text[] default array[]::text[],   -- e.g. {'6','7','8','9'}
  rating       numeric(2,1) default 0,
  trending     boolean default false,
  hidden       boolean default false,
  created_at   timestamptz default now()
);

-- ORDERS
create table if not exists public.orders (
  id              uuid primary key default uuid_generate_v4(),
  customer_name   text not null,
  phone           text not null,
  email           text not null,
  address         text not null,
  products        jsonb not null,           -- [{id,name,price,qty,size}, ...]
  quantity        integer not null default 1,
  total_price     numeric(10,2) not null,
  order_status    text default 'Pending' check (order_status in ('Pending','Completed','Cancelled')),
  created_at      timestamptz default now()
);

-- REVIEWS
create table if not exists public.reviews (
  id             uuid primary key default uuid_generate_v4(),
  product_id     uuid references public.products(id) on delete cascade,
  customer_name  text not null,
  rating         integer not null check (rating between 1 and 5),
  review         text default '',
  created_at     timestamptz default now()
);

-- Helpful indexes
create index if not exists idx_products_category on public.products(category);
create index if not exists idx_products_trending on public.products(trending);
create index if not exists idx_reviews_product on public.reviews(product_id);
create index if not exists idx_orders_status on public.orders(order_status);

-- ---------------------------------------------------------
-- 3. ROW LEVEL SECURITY
-- ---------------------------------------------------------
alter table public.products enable row level security;
alter table public.orders   enable row level security;
alter table public.reviews  enable row level security;

-- PRODUCTS: anyone can read non-hidden products (public storefront)
drop policy if exists "Public can view visible products" on public.products;
create policy "Public can view visible products"
  on public.products for select
  using ( hidden = false );

-- PRODUCTS: allow public inserts/updates/deletes via the anon key.
-- NOTE: This demo app uses a client-side password ("MS") for the admin
-- dashboard rather than real Supabase Auth, so the anon key needs write
-- access. For production, replace these with Supabase Auth + a proper
-- "is_admin" check.
drop policy if exists "Public can manage products" on public.products;
create policy "Public can manage products"
  on public.products for all
  using ( true )
  with check ( true );

-- Make sure hidden products are still manageable by admin reads:
drop policy if exists "Public can view all products for admin" on public.products;
create policy "Public can view all products for admin"
  on public.products for select
  using ( true );

-- ORDERS: anyone can insert an order (checkout), anyone can read/update/delete
-- (admin dashboard uses anon key in this demo)
drop policy if exists "Public can create orders" on public.orders;
create policy "Public can create orders"
  on public.orders for insert
  with check ( true );

drop policy if exists "Public can view orders" on public.orders;
create policy "Public can view orders"
  on public.orders for select
  using ( true );

drop policy if exists "Public can update orders" on public.orders;
create policy "Public can update orders"
  on public.orders for update
  using ( true );

drop policy if exists "Public can delete orders" on public.orders;
create policy "Public can delete orders"
  on public.orders for delete
  using ( true );

-- REVIEWS: anyone can read and create reviews
drop policy if exists "Public can view reviews" on public.reviews;
create policy "Public can view reviews"
  on public.reviews for select
  using ( true );

drop policy if exists "Public can create reviews" on public.reviews;
create policy "Public can create reviews"
  on public.reviews for insert
  with check ( true );

-- ---------------------------------------------------------
-- 4. STORAGE BUCKET FOR PRODUCT IMAGES
-- ---------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

-- Allow public read of images
drop policy if exists "Public can view product images" on storage.objects;
create policy "Public can view product images"
  on storage.objects for select
  using ( bucket_id = 'product-images' );

-- Allow public upload/update/delete (demo uses client-side admin password)
drop policy if exists "Public can upload product images" on storage.objects;
create policy "Public can upload product images"
  on storage.objects for insert
  with check ( bucket_id = 'product-images' );

drop policy if exists "Public can update product images" on storage.objects;
create policy "Public can update product images"
  on storage.objects for update
  using ( bucket_id = 'product-images' );

drop policy if exists "Public can delete product images" on storage.objects;
create policy "Public can delete product images"
  on storage.objects for delete
  using ( bucket_id = 'product-images' );

-- ---------------------------------------------------------
-- 5. SAMPLE SEED DATA (optional — comment out if not wanted)
-- ---------------------------------------------------------
insert into public.products (name, description, category, price, image_url, sizes, rating, trending)
values
  ('Aurelia Oxford', 'Hand-finished leather oxford with a gold-stitched welt.', 'Men', 8999, 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=800', array['7','8','9','10','11'], 4.7, true),
  ('Velora Sneaker', 'Lightweight everyday sneaker in navy nubuck.', 'Men', 5499, 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800', array['7','8','9','10'], 4.5, true),
  ('Marin Loafer', 'Classic penny loafer in burnished tan.', 'Men', 6999, 'https://images.unsplash.com/photo-1614252369475-531eba835eb1?w=800', array['8','9','10','11'], 4.3, false),
  ('Bellina Mary Jane', 'Soft patent leather mary jane for girls.', 'Girls', 2999, 'https://images.unsplash.com/photo-1551107696-a4b0c5a0d9a2?w=800', array['10','11','12','13'], 4.6, true),
  ('Lumi Glitter Flat', 'Sparkle ballet flat with cushioned sole.', 'Girls', 2499, 'https://images.unsplash.com/photo-1560769629-975ec94e6a86?w=800', array['11','12','13','1'], 4.4, false),
  ('Tiny Trail Runner', 'Durable kids running shoe for active play.', 'Kids', 1999, 'https://images.unsplash.com/photo-1576620243043-66d9fbd49d33?w=800', array['8','9','10','11'], 4.2, true),
  ('Cloud Step Sandal', 'Breathable summer sandal for kids.', 'Kids', 1499, 'https://images.unsplash.com/photo-1603808033587-1ce0c6c5e6f1?w=800', array['8','9','10'], 4.0, false)
on conflict do nothing;

-- =========================================================
-- DONE. After running this, copy your Project URL and
-- anon public key into index.html.
-- =========================================================