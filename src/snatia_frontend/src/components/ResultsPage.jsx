import React, { useEffect, useState } from 'react';
import { snatia_backend } from 'declarations/snatia_backend';
import '../styles/ResultsPage.css';

function ResultsPage({ navigateToVoting, navigateToVoterList }) {
  const [results, setResults] = useState([]);
  const [totalVotes, setTotalVotes] = useState(0);

  // Mengambil hasil voting dari backend.
  useEffect(() => {
    async function fetchResults() {
      const res = await snatia_backend.getResults();
      const total = await snatia_backend.getTotalVotes();
      setResults(res);
      setTotalVotes(total);
    }
    fetchResults();
  }, []);

  return (
    <div>
      <h1 className="title">Hasil Voting</h1>
      <table className="results-table">
        <thead>
          <tr>
            <th>Kandidat</th>
            <th>Jumlah Suara</th>
          </tr>
        </thead>
        <tbody>
          {results.map((result, index) => (
            <tr key={index} className="result-row">
              <td>{result.candidate}</td>
              <td>{result.voteCount.toString()}</td>
            </tr>
          ))}
        </tbody>
      </table>
      <p className="total-votes">Total Suara: {totalVotes.toString()}</p>
      <button className="navigate-button" onClick={navigateToVoting}>
        Kembali ke Voting
      </button>
      <button className="navigate-button" onClick={navigateToVoterList}>
        Lihat Daftar Pemilih
      </button>
    </div>
  );
}

export default ResultsPage;