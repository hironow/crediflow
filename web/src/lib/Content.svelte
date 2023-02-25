<script>
	import { content } from '../flow/stores';
	import { executeTransaction } from '../flow/actions';

	/**
	 * Example content object:
	 * {
	 *  host: '0x0d1f73bb7bdca8b9',
	 *  name: 'Flow Developer',
     *  creators: [{
     *      address: '0x0d1f73bb7bdca8b9',
     *      role: 'engineer',
     *      metadata: {},
     *  }],
	 * }
	 */
</script>

<article class="card">
	<label for="address">
		Address
		<input
			type="text"
			id="address"
			name="address"
			value={$content.address}
			placeholder="Address"
			disabled
		/>
	</label>
	<div class="grid">
		<label for="name">
			Name
			<input type="text" id="name" name="name" placeholder="Name" bind:value={$content.name} />
		</label>
	</div>

	<button on:click={executeTransaction}>Tip Content</button>

	<button on:click={executeTransaction}>Claim Content</button>
</article>
