# iOS 16 Stability Evidence Checklist

Use one copy of this checklist for each physical device. Gate A needs one
completed run on an arm64 device and one on an arm64e device. Do not record
full browsing URLs in committed evidence or diagnostics.

## 1. Run Metadata

| Field | Value |
| --- | --- |
| Date / tester | |
| Device model | |
| Architecture (`arm64` / `arm64e`) | |
| iOS version / build | |
| TrollStore version | |
| Installation type (`clean` / `upgrade`) | |
| Reynard commit | |
| Gecko revision | |
| App artifact filename | |
| App artifact SHA-256 | |
| JIT mode (`ptrace` / pairing / JIT-less) | |
| CI run URL | |

## 2. Installation and Data Safety

- [ ] Install the TrollStore TIPA successfully.
- [ ] Launch after a clean install without a blank or permanently blocked UI.
- [ ] Upgrade over the selected upstream Reynard build without losing regular
      tabs, bookmarks, history, downloads, settings, or site permissions.
- [ ] If legacy `Documents/AppData` data is present, verify migration completes
      and the source is not removed before the destination is usable.
- [ ] Force a migration failure, confirm the recovery view appears, retry, and
      confirm the browser launches with the original data.

Notes / evidence:

```text

```

## 3. Cold Launches and JIT

Perform 20 consecutive cold launches. Fully terminate Reynard between runs.

| Metric | Result |
| --- | --- |
| Successful launches / 20 | |
| App crashes | |
| Permanent blank screens | |
| Blocking sheets without an action | |

- [ ] Deliberately fail one JIT attachment.
- [ ] Confirm the failure view offers **Retry JIT** and **Activate JIT-Less Mode**.
- [ ] Retry and confirm a replacement content process loads the retained tab.
- [ ] Exhaust the retry budget and confirm the primary action becomes
      **Export Diagnostics**.
- [ ] Enter JIT-less mode and confirm browser chrome, settings, address bar, and
      tab switching remain usable.
- [ ] Relaunch and confirm JIT-less mode did not create a launch loop.

Notes / evidence:

```text

```

## 4. Background and Foreground Cycles

Open 10 regular tabs with distinct titles and addresses. Perform 30 complete
foreground/background cycles.

| Metric | Result |
| --- | --- |
| Completed cycles / 30 | |
| Tabs retained / 10 | |
| Selected tab retained | |
| Unexpected reloads | |
| `tabs.lifecycleFlushCompleted` failures | |

- [ ] Change the selected tab immediately before at least five background
      transitions.
- [ ] Navigate or reorder a tab immediately before at least five transitions.
- [ ] Confirm the restored selected tab and tab order after returning.

## 5. Forced Termination Restore

Perform 10 cycles. Before each termination, make a visible tab mutation such as
opening, closing, reordering, selecting, or navigating a tab. Background the
app, terminate it, relaunch, and compare the restored state.

| Cycle | Mutation | Restored correctly | Notes |
| ---: | --- | :---: | --- |
| 1 | | [ ] | |
| 2 | | [ ] | |
| 3 | | [ ] | |
| 4 | | [ ] | |
| 5 | | [ ] | |
| 6 | | [ ] | |
| 7 | | [ ] | |
| 8 | | [ ] | |
| 9 | | [ ] | |
| 10 | | [ ] | |

## 6. Gecko Process Recovery

- [ ] Kill the selected tab content process once. The tab ID, title, address,
      browser chrome, and tab switcher remain available.
- [ ] Crash the selected tab content process once. A replacement session loads
      without deleting the tab.
- [ ] Kill a background tab process. It remains present and restores when
      selected.
- [ ] Trigger three repeated crashes. The native stable failure view appears
      instead of an endless reload loop.
- [ ] Use **Retry Page** from the stable failure view.
- [ ] Export diagnostics from the recovery UI.

## 7. Tab and Memory Stress

- [ ] Complete 100 tab switches across the 10 regular tabs.
- [ ] Open and close at least 25 additional tabs.
- [ ] Exercise one private tab and confirm private state is not restored as
      regular browsing data.
- [ ] Trigger a memory warning or equivalent device pressure scenario.
- [ ] Confirm no regular tab disappears solely because a Gecko process was
      killed.

| Metric | Result |
| --- | --- |
| Tab switches / 100 | |
| Additional tabs opened / closed | |
| App crashes | |
| Lost regular tabs | |

## 8. Browsing Smoke Test

- [ ] Load a modern JavaScript-heavy site.
- [ ] Load a TLS-protected site.
- [ ] Load a media page and start/stop playback.
- [ ] Download a file and confirm it remains listed.
- [ ] Open settings and return to the current tab.
- [ ] Verify back, forward, reload, address entry, and tab creation.

Record only site categories or redacted origins; do not commit full URLs.

## 9. Diagnostic Evidence

Export diagnostics with website URLs excluded.

| Field | Value |
| --- | --- |
| Diagnostic filename | |
| Export timestamp | |
| Includes current-session URLs (`false` required for committed evidence) | |
| JIT failure event present | |
| Process recovery event present | |
| Lifecycle flush event present | |
| Migration event present | |

- [ ] Diagnostic JSON parses successfully.
- [ ] No cookies, form contents, authorization headers, page contents, or full
      URLs are present.
- [ ] Store the diagnostic beside the test report outside the repository, or in
      an access-controlled CI/test artifact with a short retention period.

## 10. Gate A Result

- [ ] 20/20 cold launches passed.
- [ ] 30/30 background cycles preserved the regular session.
- [ ] 10/10 forced termination cycles restored the expected state.
- [ ] 100/100 tab switches completed without losing a regular tab.
- [ ] JIT failure, retry, exhaustion, and JIT-less mode were verified.
- [ ] Gecko crash/kill recovery and repeated-crash stable failure were verified.
- [ ] Privacy-safe diagnostic evidence was exported.
- [ ] No unresolved launch-blocking or regular-data-loss defect remains.

Final result: `PASS / FAIL / NEEDS-VERIFICATION`

Open defects:

```text

```

Tester signature / date:

```text

```
