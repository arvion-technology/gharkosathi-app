import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync, existsSync } from "node:fs";
import {
  STATUSES, TRANSITIONS, GUARDS, FLOWS, canTransition, transition, runPath,
  createJob, escrowState, isTerminal, allowedTargets, isStatus,
} from "../src/state-machine.js";
import { appMetrics, screensByRole, screenById, edgeCount, guardCount, screensWithQueuedWrites } from "../src/app-metrics.js";
import { SCREENS, ROLES, PRODUCT, ARCHITECTURE_NOTES, CODE_HIGHLIGHTS } from "../src/product-data.js";
import { createQueue, backoffFor, QUEUE_LIMITS } from "../src/offline-queue.js";

const vectors = JSON.parse(readFileSync(new URL("./vectors/job_flow.json", import.meta.url), "utf8"));
const fileExists = (path) => existsSync(new URL(`../${path}`, import.meta.url));

/* ----------------------------------------------------------- state machine */

test("the JS transition table matches the shared vectors exactly", () => {
  assert.deepEqual([...STATUSES].sort(), [...vectors.states].sort());
  const edges = [];
  for (const [from, targets] of Object.entries(TRANSITIONS)) {
    for (const to of targets) edges.push([from, to]);
  }
  const sorted = (list) => [...list].map(([a, b]) => `${a}->${b}`).sort();
  assert.deepEqual(sorted(edges), sorted(vectors.edges));
  assert.equal(edgeCount(), vectors.edges.length);
});

test("every forbidden vector pair is rejected", () => {
  for (const [from, to] of vectors.forbidden) {
    const result = canTransition(from, to, { workerId: "w", escrowHeld: true, proofUploaded: true, feeAccepted: true, reason: "x", withinDisputeWindow: true, reviewComplete: true });
    assert.equal(result.ok, false, `${from} -> ${to} should not be allowed`);
  }
});

test("guards reject the documented context and accept the fixed context", () => {
  for (const item of vectors.guards) {
    const result = canTransition(item.from, item.to, item.context);
    assert.equal(result.ok, item.allowed, `${item.from} -> ${item.to} with ${JSON.stringify(item.context)}`);
  }
});

test("the three recorded flows run end to end and keep history", () => {
  for (const [name, path] of Object.entries(vectors.flows)) {
    assert.deepEqual(FLOWS[name], path);
    const context = { workerId: "w_1", escrowHeld: true, proofUploaded: true, feeAccepted: true, reason: "leak", withinDisputeWindow: true, reviewComplete: true };
    const start = createJob({ id: "GK-2481", serviceId: "svc_1", customerId: "c_1" });
    const contextFor = (job, to) => {
      if (to === "matching") return {};
      if (to === "matched") return { workerId: "w_1" };
      if (to === "paid") return { ...context };
      if (to === "disputed") return { ...context };
      if (to === "refunded") return { ...context };
      return context;
    };
    const final = runPath(start, path, contextFor);
    assert.equal(final.status, path.at(-1), name);
    assert.equal(final.history.length, path.length, `${name} history`);
    assert.equal(isTerminal(final.status), true);
  }
});

test("illegal transitions throw and a legal one returns a new snapshot", () => {
  const job = createJob({ id: "GK-1", serviceId: "s", customerId: "c" });
  assert.throws(() => transition(job, "paid"), /illegal transition/);
  assert.equal(job.status, "draft", "transition must not mutate the input");
  const requested = transition(job, "requested");
  assert.equal(requested.status, "requested");
  assert.equal(requested.history[0].from, "draft");
  assert.equal(job.history.length, 0);
});

test("unknown statuses fail with a reason instead of a random edge", () => {
  assert.equal(isStatus("finished"), false);
  assert.throws(() => allowedTargets("finished"), /unknown status/);
  assert.equal(canTransition("draft", "finished").ok, false);
  assert.match(canTransition("draft", "finished").reason, /unknown status/);
});

test("escrow state is derived from the job, never stored twice", () => {
  const base = { history: [] };
  assert.equal(escrowState({ ...base, status: "matched" }), "held");
  assert.equal(escrowState({ ...base, status: "completed" }), "releasable");
  assert.equal(escrowState({ ...base, status: "paid" }), "released");
  assert.equal(escrowState({ ...base, status: "disputed" }), "frozen");
  assert.equal(escrowState({ ...base, status: "refunded" }), "frozen");
  assert.equal(guardCount(), Object.keys(GUARDS).length);
});

/* ----------------------------------------------------------- offline queue */

test("the queue deduplicates by idempotency key", () => {
  const queue = createQueue();
  assert.equal(queue.enqueue({ key: "job:1", type: "status" }).added, true);
  const duplicate = queue.enqueue({ key: "job:1", type: "status" });
  assert.equal(duplicate.added, false);
  assert.equal(duplicate.reason, "duplicate");
  assert.equal(queue.size(), 1);
  assert.throws(() => queue.enqueue({ type: "status" }), /needs a key/);
});

test("flush sends in order and stops at the first failure", () => {
  const queue = createQueue();
  queue.enqueue({ key: "a", type: "status", payload: { n: 1 } });
  queue.enqueue({ key: "b", type: "status", payload: { n: 2 } });
  queue.enqueue({ key: "c", type: "status", payload: { n: 3 } });
  const sent = [];
  const result = queue.flush((operation) => {
    if (operation.key === "b") throw new Error("offline");
    sent.push(operation.key);
    return true;
  });
  assert.deepEqual(sent, ["a"]);
  assert.equal(result.sent, 1);
  assert.equal(result.remaining, 2);
  assert.equal(result.failed[0].key, "b");
  assert.equal(queue.first().key, "b");
  assert.ok(result.retryInMs > 0);
});

test("a later update never overtakes an earlier one", () => {
  const queue = createQueue();
  queue.enqueue({ key: "job:step-1", type: "status" });
  queue.enqueue({ key: "job:step-2", type: "status" });
  let online = false;
  queue.flush(() => online);
  assert.equal(queue.first().key, "job:step-1");
  online = true;
  const sent = [];
  queue.flush((operation) => { sent.push(operation.key); return true; });
  assert.deepEqual(sent, ["job:step-1", "job:step-2"]);
  assert.equal(queue.isDrained(), true);
});

test("backoff doubles per attempt and caps out", () => {
  assert.equal(backoffFor(0), 0);
  assert.equal(backoffFor(1), 1000);
  assert.equal(backoffFor(2), 2000);
  assert.equal(backoffFor(3), 4000);
  assert.equal(backoffFor(4), 8000);
  assert.equal(backoffFor(9), QUEUE_LIMITS.MAX_BACKOFF_MS);
  const queue = createQueue();
  queue.enqueue({ key: "x", type: "status" });
  let last = null;
  for (let i = 0; i < QUEUE_LIMITS.MAX_ATTEMPTS; i++) last = queue.flush(() => false);
  assert.equal(last.exhausted, true);
  assert.equal(last.remaining, 1);
});

test("the queue serialises across an app kill and restores order", () => {
  const queue = createQueue();
  queue.enqueue({ key: "a", type: "status", payload: { status: "inProgress" }, createdAt: 10 });
  queue.enqueue({ key: "b", type: "status", payload: { status: "completed" }, createdAt: 20 });
  queue.flush(() => false);
  const saved = queue.serialize();
  const restored = createQueue();
  assert.equal(restored.restore(saved), 2);
  assert.equal(restored.first().key, "a");
  assert.equal(restored.first().attempts, 1);
  assert.equal(restored.pending()[1].payload.status, "completed");
  assert.equal(restored.enqueue({ key: "a", type: "status" }).added, false, "keys restored too");
  assert.throws(() => restored.restore("{}"), /must be an array/);
});

test("a failed operation can be discarded when it will never succeed", () => {
  const queue = createQueue();
  queue.enqueue({ key: "bad", type: "status" });
  queue.enqueue({ key: "good", type: "status" });
  queue.flush((operation) => operation.key !== "bad");
  assert.equal(queue.size(), 2, "the failed operation blocks the one behind it");
  assert.equal(queue.discard("bad"), true);
  assert.equal(queue.discard("bad"), false);
  assert.equal(queue.size(), 1);
  assert.equal(queue.first().key, "good");
});

/* ----------------------------------------------------------- case-study data */

test("the case study presents eight screens across both roles", () => {
  assert.equal(SCREENS.length, 8);
  assert.equal(new Set(SCREENS.map((screen) => screen.id)).size, 8);
  assert.equal(screensByRole("customer").length, 7);
  assert.equal(screensByRole("worker").length, 1);
  assert.deepEqual(ROLES.map((role) => role.id), ["all", "customer", "worker"]);
  for (const screen of SCREENS) {
    assert.ok(screen.route.startsWith("/"), screen.id);
    assert.ok(screen.summary.length > 40, screen.id);
    assert.ok(screen.ui.body.length >= 3, screen.id);
    assert.ok(Array.isArray(screen.ui.footer) && screen.ui.footer.length === 4, screen.id);
  }
});

test("every screen maps to a Dart file that exists", () => {
  for (const screen of SCREENS) {
    assert.ok(fileExists(screen.file), `${screen.id}: missing ${screen.file}`);
  }
  assert.equal(screenById("wallet").name, "Wallet and escrow");
  assert.equal(screenById("nope"), null);
});

test("metrics are computed from the state machine and screen list", () => {
  const metrics = appMetrics();
  assert.equal(metrics.screens, 8);
  assert.equal(metrics.statuses, vectors.states.length);
  assert.equal(metrics.transitions, vectors.edges.length);
  assert.equal(metrics.flows, 3);
  assert.equal(metrics.longestFlow, 9);
  assert.equal(metrics.maxAttempts, 5);
  assert.equal(metrics.backoffAfterOneFailure, 1000);
  assert.equal(metrics.backoffAfterThreeFailures, 4000);
  assert.equal(screensWithQueuedWrites().length, 4);
});

test("the product record names the live service and the honest status", () => {
  assert.equal(PRODUCT.domain, "gharkosewa.com");
  assert.match(PRODUCT.status, /architecture sample/);
  assert.ok(!/App Store|Play Store/i.test(PRODUCT.status), "no store claim");
  assert.equal(ARCHITECTURE_NOTES.length, 4);
  assert.equal(CODE_HIGHLIGHTS.length, 2);
  assert.ok(CODE_HIGHLIGHTS.every((highlight) => highlight.code.includes("JobStatus") || highlight.code.includes("queue")));
});
