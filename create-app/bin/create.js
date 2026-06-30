#!/usr/bin/env node
import { main } from '../src/index.js';

const targetDir = process.argv[2];
main(targetDir).catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
