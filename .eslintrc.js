module.exports = {
  env: {
    browser: true,
    es2024: true
  },
  extends: [
    'eslint:recommended'
  ],
  parserOptions: {
    ecmaVersion: 2024,
    sourceType: 'module'
  },
  rules: {
    'indent': ['error', 2],
    'linebreak-style': ['error', 'unix'],
    'quotes': ['error', 'single'],
    'semi': ['error', 'always'],
    'no-unused-vars': 'warn',
    'no-console': 'warn'
  },
  globals: {
    'Stimulus': 'readonly',
    'application': 'readonly'
  }
};