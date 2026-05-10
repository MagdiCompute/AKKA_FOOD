/** @type {import('jest').Config} */
module.exports = {
  preset: "ts-jest",
  testEnvironment: "node",
  roots: ["<rootDir>/src"],
  testMatch: ["**/*.test.ts"],
  transform: {
    "^.+\\.tsx?$": [
      "ts-jest",
      {
        tsconfig: {
          // Relax strict settings for tests
          noUnusedLocals: false,
        },
      },
    ],
  },
  collectCoverageFrom: ["src/**/*.ts", "!src/**/*.test.ts"],
};
