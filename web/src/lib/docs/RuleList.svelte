<script>
  /** Container for `<Rule>` items — keeps spacing consistent. */
  let { children } = $props();
</script>

<ul class="rules">
  {@render children()}
</ul>

<style>
  .rules {
    margin: 0.5rem 0 1.25rem;
    padding: 0;
    list-style: none;
    display: flex;
    flex-direction: column;
    gap: 0.55rem;
  }
</style>
