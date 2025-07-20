import Array "mo:base/Array";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Map "mo:base/HashMap";
import Debug "mo:base/Debug";
import Prim "mo:⛔";
import Iter "mo:base/Iter";
import Float "mo:base/Float";

actor Snatia {

  type Candidate = Text;

  type Voter = {
    name: Text;         
    votedFor: Nat;      
    address: Principal;  // Tambahan: Principal address pemilih
    timestamp: Int;      // Tambahan: Waktu voting
    blockHash: Text;     // Tambahan: Hash block tempat vote disimpan
  };

  // Definisi Block untuk blockchain
  type Block = {
    index: Nat;
    timestamp: Int;
    previousHash: Text;
    hash: Text;
    votes: [VoteRecord];
    merkleRoot: Text;
  };

  // Record vote untuk blockchain
  type VoteRecord = {
    id: Nat;
    voterAddress: Principal;
    voterName: Text;
    candidateIndex: Nat;
    candidateName: Text;
    timestamp: Int;
    transactionHash: Text;
  };

  // Tipe Metrics
  type Metrics = {
    canister_memory_size : Nat;
    cycles : Nat;
  };

  // Query Results
  type VoteQueryResult = {
    vote: VoteRecord;
    blockIndex: Nat;
    confirmed: Bool;
    blockHash: Text;
  };

  type BlockQueryResult = {
    block: Block;
    totalVotes: Nat;
    isValid: Bool;
  };

  type AddressVoteHistory = {
    address: Principal;
    totalVotes: Nat;
    voteHistory: [VoteQueryResult];
  };

  // Data storage
  var candidates: [Candidate] = ["Adit", "Manik", "Yudi"];
  var votes: [Nat] = [0, 0, 0];
  private stable var voters: [Voter] = [];
  private stable var blockchain: [Block] = [];
  private stable var voteCounter: Nat = 0;

  // Helper function - cek apakah sudah vote
  func hasVoted(voterName: Text): Bool {
    for (voter in voters.vals()) {
      if (Text.equal(voter.name, voterName)) {
        return true;
      };
    };
    return false;
  };

  // Helper function - cek apakah address sudah vote
  func hasAddressVoted(address: Principal): Bool {
    for (voter in voters.vals()) {
      if (Principal.equal(voter.address, address)) {
        return true;
      };
    };
    return false;
  };

  // Helper function - generate hash
  func generateHash(input: Text): Text {
    "hash_" # input # "_" # debug_show(Time.now())
  };

  // Helper function - generate transaction hash
  func generateTxHash(voteId: Nat, address: Principal): Text {
    "tx_" # debug_show(voteId) # "_" # debug_show(address) # "_" # debug_show(Time.now())
  };

  // Helper function - create new block
  func createBlock(voteRecords: [VoteRecord]): Block {
    let blockIndex = blockchain.size();
    let previousHash = if (blockIndex == 0) {
      "genesis"
    } else {
      blockchain[blockIndex - 1].hash
    };
    
    let blockData = debug_show(blockIndex) # debug_show(Time.now()) # previousHash;
    let blockHash = generateHash(blockData);
    let merkleRoot = generateHash("merkle_" # debug_show(voteRecords.size()));

    {
      index = blockIndex;
      timestamp = Time.now();
      previousHash = previousHash;
      hash = blockHash;
      votes = voteRecords;
      merkleRoot = merkleRoot;
    }
  };

  // ===========================================
  // ORIGINAL FUNCTIONS (Enhanced)
  // ===========================================

  public query func getCandidates(): async [Candidate] {
    return candidates;
  };

  public query func getVotes(): async [Nat] {
    return votes;
  };

  public query func getTotalVotes(): async Nat {
    var total: Nat = 0;
    for (vote in votes.vals()) {
      total += vote;
    };
    return total;
  };

  public query func getResults(): async [{ candidate: Text; voteCount: Nat }] {
    let results = Array.tabulate<{ candidate: Text; voteCount: Nat }>(
      candidates.size(),
      func(i) {
        return { candidate = candidates[i]; voteCount = votes[i] };
      },
    );
    return results;
  };

  public query func getVoters(): async [{ name: Text; votedFor: Text; address: Text; timestamp: Int }] {
    return Array.map<Voter, { name: Text; votedFor: Text; address: Text; timestamp: Int }>(
      voters,
      func(voter) {
        return { 
          name = voter.name; 
          votedFor = candidates[voter.votedFor];
          address = Principal.toText(voter.address);
          timestamp = voter.timestamp;
        };
      }
    );
  };

  // Enhanced vote function dengan blockchain
  public func vote(candidateIndex: Nat, voterName: Text): async Text {
    let caller = Principal.fromActor(Snatia); // Dalam implementasi nyata, gunakan caller yang sebenarnya
    
    // Validasi nama pemilih
    if (Text.size(voterName) == 0) {
      return "Nama pemilih tidak boleh kosong.";
    };

    // Cek apakah sudah vote berdasarkan nama atau address
    if (hasVoted(voterName) or hasAddressVoted(caller)) {
      return "Anda sudah melakukan pemilihan sebelumnya.";
    };

    // Validasi indeks kandidat
    if (candidateIndex >= candidates.size()) {
      return "Kandidat tidak valid.";
    };

    let currentTime = Time.now();
    let txHash = generateTxHash(voteCounter, caller);

    // Buat vote record untuk blockchain
    let voteRecord: VoteRecord = {
      id = voteCounter;
      voterAddress = caller;
      voterName = voterName;
      candidateIndex = candidateIndex;
      candidateName = candidates[candidateIndex];
      timestamp = currentTime;
      transactionHash = txHash;
    };

    // Buat block baru
    let newBlock = createBlock([voteRecord]);
    blockchain := Array.append(blockchain, [newBlock]);

    // Update votes count
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

    // Tambah voter dengan info blockchain
    let newVoter: Voter = {
      name = voterName;
      votedFor = candidateIndex;
      address = caller;
      timestamp = currentTime;
      blockHash = newBlock.hash;
    };
    voters := Array.append(voters, [newVoter]);

    voteCounter += 1;

    return "Vote berhasil tercatat untuk " # candidates[candidateIndex] # 
           " | Block: " # debug_show(newBlock.index) # 
           " | TX: " # txHash;
  };

  public query func checkVoterStatus(voterName: Text): async Bool {
    return hasVoted(voterName);
  };

  public shared func get_subnet_metrics() : async Metrics {
    let memory = Prim.rts_memory_size();
    let cycles = Prim.cyclesBalance();
    {
      canister_memory_size = memory;
      cycles = cycles;
    }
  };

  // ===========================================
  // NEW BLOCKCHAIN QUERY FUNCTIONS
  // ===========================================

  // Query: Mendapatkan semua vote berdasarkan address
  public query func getVotesByAddress(address: Principal): async AddressVoteHistory {
    var userVotes: [VoteQueryResult] = [];
    var totalUserVotes: Nat = 0;

    for (block in blockchain.vals()) {
      for (vote in block.votes.vals()) {
        if (Principal.equal(vote.voterAddress, address)) {
          let queryResult: VoteQueryResult = {
            vote = vote;
            blockIndex = block.index;
            confirmed = true;
            blockHash = block.hash;
          };
          userVotes := Array.append(userVotes, [queryResult]);
          totalUserVotes += 1;
        };
      };
    };

    {
      address = address;
      totalVotes = totalUserVotes;
      voteHistory = userVotes;
    }
  };

  // Query: Mendapatkan semua block
  public query func getAllBlocks(): async [BlockQueryResult] {
    Array.map<Block, BlockQueryResult>(blockchain, func(block: Block): BlockQueryResult {
      {
        block = block;
        totalVotes = block.votes.size();
        isValid = validateBlock(block);
      }
    })
  };

  // Query: Mendapatkan block berdasarkan index
  public query func getBlockByIndex(index: Nat): async ?BlockQueryResult {
    if (index < blockchain.size()) {
      let block = blockchain[index];
      ?{
        block = block;
        totalVotes = block.votes.size();
        isValid = validateBlock(block);
      }
    } else {
      null
    }
  };

  // Query: Mendapatkan vote berdasarkan transaction hash
  public query func getVoteByTxHash(txHash: Text): async ?VoteQueryResult {
    for (block in blockchain.vals()) {
      for (vote in block.votes.vals()) {
        if (Text.equal(vote.transactionHash, txHash)) {
          return ?{
            vote = vote;
            blockIndex = block.index;
            confirmed = true;
            blockHash = block.hash;
          };
        };
      };
    };
    null
  };

  // Query: Mendapatkan semua vote untuk kandidat tertentu
  public query func getVotesForCandidate(candidateIndex: Nat): async [VoteQueryResult] {
    var candidateVotes: [VoteQueryResult] = [];

    for (block in blockchain.vals()) {
      for (vote in block.votes.vals()) {
        if (vote.candidateIndex == candidateIndex) {
          let queryResult: VoteQueryResult = {
            vote = vote;
            blockIndex = block.index;
            confirmed = true;
            blockHash = block.hash;
          };
          candidateVotes := Array.append(candidateVotes, [queryResult]);
        };
      };
    };

    candidateVotes
  };

  // Query: Statistik blockchain lengkap
  public query func getBlockchainStats(): async {
    totalBlocks: Nat;
    totalVotes: Nat;
    totalUniqueVoters: Nat;
    candidateStats: [{ candidate: Text; votes: Nat; percentage: Float }];
    averageVotesPerBlock: Float;
    firstVoteTime: ?Int;
    lastVoteTime: ?Int;
  } {
    let totalBlocks = blockchain.size();
    var totalVotes = 0;
    var firstTime: ?Int = null;
    var lastTime: ?Int = null;

    // Hitung total votes dan waktu
    for (block in blockchain.vals()) {
      totalVotes += block.votes.size();
      for (vote in block.votes.vals()) {
        switch (firstTime) {
          case null { firstTime := ?vote.timestamp; };
          case (?t) { 
            if (vote.timestamp < t) { firstTime := ?vote.timestamp; };
          };
        };
        switch (lastTime) {
          case null { lastTime := ?vote.timestamp; };
          case (?t) { 
            if (vote.timestamp > t) { lastTime := ?vote.timestamp; };
          };
        };
      };
    };

    // Hitung statistik kandidat dengan persentase
    let candidateStats = Array.tabulate<{ candidate: Text; votes: Nat; percentage: Float }>(
      candidates.size(),
      func(i) {
        let voteCount = votes[i];
        let percentage = if (totalVotes > 0) {
          Float.fromInt(voteCount) / Float.fromInt(totalVotes) * 100.0
        } else { 0.0 };
        { 
          candidate = candidates[i]; 
          votes = voteCount; 
          percentage = percentage;
        }
      },
    );

    let avgVotesPerBlock = if (totalBlocks > 0) {
      Float.fromInt(totalVotes) / Float.fromInt(totalBlocks)
    } else { 0.0 };

    {
      totalBlocks = totalBlocks;
      totalVotes = totalVotes;
      totalUniqueVoters = voters.size();
      candidateStats = candidateStats;
      averageVotesPerBlock = avgVotesPerBlock;
      firstVoteTime = firstTime;
      lastVoteTime = lastTime;
    }
  };

  // Query: Verifikasi integritas blockchain
  public query func verifyBlockchainIntegrity(): async {
    isValid: Bool;
    invalidBlocks: [Nat];
    totalBlocks: Nat;
    message: Text;
  } {
    let totalBlocks = blockchain.size();
    var isValid = true;
    var invalidBlocks: [Nat] = [];

    if (totalBlocks == 0) {
      return {
        isValid = true;
        invalidBlocks = [];
        totalBlocks = 0;
        message = "Blockchain kosong";
      };
    };

    // Verifikasi genesis block
    let genesisBlock = blockchain[0];
    if (genesisBlock.index != 0 or genesisBlock.previousHash != "genesis") {
      isValid := false;
      invalidBlocks := Array.append(invalidBlocks, [0]);
    };

    // Verifikasi chain linking
    for (i in Iter.range(1, blockchain.size() - 1)) {
      let currentBlock = blockchain[i];
      let previousBlock = blockchain[i-1];
      
      if (currentBlock.previousHash != previousBlock.hash or 
          currentBlock.index != previousBlock.index + 1) {
        isValid := false;
        invalidBlocks := Array.append(invalidBlocks, [i]);
      };
    };

    let message = if (isValid) {
      "Blockchain valid dengan " # debug_show(totalBlocks) # " block"
    } else {
      "Ditemukan " # debug_show(invalidBlocks.size()) # " block tidak valid"
    };

    {
      isValid = isValid;
      invalidBlocks = invalidBlocks;
      totalBlocks = totalBlocks;
      message = message;
    }
  };

  // Query: Mendapatkan timeline voting
  public query func getVotingTimeline(): async [{ 
    timestamp: Int; 
    voterName: Text; 
    candidate: Text; 
    blockIndex: Nat; 
    txHash: Text; 
  }] {
    var timeline: [{ timestamp: Int; voterName: Text; candidate: Text; blockIndex: Nat; txHash: Text }] = [];

    for (block in blockchain.vals()) {
      for (vote in block.votes.vals()) {
        let entry = {
          timestamp = vote.timestamp;
          voterName = vote.voterName;
          candidate = vote.candidateName;
          blockIndex = block.index;
          txHash = vote.transactionHash;
        };
        timeline := Array.append(timeline, [entry]);
      };
    };

    timeline
  };

  // Helper function untuk validasi block
  func validateBlock(block: Block): Bool {
    // Validasi dasar: block harus memiliki vote dan hash tidak kosong
    block.votes.size() > 0 and block.hash != ""
  };

  // Query: Cek address sudah vote atau belum
  public query func checkAddressVoted(address: Principal): async {
    hasVoted: Bool;
    voteDetails: ?{ candidateName: Text; timestamp: Int; blockHash: Text };
  } {
    for (voter in voters.vals()) {
      if (Principal.equal(voter.address, address)) {
        return {
          hasVoted = true;
          voteDetails = ?{
            candidateName = candidates[voter.votedFor];
            timestamp = voter.timestamp;
            blockHash = voter.blockHash;
          };
        };
      };
    };
    
    {
      hasVoted = false;
      voteDetails = null;
    }
  };
};