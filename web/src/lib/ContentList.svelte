<script>
	import { user, contents, creatorNFTHoldersMap, admirerNFTHoldersMap } from '../flow/stores';
	import {
		getNFTHolder,
		mintCreatorNFT,
		mintAdmirerNFT,
		executeClaim,
		executeTip
	} from '../flow/actions';

	// input state
	let tipAmount = 0.0001;

	// Example store data
	// let contents = [
	// 	{
	// 		id: 1,
	// 		name: 'Name 1',
	// 		host: '0x01',
	// 		creators: {
	// 			'0x11': { role: 'engineer' },
	// 			'0x22': { role: 'designer' },
	// 			'0x33': { role: 'sales' }
	// 		}
	// 	},
	// 	{ id: 2, name: 'Name 2', host: '0x02', creators: { '0x22': { role: 'publisher' } } }
	// ];

	/**
	 * check address is in the list of address
	 *
	 * @param {string} address
	 * @param {string[]} list
	 */
	function isAddressInList(address, list) {
		return list.some((item) => item === address);
	}

	/**
	 * get my nftId from the holders
	 *
	 * @param {Object} holders
	 */
	function getMyNFTIdFromHolders(holders) {
		let nftId = holders[$user?.addr].id;
		return nftId;
	}
</script>

<article class="card">
	{#each $contents as content, index (content.id)}
		<label for="name">
			Name
			<input type="text" id="name" name="name" value={content.name} disabled />
		</label>
		<!-- <label for="address">
			Host
			<input
				type="text"
				id="address"
				name="address"
				value={content.host}
				placeholder="Address"
				disabled
			/>
		</label> -->
		<details open={false}>
			<summary>Creators</summary>
			{#each Object.entries(content.creators) as [creatorAddress, creatorMetadata], index (creatorAddress)}
				<div class="grid">
					<label for="address">
						<input
							type="text"
							id="address"
							name="address"
							value={creatorMetadata.role}
							placeholder="Address"
							disabled
						/>
					</label>
					<label for="address">
						<input
							type="text"
							id="address"
							name="address"
							value={creatorAddress}
							placeholder="Address"
							disabled
						/>
						{#if creatorAddress == $user?.addr}
							<small><mark>you</mark></small>
						{/if}
					</label>
				</div>
			{/each}
		</details>
		<details open={false}>
			<summary>Holders</summary>
			<button on:click={() => getNFTHolder(content.id, '0x497866d0e68bf2cf')}>Load holders</button>

			<div>
				{#if content.id in $creatorNFTHoldersMap}
					<small><i>Creator NFT holders</i></small>
					{#each Object.entries($creatorNFTHoldersMap[content.id]) as [address, nftData], index (address)}
						<div class="grid">
							<label for="serial">
								<input
									type="text"
									id="serial"
									name="serial"
									value={nftData.serial}
									placeholder="Serial"
									disabled
								/>
							</label>
							<label for="address">
								<input
									type="text"
									id="address"
									name="address"
									value={address}
									placeholder="Address"
									disabled
								/>
								{#if address == $user?.addr}
									<small><mark>you</mark></small>
								{/if}
							</label>
						</div>
					{/each}

					<div class="grid">
						{#if !isAddressInList($user?.addr, Object.keys($creatorNFTHoldersMap[content.id]))}
							<button
								class="outline"
								disabled={!isAddressInList($user?.addr, Object.keys(content.creators))}
								on:click={() => mintCreatorNFT(content.id, '0x497866d0e68bf2cf')}
								>Creator Mint</button
							>
						{:else}
							<button
								class="outline"
								disabled={!isAddressInList(
									$user?.addr,
									Object.keys($creatorNFTHoldersMap[content.id])
								)}
								on:click={() =>
									executeClaim(getMyNFTIdFromHolders($creatorNFTHoldersMap[content.id]))}
								>Claim</button
							>
						{/if}
					</div>
				{/if}
			</div>

			<div>
				{#if content.id in $admirerNFTHoldersMap}
					<small><i>Admirer NFT holders</i></small>
					{#each Object.entries($admirerNFTHoldersMap[content.id]) as [address, nftData], index (address)}
						<div class="grid">
							<label for="serial">
								<input
									type="number"
									id="serial"
									name="serial"
									value={nftData.serial}
									placeholder="Serial"
									disabled
								/>
							</label>
							<label for="address">
								<input
									type="text"
									id="address"
									name="address"
									value={address}
									placeholder="Address"
									disabled
								/>
								{#if address == $user?.addr}
									<small><mark>you</mark></small>
								{/if}
							</label>
						</div>
					{/each}
					<div class="grid">
						{#if !isAddressInList($user?.addr, Object.keys($admirerNFTHoldersMap[content.id]))}
							<button
								class="outline"
								disabled={isAddressInList(
									$user?.addr,
									Object.keys($admirerNFTHoldersMap[content.id])
								)}
								on:click={() => mintAdmirerNFT(content.id, '0x497866d0e68bf2cf')}
								>Admirer Mint</button
							>
						{:else}
							<label for="tipAmount">
								<input
									type="number"
									step="0.001"
									id="tipAmount"
									name="tipAmount"
									bind:value={tipAmount}
									placeholder="Tip Amount"
								/>
							</label>
							<button
								class="outline"
								disabled={!isAddressInList(
									$user?.addr,
									Object.keys($admirerNFTHoldersMap[content.id])
								)}
								on:click={() =>
									executeTip(getMyNFTIdFromHolders($admirerNFTHoldersMap[content.id]), tipAmount)}
								>Tip</button
							>
						{/if}
					</div>
				{/if}
			</div>
		</details>
	{/each}
</article>
