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

test('collapses repeated spaces into one dash (#41)', () => {
  assert.strictEqual(slugify('Hello   World'), 'hello-world');
  assert.strictEqual(slugify('Hello\t\n World'), 'hello-world');
});

test('collapses spaces around a dash into one dash (#41)', () => {
  assert.strictEqual(slugify('Rock - Paper'), 'rock-paper');
  assert.strictEqual(slugify('Rock -- Paper'), 'rock-paper');
});

test('collapses separators left by stripped punctuation (#41)', () => {
  assert.strictEqual(slugify('Salt & Pepper'), 'salt-pepper');
});
