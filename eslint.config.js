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
      "pnpm-lock.yaml",
      "lib/murky/**",
      "lib/solady/**",
      "lib/solmate/**",
      "lib/prb-test/**",
      "lib/forge-std/**",
      "lib/properties/**",
      "lib/create-util/**",
      "lib/erc4626-tests/**",
      "lib/FreshCryptoLib/**",
      "lib/halmos-cheatcodes/**",
      "lib/solidity-bytes-utils/**",
      "lib/openzeppelin-contracts/**",
      "echidna-corpus/**",
      "crytic-export/**",
      "cache/**",
      "out/**",
      "dist/**",
    ],
  },
];
