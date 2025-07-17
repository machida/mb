const js = require("@eslint/js");

module.exports = [
  js.configs.recommended,
  {
    ignores: [
      "node_modules/",
      "vendor/",
      "app/javascript/controllers/image_upload_controller.js",
      "app/javascript/controllers/markdown_preview_controller.js", 
      "app/javascript/controllers/thumbnail_upload_controller.js",
      "app/javascript/controllers/toast_controller.js"
    ]
  },
  {
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      globals: {
        window: "readonly",
        document: "readonly",
        console: "readonly",
        Stimulus: "readonly",
        FormData: "readonly",
        fetch: "readonly",
        Event: "readonly",
        setTimeout: "readonly",
        alert: "readonly",
        Date: "readonly"
      }
    },
    rules: {
      "eol-last": ["error", "always"],
      "no-trailing-spaces": "error",
      "indent": ["error", 2],
      "quotes": ["error", "single"],
      "semi": ["error", "always"],
      "no-unused-vars": ["error", { 
        "argsIgnorePattern": "^_", 
        "varsIgnorePattern": "^_",
        "caughtErrorsIgnorePattern": "^_"
      }]
    }
  }
];