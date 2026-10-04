--[[
	Every readable text in Story 1. A note part in the map carries a NoteId
	attribute that matches a key here.

	Three layers, per the direction doc:
	  Cornelius   catalogue cards: WHAT each object is and how it behaves
	  First crew  voice memos: WHAT WENT WRONG (rules taught by mistakes)
	  The dead    memos only readable while the Banshee mourns there

	The auction house and every name here are invented. Keep it that way:
	no real people, brands or places' logos.
]]

export type Note = {
	title: string,
	body: string,
}

local Notes: { [string]: Note } = {
	Manifest = {
		title = "Retrieval manifest, crew 2",
		body = [[PELLAM & SLOANE, AUCTIONEERS
Estate of C. Ashgrove. Retrieval, second attempt.

Crew 1 (Okafor, Pruitt, Wren) lost contact on night one. Find them. Then finish the job.

LOT 114  Spine whip, in tack case. Portrait gallery.
LOT 203  Hollow lantern. Servants' wing, scullery.
LOT 077  Silver comb. Servants' wing. CASE FOUND EMPTY. Do not search for it.
LOT 001  Wine cabinet ("the sealed box"). Cellar vault. SEALED. Do not open.

Secure each lot in a warded crate where you find it. Crates are on site.
Read Mr Ashgrove's catalogue cards before you touch anything.]],
	},

	Card_Dullahan = {
		title = "Catalogue card: Lot 114",
		body = [[THE RIDER'S WHIP. West of Ireland. Bought 1991.

The whip is a spine. He came with it.

He carries his own head and sees only what the head is facing. Stand where it is not looking and he will walk past you.

He kills from the length of the whip, not from arm's reach.

Gold. Any gold. Hold it up where the head can see it and he will not come near. It will not stop him for long.

- C.A.]],
	},

	Card_Lampshy = {
		title = "Catalogue card: Lot 203",
		body = [[THE HOLLOW LANTERN. From a mining family's estate. Bought 1987.

The thing that came with it lives in the dark and feeds there. It will not move while a light is on it. Not an inch.

It moves the moment the light leaves it.

Never trim the wick and look away at the same time.

- C.A.]],
	},

	Card_Banshee = {
		title = "Catalogue card: Lot 077",
		body = [[THE COMB. Silver, Irish. Eighteenth century.

Listed for completeness. The comb is not in its case and I no longer look for it.

She came with it, or it came with her.

She does not hunt. She keens before a death and grieves after one. If she keens near you, something must die, or you must leave.

The servants kept the old customs. The housekeeper's book has them.

- C.A.]],
	},

	Card_Gold = {
		title = "Catalogue card: pocket piece",
		body = [[GOLD SOVEREIGN. Not for sale. My own.

I carry it into the gallery. Raise it where the head can see it.

- C.A.]],
	},

	Memo_Hall = {
		title = "Voice memo: Okafor (crew 1)",
		body = [["Night one. Generator's running, so we've got the lamp in the hall. Nothing's coming in here. Hall's fine.

Case 114 in the gallery is empty. The whip's at the far end on the floor. Pruitt says something's walking down there.

Nobody goes in without a light. Nobody goes in alone."]],
	},

	Memo_Gallery = {
		title = "Voice memo: Pruitt (crew 1)",
		body = [["It doesn't look at you. The head does. It carries the head, and the head's what sees.

If the head's turned away you can walk right past it.

I put two in its chest and it didn't care. It cared when I hit the head. It dropped it. It went feeling around on the floor like a man who's lost his glasses.

Then it found it again."]],
	},

	Memo_Kitchen = {
		title = "Voice memo: Wren (crew 1), whispering",
		body = [["She's in the kitchen with Okafor. She isn't doing anything. She's just... crying over him.

The lantern thing came out of the scullery when Okafor's torch died. I got my light on it and it stopped dead. Didn't even twitch. Then Okafor went to reload and it was on him.

She was wailing before it happened. Before. Like she knew.

I'm going for the van."]],
	},

	Customs = {
		title = "The housekeeper's book",
		body = [[When the keening is heard in the house:

Stop the clock, so the hour is kept.
Cover the glass, so no soul is caught in it.
Open the window, so it may go.

Do all three before she is done, and she will take no one from that room.

Each room keeps the custom once. After that it is only a room.]],
	},

	Bells = {
		title = "Note pinned under the bell board",
		body = [[Each bell rings for its room.

Mr Ashgrove says the bells ring by themselves now. We have stopped answering them. We still look at which one rings.

- Mrs Dunne, housekeeper]],
	},

	Vault_Ledger = {
		title = "Cornelius Ashgrove's ledger, last entry",
		body = [[The box is the only thing I have bought that I would sell back.

What is in it was somebody once. It wants to be somebody again. It does not want a room, or a house. It wants a person.

If the seal is broken, it is already wearing someone.

- C.A.]],
	},
}

return Notes
