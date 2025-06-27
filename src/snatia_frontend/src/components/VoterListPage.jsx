import React, { useEffect, useState } from 'react';
import { snatia_backend } from 'declarations/snatia_backend';
import '../styles/VoterListPage.css';

function VoterListPage({ navigateToVoting, navigateToResults }) {
  const [voters, setVoters] = useState([]);

  useEffect(() => {
    async function fetchVoters() {
      try {
        const voterList = await snatia_backend.getVoters();
        setVoters(voterList); 
      } catch (error) {
        console.error("Error fetching voters:", error);
      }
    }
    fetchVoters();
  }, []);

  return (
    <div>
      <h1 className="title">Daftar Pemilih</h1>
      <table className="voter-table">
        <thead>
          <tr>
            <th>Nama Pemilih</th>
            <th>Kandidat</th>
          </tr>
        </thead>
        <tbody>
          {voters.map((voter, index) => (
            <tr key={index}>
              <td>{voter.name}</td>
              <td>{voter.votedFor}</td>
            </tr>
          ))}
        </tbody>
      </table>
      <div className="buttons">
        <button className="navigate-button" onClick={navigateToVoting}>
          Kembali ke Voting
        </button>
        <button className="navigate-button" onClick={navigateToResults}>
          Lihat Hasil Voting
        </button>
      </div>
    </div>
  );
}

export default VoterListPage;