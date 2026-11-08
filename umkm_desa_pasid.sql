
-- 1. Pengguna (akun login)
CREATE TABLE pengguna (
    id          SERIAL PRIMARY KEY,
    username    VARCHAR(50) NOT NULL UNIQUE,
    email       VARCHAR(100) NOT NULL UNIQUE,
    password    VARCHAR(255) NOT NULL,
    role        VARCHAR(20) NOT NULL DEFAULT 'pembeli' CHECK (role IN ('admin', 'pembeli')),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Profil pengguna -> ONE TO ONE dengan pengguna
CREATE TABLE profil_pengguna (
    id            SERIAL PRIMARY KEY,
    pengguna_id   INT NOT NULL UNIQUE REFERENCES pengguna(id) ON DELETE CASCADE,
    nama_lengkap  VARCHAR(100) NOT NULL,
    no_hp         VARCHAR(15),
    alamat        TEXT
);

-- 3. UMKM (usaha catering / tumpeng milik warga desa)
CREATE TABLE umkm (
    id           SERIAL PRIMARY KEY,
    nama_usaha   VARCHAR(100) NOT NULL,
    pemilik      VARCHAR(100) NOT NULL,
    alamat       TEXT,
    no_hp        VARCHAR(15),
    deskripsi    TEXT,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Kategori produk
CREATE TABLE kategori_produk (
    id         SERIAL PRIMARY KEY,
    nama       VARCHAR(50) NOT NULL UNIQUE,
    deskripsi  TEXT
);

-- 5. Produk -> ONE TO MANY dari umkm dan dari kategori_produk
CREATE TABLE produk (
    id            SERIAL PRIMARY KEY,
    umkm_id       INT NOT NULL REFERENCES umkm(id) ON DELETE CASCADE,
    kategori_id   INT NOT NULL REFERENCES kategori_produk(id),
    nama          VARCHAR(100) NOT NULL,
    deskripsi     TEXT,
    harga         NUMERIC(12,2) NOT NULL CHECK (harga >= 0),
    min_order     INT NOT NULL DEFAULT 1,
    tersedia      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Pesanan -> ONE TO MANY dari pengguna
CREATE TABLE pesanan (
    id                  SERIAL PRIMARY KEY,
    pengguna_id         INT NOT NULL REFERENCES pengguna(id),
    tanggal_pesan       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tanggal_acara       DATE NOT NULL,
    alamat_pengiriman   TEXT NOT NULL,
    status              VARCHAR(30) NOT NULL DEFAULT 'menunggu_pembayaran'
                        CHECK (status IN ('menunggu_pembayaran', 'diproses', 'dikirim', 'selesai', 'dibatalkan')),
    total_harga         NUMERIC(12,2) NOT NULL DEFAULT 0,
    catatan             TEXT
);

-- 7. Detail pesanan -> MANY TO MANY antara pesanan dan produk
CREATE TABLE detail_pesanan (
    pesanan_id     INT NOT NULL REFERENCES pesanan(id) ON DELETE CASCADE,
    produk_id      INT NOT NULL REFERENCES produk(id),
    jumlah         INT NOT NULL CHECK (jumlah > 0),
    harga_satuan   NUMERIC(12,2) NOT NULL,
    PRIMARY KEY (pesanan_id, produk_id)
);

-- 8. Pembayaran -> ONE TO ONE dengan pesanan
CREATE TABLE pembayaran (
    id                SERIAL PRIMARY KEY,
    pesanan_id        INT NOT NULL UNIQUE REFERENCES pesanan(id) ON DELETE CASCADE,
    metode            VARCHAR(30) NOT NULL CHECK (metode IN ('transfer', 'tunai', 'e-wallet')),
    jumlah_dibayar    NUMERIC(12,2) NOT NULL,
    status            VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'lunas', 'gagal')),
    tanggal_bayar     TIMESTAMP
);

-- 9. Ulasan -> ONE TO MANY dari pengguna dan dari produk
CREATE TABLE ulasan (
    id            SERIAL PRIMARY KEY,
    pengguna_id   INT NOT NULL REFERENCES pengguna(id) ON DELETE CASCADE,
    produk_id     INT NOT NULL REFERENCES produk(id) ON DELETE CASCADE,
    rating        INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    komentar      TEXT,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- DATA CONTOH (untuk tes GET di Postman)
-- =====================================================
INSERT INTO pengguna (username, email, password, role) VALUES
('admin_desa', 'admin@desa.id', 'hash_contoh_1', 'admin'),
('budi', 'budi@mail.com', 'hash_contoh_2', 'pembeli'),
('siti', 'siti@mail.com', 'hash_contoh_3', 'pembeli');

INSERT INTO profil_pengguna (pengguna_id, nama_lengkap, no_hp, alamat) VALUES
(1, 'Admin Desa', '081200000000', 'Kantor Desa'),
(2, 'Budi Santoso', '081200000001', 'Jl. Melati No. 5'),
(3, 'Siti Aminah', '081200000002', 'Jl. Mawar No. 12');

INSERT INTO umkm (nama_usaha, pemilik, alamat, no_hp, deskripsi) VALUES
('Tumpeng Bu Sari', 'Sari Wulandari', 'Dusun 1, RT 01', '081300000001', 'Spesialis tumpeng untuk syukuran dan acara adat'),
('Catering Barokah', 'Ahmad Fauzi', 'Dusun 2, RT 03', '081300000002', 'Nasi box dan snack box untuk acara desa');

INSERT INTO kategori_produk (nama, deskripsi) VALUES
('Tumpeng', 'Nasi tumpeng berbagai ukuran'),
('Nasi Box', 'Paket nasi kotak'),
('Snack Box', 'Paket kue dan camilan');

INSERT INTO produk (umkm_id, kategori_id, nama, deskripsi, harga, min_order) VALUES
(1, 1, 'Tumpeng Mini', 'Untuk 5-8 orang', 150000, 1),
(1, 1, 'Tumpeng Besar', 'Untuk 20-25 orang', 350000, 1),
(2, 2, 'Nasi Box Ayam Bakar', 'Nasi, ayam bakar, lalapan, sambal', 25000, 10),
(2, 3, 'Snack Box Komplit', '3 jenis kue + air mineral', 18000, 20);

INSERT INTO pesanan (pengguna_id, tanggal_acara, alamat_pengiriman, status, total_harga, catatan) VALUES
(2, '2026-11-05', 'Jl. Melati No. 5', 'selesai', 850000, 'Acara syukuran keluarga'),
(3, '2026-11-20', 'Balai Desa', 'diproses', 540000, 'Untuk rapat warga'),
(2, '2026-11-25', 'Jl. Melati No. 5', 'menunggu_pembayaran', 300000, NULL);

INSERT INTO detail_pesanan (pesanan_id, produk_id, jumlah, harga_satuan) VALUES
(1, 2, 1, 350000),
(1, 3, 20, 25000),
(2, 4, 30, 18000),
(3, 1, 2, 150000);

INSERT INTO pembayaran (pesanan_id, metode, jumlah_dibayar, status, tanggal_bayar) VALUES
(1, 'transfer', 850000, 'lunas', '2026-11-01 10:00'),
(2, 'e-wallet', 540000, 'lunas', '2026-11-07 14:30');

INSERT INTO ulasan (pengguna_id, produk_id, rating, komentar) VALUES
(2, 2, 5, 'Tumpeng enak dan porsinya pas, pengiriman tepat waktu.'),
(2, 3, 4, 'Ayam bakarnya empuk, sambalnya bisa lebih pedas.');
