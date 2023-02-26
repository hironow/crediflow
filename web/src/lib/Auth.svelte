<script>
	import { contents, user, host } from '../flow/stores';
	import { getAllContent, unauthenticate, logIn, signUp, initAccount } from '../flow/actions';

	import UserAddress from './UserAddress.svelte';
	import ContentList from './ContentList.svelte';

	let newContent = {
		name: '',
		creators: [{ address: '', role: '' }]
	};

	function addCreator() {
		newContent.creators = newContent.creators.concat({ address: '', role: '' });
	}

	function clearCreator() {
		newContent.creators = [];
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
				<p>Create a Crediflow and then click on Load all Crediflow to see it here.</p>
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
					>Host
					<input type="text" id="host" name="host" placeholder="Host" bind:value={$host} />
				</label>
				<button on:click={() => getAllContent($host)}>Load All Crediflow</button>

				<div>
					<!-- new content name form -->
					<label for="name">
						Name
						<input
							type="text"
							id="name"
							name="name"
							placeholder="Content"
							bind:value={newContent.name}
						/>
					</label>
					<!-- new content creator address and role dynamic additional and removable forms by using dynamic form count -->

					{#each newContent.creators as creator, index}
						<div class="grid">
							<label for="role">
								<input
									type="text"
									id="role"
									name="role"
									placeholder="Role"
									bind:value={newContent.creators[index].role}
								/>
							</label>
							<label for="address">
								<input
									type="text"
									id="address"
									name="address"
									placeholder="Address"
									bind:value={newContent.creators[index].address}
								/>
							</label>
						</div>
					{/each}
					<div class="grid">
						<button class="outline" on:click={() => clearCreator()}>Clear All</button>
						<button class="outline" on:click={() => addCreator()}>Add Creator</button>
					</div>
				</div>
				<button on:click={initAccount}>Create Crediflow</button>
			</div>
		{:else}
			<div>
				<button on:click={logIn}>Log In</button>
				<button on:click={signUp}>Sign Up</button>
			</div>
		{/if}
	</div>
</div>
