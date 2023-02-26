<script>
	import { contents, user } from '../flow/stores';
	import { getAllContent, unauthenticate, logIn, signUp, initAccount } from '../flow/actions';

	import UserAddress from './UserAddress.svelte';
	import ContentList from './ContentList.svelte';
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
				<button on:click={initAccount}>Create Crediflow</button>

				<label for="host"
					>Host
					<input
						type="text"
						id="host"
						name="host"
						placeholder="Host"
						value={'0x497866d0e68bf2cf'}
						disabled
					/>
				</label>
				<button on:click={() => getAllContent('0x497866d0e68bf2cf')}>Load All Crediflow</button>
			</div>
		{:else}
			<div>
				<button on:click={logIn}>Log In</button>
				<button on:click={signUp}>Sign Up</button>
			</div>
		{/if}
	</div>
</div>
