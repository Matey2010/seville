# Obsivilian quality baseline

This is the starting ledger for polishing existing behavior. It records what
the code currently exposes and what still needs owner verification. An issue
found by reading code is not a claim that it has been observed in the running
app. The owner runs and debugs the macOS app; Codex may inspect code and run
non-interactive static checks.

## Scope and order

1. **Read:** open the global graph, select a Node, read its title, slug,
   classification labels, and full body; follow a connection to another Node.
2. **Explore:** switch between global and local graphs, pan and zoom, inspect
   bounded-result messaging, and refresh.
3. **Find:** submit and clear search, inspect matching Nodes and empty results.
4. **Change:** create a Node, edit its body, preserve a draft on failure, and
   handle a stale `update_count`.
5. **Controls:** keyboard shortcuts and copy slug.

For each slice, record the initial behavior, fix one reproducible problem at a
time, and ask the owner to verify the result in the app before marking it done.
The Go, Neo4j, and protobuf boundary remains closed during client polishing.

## Initial issue ledger

| ID | Slice | Evidence from code | Expected behavior | Status |
| --- | --- | --- | --- | --- |
| R-01 | Read/global list | With no submitted search, `_nodeList` receives an empty list whenever `nodeGraphProvider` is loading or has failed. Its empty branch then displays “No Nodes yet.” | Loading should show progress; a failed read should show an error and retry; “No Nodes yet” should require a successful empty response. | Code-confirmed; runtime unverified |
| R-02 | Read/search list | With a submitted search, `_nodeList` falls back to graph Nodes whenever `nodeSearchProvider` is empty, loading, or failed. The list can therefore display graph matches under “Search results,” or hide a search error. | Results, loading, empty, and error states should come from one clearly named source; a failed search must be visible. | Code-confirmed; runtime unverified |
| R-03 | Find | The global graph matches body text, but the sidebar search only matches slug, title, tag, and label. | The UI should explain the difference or make both views use consistent search semantics. | Code-confirmed; runtime unverified |
| R-04 | Find | The search field limits 256 characters; the graph endpoint limits 256 UTF-8 bytes. A multibyte query can pass the field and fail at the API. | The client should prevent or explain an oversized query before sending it. | Code-confirmed; runtime unverified |
| R-05 | Refresh/read | The graph pane replaces its content while the provider loads. Whether this resets the owner's pan/zoom context or causes distracting flicker needs app observation. | A refresh should keep the reader oriented, or give a clear loading transition. | Runtime check needed |

Record new findings here with an ID, exact steps, expected and observed result,
and a screenshot when it helps. Keep design preferences separate from broken
behavior so the read slice has a clear completion point.

## Owner's first macOS pass

Run `make -C scripts interface` and record observations for these steps:

1. Open with data available. Note what appears first in the graph and Node list.
   Select one Node with a long body and scroll to its end in the modal.
2. Select a connected Node. Note whether the reader and local graph agree on
   which Node is focused; then return to the global graph.
3. Refresh while viewing the global graph and then while viewing a local graph.
   Note any false empty message, lost selection, movement, or flicker.
4. Search for a term in a title, then one only in a body, then one with no
   matches. Note what the graph and list show in each case.

If an API or Neo4j failure is already available to reproduce, record the
graph and list error states too. No failure needs to be manufactured for this
baseline.

## Completion gate for the read slice

The owner can open, select, and read a Node; follow a visible connection; and
recover from a read failure without a false empty state or loss of an unsaved
draft. Every read-related issue in this ledger is either fixed and owner
verified or explicitly deferred with a reason. Static analysis supports the
code review but does not count as runtime verification.
