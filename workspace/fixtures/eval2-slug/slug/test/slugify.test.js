'use strict';
const test = require('node:test');
const assert = require('node:assert');
const { slugify } = require('../src/index.js');

test('lowercases and dashes words', () => {
  assert.strictEqual(slugify('Hello World'), 'hello-world');
});

test('strips punctuation', () => {
  assert.strictEqual(slugify('Hello, World!'), 'hello-world');
});

test('removes accents', () => {
  assert.strictEqual(slugify('Crème Brûlée'), 'creme-brulee');
});
