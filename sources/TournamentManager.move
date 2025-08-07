module my_addr::tournament {
    use std::signer;
    use std::vector;
    use aptos_framework::event;
    use aptos_framework::timestamp;
    struct Tournament has key, store {
        id: u64,
        name: vector<u8>,
        participants: vector<address>,
        brackets: vector<Match>,
        winner: address,
        is_active: bool,
        created_at: u64,
    }
    struct Match has store, copy, drop {
        player1: address,
        player2: address,
        winner: address,
        round: u8,
    }    
    #[event]
    struct TournamentCreated has drop, store {
        tournament_id: u64,
        creator: address,
        name: vector<u8>,
    }
    #[event]
    struct MatchCompleted has drop, store {
        tournament_id: u64,
        winner: address,
        round: u8,
    }
    const E_TOURNAMENT_EXISTS: u64 = 1;
    const E_NOT_TOURNAMENT_OWNER: u64 = 2;
    const E_INSUFFICIENT_PARTICIPANTS: u64 = 3;
    const E_TOURNAMENT_NOT_ACTIVE: u64 = 4;    
    public entry fun create_tournament(
        creator: &signer,
        tournament_id: u64,
        name: vector<u8>,
        participants: vector<address>
    ) {
        let creator_addr = signer::address_of(creator);
        assert!(!exists<Tournament>(creator_addr), E_TOURNAMENT_EXISTS);        
        assert!(vector::length(&participants) >= 2, E_INSUFFICIENT_PARTICIPANTS);        
        let brackets = vector::empty<Match>();
        let i = 0;
        let len = vector::length(&participants);        
        while (i < len - 1) {
            let player1 = *vector::borrow(&participants, i);
            let player2 = *vector::borrow(&participants, i + 1);
            let match = Match {
                player1,
                player2,
                winner: @0x0,
                round: 1,
            };            
            vector::push_back(&mut brackets, match);
            i = i + 2;
        };
        let tournament = Tournament {
            id: tournament_id,
            name,
            participants,
            brackets,
            winner: @0x0,
            is_active: true,
            created_at: timestamp::now_seconds(),
        };
        event::emit(TournamentCreated {
            tournament_id,
            creator: creator_addr,
            name,
        });
        move_to(creator, tournament);
    }
    public entry fun complete_match(
        tournament_owner: &signer,
        match_index: u64,
        winner: address
    ) acquires Tournament {
        let owner_addr = signer::address_of(tournament_owner);
        let tournament = borrow_global_mut<Tournament>(owner_addr);
        assert!(tournament.is_active, E_TOURNAMENT_NOT_ACTIVE);
        let match = vector::borrow_mut(&mut tournament.brackets, match_index);
        match.winner = winner;
        event::emit(MatchCompleted {
            tournament_id: tournament.id,
            winner,
            round: match.round,
        });        
        if (vector::length(&tournament.brackets) == 1) {
            tournament.winner = winner;
            tournament.is_active = false;
        };
    }
}
