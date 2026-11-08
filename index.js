require('dotenv').config();
const express = require('express');
const pool = require('./db');

const app = express();
app.use(express.json());

app.get('/', (req, res) => {
  res.json({ message: 'API UMKM Catering dan Tumpeng Desa berjalan' });
});

// GET semua produk
app.get('/produk', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM produk ORDER BY id');
    res.json({ data: result.rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET produk berdasarkan ID
app.get('/produk/:id', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM produk WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Produk tidak ditemukan' });
    }
    res.json({ data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST buat produk baru
app.post('/produk', async (req, res) => {
  try {
    const { umkm_id, kategori_id, nama, deskripsi, harga, min_order } = req.body;
    if (!umkm_id || !kategori_id || !nama || harga === undefined) {
      return res.status(400).json({ error: 'umkm_id, kategori_id, nama, dan harga wajib diisi' });
    }
    const result = await pool.query(
      `INSERT INTO produk (umkm_id, kategori_id, nama, deskripsi, harga, min_order)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [umkm_id, kategori_id, nama, deskripsi || null, harga, min_order || 1]
    );
    res.status(201).json({ message: 'Produk berhasil dibuat', data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT perbarui produk
app.put('/produk/:id', async (req, res) => {
  try {
    const { umkm_id, kategori_id, nama, deskripsi, harga, min_order, tersedia } = req.body;
    const result = await pool.query(
      `UPDATE produk
       SET umkm_id = $1, kategori_id = $2, nama = $3, deskripsi = $4,
           harga = $5, min_order = $6, tersedia = $7
       WHERE id = $8 RETURNING *`,
      [umkm_id, kategori_id, nama, deskripsi || null, harga, min_order || 1, tersedia ?? true, req.params.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Produk tidak ditemukan' });
    }
    res.json({ message: 'Produk berhasil diperbarui', data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE hapus produk
app.delete('/produk/:id', async (req, res) => {
  try {
    const result = await pool.query('DELETE FROM produk WHERE id = $1 RETURNING *', [req.params.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Produk tidak ditemukan' });
    }
    res.json({ message: 'Produk berhasil dihapus', data: result.rows[0] });
  } catch (err) {
    if (err.code === '23503') {
      return res.status(409).json({ error: 'Produk tidak bisa dihapus karena sudah dipakai di pesanan' });
    }
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server berjalan di http://localhost:${PORT}`);
});