<script>
	import { contents, user, host, newContent } from '../flow/stores';
	import { getAllContent, unauthenticate, logIn, signUp, createContent } from '../flow/actions';

	import UserAddress from './UserAddress.svelte';
	import ContentList from './ContentList.svelte';

	function addCreator() {
		newContent.update((state) => {
			state.creators = state.creators.concat({ address: '', role: '' });
			return state;
		});
	}

	function clearCreator() {
		newContent.update((state) => {
			state.creators = [];
			return state;
		});
	}
</script>

<div class="grid">
	<div class="mb-2">
		{#if $user?.loggedIn && $contents.length > 0}
			<ContentList />
		{:else}
			<h1>Welcome to Crediflow!</h1>
			<p>
				This contract is for <code>Crediflow</code>, a decentralized platform on the
				<strong>Flow</strong> blockchain that enables creators and admirers to share and reward each
				other with end credits and tips.
			</p>
			{#if !$user?.loggedIn}
				<p>Login to get started.</p>
			{:else}
				<p>
					Click on Load host Crediflow to see it here.
					<br /><small>or</small><br />
					Create own Crediflow by your own address and become a host.
				</p>
			{/if}
		{/if}
	</div>
	<div>
		{#if $user?.loggedIn}
			<div>
				<div>
					You are now logged in as: <UserAddress /><button on:click={unauthenticate}>Log Out</button
					>
				</div>

				<h2>Controls</h2>
				<label for="host"
					>Crediflow Host
					<input type="text" id="host" name="host" placeholder="Host" bind:value={$host} />
					<small><code>0x497866d0e68bf2cf</code> is prepared for check</small>
				</label>
				<button on:click={() => getAllContent($host)}>Load Host Crediflow</button>

				<hr />

				<div>
					<!-- new content name form -->
					<label for="name">
						<input
							type="text"
							id="name"
							name="name"
							placeholder="Crediflow Content Name"
							bind:value={$newContent.name}
						/>
					</label>
					<!-- new content creator address and role dynamic additional and removable forms by using dynamic form count -->

					{#each $newContent.creators as creator, index}
						<div class="grid">
							<label for="role">
								<input
									type="text"
									id="role"
									name="role"
									placeholder="Creator Role"
									bind:value={$newContent.creators[index].role}
								/>
							</label>
							<label for="address">
								<input
									type="text"
									id="address"
									name="address"
									placeholder="Creator Address"
									bind:value={$newContent.creators[index].address}
								/>
							</label>
						</div>
					{/each}
					<div class="grid">
						<button class="outline" on:click={() => clearCreator()}>Clear All</button>
						<button class="outline" on:click={() => addCreator()}>Add Creator</button>
					</div>
				</div>
				<button
					on:click={() =>
						createContent(
							$newContent.name,
							$newContent.creators.map((creator) => creator.address),
							$newContent.creators.map((creator) => creator.role)
						)}>Create Own Crediflow</button
				>
			</div>
		{:else}
			<div>
				<button on:click={logIn}>Log In</button>
				<button on:click={signUp}>Sign Up</button>
			</div>
		{/if}
	</div>
</div>
