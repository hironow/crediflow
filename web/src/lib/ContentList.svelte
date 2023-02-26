<script>
	import { user } from '../flow/stores';
	// import { content } from '../flow/stores';
	// import { executeTransaction } from '../flow/actions';

	let contents = [
		{
			id: 1,
			name: 'Name 1',
			host: '0x01',
			creators: {
				'0x11': { role: 'engineer' },
				'0x22': { role: 'designer' },
				'0x33': { role: 'sales' }
			}
		},
		{ id: 2, name: 'Name 2', host: '0x02', creators: { '0x22': { role: 'publisher' } } }
	];

	console.log($user.addr);
</script>

<article class="card">
	{#each contents as content, index (content.id)}
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

			<div class="grid">
				<button class="outline" on:click={() => console.log('Creator Mint')}>Creator Mint</button>
				<button class="outline" on:click={() => console.log('Admirer Mint')}>Admirer Mint</button>
			</div>

			<div class="grid">
				<button class="outline" on:click={() => console.log('Tip')}>Tip</button>
				<button class="outline" on:click={() => console.log('Claim')}>Claim</button>
			</div>
		</details>
	{/each}
</article>
