import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    setupFiles: ['./vitest.setup.ts'],
    include: ['src/**/*.test.ts'],
    // Integration suites share one PostgreSQL database: run files
    // sequentially so concurrent Serializable transactions don't conflict.
    fileParallelism: false,
  },
});
