# Explain this project in two minutes

**Problem:** A lab lending equipment needs a visible record of what is available and who has checked out an item.

**Actors:** One MetaMask wallet is the custodian because it deployed the contract. Other wallets act as students.

**Flow:** The custodian adds `Camera tripod`. A student requests item `#0`. The custodian approves it, which stores the student's wallet as borrower. When the student physically returns it, the custodian marks the item Available again. The UI reads each item from the contract and shows the wallet's permitted button.

**Contract in plain language:** `constructor` saves the custodian address. `Item` contains a name, status, requester, and borrower. `onlyCustodian` blocks student wallets from privileged actions. `require` rejects invalid names, nonexistent IDs, and incorrect state transitions. Events describe successful changes. `itemCount` and `getItem` return blockchain data without sending a transaction.

**Frontend in plain language:** Ethers.js talks to the MetaMask provider. `eth_requestAccounts` prompts for a wallet connection. Read functions fetch state. Write functions open a MetaMask confirmation, then the UI waits for the transaction receipt and refreshes. The custodian sees add, approve, and return actions; a student sees request.

**Example invalid/unauthorized cases:** Empty item name fails validation. A second request while an item is Requested fails the state check. A student trying to approve fails `onlyCustodian`.

**Limitations to say honestly:** This contract records wallet addresses, not verified campus identities or proof of physical handover. It handles one request per item at a time and has no cancellation; a pending request requires a future improvement to clear it. Gas is paid in test ETH on Ganache/testnet. The UI is a frontend to on-chain state, not a database.
