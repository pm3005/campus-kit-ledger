import { ethers } from "https://cdn.jsdelivr.net/npm/ethers@6.13.5/+esm";

// These signatures are the contract ABI needed by this small frontend.
const ABI = [
  "function custodian() view returns (address)",
  "function itemCount() view returns (uint256)",
  "function getItem(uint256) view returns (tuple(string name,uint8 status,address requester,address borrower))",
  "function addItem(string)",
  "function requestItem(uint256)",
  "function approveRequest(uint256)",
  "function markReturned(uint256)"
];

const $ = (id) => document.getElementById(id);
const states = ["Available", "Requested", "Borrowed"];
let provider, signer, contract, account, owner;

function status(text, error = false) {
  $("message").textContent = text;
  $("message").classList.toggle("error", error);
}

function short(address) {
  return `${address.slice(0, 6)}…${address.slice(-4)}`;
}

async function connect() {
  if (!window.ethereum) throw new Error("Install or enable MetaMask first.");
  provider = new ethers.BrowserProvider(window.ethereum);
  await provider.send("eth_requestAccounts", []);
  signer = await provider.getSigner();
  account = await signer.getAddress();
  const network = await provider.getNetwork();
  $("wallet").textContent = `${short(account)} connected on chain ${network.chainId}`;
  status(network.chainId === 1337n ? "Wallet connected to Ganache. Load your deployed contract." : "Wrong network. Click Switch to Ganache (chain 1337).");
  if (contract) await loadContract();
}

async function switchToGanache() {
  if (!window.ethereum) throw new Error("Install or enable MetaMask first.");
  try {
    await window.ethereum.request({ method: "wallet_switchEthereumChain", params: [{ chainId: "0x539" }] });
  } catch (error) {
    if (error.code !== 4902) throw error;
    await window.ethereum.request({
      method: "wallet_addEthereumChain",
      params: [{
        chainId: "0x539",
        chainName: "Ganache Local",
        rpcUrls: ["http://127.0.0.1:7545"],
        nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 }
      }]
    });
  }
  status("Ganache selected. Click Connect MetaMask, then Load contract.");
}

async function loadContract() {
  if (!signer) throw new Error("Connect MetaMask first.");
  const address = $("address").value.trim();
  if (!ethers.isAddress(address)) throw new Error("Enter a valid Ethereum contract address.");
  if ((await provider.getCode(address)) === "0x") throw new Error("No contract at that address on this network.");
  const candidate = new ethers.Contract(address, ABI, signer);
  const custodian = await candidate.custodian(); // Also verifies that this is our contract.
  contract = candidate;
  owner = custodian;
  localStorage.setItem("campusKitContract", address);
  const isOwner = account.toLowerCase() === owner.toLowerCase();
  $("admin").classList.toggle("hidden", !isOwner);
  $("role").textContent = isOwner ? "Your wallet is the custodian." : `Custodian: ${short(owner)}. Your wallet can request an available item.`;
  await refresh();
  status("Contract loaded. Equipment is read directly from the blockchain.");
}

async function refresh() {
  if (!contract) throw new Error("Load a contract first.");
  const count = Number(await contract.itemCount());
  const list = $("items");
  list.replaceChildren();
  if (count === 0) { list.textContent = "No items yet. The custodian can add one below."; return; }
  const isOwner = account.toLowerCase() === owner.toLowerCase();
  for (let id = 0; id < count; id++) {
    const item = await contract.getItem(id);
    const state = Number(item.status);
    const card = document.createElement("article");
    card.className = "card";
    const top = document.createElement("div");
    top.className = "card-top";
    const title = document.createElement("h3");
    title.textContent = `#${id} · ${item.name}`;
    const badge = document.createElement("span");
    badge.className = "badge";
    badge.textContent = states[state] ?? "Unknown";
    top.append(title, badge);
    const detail = document.createElement("p");
    detail.textContent = state === 1 ? `Requested by ${short(item.requester)}` : state === 2 ? `Borrowed by ${short(item.borrower)}` : "Ready to request";
    card.append(top, detail);
    let action, label;
    if (state === 0 && !isOwner) { action = "requestItem"; label = "Request item"; }
    if (state === 1 && isOwner) { action = "approveRequest"; label = "Approve request"; }
    if (state === 2 && isOwner) { action = "markReturned"; label = "Confirm physical return"; }
    if (action) {
      const button = document.createElement("button");
      button.textContent = label;
      button.addEventListener("click", () => runTransaction(() => contract[action](id)));
      card.append(button);
    }
    list.append(card);
  }
}

async function runTransaction(send) {
  try {
    status("Confirm the transaction in MetaMask…");
    const tx = await send();
    status(`Transaction sent: ${tx.hash}. Waiting for confirmation…`);
    const receipt = await tx.wait();
    if (receipt.status !== 1) throw new Error("Transaction failed on-chain.");
    await refresh();
    status(`Confirmed in block ${receipt.blockNumber}. Transaction: ${tx.hash}`);
  } catch (error) { status(error.shortMessage || error.reason || error.message, true); }
}

$("connect").addEventListener("click", async () => {
  try { await connect(); } catch (error) { status(error.shortMessage || error.message, true); }
});
$("switch-network").addEventListener("click", async () => {
  try { await switchToGanache(); } catch (error) { status(error.shortMessage || error.message, true); }
});
$("load").addEventListener("click", async () => {
  try { await loadContract(); } catch (error) { status(error.shortMessage || error.message, true); }
});
$("refresh").addEventListener("click", async () => {
  try { await refresh(); status("Blockchain data refreshed."); } catch (error) { status(error.shortMessage || error.message, true); }
});
$("add-form").addEventListener("submit", (event) => {
  event.preventDefault();
  const name = $("item-name").value.trim();
  if (!name || new TextEncoder().encode(name).length > 64) { status("Name must be 1-64 UTF-8 bytes.", true); return; }
  runTransaction(async () => {
    const tx = await contract.addItem(name);
    $("item-name").value = "";
    return tx;
  });
});
$("address").value = localStorage.getItem("campusKitContract") || "";
if (window.ethereum) {
  window.ethereum.on("accountsChanged", () => location.reload());
  window.ethereum.on("chainChanged", () => location.reload());
}
