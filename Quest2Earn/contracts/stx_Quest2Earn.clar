;; Play-to-Earn Adventure Game Smart Contract
;; A comprehensive blockchain-based RPG with quests, battles, NFTs, and token rewards

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INSUFFICIENT-ENERGY (err u103))
(define-constant ERR-INSUFFICIENT-TOKENS (err u104))
(define-constant ERR-INVALID-LEVEL (err u105))
(define-constant ERR-QUEST-NOT-AVAILABLE (err u106))
(define-constant ERR-QUEST-ALREADY-COMPLETED (err u107))
(define-constant ERR-BATTLE-COOLDOWN (err u108))
(define-constant ERR-INSUFFICIENT-STATS (err u109))
(define-constant ERR-INVALID-ITEM (err u110))

;; Game Token (Adventure Coins - ADV)
(define-fungible-token adventure-coins)

;; NFT for unique items/equipment
(define-non-fungible-token game-items uint)

;; Data Variables
(define-data-var next-character-id uint u1)
(define-data-var next-quest-id uint u1)
(define-data-var next-item-id uint u1)
(define-data-var token-mint-rate uint u100) ;; tokens per quest completion
(define-data-var energy-regen-time uint u144) ;; blocks for full energy regen (~24 hours)

;; Character Classes
(define-constant CLASS-WARRIOR u1)
(define-constant CLASS-MAGE u2)
(define-constant CLASS-RANGER u3)
(define-constant CLASS-ROGUE u4)

;; Item Types
(define-constant ITEM-WEAPON u1)
(define-constant ITEM-ARMOR u2)
(define-constant ITEM-ACCESSORY u3)
(define-constant ITEM-CONSUMABLE u4)

;; Character Structure
(define-map characters
    { character-id: uint }
    {
        owner: principal,
        name: (string-ascii 32),
        class: uint,
        level: uint,
        experience: uint,
        health: uint,
        max-health: uint,
        energy: uint,
        max-energy: uint,
        attack: uint,
        defense: uint,
        magic: uint,
        agility: uint,
        last-energy-update: uint,
        equipped-weapon: (optional uint),
        equipped-armor: (optional uint),
        equipped-accessory: (optional uint),
        total-quests-completed: uint,
        total-battles-won: uint,
        creation-time: uint
    }
)

;; Player's characters list
(define-map player-characters
    { player: principal }
    { character-ids: (list 10 uint) }
)

;; Quest Structure
(define-map quests
    { quest-id: uint }
    {
        name: (string-ascii 64),
        description: (string-ascii 256),
        required-level: uint,
        energy-cost: uint,
        base-experience-reward: uint,
        base-token-reward: uint,
        required-class: (optional uint),
        completion-time: uint, ;; blocks to complete
        is-active: bool,
        max-completions: (optional uint)
    }
)

;; Quest Progress
(define-map character-quest-progress
    { character-id: uint, quest-id: uint }
    {
        started-at: uint,
        completed-at: (optional uint),
        completion-count: uint
    }
)

;; Items/Equipment Structure
(define-map game-item-data
    { item-id: uint }
    {
        name: (string-ascii 32),
        item-type: uint,
        rarity: uint, ;; 1=common, 2=uncommon, 3=rare, 4=epic, 5=legendary
        attack-bonus: uint,
        defense-bonus: uint,
        magic-bonus: uint,
        agility-bonus: uint,
        health-bonus: uint,
        required-level: uint,
        is-consumable: bool,
        creator: principal,
        creation-time: uint
    }
)

;; Battle System
(define-map battle-history
    { battle-id: uint }
    {
        attacker-id: uint,
        defender-id: uint,
        winner-id: uint,
        battle-time: uint,
        experience-gained: uint,
        tokens-gained: uint
    }
)

;; Battle cooldowns
(define-map character-battle-cooldown
    { character-id: uint }
    { last-battle: uint }
)

;; Marketplace for items
(define-map item-marketplace
    { item-id: uint }
    {
        seller: principal,
        price: uint,
        listed-at: uint,
        is-active: bool
    }
)

;; Random seed for battle outcomes
(define-data-var battle-seed uint u1)

;; Helper function: min of two uints
(define-private (min-uint (a uint) (b uint))
    (if (<= a b) a b)
)

;; Read-only functions

;; Get character details
(define-read-only (get-character (character-id uint))
    (map-get? characters { character-id: character-id })
)

;; Get player's characters
(define-read-only (get-player-characters (player principal))
    (map-get? player-characters { player: player })
)

;; Get quest details
(define-read-only (get-quest (quest-id uint))
    (map-get? quests { quest-id: quest-id })
)

;; Get quest progress
(define-read-only (get-quest-progress (character-id uint) (quest-id uint))
    (map-get? character-quest-progress { character-id: character-id, quest-id: quest-id })
)

;; Get item details
(define-read-only (get-item (item-id uint))
    (map-get? game-item-data { item-id: item-id })
)

;; Calculate experience needed for next level
(define-read-only (experience-for-level (level uint))
    (* level (* level u10)) ;; Quadratic scaling
)

;; Calculate current energy (with regeneration)
(define-read-only (calculate-current-energy (character-id uint))
    (match (map-get? characters { character-id: character-id })
        character-data
        (let (
            (time-passed (- stacks-block-height (get last-energy-update character-data)))
            (max-energy (get max-energy character-data))
            (current-energy (get energy character-data))
            (energy-per-block (/ max-energy (var-get energy-regen-time)))
            (regenerated-energy (min-uint max-energy (+ current-energy (* time-passed energy-per-block))))
        )
            regenerated-energy
        )
        u0
    )
)

;; Check if quest is available for character
(define-read-only (is-quest-available (character-id uint) (quest-id uint))
    (match (map-get? characters { character-id: character-id })
        character-data
        (match (map-get? quests { quest-id: quest-id })
            quest-data
            (and
                (get is-active quest-data)
                (>= (get level character-data) (get required-level quest-data))
                (match (get required-class quest-data)
                    required-class (is-eq (get class character-data) required-class)
                    true
                )
                (>= (calculate-current-energy character-id) (get energy-cost quest-data))
            )
            false
        )
        false
    )
)

;; Calculate battle power
(define-read-only (calculate-battle-power (character-id uint))
    (match (map-get? characters { character-id: character-id })
        character-data
        (+ 
            (get attack character-data)
            (get defense character-data)
            (get magic character-data)
            (get agility character-data)
            (* (get level character-data) u5)
        )
        u0
    )
)

;; Public functions

;; Create a new character
(define-public (create-character 
    (name (string-ascii 32))
    (class uint)
)
    (let (
        (character-id (var-get next-character-id))
        (base-stats (get-class-base-stats class))
    )
        ;; Validate class
        (asserts! (and (>= class u1) (<= class u4)) ERR-INVALID-LEVEL)
        
        ;; Create character
        (map-set characters
            { character-id: character-id }
            {
                owner: tx-sender,
                name: name,
                class: class,
                level: u1,
                experience: u0,
                health: (get max-health base-stats),
                max-health: (get max-health base-stats),
                energy: (get max-energy base-stats),
                max-energy: (get max-energy base-stats),
                attack: (get attack base-stats),
                defense: (get defense base-stats),
                magic: (get magic base-stats),
                agility: (get agility base-stats),
                last-energy-update: stacks-block-height,
                equipped-weapon: none,
                equipped-armor: none,
                equipped-accessory: none,
                total-quests-completed: u0,
                total-battles-won: u0,
                creation-time: stacks-block-height
            }
        )
        
        ;; Add to player's character list
        (match (map-get? player-characters { player: tx-sender })
            existing-chars
            (map-set player-characters
                { player: tx-sender }
                { character-ids: (unwrap-panic (as-max-len? 
                    (append (get character-ids existing-chars) character-id) u10)) }
            )
            (map-set player-characters
                { player: tx-sender }
                { character-ids: (list character-id) }
            )
        )
        
        ;; Increment character counter
        (var-set next-character-id (+ character-id u1))
        
        (ok character-id)
    )
)

;; Helper function for class base stats
(define-private (get-class-base-stats (class uint))
    (if (is-eq class CLASS-WARRIOR)
        { max-health: u120, max-energy: u80, attack: u15, defense: u12, magic: u5, agility: u8 }
        (if (is-eq class CLASS-MAGE)
            { max-health: u80, max-energy: u120, attack: u8, defense: u6, magic: u18, agility: u8 }
            (if (is-eq class CLASS-RANGER)
                { max-health: u100, max-energy: u100, attack: u12, defense: u8, magic: u10, agility: u15 }
                ;; ROGUE
                { max-health: u90, max-energy: u110, attack: u14, defense: u7, magic: u8, agility: u16 }
            )
        )
    )
)

;; Create a new quest (admin only)
(define-public (create-quest
    (name (string-ascii 64))
    (description (string-ascii 256))
    (required-level uint)
    (energy-cost uint)
    (base-experience-reward uint)
    (base-token-reward uint)
    (required-class (optional uint))
    (completion-time uint)
    (max-completions (optional uint))
)
    (let ((quest-id (var-get next-quest-id)))
        ;; Only contract owner can create quests
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        
        ;; Create quest
        (map-set quests
            { quest-id: quest-id }
            {
                name: name,
                description: description,
                required-level: required-level,
                energy-cost: energy-cost,
                base-experience-reward: base-experience-reward,
                base-token-reward: base-token-reward,
                required-class: required-class,
                completion-time: completion-time,
                is-active: true,
                max-completions: max-completions
            }
        )
        
        ;; Increment quest counter
        (var-set next-quest-id (+ quest-id u1))
        
        (ok quest-id)
    )
)

;; Start a quest
(define-public (start-quest (character-id uint) (quest-id uint))
    (let (
        (character-data (unwrap! (map-get? characters { character-id: character-id }) ERR-NOT-FOUND))
        (quest-data (unwrap! (map-get? quests { quest-id: quest-id }) ERR-NOT-FOUND))
        (current-energy (calculate-current-energy character-id))
    )
        ;; Verify ownership
        (asserts! (is-eq tx-sender (get owner character-data)) ERR-NOT-AUTHORIZED)
        
        ;; Check if quest is available
        (asserts! (is-quest-available character-id quest-id) ERR-QUEST-NOT-AVAILABLE)
        
        ;; Check if already in progress
        (asserts! (is-none (map-get? character-quest-progress 
            { character-id: character-id, quest-id: quest-id })) ERR-ALREADY-EXISTS)
        
        ;; Deduct energy
        (map-set characters
            { character-id: character-id }
            (merge character-data {
                energy: (- current-energy (get energy-cost quest-data)),
                last-energy-update: stacks-block-height
            })
        )
        
        ;; Start quest progress
        (map-set character-quest-progress
            { character-id: character-id, quest-id: quest-id }
            {
                started-at: stacks-block-height,
                completed-at: none,
                completion-count: u0
            }
        )
        
        (ok true)
    )
)

;; Complete a quest
(define-public (complete-quest (character-id uint) (quest-id uint))
    (let (
        (character-data (unwrap! (map-get? characters { character-id: character-id }) ERR-NOT-FOUND))
        (quest-data (unwrap! (map-get? quests { quest-id: quest-id }) ERR-NOT-FOUND))
        (progress-data (unwrap! (map-get? character-quest-progress 
            { character-id: character-id, quest-id: quest-id }) ERR-NOT-FOUND))
    )
        ;; Verify ownership
        (asserts! (is-eq tx-sender (get owner character-data)) ERR-NOT-AUTHORIZED)
        
        ;; Check if quest is not already completed
        (asserts! (is-none (get completed-at progress-data)) ERR-QUEST-ALREADY-COMPLETED)
        
        ;; Check if enough time has passed
        (asserts! (>= (- stacks-block-height (get started-at progress-data)) 
                     (get completion-time quest-data)) ERR-QUEST-NOT-AVAILABLE)
        
        ;; Calculate rewards
        (let (
            (experience-reward (+ (get base-experience-reward quest-data) 
                                (* (get level character-data) u5)))
            (token-reward (+ (get base-token-reward quest-data) 
                           (* (get level character-data) u10)))
            (new-experience (+ (get experience character-data) experience-reward))
            (new-level (calculate-level-from-experience new-experience))
        )
            ;; Update character progress
            (map-set characters
                { character-id: character-id }
                (merge character-data {
                    experience: new-experience,
                    level: new-level,
                    total-quests-completed: (+ (get total-quests-completed character-data) u1)
                })
            )
            
            ;; Mark quest as completed
            (map-set character-quest-progress
                { character-id: character-id, quest-id: quest-id }
                (merge progress-data {
                    completed-at: (some stacks-block-height),
                    completion-count: (+ (get completion-count progress-data) u1)
                })
            )
            
            ;; Mint reward tokens
            (unwrap! (ft-mint? adventure-coins token-reward tx-sender) ERR-INSUFFICIENT-TOKENS)
            
            ;; Level up bonuses if leveled up
            (if (> new-level (get level character-data))
                (level-up-character character-id new-level)
                (ok true)
            )
        )
    )
)

;; Level up character (internal)
(define-private (level-up-character (character-id uint) (new-level uint))
    (let ((character-data (unwrap-panic (map-get? characters { character-id: character-id }))))
        (map-set characters
            { character-id: character-id }
            (merge character-data {
                max-health: (+ (get max-health character-data) u10),
                max-energy: (+ (get max-energy character-data) u5),
                attack: (+ (get attack character-data) u2),
                defense: (+ (get defense character-data) u2),
                magic: (+ (get magic character-data) u1),
                agility: (+ (get agility character-data) u1),
                health: (+ (get health character-data) u10) ;; Heal on level up
            })
        )
        (ok true)
    )
)

;; Calculate level from experience
(define-private (calculate-level-from-experience (experience uint))
    (if (<= experience u100) u1
        (if (<= experience u400) u2
            (if (<= experience u900) u3
                (if (<= experience u1600) u4
                    (if (<= experience u2500) u5
                        ;; For higher levels, use approximation
                        (+ u5 (/ (- experience u2500) u500))
                    )
                )
            )
        )
    )
)

;; Battle another character
(define-public (battle-character (attacker-id uint) (defender-id uint))
    (let (
        (attacker-data (unwrap! (map-get? characters { character-id: attacker-id }) ERR-NOT-FOUND))
        (defender-data (unwrap! (map-get? characters { character-id: defender-id }) ERR-NOT-FOUND))
        (battle-cooldown (map-get? character-battle-cooldown { character-id: attacker-id }))
    )
        ;; Verify ownership of attacker
        (asserts! (is-eq tx-sender (get owner attacker-data)) ERR-NOT-AUTHORIZED)
        
        ;; Check battle cooldown (1 hour = ~6 blocks)
        (asserts! (match battle-cooldown
            cooldown-data (>= (- stacks-block-height (get last-battle cooldown-data)) u6)
            true
        ) ERR-BATTLE-COOLDOWN)
        
        ;; Calculate battle outcome
        (let (
            (attacker-power (calculate-battle-power attacker-id))
            (defender-power (calculate-battle-power defender-id))
            (random-factor (mod (+ (var-get battle-seed) stacks-block-height) u100))
            (attacker-wins (> (+ attacker-power random-factor) defender-power))
            (winner-id (if attacker-wins attacker-id defender-id))
            (experience-gain (if attacker-wins u50 u20))
            (token-gain (if attacker-wins u25 u10))
        )
            ;; Update battle seed for next battle
            (var-set battle-seed (+ (var-get battle-seed) u1))
            
            ;; Set battle cooldown
            (map-set character-battle-cooldown
                { character-id: attacker-id }
                { last-battle: stacks-block-height }
            )
            
            ;; Update winner's stats
            (if attacker-wins
                (map-set characters
                    { character-id: attacker-id }
                    (merge attacker-data {
                        experience: (+ (get experience attacker-data) experience-gain),
                        total-battles-won: (+ (get total-battles-won attacker-data) u1)
                    })
                )
                (map-set characters
                    { character-id: defender-id }
                    (merge defender-data {
                        experience: (+ (get experience defender-data) experience-gain),
                        total-battles-won: (+ (get total-battles-won defender-data) u1)
                    })
                )
            )
            
            ;; Mint tokens for attacker (participation reward)
            (unwrap! (ft-mint? adventure-coins token-gain tx-sender) ERR-INSUFFICIENT-TOKENS)
            
            (ok { winner: winner-id, experience-gained: experience-gain, tokens-gained: token-gain })
        )
    )
)

;; Create a new item/equipment (for rewards or crafting)
(define-public (create-item
    (name (string-ascii 32))
    (item-type uint)
    (rarity uint)
    (attack-bonus uint)
    (defense-bonus uint)
    (magic-bonus uint)
    (agility-bonus uint)
    (health-bonus uint)
    (required-level uint)
    (is-consumable bool)
    (recipient principal)
)
    (let ((item-id (var-get next-item-id)))
        ;; Only contract owner can create items (for now)
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        
        ;; Create item data
        (map-set game-item-data
            { item-id: item-id }
            {
                name: name,
                item-type: item-type,
                rarity: rarity,
                attack-bonus: attack-bonus,
                defense-bonus: defense-bonus,
                magic-bonus: magic-bonus,
                agility-bonus: agility-bonus,
                health-bonus: health-bonus,
                required-level: required-level,
                is-consumable: is-consumable,
                creator: tx-sender,
                creation-time: stacks-block-height
            }
        )
        
        ;; Mint NFT to recipient
        (unwrap! (nft-mint? game-items item-id recipient) ERR-INVALID-ITEM)
        
        ;; Increment item counter
        (var-set next-item-id (+ item-id u1))
        
        (ok item-id)
    )
)

;; Equip an item
(define-public (equip-item (character-id uint) (item-id uint))
    (let (
        (character-data (unwrap! (map-get? characters { character-id: character-id }) ERR-NOT-FOUND))
        (item-data (unwrap! (map-get? game-item-data { item-id: item-id }) ERR-NOT-FOUND))
        (item-owner (unwrap! (nft-get-owner? game-items item-id) ERR-NOT-FOUND))
    )
        ;; Verify character ownership
        (asserts! (is-eq tx-sender (get owner character-data)) ERR-NOT-AUTHORIZED)
        
        ;; Verify item ownership
        (asserts! (is-eq tx-sender item-owner) ERR-NOT-AUTHORIZED)
        
        ;; Check level requirement
        (asserts! (>= (get level character-data) (get required-level item-data)) ERR-INSUFFICIENT-STATS)
        
        ;; Update character based on item type
        (let ((updated-character
            (if (is-eq (get item-type item-data) ITEM-WEAPON)
                (merge character-data { equipped-weapon: (some item-id) })
                (if (is-eq (get item-type item-data) ITEM-ARMOR)
                    (merge character-data { equipped-armor: (some item-id) })
                    (if (is-eq (get item-type item-data) ITEM-ACCESSORY)
                        (merge character-data { equipped-accessory: (some item-id) })
                        character-data
                    )
                )
            )))
            (map-set characters { character-id: character-id } updated-character)
            (ok true)
        )
    )
)

;; Rest to restore energy (costs tokens)
(define-public (rest-character (character-id uint))
    (let (
        (character-data (unwrap! (map-get? characters { character-id: character-id }) ERR-NOT-FOUND))
        (rest-cost u50) ;; Cost in adventure coins
    )
        ;; Verify ownership
        (asserts! (is-eq tx-sender (get owner character-data)) ERR-NOT-AUTHORIZED)
        
        ;; Check token balance and burn cost
        (unwrap! (ft-burn? adventure-coins rest-cost tx-sender) ERR-INSUFFICIENT-TOKENS)
        
        ;; Restore full energy
        (map-set characters
            { character-id: character-id }
            (merge character-data {
                energy: (get max-energy character-data),
                health: (get max-health character-data),
                last-energy-update: stacks-block-height
            })
        )
        
        (ok true)
    )
)

;; Get adventure coin balance
(define-read-only (get-token-balance (account principal))
    (ft-get-balance adventure-coins account)
)

;; Transfer adventure coins
(define-public (transfer-tokens (amount uint) (recipient principal))
    (ft-transfer? adventure-coins amount tx-sender recipient)
)