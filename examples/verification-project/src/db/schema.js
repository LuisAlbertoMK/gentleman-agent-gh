/**
 * Database schema — Prisma-style ORM definition
 * Demonstrates: proper relations, indexes, constraints, soft delete
 */

// ── Schema (Prisma-style) ──────────────────────────────────
//
// model User {
//   id        Int       @id @default(autoincrement())
//   email     String    @unique
//   name      String
//   role      Role      @default(VIEWER)
//   posts     Post[]
//   profile   Profile?
//   createdAt DateTime  @default(now())
//   updatedAt DateTime  @updatedAt
//   deletedAt DateTime?
//
//   @@index([email])
//   @@index([role])
//   @@map("users")
// }
//
// model Post {
//   id        Int       @id @default(autoincrement())
//   title     String
//   content   String?
//   published Boolean   @default(false)
//   author    User      @relation(fields: [authorId], references: [id])
//   authorId  Int
//   tags      Tag[]
//   createdAt DateTime  @default(now())
//   updatedAt DateTime  @updatedAt
//
//   @@index([authorId])
//   @@index([published])
//   @@map("posts")
// }
//
// model Tag {
//   id    Int    @id @default(autoincrement())
//   name  String @unique
//   posts Post[]
//
//   @@map("tags")
// }
//
// model Profile {
//   id     Int    @id @default(autoincrement())
//   bio    String?
//   avatar String?
//   user   User   @relation(fields: [userId], references: [id])
//   userId Int    @unique
//
//   @@map("profiles")
// }
//
// enum Role {
//   ADMIN
//   EDITOR
//   VIEWER
// }

// ── Query examples (repository pattern) ────────────────────

/**
 * User repository — handles all user database operations
 * @class UserRepository
 */
class UserRepository {
  /**
   * @param {import('@prisma/client').PrismaClient} prisma - Prisma client instance
   */
  constructor(prisma) {
    this.prisma = prisma;
  }

  /**
   * Find user by ID with profile and posts
   * @param {number} id - User ID
   * @returns {Promise<Object|null>} User object or null if not found
   */
  async findById(id) {
    try {
      return await this.prisma.user.findUnique({
        where: { id },
        include: { profile: true, posts: { where: { deletedAt: null } } },
      });
    } catch (err) {
      throw new Error(`Failed to find user by ID: ${err.message}`);
    }
  }

  /**
   * Find user by email
   * @param {string} email - User email
   * @returns {Promise<Object|null>} User object or null if not found
   */
  async findByEmail(email) {
    try {
      return await this.prisma.user.findUnique({ where: { email } });
    } catch (err) {
      throw new Error(`Failed to find user by email: ${err.message}`);
    }
  }

  /**
   * Create a new user
   * @param {{ email: string, name: string, role?: string }} data - User data
   * @returns {Promise<Object>} Created user
   */
  async create({ email, name, role = 'VIEWER' }) {
    try {
      return await this.prisma.user.create({
        data: { email: email.toLowerCase(), name, role },
      });
    } catch (err) {
      throw new Error(`Failed to create user: ${err.message}`);
    }
  }

  /**
   * Update user by ID
   * @param {number} id - User ID
   * @param {Object} data - Fields to update
   * @returns {Promise<Object>} Updated user
   */
  async update(id, data) {
    try {
      return await this.prisma.user.update({
        where: { id },
        data: { ...data, updatedAt: new Date() },
      });
    } catch (err) {
      throw new Error(`Failed to update user: ${err.message}`);
    }
  }

  /**
   * Soft delete user (set deletedAt timestamp)
   * @param {number} id - User ID
   * @returns {Promise<Object>} Updated user
   */
  async softDelete(id) {
    try {
      return await this.prisma.user.update({
        where: { id },
        data: { deletedAt: new Date() },
      });
    } catch (err) {
      throw new Error(`Failed to soft delete user: ${err.message}`);
    }
  }

  /**
   * List users with pagination and optional role filter
   * @param {{ page?: number, pageSize?: number, role?: string }} options - Query options
   * @returns {Promise<{ data: Object[], total: number, page: number, pageSize: number, totalPages: number }>}
   */
  async list({ page = 1, pageSize = 20, role } = {}) {
    try {
      const where = { deletedAt: null, ...(role && { role }) };
      const [data, total] = await Promise.all([
        this.prisma.user.findMany({
        where,
        skip: (page - 1) * pageSize,
        take: pageSize,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.user.count({ where }),
    ]);
    return { data, total, page, pageSize, totalPages: Math.ceil(total / pageSize) };
    } catch (err) {
      throw new Error(`Failed to list users: ${err.message}`);
    }
  }
}

/**
 * Post repository — handles all post database operations
 * @class PostRepository
 */
class PostRepository {
  /**
   * @param {import('@prisma/client').PrismaClient} prisma - Prisma client instance
   */
  constructor(prisma) {
    this.prisma = prisma;
  }

  /**
   * Create a post with optional tags
   * @param {{ title: string, content?: string, authorId: number, tags?: string[] }} data - Post data
   * @returns {Promise<Object>} Created post with author and tags
   */
  async create({ title, content, authorId, tags = [] }) {
    try {
      return await this.prisma.post.create({
        data: {
          title,
          content,
          authorId,
          tags: {
            connectOrCreate: tags.map((name) => ({
              where: { name },
              create: { name },
            })),
          },
        },
        include: { author: { select: { id: true, name: true } }, tags: true },
      });
    } catch (err) {
      throw new Error(`Failed to create post: ${err.message}`);
    }
  }

  /**
   * Find all posts by author
   * @param {number} authorId - Author user ID
   * @returns {Promise<Object[]>} Array of posts with tags
   */
  async findByAuthor(authorId) {
    try {
      return await this.prisma.post.findMany({
        where: { authorId },
        include: { tags: true },
        orderBy: { createdAt: 'desc' },
      });
    } catch (err) {
      throw new Error(`Failed to find posts by author: ${err.message}`);
    }
  }

  /**
   * Publish a post
   * @param {number} id - Post ID
   * @returns {Promise<Object>} Updated post
   */
  async publish(id) {
    try {
      return await this.prisma.post.update({
        where: { id },
        data: { published: true },
    });
  }
}

module.exports = { UserRepository, PostRepository };
