# Deployment and actual observations

Recorded from the real Remix, Ganache, MetaMask, and UI session. Pending fields have not been observed.

| Field | Value |
| --- | --- |
| Network name | Ganache local (`http://127.0.0.1:7545` via Remix External HTTP Provider) |
| Chain ID | 1337 (shown in Remix during deployment) |
| Compiler version | Solidity 0.8.x, EVM London (exact patch version not recorded) |
| Custodian address | `0xfF527aD658052EE4816f41633F9871957e34B28F` |
| Contract address | `0x15E3e4d371BBbf45A95Cc7833C2fB1b01a585C19` |
| Deployment transaction hash | Not captured from Remix |
| Successful add-item transaction hash | `0xdf62c7fbdc7339962240ed9662bef338b477c3042655979bdd02cde00265ad1d` (camera, confirmed in block 3) |
| Successful approval transaction hash | Not run in live UI session; covered by Remix unit tests |
| Successful return transaction hash | Not run in live UI session; covered by Remix unit tests |
| Failed/unauthorized input and actual error | Seven validation/authorization unit tests passed in Remix; live failed-action screenshot pending |
| Remix unit test result and date | 7 passed, 0 failed; observed in Remix on 2026-10-22 (`evidence/07-unit-tests.png`) |

## Screenshot filenames

Actual screenshots under `evidence/`: `01-compile.png`, `02-deploy.png`, `03-metamask-ganache.png` (MetaMask transaction request on Ganache), `04-ui-success.png` (confirmed add-item transaction and blockchain item displayed), and `07-unit-tests.png` (7 passed, 0 failed). A live failed-action screenshot is still pending.

If a wallet screen reveals any sensitive material, crop or redact it before committing. Addresses and transaction hashes are public; seed phrases and private keys are secret.
