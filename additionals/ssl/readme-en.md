# The Letter Between Two Companies

**Company A** wants to send an official letter to **Company B** in another city. But the road between the two cities isn't safe — couriers, intermediary carriers, whoever handles the route, can open any letter passing through, read it, even change it and reseal it. Company A knows this.

## Company A's Own Gate

Company A has a rule of its own: all official correspondence, before it leaves the city, goes through the company's own records control office. This office's seal is already introduced to employees — they trust it on sight. So every letter leaving Company A, including everything described below, passes through this office first.

## An Empty Handshake First

Company A doesn't send the actual letter directly. First it sends a **completely empty** note — just a short heads-up that something is about to be sent, no seal, no identity information at all. This note passes through the records office and reaches Company B. Company B replies the same way, with an empty note saying it's ready. At this point neither note carries any trust yet — they only confirm the road is open and both sides are there.

## Now Identities Come Into Play

Once the road is open, the real conversation begins. Company B sends its **seal, its notary chain, and its signature** to prove its identity. A seal is a mark anyone can be shown — but what actually presses it is different: a **die**, kept only by its owner, never handed off. Company B's signature was made with this die, which is why it can't be forged. But this package reaches the records office before it reaches Company A — everything already passes through there. The office looks at the seal: stamped by a **notary**, and that notary traces back to a higher authority it already recognizes. It checks the signature too — clearly made with the die, it matches. The office is now certain who Company B is.

The office reports this verification to Company A with its own seal — the seal Company A has trusted from the start. So Company A learns Company B's identity **not directly, but through the office's assurance**.

Most of the time this is enough. But sometimes, when two institutions are conducting official, sensitive business, Company B also asks for Company A's identity — and this happens the same way, verified and relayed by the office in between.

The top authority can't stamp seals for tens of thousands of companies on its own, so it delegates this to notaries — much like a brand granting authority to regional distributors. The workload spreads out, but the chain of trust never breaks.

## Two Separate Shared Keys

Company A now knows who Company B is — through the office's assurance. But verifying every letter with this heavy trust chain would be slow. Company A generates a random shared key and locks it with the office's seal — not Company B's, because the party Company A is actually talking to is now the office. Only the die at the office can open this key now. A courier along the way could see the package but couldn't open it, because the die is only at the office.

The office opens this key. Then, on its own, it repeats the same steps with Company B and agrees on a **separate shared key**. The result is two fast channels: one between Company A and the office, another between the office and Company B. The office sits in the middle, holding both.

## The Office's Own Job

This is exactly why the office can open every letter — it arrives over its own channel, encrypted with its own key. It can open the letter, see the request inside, and do its own work. Say Company A's letter contains a clause that needs prior approval. The office routes this on its own, over a new channel, to one or more relevant departments. It collects the replies, and passes the result it prepares along its own channel to Company B.

Sometimes the reply coming back from the final destination isn't just an "it arrived" confirmation — it's a real answer Company A is actually waiting for (say, "your offer is accepted, here's the signed contract"), and this reply comes back protected the same way, through both channels.

## A Difference From the Real World

Everything described so far closely resembles a real courier network. But it diverges at one point: a real courier can act independently after dropping off an envelope — go back and find Company A to say something else, or head to a third company.

Not in this system. Once Company A opens a "road," that road stays one-directional and fixed. Company B's reply always comes back along that same road, straight to Company A. Company B doesn't independently seek out Company A or open a new road of its own. The correspondence goes back and forth over a single opened channel.

---

This process runs in the background every time you visit a website — it's the mechanism behind the padlock icon in the address bar. And it all completes in a fraction of a second, without anyone noticing.