<script>
	import { contents, user, input } from '../flow/stores';
	import { sendQuery, unauthenticate, logIn, signUp, initAccount } from '../flow/actions';

	import UserAddress from './UserAddress.svelte';
	import ContentList from './ContentList.svelte';
</script>

<div class="grid">
	<div class="mb-2">
		{#if $user?.loggedIn}
			<ContentList />
		{:else}
			<h1>Welcome to Crediflow!</h1>
			<p>
				This is a starter app built on Flow. It demonstrates how to use the Flow Client Library
				(FCL) with SvelteKit.
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
					<input type="text" id="host" name="host" placeholder="Host" bind:value={$input.host} />
				</label>
				<button on:click={() => sendQuery($input.host)}>Load All Crediflow</button>
			</div>
		{:else}
			<div>
				<button on:click={logIn}>Log In</button>
				<button on:click={signUp}>Sign Up</button>
			</div>
		{/if}
	</div>
</div>
