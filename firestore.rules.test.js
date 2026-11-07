const {
  loadFirestoreRules,
  initializeTestApp,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const projectId = 'bahria-uni-queueless-app';
const rules = require('fs').readFileSync('firestore.rules', 'utf8');

beforeAll(async () => {
  await loadFirestoreRules({ projectId, rules });
});

afterAll(async () => {
  await Promise.all(apps().map((a) => a.delete()));
});

function studentAuth(uid) {
  return { uid, token: { role: 'student' } };
}
function handlerAuth(uid) {
  return { uid, token: { role: 'handler' } };
}

describe('Firestore security rules', () => {
  test('a user cannot read another user\'s profile', async () => {
    const db = initializeTestApp({ projectId, auth: studentAuth('userA') }).firestore();
    await assertFails(db.doc('users/userB').get());
  });

  test('a user can read and write their own profile', async () => {
    const db = initializeTestApp({ projectId, auth: studentAuth('userA') }).firestore();
    await assertSucceeds(db.doc('users/userA').get());
    await assertSucceeds(
      db.doc('users/userA').set({ name: 'A', email: 'a@x', role: 'student' }),
    );
  });

  test('a student cannot promote themselves to handler', async () => {
    const db = initializeTestApp({ projectId, auth: studentAuth('userA') }).firestore();
    await assertFails(
      db.doc('users/userA').update({ role: 'handler', handlerRole: 'Student Advisor' }),
    );
  });

  test('a handler can read all appointments', async () => {
    const db = initializeTestApp({ projectId, auth: handlerAuth('handler1') }).firestore();
    await assertSucceeds(db.collection('appointments').get());
  });

  test('a student cannot update another user\'s appointment status', async () => {
    const db = initializeTestApp({ projectId, auth: studentAuth('userA') }).firestore();
    await assertFails(
      db.doc('appointments/otherAppt').update({ status: 'completed' }),
    );
  });

  test('a handler can update an appointment status (manage their queue)', async () => {
    const db = initializeTestApp({ projectId, auth: handlerAuth('handler1') }).firestore();
    await assertSucceeds(
      db.doc('appointments/appt1').update({ status: 'inProgress' }),
    );
  });

  test('no one can delete appointments', async () => {
    const db = initializeTestApp({ projectId, auth: handlerAuth('handler1') }).firestore();
    await assertFails(db.doc('appointments/appt1').delete());
  });
});
