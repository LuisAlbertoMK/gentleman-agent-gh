/**
 * React Component — UserCard (atomic design)
 * Demonstrates: container/presentational, accessibility, TypeScript-ready, responsive
 */

// ── Types (JSDoc — TypeScript-ready) ───────────────────────
/**
 * @typedef {'admin' | 'editor' | 'viewer'} UserRole
 * @typedef {{ id: number; name: string; email: string; role: UserRole; createdAt: string }} User
 */

// ── Presentational Component ───────────────────────────────

/**
 * UserCard — displays a single user with role badge and actions
 *
 * @param {{ user: User, onEdit?: (user: User) => void, onDelete?: (id: number) => void }} props
 */
function UserCard({ user, onEdit, onDelete }) {
  const roleColors = {
    admin: { bg: 'oklch(0.90 0.10 25)', text: 'oklch(0.40 0.15 25)' },
    editor: { bg: 'oklch(0.90 0.10 264)', text: 'oklch(0.40 0.15 264)' },
    viewer: { bg: 'oklch(0.92 0.05 150)', text: 'oklch(0.35 0.10 150)' },
  };

  const colors = roleColors[user.role] || roleColors.viewer;
  const date = new Date(user.createdAt).toLocaleDateString();

  return (
    <article
      className="user-card"
      aria-label={`User: ${user.name}`}
      style={styles.card}
    >
      <div style={styles.header}>
        <h3 style={styles.name}>{user.name}</h3>
        <span
          style={{
            ...styles.badge,
            background: colors.bg,
            color: colors.text,
          }}
          aria-label={`Role: ${user.role}`}
        >
          {user.role}
        </span>
      </div>

      <p style={styles.email}>
        <a href={`mailto:${user.email}`} style={styles.link}>
          {user.email}
        </a>
      </p>

      <time style={styles.date} dateTime={user.createdAt}>
        Joined {date}
      </time>

      <div style={styles.actions} role="group" aria-label="User actions">
        {onEdit && (
          <button
            onClick={() => onEdit(user)}
            style={styles.btn}
            aria-label={`Edit ${user.name}`}
          >
            Edit
          </button>
        )}
        {onDelete && (
          <button
            onClick={() => onDelete(user.id)}
            style={{ ...styles.btn, ...styles.btnDanger }}
            aria-label={`Delete ${user.name}`}
          >
            Delete
          </button>
        )}
      </div>
    </article>
  );
}

// ── Inline styles (no CSS-in-JS dependency) ────────────────

const styles = {
  card: {
    padding: '1.5rem',
    background: 'white',
    borderRadius: '0.75rem',
    boxShadow: '0 1px 3px oklch(0 0 0 / 0.1)',
    transition: 'transform 0.2s, box-shadow 0.2s',
  },
  header: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: '0.5rem',
  },
  name: { fontSize: '1.25rem', fontWeight: 700, margin: 0 },
  badge: {
    padding: '0.2rem 0.6rem',
    borderRadius: '1rem',
    fontSize: '0.75rem',
    fontWeight: 600,
    textTransform: 'uppercase',
  },
  email: { color: 'oklch(0.50 0.02 264)', margin: '0.25rem 0' },
  link: { color: 'inherit', textDecoration: 'none' },
  date: { fontSize: '0.85rem', color: 'oklch(0.60 0.02 264)' },
  actions: {
    display: 'flex',
    gap: '0.5rem',
    marginTop: '1rem',
  },
  btn: {
    padding: '0.4rem 1rem',
    border: '1px solid oklch(0 0 0 / 0.15)',
    borderRadius: '0.5rem',
    background: 'transparent',
    cursor: 'pointer',
    fontSize: '0.9rem',
    transition: 'background 0.15s',
  },
  btnDanger: {
    color: 'oklch(0.55 0.20 25)',
    borderColor: 'oklch(0.55 0.20 25)',
  },
};

// ── Container Component ────────────────────────────────────

/**
 * UserList — fetches and renders a list of users
 *
 * @param {{ users: User[], onEdit?: Function, onDelete?: Function }} props
 */
export function UserList({ users = [], onEdit, onDelete }) {
  if (users.length === 0) {
    return (
      <div role="status" style={{ textAlign: 'center', padding: '2rem', color: 'oklch(0.50 0.02 264)' }}>
        No users found.
      </div>
    );
  }

  return (
    <section aria-label="User list" style={{ display: 'grid', gap: '1rem', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))' }}>
      {users.map((user) => (
        <UserCard key={user.id} user={user} onEdit={onEdit} onDelete={onDelete} />
      ))}
    </section>
  );
}

export default UserCard;
