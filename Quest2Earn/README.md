# 🎮 Play-to-Earn Adventure Game Smart Contract

A comprehensive blockchain-based RPG built on the Stacks blockchain featuring character creation, quests, battles, NFT equipment, and token rewards.

## 🌟 Features

### Core Gameplay
- **Multiple Character Classes**: Warrior, Mage, Ranger, and Rogue with unique base stats
- **Leveling System**: Experience-based progression with quadratic scaling
- **Energy System**: Time-based energy regeneration for quest participation
- **Quest System**: Timed quests with level and class requirements
- **PvP Battles**: Character vs character combat with cooldowns
- **Equipment System**: NFT-based weapons, armor, and accessories

### Economic Features
- **Adventure Coins (ADV)**: Native fungible token for in-game economy
- **Play-to-Earn**: Earn tokens through quest completion and battles
- **NFT Equipment**: Unique items with different rarities and stat bonuses
- **Token Utilities**: Rest mechanics, item trading, and more

## 🏗️ Smart Contract Architecture

### Token Standards
- **Fungible Token**: Adventure Coins (ADV) - SIP-010 compliant
- **Non-Fungible Token**: Game Items/Equipment - SIP-009 compliant

### Core Data Structures

#### Characters
- Unique character progression with stats, equipment, and history
- Energy regeneration system (144 blocks ≈ 24 hours for full regen)
- Equipment slots for weapons, armor, and accessories

#### Quests
- Configurable requirements (level, class, energy cost)
- Timed completion mechanics
- Scalable rewards based on character level

#### Items/Equipment
- 5 rarity tiers (Common to Legendary)
- Stat bonuses for attack, defense, magic, agility, and health
- Level requirements for equipment

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) for local development
- Stacks wallet for mainnet/testnet deployment

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd adventure-game-contract
```

2. Initialize Clarinet project:
```bash
clarinet new adventure-game
cd adventure-game
```

3. Add the contract to your `Clarinet.toml`:
```toml
[contracts.adventure-game]
path = "contracts/adventure-game.clar"
depends_on = []
```

4. Test the contract:
```bash
clarinet test
```

## 📋 Contract Functions

### Character Management

#### `create-character`
Create a new character with specified name and class.

```clarity
(create-character "Hero Name" u1) ;; u1 = Warrior class
```

**Classes:**
- `u1` - Warrior (High health, attack, defense)
- `u2` - Mage (High magic, energy)
- `u3` - Ranger (Balanced stats, high agility)
- `u4` - Rogue (High agility, moderate attack)

#### `rest-character`
Restore character's energy and health for 50 Adventure Coins.

```clarity
(rest-character u1) ;; Character ID 1
```

### Quest System

#### `start-quest`
Begin a quest with specified character.

```clarity
(start-quest u1 u1) ;; Character ID 1, Quest ID 1
```

#### `complete-quest`
Complete a started quest and claim rewards.

```clarity
(complete-quest u1 u1) ;; Character ID 1, Quest ID 1
```

### Battle System

#### `battle-character`
Challenge another character to PvP combat.

```clarity
(battle-character u1 u2) ;; Attacker ID 1 vs Defender ID 2
```

**Battle Mechanics:**
- 1-hour cooldown between battles (≈6 blocks)
- Power calculation includes all stats + level bonus
- Random factor influences outcome
- Both participants gain experience

### Equipment System

#### `equip-item`
Equip an owned NFT item to a character.

```clarity
(equip-item u1 u1) ;; Character ID 1, Item ID 1
```

**Item Types:**
- `u1` - Weapon (equipped to weapon slot)
- `u2` - Armor (equipped to armor slot)
- `u3` - Accessory (equipped to accessory slot)
- `u4` - Consumable (single-use items)

### Read-Only Functions

#### Character Information
```clarity
(get-character u1) ;; Get character details
(get-player-characters 'SP1234...) ;; Get player's character list
(calculate-current-energy u1) ;; Get current energy with regeneration
```

#### Quest Information
```clarity
(get-quest u1) ;; Get quest details
(is-quest-available u1 u1) ;; Check if character can start quest
(get-quest-progress u1 u1) ;; Get quest progress
```

#### Item Information
```clarity
(get-item u1) ;; Get item details
(get-token-balance 'SP1234...) ;; Get Adventure Coins balance
```

## 🎯 Game Balance

### Character Progression
- **Level 1-5**: Fast progression with fixed experience thresholds
- **Level 6+**: Linear scaling (500 XP per level)
- **Stat Growth**: +10 HP, +5 Energy, +2 Attack/Defense, +1 Magic/Agility per level

### Energy System
- **Regeneration**: Full energy restored every 144 blocks (≈24 hours)
- **Quest Costs**: Varies by quest difficulty
- **Rest Option**: Instant full restore for 50 Adventure Coins

### Token Economy
- **Quest Rewards**: Base reward + (level × 10) Adventure Coins
- **Battle Rewards**: 25 coins for winner, 10 for participation
- **Token Utilities**: Rest, future marketplace, upgrades

## 🛡️ Security Features

- **Ownership Verification**: All actions require character ownership
- **Cooldown Systems**: Prevents battle spam and energy abuse
- **Level Requirements**: Equipment and quest gating
- **Admin Controls**: Quest and item creation restricted to contract owner

## 🧪 Testing

### Unit Tests
Create comprehensive tests for:
- Character creation and progression
- Quest mechanics and timing
- Battle outcomes and cooldowns
- Equipment system and stat bonuses
- Token minting and burning

### Integration Tests
- Full gameplay loops
- Economic balance testing
- Edge cases and error handling

## 📈 Future Enhancements

### Planned Features
- **Guilds/Clans**: Social gameplay elements
- **Crafting System**: Create equipment from materials
- **Marketplace**: Player-to-player item trading
- **Tournaments**: Organized PvP events
- **Land/Territory**: Strategic resource control
- **Breeding/Pets**: Companion creatures

### Technical Improvements
- **Gas Optimization**: Reduce transaction costs
- **Batch Operations**: Multiple actions per transaction
- **Oracle Integration**: External randomness source
- **Cross-chain Bridge**: Multi-blockchain support

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Clarity best practices
- Add comprehensive tests for new features
- Update documentation for contract changes
- Consider gas costs and optimization

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)
- [Clarinet Development Tool](https://github.com/hirosystems/clarinet)

## 📞 Support

- Create an issue for bug reports
- Join our Discord community for discussions
- Follow development updates on Twitter

---

**Built with ❤️ on Stacks Blockchain**