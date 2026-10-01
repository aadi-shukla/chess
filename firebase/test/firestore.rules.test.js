const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");
const { readFileSync } = require("fs");
const path = require("path");
const { expect } = require("chai");

const PROJECT_ID = "chess-rules-test";
const RULES_PATH = path.resolve(__dirname, "../../firestore.rules");

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(RULES_PATH, "utf8"),
      host: "127.0.0.1",
      port: 8080,
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

function authedContext(uid) {
  return testEnv.authenticatedContext(uid);
}

describe("Firestore Security Rules", () => {
  it("denies unauthenticated reads on users collection", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(db.collection("users").doc("user1").get());
  });

  it("allows owner to read own user document", async () => {
    const db = authedContext("user1").firestore();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection("users").doc("user1").set({
        email: "test@example.com",
        displayName: "Tester",
        rating: 1200,
        stats: { played: 0, wins: 0, losses: 0, draws: 0 },
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });

    await assertSucceeds(db.collection("users").doc("user1").get());
  });

  it("denies user from modifying protected rating field", async () => {
    const db = authedContext("user1").firestore();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection("users").doc("user1").set({
        email: "test@example.com",
        displayName: "Tester",
        rating: 1200,
        stats: { played: 0, wins: 0, losses: 0, draws: 0 },
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });

    await assertFails(
      db.collection("users").doc("user1").update({ rating: 9999 }),
    );
  });

  it("denies direct writes to games collection", async () => {
    const db = authedContext("user1").firestore();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection("games").doc("game1").set({
        whiteUid: "user1",
        blackUid: "user2",
        status: "active",
      });
    });

    await assertFails(
      db.collection("games").doc("game1").update({ status: "finished" }),
    );
  });

  it("denies user from setting privileged fields on create", async () => {
    const db = authedContext("user1").firestore();
    await assertFails(
      db.collection("users").doc("user1").set({
        email: "test@example.com",
        displayName: "Tester",
        rating: 1200,
        stats: { played: 0, wins: 0, losses: 0, draws: 0 },
        activeGameId: "fake-game",
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );
  });

  it("denies non-host from reading match invites", async () => {
    const db = authedContext("guest").firestore();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection("matchInvites").doc("ABC123").set({
        hostUid: "host1",
        status: "open",
        mode: "casual",
        timeControl: "10+0",
      });
    });

    await assertFails(db.collection("matchInvites").doc("ABC123").get());
  });

  it("allows public read on leaderboard entries", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .collection("leaderboards")
        .doc("global")
        .collection("entries")
        .doc("user1")
        .set({ displayName: "Tester", rating: 1200, rank: 1 });
    });

    const snap = await assertSucceeds(
      db
        .collection("leaderboards")
        .doc("global")
        .collection("entries")
        .doc("user1")
        .get(),
    );
    expect(snap.data().rating).to.equal(1200);
  });
});
