const eslint = require("@eslint/js");
const eslintConfigPrettier = require("eslint-config-prettier");

module.exports = [
  eslint.configs.recommended,
  eslintConfigPrettier,
  {
    files: ["**/*.js"],
    languageOptions: {
      sourceType: "commonjs",
      ecmaVersion: "latest",
    },
  },
  {
    ignores: [
      "node_modules/**",
      "lib/murky/**",
      "lib/solady/**",
      "lib/solmate/**",
      "lib/prb-test/**",
      "lib/forge-std/**",
      "lib/create-util/**",
      "lib/erc4626-tests/**",
      "lib/solidity-bytes-utils/**",
      "lib/openzeppelin-contracts/**",
      "cache/**",
      "out/**",
      "dist/**",
    ],
  },
];
