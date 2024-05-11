/* eslint-disable no-undef */
const { secp256r1 } = require("@noble/curves/p256");
const { hexlify } = require("ethers");

privateKey = process.argv[2].slice(2);
publicKey = secp256r1.getPublicKey(privateKey, false);

process.stdout.write(hexlify(publicKey));
