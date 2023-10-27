## Perpetual 

Protocol developed during Advanced Web3 Security Course - Mission 1.

Liquidity is used in regards to collateral.

### How does the system work? How would a user interact with it?

The Perpetuals consists of 3 main contracts:
 - Liquidity Provider - managing of liquidity
 - PositionManager - managing of positions
 - Perpetuals - entry point


#### LiquidityProvider
1. User deposits liqudity
2. User can withdraw liquidity
3. Pepr can lock liqudity for a user
4. Perp can unlock liqudity for a user

#### PositionManager
1. User open position
2. User can increase the position size
3. User can increase liquidity for the postition
4. User can close position
5. If the postition is insolvent it can be liquidated


#### Actors
- Liquidity providers - users can provide liquidity(collateral) to protocol to open position against
- Users can open postions and manage them
- Keeper/Any user can liqudidate the insolvent loan
- Any pertinent formulas used.


#### Known issues
- No way for lovering the collateral/size in the position
- No real swaps to BTC/USDC