import Array "mo:base/Array";
import Text "mo:base/Text";

actor Snatia {

  type Candidate = Text;

  type Voter = {
    name: Text;         // Nama pemilih
    votedFor: Nat;      // Index kandidat yang dipilih
  };

  var candidates: [Candidate] = ["Adit", "Manik", "Yudi"]; // Daftar kandidat
  var votes: [Nat] = [0, 0, 0];                            // Jumlah suara untuk tiap kandidat
  var voters: [Voter] = [];                               // Daftar pemilih

  // Fungsi untuk mengecek apakah pemilih sudah memberikan suara
  func hasVoted(voterName: Text): Bool {
    for (voter in voters.vals()) {
      if (Text.equal(voter.name, voterName)) {
        return true;
      };
    };
    return false;
  };

  // Mengambil daftar kandidat
  public query func getCandidates(): async [Candidate] {
    return candidates;
  };

  // Mengambil jumlah suara untuk setiap kandidat
  public query func getVotes(): async [Nat] {
    return votes;
  };

  // Menghitung total seluruh suara
  public query func getTotalVotes(): async Nat {
    var total: Nat = 0;
    for (vote in votes.vals()) {
      total += vote;
    };
    return total;
  };

  // Menampilkan hasil voting dalam format kandidat dan jumlah suara
  public query func getResults(): async [{ candidate: Text; voteCount: Nat }] {
    let results = Array.tabulate<{ candidate: Text; voteCount: Nat }>(
      candidates.size(),
      func(i) {
        return { candidate = candidates[i]; voteCount = votes[i] };
      },
    );
    return results;
  };

  // Menampilkan daftar pemilih beserta kandidat yang mereka pilih
  public query func getVoters(): async [{ name: Text; votedFor: Text }] {
    return Array.map<Voter, { name: Text; votedFor: Text }>(
      voters,
      func(voter) {
        return { name = voter.name; votedFor = candidates[voter.votedFor] };
      }
    );
  };

  // Fungsi untuk mencatat suara seorang pemilih
  public func vote(candidateIndex: Nat, voterName: Text): async Text {
    // Validasi nama pemilih tidak boleh kosong
    if (Text.size(voterName) == 0) {
      return "Nama pemilih tidak boleh kosong.";
    };

    // Cek apakah pemilih sudah memberikan suara sebelumnya
    if (hasVoted(voterName)) {
      return "Anda sudah melakukan pemilihan sebelumnya.";
    };

    // Validasi indeks kandidat
    if (candidateIndex >= candidates.size()) {
      return "Kandidat tidak valid.";
    };

    // Tambahkan suara
    votes := Array.tabulate<Nat>(
      votes.size(),
      func(i) {
        if (i == candidateIndex) {
          return votes[i] + 1;
        } else {
          return votes[i];
        };
      },
    );

    // Catat pemilih
    voters := Array.append(voters, [{ name = voterName; votedFor = candidateIndex }]);

    return "Vote berhasil tercatat untuk " # candidates[candidateIndex];
  };

  // Mengecek status pemilih berdasarkan nama
  public query func checkVoterStatus(voterName: Text): async Bool {
    return hasVoted(voterName);
  };

};