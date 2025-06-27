import React, { useState, useEffect } from 'react';
import { snatia_backend } from 'declarations/snatia_backend';
import '../styles/VotingPage.css';

function VotingPage({ navigateToResults }) {
  const [candidates, setCandidates] = useState([]);
  const [voterName, setVoterName] = useState('');
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);

  // Mengambil daftar kandidat dari backend.
  useEffect(() => {
    async function fetchCandidates() {
      const c = await snatia_backend.getCandidates();
      setCandidates(c);
    }
    fetchCandidates();
  }, []);

  // Fungsi untuk melakukan vote
  async function vote(index) {
    if (!voterName.trim()) {
      setMessage('Masukkan nama Anda terlebih dahulu');
      return;
    }
    setLoading(true);
    try {
      const result = await snatia_backend.vote(index, voterName);
      setMessage(result);
    } catch {
      setMessage('Terjadi kesalahan. Silakan coba lagi.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h1 className="title">E-Voting</h1>
      <form className="name-form">
        <label className="label">Nama:</label>
        <div className="input-container">
          <input
            type="text"
            value={voterName}
            onChange={(e) => setVoterName(e.target.value)}
            className="input"
            placeholder="Masukkan nama Anda"
          />
        </div>
      </form>
      <ul className="candidate-list">
        {candidates.map((candidate, index) => (
          <li key={index} className="candidate-item">
            <div className="candidate-name">{candidate}</div>
            <button
              className="vote-button"
              onClick={() => vote(index)}
              disabled={loading}
            >
              Pilih
            </button>
          </li>
        ))}
      </ul>
      <button className="navigate-button" onClick={navigateToResults}>
        Lihat Hasil
      </button>
      {message && <div className="message">{message}</div>}
    </div>
  );
}

export default VotingPage;