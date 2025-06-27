import React, { useState } from 'react';
import './App.css';
import VotingPage from './components/VotingPage';
import ResultsPage from './components/ResultsPage';
import VoterListPage from './components/VoterListPage'; // Tambahkan VoterListPage

// Component utama dengan navigasi antara halaman Voting, Hasil, dan Daftar Pemilih.
function App() {
  const [currentPage, setCurrentPage] = useState('voting'); // Navigasi halaman

  return (
    <div className="app">
      <div className="container">
        {currentPage === 'voting' ? (
          <VotingPage navigateToResults={() => setCurrentPage('results')} navigateToVoterList={() => setCurrentPage('voterlist')} />
        ) : currentPage === 'results' ? (
          <ResultsPage navigateToVoting={() => setCurrentPage('voting')} navigateToVoterList={() => setCurrentPage('voterlist')} />
        ) : currentPage === 'voterlist' ? (
          <VoterListPage navigateToVoting={() => setCurrentPage('voting')} navigateToResults={() => setCurrentPage('results')} />
        ) : (
          <VotingPage navigateToResults={() => setCurrentPage('results')} navigateToVoterList={() => setCurrentPage('voterlist')} />
        )}
      </div>
    </div>
  );
}

export default App;