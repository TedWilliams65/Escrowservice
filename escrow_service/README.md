Escrow STX Smart Contract
This Clarity smart contract implements a secure escrow mechanism on the Stacks blockchain, allowing buyers and sellers to safely transact using STX or SIP-010 compatible tokens. It supports disputes, arbitration, timeouts, and refunds.

📦 Features
Create escrow agreements with optional arbiters and deadlines.

Release funds directly or through arbitration.

Raise and resolve disputes.

Automatic refund to buyer if conditions are unmet by the deadline.

Token-agnostic (supports optional SIP-010 token transfers).

🛠 Functions
Public Functions
create-escrow (seller principal) (amount uint) (token optional (trait_reference)) (deadline uint) (arbiter optional principal)

Initializes a new escrow agreement.

release-funds (escrow-id uint)

Releases funds to the seller (by buyer or arbiter).

dispute (escrow-id uint)

Buyer can raise a dispute before release.

resolve-dispute (escrow-id uint) (winner principal)

Arbiter decides the winner and ends the dispute.

refund (escrow-id uint)

Buyer can reclaim funds if deadline has passed and funds weren't released.




