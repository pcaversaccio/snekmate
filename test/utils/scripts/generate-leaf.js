const keccak256 = require("keccak256");
const elements = require("./elements.js");

const leaf = "0x" + keccak256(elements[0]).toString("hex");

// eslint-disable-next-line no-undef
process.stdout.write(leaf);
